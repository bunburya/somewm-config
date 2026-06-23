local awful = require("awful")
local naughty = require("naughty")
local wibox = require("wibox")
local utils = require("utils")

local custom_widgets = {}

-- Separators

custom_widgets.bar_sep = wibox.widget.textbox(" | ")
custom_widgets.space_sep = wibox.widget.textbox(" ")

-- Volume widget

custom_widgets.volume = wibox.widget {
    {
        image = "/home/alan/.config/awesome/themes/custom/speaker.png",
        widget = wibox.widget.imagebox,
    },
    {
        id = "level",
        widget = wibox.widget.textbox,
    },
    layout = wibox.layout.fixed.horizontal,
    buttons = {
        awful.button({}, 1, function () awful.spawn("amixer -c 0 sset Master toggle") end)
    }
}

function update_volume(stdout)
	-- stdout here is the output of calling amixer -c 0 sget Master
	local level, sound_status = string.match(stdout, "%[(%d+%%)%] %[%-?%d+%.%d%ddB%] %[(%a+)%]")
	local text = " <b>" .. level .. "</b>"
    if sound_status == "off" then
        text = "<span color=\"red\">" .. text .. "</span>"
    end
	    custom_widgets.volume:get_children_by_id("level")[1]:set_markup(text)
end

-- set initial value
awful.spawn.easy_async("amixer -c 0 sget Master", update_volume)
-- listen to `alsactl` for changes and update each time
awful.spawn.with_line_callback("unbuffer alsactl monitor", { 
    stdout = function() awful.spawn.easy_async("amixer -c 0 sget Master", update_volume)  end
})



-- Battery widget

-- Displays battery charge as %, and indicates charging/discharging
-- status with +/- after the battery level.
-- Color coding and notifications alert user if battery is reaching
-- very low levels.

local bat_status = {
    present = nil,
    dis_charge = nil,
    level = nil
}

-- Set the initial status
local init_bat_status = io.popen("acpi -b"):read("*all")
if init_bat_status == "" then
    bat_status.present = false
else
    bat_status.present = true
    local dis_charge, level = string.match(init_bat_status, "(%a+), (%d+)%%")
    if dis_charge == "Full" then
        bat_status.dis_charge = "FullyCharged"
    else
        bat_status.dis_charge = dis_charge
    end
    bat_status.level = tonumber(level)
end

custom_widgets.battery = wibox.widget {
    {
        image = "/home/alan/.config/awesome/themes/custom/battery.png",
        widget = wibox.widget.imagebox,
    },
    {
        id = "level",
        widget = wibox.widget.textbox,
    },
    layout = wibox.layout.fixed.horizontal,
}

function update_battery(status)
    local text
	if not status.present then
		text = " <b>removed</b> "
	else		
		if status.dis_charge == "Discharging" then
			if status.level <= 10 then
				text = ' <b><span color="red">' .. status.level .. '%-</span></b> '
				naughty.notify({ 
                    text = "Battery is running low.\n" .. status.level .. "% remaining.",
                    title = "Low battery" 
                })
			else
				text = " <b>" .. status.level .. "%-</b> "
			end
		elseif status.dis_charge == "Charging" then
			text = " <b>" .. status.level .. "%+</b> "
		elseif status.dis_charge == "FullyCharged" then
			text = ' <b><span color="green">' .. status.level .. '%</span></b> '
		end
	end
	custom_widgets.battery:get_children_by_id("level")[1]:set_markup(text)
end

local dbus = dbus

dbus.add_match(
    "system",
    "type='signal',"
        .."interface='org.freedesktop.DBus.Properties',"
        .."member='PropertiesChanged',"
        .."path='/org/freedesktop/UPower/devices/battery_BAT0'"
)

local dbus_vals = {
    "Unknown",
    "Charging",
    "Discharging",
    "Empty",
    "FullyCharged",
    "PendingCharge",
    "PendingDischarge"
}

dbus.connect_signal("org.freedesktop.DBus.Properties", function(...)
    local args = { ... }
    if args[1].path ~= "/org/freedesktop/UPower/devices/battery_BAT0" then return end
    local values = args[3]
    if values["State"] ~= nil then bat_status.dis_charge = dbus_vals[values["State"]+1] end
    if values["Percentage"] ~= nil then bat_status.level = math.ceil(values["Percentage"]) end

    update_battery(bat_status)
end)

update_battery(bat_status)

