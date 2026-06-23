-- awesome_mode: api-level=4:screen=on
-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

local lfs = require("lfs")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
-- Declarative object management
local ruled = require("ruled")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

local custom_widgets = require("custom_widgets")

-- {{{ Input configuration

awful.input.xkb_layout = "ie"
awful.input.send_events_mode = "disbled_on_external_mouse"
awful.input.middle_button_emulation = 1
awful.input.tap_to_click = 1
awful.input.tap_button_map = "lmr"
awesome._set_keyboard_setting("numlock", true)

-- }}}


-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
naughty.connect_signal("request::display_error", function(message, startup)
    naughty.notification {
        urgency = "critical",
        title   = "Oops, an error happened"..(startup and " during startup!" or "!"),
        message = message
    }
end)

-- Show notification if we fell back due to X11-specific patterns in user config
if awesome.x11_fallback_info then
    -- Defer notification until after startup (naughty needs event loop running)
    gears.timer.delayed_call(function()
        local info = awesome.x11_fallback_info
        local msg = string.format(
            "Your config was skipped because it contains X11-specific code that " ..
            "won't work on Wayland.\n\n" ..
            "File: %s:%d\n" ..
            "Pattern: %s\n" ..
            "Code: %s\n\n" ..
            "Suggestion: %s\n\n" ..
            "Edit your rc.lua to remove X11 dependencies, then restart somewm.",
            info.config_path or "unknown",
            info.line_number or 0,
            info.pattern or "unknown",
            info.line_content or "",
            info.suggestion or "See somewm migration guide"
        )
        naughty.notification {
            urgency = "critical",
            title   = "Config contains X11 patterns - using fallback",
            message = msg,
            timeout = 0  -- Don't auto-dismiss
        }
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")

-- Initialize lockscreen (must be after beautiful.init)
require("lockscreen").init()

-- This is used later as the default terminal and editor to run.
terminal = "xterm"
editor = os.getenv("EDITOR") or "nano"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Path to directory where the background images are stored
wallpaper_dir = ('/home/alan/pics/backgrounds/')
-- Directory to which screenshots are to be saved
scrn_dir = "/home/alan/pics/screenshots"

-- Shutdown, suspend and restart
shutdown = "shutdown -h now"
reboot = "reboot"
reboot_bios = "systemctl reboot --firmware-setup"
suspend = "pm-suspend"

-- Browser
browser = "firefox"

-- Default terminal and editor.
terminal = "kitty"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor
python = terminal .. " -e ipython"

-- File manager
fm = "pcmanfm"

-- Whether the info bar at the bottom is visible
info_vis = false

-- Useful functions
function splitstr(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

function sleep (n)
    os.execute("sleep " .. tonumber(n))
end

-- }}}

