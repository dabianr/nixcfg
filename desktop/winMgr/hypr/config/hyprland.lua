-- Hyprland 0.57 (Lua config) · 键位对齐 niri
-- 文档: https://wiki.hypr.land/0.57.0/

local mod     = "SUPER"
local term    = "kitty"
local browser = "brave"
local files   = "thunar"
local menu    = "noctalia msg panel-toggle launcher"

----------------------------------------
-- 显示器 / 环境
----------------------------------------
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

hl.env("TERM", "xterm-kitty")
hl.env("TERMINAL", term)
hl.env("XCURSOR_SIZE", "27")
hl.env("HYPRCURSOR_SIZE", "24")

----------------------------------------
-- 外观 (niri: 4px gap / 12px 圆角 / Catppuccin)
----------------------------------------
hl.config({
    general = {
        gaps_in     = 4,
        gaps_out    = 4,
        border_size = 2,
        layout      = "scrolling",
        col = {
            active_border   = "rgba(cba6f7ff)",
            inactive_border = "rgba(1e1e2eee)",
        },
    },
    decoration = {
        rounding = 12,
        shadow   = { enabled = true, range = 4, render_power = 3, color = 0x70000000 },
        blur     = { enabled = true, size = 3, passes = 1, vibrancy = 0.1696 },
    },
    scrolling = {
        direction                = "right",
        column_width             = 0.5,
        fullscreen_on_one_column = false, -- niri 单列也保持 50% 宽
    },
    input = {
        kb_layout          = "us",
        kb_options         = "caps:swapescape",
        numlock_by_default = true,
        follow_mouse       = 2, -- 悬停不抢键盘焦点, 点击才切; 避免半露窗口被 hover 拉进视野
        touchpad           = { natural_scroll = true },
    },
    binds = {
        movefocus_cycles_fullscreen = true,
    },
    cursor = {
        no_warps = true, -- 焦点变化时不把鼠标吸到窗口中心
    },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
    },
})

----------------------------------------
-- 动画 (比默认快约 4x; speed 单位 = 100ms)
----------------------------------------
hl.animation({ leaf = "global",      enabled = true, speed = 3,   bezier = "default" })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 1,   bezier = "default" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 0.5, bezier = "linear" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 1,   bezier = "default" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 1,   bezier = "default" })
hl.animation({ leaf = "layersIn",    enabled = true, speed = 1,   bezier = "default" })
hl.animation({ leaf = "layersOut",   enabled = true, speed = 0.5, bezier = "linear" })
hl.animation({ leaf = "fade",        enabled = true, speed = 1,   bezier = "default" })
hl.animation({ leaf = "border",      enabled = true, speed = 1.5, bezier = "default" })

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

----------------------------------------
-- 自启动 (同 niri)
----------------------------------------
hl.on("hyprland.start", function()
    hl.exec_cmd("noctalia")
    hl.exec_cmd("fcitx5 --replace")
    hl.exec_cmd("waypaper --restore")
end)