-- RAM widget

custom_widgets.memory = awful.widget.watch("free --bytes", 2, function(widget, stdout)
    local used, total = utils.parse_free(stdout)
    local pct = math.floor((used / total) * 100)
    widget:set_markup(string.format("<b>RAM:</b> %s (%d%%)", utils.format_bytes(used), pct))
end)
 
-- CPU usage widget
        
-- Check CPU temp.  The bash outputs CPU temp in a format like "41.2°C"
local cpu_temp = awful.widget.watch('bash -c "sensors | grep \\"Package id 0:\\" | awk -F \' \' \'{print $4}\' | cut -c 2-"', 5,
    function(widget, stdout)
        -- strip spaces and newline from output
        widget:set_markup('('..string.gsub(stdout, "%s*\n", "")..')') 
    end
)

custom_widgets.cpu = wibox.widget {
    {
        markup = "<b>CPU: </b>",
        widget = wibox.widget.textbox,
    },
    {
        id = "use",
        widget = wibox.widget.textbox,
    },
    {
        markup = " ",
        widget = wibox.widget.textbox,
    },
    cpu_temp,
    layout = wibox.layout.fixed.horizontal,
}

function handle_mpstat_output(stdout)
    if string.find(stdout, "all") then
        local idle = tonumber(utils.splitstr(stdout)[12])
        local busy = 100 - idle
        custom_widgets.cpu:get_children_by_id("use")[1]:set_markup(math.floor(busy+0.5).."%")
    end
end

awful.spawn.with_line_callback('mpstat 3', { stdout = handle_mpstat_output })

-- Net usage widget

local netstats = {up = 0, down = 0}
local net_count_interval = 2
custom_widgets.net = awful.widget.watch("grep wlan0 /proc/net/dev", net_count_interval, function(widget, stdout)
    local down, up = utils.parse_net_dev(stdout)
    -- divide by two to get per-second value
    local d_down = math.floor((down - netstats["down"]) / net_count_interval)
    local d_up = math.floor((up - netstats["up"]) / net_count_interval)
    netstats["down"] = down
    netstats["up"] = up
    down_hr = utils.format_bytes(d_down)
    up_hr = utils.format_bytes(d_up)
    widget:set_markup(string.format("<b>NET:</b> %s ↑ %s ↓", up_hr, down_hr))
end)

-- Drive usage widget

local mountpoints = { ["/"] = "main", ["/mnt/storage"] = "storage" }
custom_widgets.hdd = awful.widget.watch("df", 5, function(widget, stdout)
    local stats = utils.parse_df(stdout, mountpoints)
    local main = stats["main"]
    local main_total = main[1] / 1000000
    local main_used = main[2] / 1000000
    local storage = stats["storage"]
    local storage_total = storage[1] / 1000000
    local storage_used = storage[2] / 1000000
    widget:set_markup(string.format("<b>main:</b> %.1f / %.1f GB <b>storage:</b> %.1f / %.1f GB", main_used, main_total, storage_used, storage_total))
end)

-- Pending upgrades widget

custom_widgets.updates = awful.widget.watch("bash -c \"trizen -Qu | wc -l\"", 300, function(widget, stdout)
    widget:set_markup(string.format("<b>UPDATES:</b> %d", stdout))
end)

-- Now playing widget

local np_cmd = "playerctl --format '{{status}} {{artist}} - {{title}}' -F metadata"

function get_now_playing(output_str)
    -- Parse output of `np_cmd` and get message to display
    local i, _ = string.find(output_str, ' ')
    local status = string.sub(output_str, 0, i-1)
    if status == "Paused" or status == "Stopped" then return "N/A" end
    return ' ' .. string.sub(output_str, i+1) .. ' '
end

custom_widgets.now_playing = wibox.widget {
    {
        markup = "<b>PLAYING: </b>",
        widget = wibox.widget.textbox,
    },
    {
        {
            id = "status",
            markup = "N/A",
            widget = wibox.widget.textbox,
        },
        layout = wibox.container.scroll.horizontal,
    },
    layout = wibox.layout.align.horizontal,
}

awful.spawn.with_line_callback(np_cmd, {stdout = function(line)
    local np = get_now_playing(line)
    custom_widgets.now_playing:get_children_by_id("status")[1]:set_markup(np)
    if np ~= "N/A" then naughty.notify({ title = "Now playing", text = np }) end
end})

return custom_widgets