-- {{{ Menu
-- Create a launcher widget and a main menu
local gamesmenu = {
    { "armagetron", "armagetronad" },
    { "corsix-th", "CorsixTH" },
    { "openttd", "openttd"},
    { "supertuxkart", "supertuxkart" },
    { "warzone 2100", "warzone2100" },
    { "wesnoth", "wesnoth" },
    { "morrowind", "openmw"},
    { "nethack", terminal.." -e nethack" },
    { "steam", "steam" }
}

local netmenu = {
    { "firefox", "firefox" },
    { "surf", "surf" },
    { "elinks", terminal.." -e elinks" },
    { "thunderbird", "thunderbird" },
}

local officemenu = {
    { "libreoffice", "libreoffice" },
    { "-base", "libreoffice -base" },
    { "-calc", "libreoffice -calc" },
    { "-impress", "libreoffice -impress" },
    { "-writer", "libreoffice -writer" },
    { "zathura (pdf)", "zathopen" }
}

local mediamenu = {
    { "spotify", "spotify" },
    { "vlc", "vlc" },
    { "mirage (imgs)", "mirage" },
    { "gimp", "gimp" }
}

local progmenu = {
    { "geany", "geany" },
    { "vim", terminal .. " -e vim" },
    { "helix", terminal .. " -e helix" },
    { "python", terminal .. " -e python" }
}

local sysmenu = {
    { "hotkeys", function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
    { "home", fm },
    { "terminal", terminal },
    { "tasks", terminal .. " -e top" },
    { "restart", awesome.restart },
    { "logout", awesome.quit },
    { "reboot", reboot },
    { "reboot (bios)", reboot_bios },
    { "suspend", suspend },
    { "shutdown", shutdown }
}
 
mymainmenu = awful.menu({ items = { 
    { "games", gamesmenu },
    { "internet", netmenu },
    { "office", officemenu },
    { "media", mediamenu },
    { "prog", progmenu },
    { "system", sysmenu },
}})
 
mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- {{{ Tag layout
-- Table of layouts to cover with awful.layout.inc, order matters.
tag.connect_signal("request::default_layouts", function()
    awful.layout.append_default_layouts({
        awful.layout.suit.floating,
        awful.layout.suit.tile,
        awful.layout.suit.tile.left,
        awful.layout.suit.tile.bottom,
        awful.layout.suit.tile.top,
        awful.layout.suit.fair,
        awful.layout.suit.fair.horizontal,
        awful.layout.suit.spiral,
        awful.layout.suit.spiral.dwindle,
        awful.layout.suit.max,
        awful.layout.suit.max.fullscreen,
        awful.layout.suit.magnifier,
        awful.layout.suit.corner.nw,
    })
end)
-- }}}

-- {{{ Wallpaper

-- Set random wallpaper from wallpapers folder
local wallpapers = {}
for fpath in lfs.dir(wallpaper_dir) do
    if fpath ~= "." and fpath ~= ".." then
        table.insert(wallpapers, string.format("%s/%s", wallpaper_dir, fpath))
    end
end
math.randomseed(os.time())

screen.connect_signal("request::wallpaper", function(s)
    awful.wallpaper {
        screen = s,
        widget = {
            {
                image     = wallpapers[math.random(1, #wallpapers)] or beautiful.wallpaper,
                upscale   = true,
                downscale = true,
                widget    = wibox.widget.imagebox,
            },
            valign = "center",
            halign = "center",
            tiled  = false,
            widget = wibox.container.tile,
        }
    }
end)
-- }}}

-- {{{ Tag persistence across monitor hotplug
-- The save handler lives in awful.permissions.tag_screen and stores tag
-- metadata into awful.permissions.saved_tags keyed by connector name.
-- To disable or replace it:
--   tag.disconnect_signal("request::screen", awful.permissions.tag_screen)
-- }}}

-- {{{ Wibar

-- Unless there is a compelling reason to do otherwise, add new tags to the end.
-- Otherwise we have to go and change the rules relating to specific apps later on.

local layouts = awful.layout.layouts

-- Main screen (ie, laptop screen)
local main_tag_names = {"general", "email", "music", "prog", "misc"}
local main_tag_layouts = {layouts[1], layouts[10], layouts[10], layouts[3], layouts[3]}

-- Each spare screen (eg, external monitor)
local spare_tag_names = {'spare'}
local spare_tag_layouts = {layouts[1]}

-- Keyboard map indicator and switcher
local mykeyboardlayout = awful.widget.keyboardlayout()

-- Create a textclock widget
local mytextclock = wibox.widget.textclock()

screen.connect_signal("request::desktop_decoration", function(s)
    -- Restore saved tags if this output was previously removed
    local output_name = s.output and s.output.name
    local restore = output_name and awful.permissions.saved_tags[output_name]
    if restore then
        awful.permissions.saved_tags[output_name] = nil
        -- Pass 1: recreate tags and build per-client tag lists
        local client_tags = {}
        for _, td in ipairs(restore) do
            local t = awful.tag.add(td.name, {
                screen = s,
                layout = td.layout,
                master_width_factor = td.master_width_factor,
                master_count = td.master_count,
                gap = td.gap,
                selected = td.selected,
            })
            for _, c in ipairs(td.clients) do
                if c.valid then
                    if not client_tags[c] then
                        client_tags[c] = {}
                    end
                    table.insert(client_tags[c], t)
                end
            end
        end
        -- Pass 2: move clients and assign full tag lists
        for c, tags in pairs(client_tags) do
            c:move_to_screen(s)
            c:tags(tags)
        end
    else
        -- Each screen has its own tag table.
        if s == screen.primary then
            awful.tag(main_tag_names, s, main_tag_layouts)
        else
            awful.tag(spare_tag_names, s, spare_tag_layouts)
        end
    end

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()

    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox {
        screen  = s,
        buttons = {
            awful.button({ }, 1, function () awful.layout.inc( 1) end),
            awful.button({ }, 3, function () awful.layout.inc(-1) end),
            awful.button({ }, 4, function () awful.layout.inc(-1) end),
            awful.button({ }, 5, function () awful.layout.inc( 1) end),
        }
    }

    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.all,
        buttons = {
            awful.button({ }, 1, function(t) t:view_only() end),
            awful.button({ modkey }, 1, function(t)
                                            if client.focus then
                                                client.focus:move_to_tag(t)
                                            end
                                        end),
            awful.button({ }, 3, awful.tag.viewtoggle),
            awful.button({ modkey }, 3, function(t)
                                            if client.focus then
                                                client.focus:toggle_tag(t)
                                            end
                                        end),
            awful.button({ }, 4, function(t) awful.tag.viewprev(t.screen) end),
            awful.button({ }, 5, function(t) awful.tag.viewnext(t.screen) end),
        }
    }

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist {
        screen  = s,
        filter  = awful.widget.tasklist.filter.currenttags,
        buttons = {
            awful.button({ }, 1, function (c)
                c:activate { context = "tasklist", action = "toggle_minimization" }
            end),
            awful.button({ }, 3, function() awful.menu.client_list { theme = { width = 250 } } end),
            awful.button({ }, 4, function() awful.client.focus.byidx(-1) end),
            awful.button({ }, 5, function() awful.client.focus.byidx( 1) end),
        }
    }

    -- Create the wibox
    s.mywibox = awful.wibar {
        position = "top",
        screen   = s,
        widget   = {
            layout = wibox.layout.align.horizontal,
            { -- Left widgets
                layout = wibox.layout.fixed.horizontal,
                mylauncher,
                s.mytaglist,
                s.mypromptbox,
            },
            s.mytasklist, -- Middle widget
            { -- Right widgets
                layout = wibox.layout.fixed.horizontal,
                wibox.widget.systray(),
                custom_widgets.space_sep,
                custom_widgets.volume,
                custom_widgets.space_sep,
                custom_widgets.battery,
                mytextclock,
                s.mylayoutbox,
            },
        }
    }
    
    -- Create the info bar
    s.myinfobar = awful.wibar({position = "bottom", screen = s, ontop = true})
    s.myinfobar.visible = info_vis
    
    s.myinfobar:setup {
        layout = wibox.layout.ratio.horizontal,
        spacing_widget = wibox.widget.separator,
        spacing = 10,
        custom_widgets.memory,
        custom_widgets.cpu,
        custom_widgets.net,
        custom_widgets.hdd,
        custom_widgets.updates,
        custom_widgets.now_playing
    }
    for i, r in pairs({ 0.15, 0.15, 0.15, 0.2, 0.15, 0.2 }) do
        s.myinfobar.widget:set_ratio(i, r)
    end
end)

-- }}}

-- {{{ Mouse bindings
awful.mouse.append_global_mousebindings({
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewprev),
    awful.button({ }, 5, awful.tag.viewnext),
})
-- }}}

-- {{{ Key bindings

-- General Awesome keys
awful.keyboard.append_global_keybindings({
    awful.key({ modkey,           }, "s",      hotkeys_popup.show_help,
              {description="show help", group="awesome"}),
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end,
              {description = "show main menu", group = "awesome"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit,
              {description = "quit awesome", group = "awesome"}),
    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)          end,
              {description = "increase master width factor", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "Escape", function() awesome.lock() end,
              {description = "lock screen", group = "awesome"}),
    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run {
                    prompt       = "Run Lua code: ",
                    textbox      = awful.screen.focused().mypromptbox.widget,
                    exe_callback = awful.util.eval,
                    history_path = awful.util.get_cache_dir() .. "/history_eval"
                  }
              end,
              {description = "lua execute prompt", group = "awesome"}),
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey },            "r",     function () awful.screen.focused().mypromptbox:run() end,
              {description = "run prompt", group = "launcher"}),
    awful.key({ modkey }, "p", function() menubar.show() end,
              {description = "show the menubar", group = "launcher"}),
})

-- Tags related keybindings
awful.keyboard.append_global_keybindings({
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
              {description = "view previous", group = "tag"}),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
              {description = "view next", group = "tag"}),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore,
              {description = "go back", group = "tag"}),
})