----------------------------------------
-- 应用 / 会话
----------------------------------------
hl.bind(mod .. " + T", hl.dsp.exec_cmd(term))
hl.bind(mod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mod .. " + E", hl.dsp.exec_cmd(files))
hl.bind(mod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + ALT + L", hl.dsp.exec_cmd("noctalia msg session lock"))
hl.bind(mod .. " + SHIFT + E", hl.dsp.exit())
hl.bind("CTRL + ALT + Delete", hl.dsp.exit())
hl.bind(mod .. " + SHIFT + P", function()
    hl.timer(function() hl.dispatch(hl.dsp.dpms({ action = "disable" })) end, { timeout = 500, type = "oneshot" })
end)

----------------------------------------
-- 焦点: 列 / 窗口 / workspace
----------------------------------------
for _, k in ipairs({ "left", "H", "A" }) do
    hl.bind(mod .. " + " .. k, hl.dsp.layout("focus l"))
end
for _, k in ipairs({ "right", "L", "D" }) do
    hl.bind(mod .. " + " .. k, hl.dsp.layout("focus r"))
end
hl.bind(mod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + K", hl.dsp.focus({ direction = "up" }))
for _, k in ipairs({ "up", "W" }) do
    hl.bind(mod .. " + " .. k, hl.dsp.focus({ workspace = "r-1" }))
end
for _, k in ipairs({ "down", "S" }) do
    hl.bind(mod .. " + " .. k, hl.dsp.focus({ workspace = "r+1" }))
end

----------------------------------------
-- 移动: 列 / 窗口 / workspace
----------------------------------------
for _, k in ipairs({ "left", "H", "A" }) do
    hl.bind(mod .. " + CTRL + " .. k, hl.dsp.layout("swapcol l"))
end
for _, k in ipairs({ "right", "L", "D" }) do
    hl.bind(mod .. " + CTRL + " .. k, hl.dsp.layout("swapcol r"))
end
hl.bind(mod .. " + CTRL + J", hl.dsp.window.move({ direction = "down" }))
hl.bind(mod .. " + CTRL + K", hl.dsp.window.move({ direction = "up" }))
for _, k in ipairs({ "up", "W" }) do
    hl.bind(mod .. " + CTRL + " .. k, hl.dsp.window.move({ workspace = "r-1" }))
end
for _, k in ipairs({ "down", "S" }) do
    hl.bind(mod .. " + CTRL + " .. k, hl.dsp.window.move({ workspace = "r+1" }))
end

----------------------------------------
-- 多显示器 (niri: Shift 焦点 / Shift+Ctrl 移动)
----------------------------------------
for dir, keys in pairs({ l = { "left", "H" }, r = { "right", "L" }, u = { "up", "K" }, d = { "down", "J" } }) do
    for _, k in ipairs(keys) do
        hl.bind(mod .. " + SHIFT + " .. k, hl.dsp.focus({ monitor = dir }))
        hl.bind(mod .. " + SHIFT + CTRL + " .. k, hl.dsp.window.move({ monitor = dir }))
    end
end

----------------------------------------
-- workspace 1-9
----------------------------------------
for i = 1, 9 do
    hl.bind(mod .. " + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + CTRL + " .. i, hl.dsp.window.move({ workspace = i }))
end

----------------------------------------
-- 列 / 窗口
----------------------------------------
hl.bind(mod .. " + G", hl.dsp.layout("colresize +conf"))
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mod .. " + CTRL + F", hl.dsp.layout("fit expand"))
hl.bind(mod .. " + C", hl.dsp.layout("center"))
hl.bind(mod .. " + minus", hl.dsp.layout("colresize -0.1"))
hl.bind(mod .. " + equal", hl.dsp.layout("colresize +0.1"))
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + X", hl.dsp.group.toggle())
hl.bind(mod .. " + bracketleft", hl.dsp.layout("consume_or_expel prev"))
hl.bind(mod .. " + bracketright", hl.dsp.layout("consume_or_expel next"))
hl.bind(mod .. " + comma", hl.dsp.layout("consume"))
hl.bind(mod .. " + period", hl.dsp.layout("expel"))

----------------------------------------
-- 鼠标
----------------------------------------
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "r+1" }))
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "r-1" }))
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

----------------------------------------
-- 截图 (niri: Print / Ctrl+Print / Alt+Print)
----------------------------------------
hl.bind("Print", hl.dsp.exec_cmd("noctalia msg screenshot-region"))
hl.bind("CTRL + Print", hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen"))
hl.bind("ALT + Print", hl.dsp.exec_cmd("noctalia msg screenshot-window"))

----------------------------------------
-- 媒体键 (同 niri)
----------------------------------------
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("noctalia msg volume-up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("noctalia msg volume-down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("noctalia msg volume-mute"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("noctalia msg mic-mute"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("noctalia msg brightness-up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("noctalia msg brightness-down"), { locked = true, repeating = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("noctalia msg media toggle"), { locked = true })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("noctalia msg media stop"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("noctalia msg media previous"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("noctalia msg media next"), { locked = true })

----------------------------------------
-- 窗口规则
----------------------------------------
hl.window_rule({
    name = "suppress-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "fix-xwayland-drag",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

hl.window_rule({
    name = "pip-float",
    match = { class = "firefox$", title = "^Picture-in-Picture$" },
    float = true,
})

hl.window_rule({
    name = "thunar-rename-float",
    match = { class = "thunar", title = "^重命名 “" },
    float = true,
})

-- 浏览器 / 编辑器默认占满整列 (niri: default-column-width {})
hl.window_rule({
    name = "wide-apps",
    match = { class = [[firefox$|^brave-browser$|^code$|^codium$|^dev\.zed\.Zed$]] },
    scrolling_width = 1.0,
})