-- Focus related keybindings
awful.keyboard.append_global_keybindings({
    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
        end,
        {description = "focus next by index", group = "client"}
    ),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
        end,
        {description = "focus previous by index", group = "client"}
    ),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end,
              {description = "focus the next screen", group = "screen"}),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end,
              {description = "focus the previous screen", group = "screen"}),
    awful.key({ modkey, "Control" }, "n",
              function ()
                  local c = awful.client.restore()
                  -- Focus restored client
                  if c then
                    c:activate { raise = true, context = "key.unminimize" }
                  end
              end,
              {description = "restore minimized", group = "client"}),
})

-- Layout related keybindings
awful.keyboard.append_global_keybindings({
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end,
              {description = "swap with next client by index", group = "client"}),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end,
              {description = "swap with previous client by index", group = "client"}),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"}),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)          end,
              {description = "decrease master width factor", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end,
              {description = "increase the number of master clients", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end,
              {description = "decrease the number of master clients", group = "layout"}),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1, nil, true)    end,
              {description = "increase the number of columns", group = "layout"}),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1, nil, true)    end,
              {description = "decrease the number of columns", group = "layout"}),
    awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end,
              {description = "select next", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end,
              {description = "select previous", group = "layout"}),
})

awful.keyboard.append_global_keybindings({
    awful.key {
        modifiers   = { modkey },
        keygroup    = "numrow",
        description = "only view tag",
        group       = "tag",
        on_press    = function (index)
            local screen = awful.screen.focused()
            local tag = screen.tags[index]
            if tag then
                tag:view_only()
            end
        end,
    },
    awful.key {
        modifiers   = { modkey, "Control" },
        keygroup    = "numrow",
        description = "toggle tag",
        group       = "tag",
        on_press    = function (index)
            local screen = awful.screen.focused()
            local tag = screen.tags[index]
            if tag then
                awful.tag.viewtoggle(tag)
            end
        end,
    },
    awful.key {
        modifiers = { modkey, "Shift" },
        keygroup    = "numrow",
        description = "move focused client to tag",
        group       = "tag",
        on_press    = function (index)
            if client.focus then
                local tag = client.focus.screen.tags[index]
                if tag then
                    client.focus:move_to_tag(tag)
                end
            end
        end,
    },
    awful.key {
        modifiers   = { modkey, "Control", "Shift" },
        keygroup    = "numrow",
        description = "toggle focused client on tag",
        group       = "tag",
        on_press    = function (index)
            if client.focus then
                local tag = client.focus.screen.tags[index]
                if tag then
                    client.focus:toggle_tag(tag)
                end
            end
        end,
    },
    awful.key {
        modifiers   = { modkey },
        keygroup    = "numpad",
        description = "select layout directly",
        group       = "layout",
        on_press    = function (index)
            local t = awful.screen.focused().selected_tag
            if t then
                t.layout = t.layouts[index] or t.layout
            end
        end,
    }
})

-- Custom keybindings
awful.keyboard.append_global_keybindings({
    
    -- Volume control
    -- NOTE: When using PulseAudio, need to use the pactl command to toggle mute, as unmuting
    -- doesn't work properly when using amixer. But changing volume with amixer seems to work fine
    -- and is more responsive than the pactl equivalent.
    awful.key({                   }, "XF86AudioLowerVolume", function () awful.spawn("amixer -D pulse -c 0 sset Master playback 5%-") end,
                {description = "decrease volume 5%", group = "audio"}),
    awful.key({                   }, "XF86AudioRaiseVolume", function () awful.spawn("amixer -D pulse -c 0 sset Master playback 5%+") end,
                {description = "increase volume 5%", group = "audio"}),
    awful.key({                   }, "XF86AudioMute", function () awful.spawn("pactl set-sink-mute 0 toggle") end,
                {description = "mute audio", group = "audio"}),
    
    -- Music control, assumes Spotify handles music with playerctl installed.
    awful.key({ modkey, "Control" }, "p", function() awful.util.spawn("playerctl play-pause") end,
                {description = "play/pause music", group="audio"}), 
    awful.key({ modkey, "Control" }, ",", function() awful.util.spawn("playerctl previous") end,
                {description = "play previous song", group="audio"}),
    awful.key({ modkey, "Control" }, ".", function() awful.util.spawn("playerctl next") end,
                {description = "play next song", group="audio"}),
    
    -- Brightness control
    awful.key({                   }, "XF86MonBrightnessDown", function () awful.spawn ("light -U 10") end,
                {description = "decrease brightness 10%", group = "screen"}),
    awful.key({                   }, "XF86MonBrightnessUp", function () awful.spawn ("light -A 10") end,
                {description = "increase brightness 10%", group = "screen"}),
    
    -- Common applications
    awful.key({ modkey,           }, "b",     function() awful.spawn(browser) end,
                {description = "launch browser", group = "applications"}),
    awful.key({                   }, "XF86Calculator",     function() awful.spawn(python) end,
                {description = "launch python interpreter", group = "applications"}),
    awful.key({ modkey,           }, "Prior", function() awful.spawn(fm) end, -- Prior = PgUp
                {description = "launch file manager", group = "applications"}),
    awful.key({ modkey,           }, "g",     function() awful.spawn("geany") end,
                {description = "launch geany", group = "applications"}),
    awful.key({ modkey,           }, "w",     function() awful.spawn("libreoffice -writer") end,
                {description = "launch libreoffice writer", group = "applications"}),
    awful.key({ modkey, "Control" }, "v", function() awful.util.spawn("mullvad") end,
                {description = "toggle wireguard (choose interface)", group = "network"}),
                
    awful.key({ modkey,           }, "v", function() awful.util.spawn("mullvad default") end,
                {description = "toggle wireguard (default interface)", group = "network"}),
    
    -- System monitoring / maintenance
    awful.key(
        { modkey,           }, "i",
        function()
            info_vis = not info_vis
            awful.screen.connect_for_each_screen(function (s) 
                if s.myinfobar ~= nil then s.myinfobar.visible = info_vis end 
            end)
        end,
        {description = "toggle infobar", group = "system"}
    ),
    awful.key({ modkey,           }, "u",     function() awful.util.spawn(terminal .. " -e trizen -Syu") end,
                {description = "update", group = "system"}),
                
    -- Screenshots
    -- sleep() is required in these functions to give awesome time to hand control of the keyboard over to scrot
    awful.key({                   }, "Print",     function() sleep(0.5); awful.util.spawn("sshost-wl") end,
                {description = "take screenshot and save locally (selection)", group = "screen"}),
    awful.key({ "Shift",          }, "Print",     function() sleep(0.5); awful.util.spawn("sshost-wl fs") end,
                {description = "take screenshot and save locally (fullscreen)", group = "screen"}),
    awful.key({ modkey,           }, "Print",     function() sleep(0.5); awful.util.spawn("sshost-wl cloud") end,
                {description = "take screenshot and upload to remote server (selection)", group = "screen"}),
    awful.key({ modkey, "Shift"   }, "Print",     function() awful.util.spawn("sshost-wl cloud fs") end,
                {description = "take screenshot and upload to remote server (fullscreen)", group = "screen"}),
})

client.connect_signal("request::default_mousebindings", function()
    awful.mouse.append_client_mousebindings({
        awful.button({ }, 1, function (c)
            c:activate { context = "mouse_click" }
        end),
        awful.button({ modkey }, 1, function (c)
            c:activate { context = "mouse_click", action = "mouse_move"  }
        end),
        awful.button({ modkey }, 3, function (c)
            c:activate { context = "mouse_click", action = "mouse_resize"}
        end),
    })
end)

client.connect_signal("request::default_keybindings", function()
    awful.keyboard.append_client_keybindings({
        awful.key({ modkey,           }, "f",
            function (c)
                c.fullscreen = not c.fullscreen
                c:raise()
            end,
            {description = "toggle fullscreen", group = "client"}),
        awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end,
                {description = "close", group = "client"}),
        awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ,
                {description = "toggle floating", group = "client"}),
        awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
                {description = "move to master", group = "client"}),
        awful.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end,
                {description = "move to screen", group = "client"}),
        awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
                {description = "toggle keep on top", group = "client"}),
        awful.key({ modkey,           }, "n",
            function (c)
                -- The client currently has the input focus, so it cannot be
                -- minimized, since minimized clients can't have the focus.
                c.minimized = true
            end ,
            {description = "minimize", group = "client"}),
        awful.key({ modkey,           }, "m",
            function (c)
                c.maximized = not c.maximized
                c:raise()
            end ,
            {description = "(un)maximize", group = "client"}),
        awful.key({ modkey, "Control" }, "m",
            function (c)
                c.maximized_vertical = not c.maximized_vertical
                c:raise()
            end ,
            {description = "(un)maximize vertically", group = "client"}),
        awful.key({ modkey, "Shift"   }, "m",
            function (c)
                c.maximized_horizontal = not c.maximized_horizontal
                c:raise()
            end ,
            {description = "(un)maximize horizontally", group = "client"}),
    })
end)

-- }}}

-- {{{ Rules
-- Rules to apply to new clients.
ruled.client.connect_signal("request::rules", function()
    -- All clients will match this rule.
    ruled.client.append_rule {
        id         = "global",
        rule       = { },
        properties = {
            focus     = awful.client.focus.filter,
            raise     = true,
            screen    = awful.screen.preferred,
            placement = awful.placement.no_overlap+awful.placement.no_offscreen
        }
    }

    -- Floating clients.
    ruled.client.append_rule {
        id       = "floating",
        rule_any = {
            instance = {
                "DTA",  -- Firefox addon DownThemAll.
                "copyq",  -- Includes session name in class.
            },
            class = {
                "Arandr",
                "Gpick",
                "Kruler",
                "MessageWin",  -- kalarm.
                "Sxiv",
                "Wpa_gui",
                "pinentry",
                "veromix",
                "xtightvncviewer",
                "Mplayer",
                "Tilda",
                "pinentry",
                "gimp"
            },
            -- Note that the name property shown in xprop might be set slightly after creation of the client
            -- and the name shown there might not match defined rules here.
            name    = {
                "Event Tester",  -- xev.
            },
            role    = {
                "AlarmWindow",    -- Thunderbird's calendar.
                "ConfigManager",  -- Thunderbird's about:config.
                "pop-up",         -- e.g. Google Chrome's (detached) Developer Tools.
            }
        },
        properties = { floating = true }
    }
    
    -- Disable titlebars for normal clients and dialogs
    ruled.client.append_rule {
        id         = "titlebars",
        rule_any   = { type = { "normal", "dialog" } },
        properties = { titlebars_enabled = false      }
    }

    -- Autoplacement rules for specific apps
    ruled.client.append_rule {
        rule       = { class = "org.mozilla.Thunderbird" },
        properties = { screen = screen.primary, tag = "email" }
    }
    ruled.client.append_rule {
        rule       = { class = "Spotify" },
        properties = { screen = screen.primary, tag = "music" }
    }
    ruled.client.append_rule {
        rule_any = { class = { "jetbrains-pycharm-ce", "jetbrains-studio", "jetbrains-idea-ce" } },
        properties = { screen = screen.primary, tag = "prog" }
    }
    ruled.client.append_rule {
        rule       = { class = "Steam" },
        properties = { screen = screen.primary, tag = "general" }
    }

end)
-- }}}

-- {{{ Titlebars
-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = {
        awful.button({ }, 1, function()
            c:activate { context = "titlebar", action = "mouse_move"  }
        end),
        awful.button({ }, 3, function()
            c:activate { context = "titlebar", action = "mouse_resize"}
        end),
    }

    awful.titlebar(c).widget = {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                halign = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton (c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton   (c),
            awful.titlebar.widget.ontopbutton    (c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)
-- }}}

-- {{{ Notifications

ruled.notification.connect_signal('request::rules', function()
    -- All notifications will match this rule.
    ruled.notification.append_rule {
        rule       = { },
        properties = {
            screen           = awful.screen.preferred,
            implicit_timeout = 5,
        }
    }
end)

naughty.connect_signal("request::display", function(n)
    naughty.layout.box { notification = n }
end)

-- }}}

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    c:activate { context = "mouse_enter", raise = false }
end)

-- {{{ Autostart
awful.spawn.with_shell(
    -- list each of your autostart commands, followed by ; inside single quotes, followed by ..
    'dex --environment SomeWM --autostart'
)
-- }}}
