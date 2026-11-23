-- LisiOS - конфигурация Hyprland в формате Lua.
--
-- Hyprland 0.57+ больше НЕ читает hyprland.conf (поддержка удалена), поэтому для него lisios-session
-- запускает Hyprland с этим файлом:  start-hyprland -- -c ~/.config/hypr/lisios.lua
-- Для Hyprland до 0.57 используется классический hyprland.conf.
--
-- Все имена функций и параметров сверены с исходниками Hyprland v0.57.2
-- (example/hyprland.lua и src/config/lua/bindings). Если после обновления Hyprland что-то
-- не применилось, ошибка записывается в ~/.cache/lisios/hypr-lua.log, а оболочка всё равно запустится.

local HOME = os.getenv("HOME") or ""

-- Записать проблему в журнал и не прерывать остальную конфигурацию
local function log(msg)
    local f = io.open(HOME .. "/.cache/lisios/hypr-lua.log", "a")
    if f then
        f:write(os.date("%H:%M:%S ") .. tostring(msg) .. "\n")
        f:close()
    end
end

local function safe(name, fn)
    local ok, err = pcall(fn)
    if not ok then log(name .. ": " .. tostring(err)) end
end

---------------------------------------------------------------------------
-- 1. АВТОЗАПУСК ОБОЛОЧКИ - самым первым, чтобы ошибка ниже его не отменила
---------------------------------------------------------------------------
hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("hyprpolkitagent")
    hl.exec_cmd("lisios-shell")
    hl.exec_cmd("lisios-gamemode ensure")
end)

---------------------------------------------------------------------------
-- 2. ОБЩИЕ НАСТРОЙКИ
---------------------------------------------------------------------------
safe("monitor", function()
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "1" })
end)

safe("config", function()
    hl.config({
        misc = {
            disable_hyprland_logo   = true,
            disable_splash_rendering = true,
            force_default_wallpaper = 0,
            background_color        = 0xff000000,
        },
        ecosystem = {
            no_update_news   = true,
            no_donation_nag  = true,
        },
        input = {
            kb_layout    = "us,ru",
            kb_options   = "grp:alt_shift_toggle",
            follow_mouse = 1,
            touchpad = { natural_scroll = true },
        },
        general = {
            gaps_in          = 6,
            gaps_out         = 12,
            border_size      = 1,
            col = {
                active_border   = "rgba(ffffff38)",
                inactive_border = "rgba(ffffff10)",
            },
            layout           = "dwindle",
            resize_on_border = true,
        },
        decoration = {
            rounding         = 14,
            active_opacity   = 1.0,
            inactive_opacity = 0.97,
            shadow = {
                enabled      = true,
                range        = 32,
                render_power = 3,
                color        = "rgba(00000070)",
            },
            blur = {
                enabled = true,
                size    = 8,
                passes  = 3,
            },
        },
        dwindle = { preserve_split = true },
        animations = { enabled = true },
    })
end)

-- Все окна плавающие (как в предыдущей версии конфигурации)
safe("window_rule", function()
    hl.window_rule({
        name  = "lisios-float-all",
        match = { class = ".*" },
        float = true,
    })
end)

---------------------------------------------------------------------------
-- 3. АНИМАЦИИ (скорость меняют «Системные настройки» - файл lisios-animations.lua)
--    и правила сессии (создаёт lisios-session при каждом входе - lisios-generated.lua)
---------------------------------------------------------------------------
safe("animations", function() require("lisios-animations") end)
safe("generated", function() require("lisios-generated") end)

---------------------------------------------------------------------------
-- 4. КЛАВИШИ
---------------------------------------------------------------------------
local mod = "SUPER"

safe("binds", function()
    hl.bind(mod .. " + SPACE",         hl.dsp.exec_cmd("lisios-shell ipc launcher toggle"))
    hl.bind(mod .. " + Return",        hl.dsp.exec_cmd("kitty"))
    hl.bind(mod .. " + E",             hl.dsp.exec_cmd("thunar"))
    hl.bind(mod .. " + B",             hl.dsp.exec_cmd("firefox"))
    hl.bind(mod .. " + comma",         hl.dsp.exec_cmd("lisios-settings"))
    hl.bind(mod .. " + Q",             hl.dsp.window.close())
    hl.bind(mod .. " + F",             hl.dsp.window.fullscreen({ mode = "maximized" }))
    hl.bind(mod .. " + SHIFT + F",     hl.dsp.window.float({ action = "toggle" }))
    hl.bind(mod .. " + M",             hl.dsp.window.move({ workspace = "special:minimized", follow = false }))
    hl.bind(mod .. " + SHIFT + M",     hl.dsp.workspace.toggle_special("minimized"))
    hl.bind("Print",                   hl.dsp.exec_cmd([[grim -g "$(slurp)" - | wl-copy]]))

    hl.bind(mod .. " + mouse:272",     hl.dsp.window.drag(),   { mouse = true })
    hl.bind(mod .. " + mouse:273",     hl.dsp.window.resize(), { mouse = true })

    hl.bind(mod .. " + left",          hl.dsp.focus({ direction = "left" }))
    hl.bind(mod .. " + right",         hl.dsp.focus({ direction = "right" }))
    hl.bind(mod .. " + up",            hl.dsp.focus({ direction = "up" }))
    hl.bind(mod .. " + down",          hl.dsp.focus({ direction = "down" }))
    hl.bind(mod .. " + CTRL + left",   hl.dsp.focus({ workspace = "e-1" }))
    hl.bind(mod .. " + CTRL + right",  hl.dsp.focus({ workspace = "e+1" }))

    hl.bind("XF86AudioRaiseVolume",    hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
    hl.bind("XF86AudioLowerVolume",    hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),        { locked = true, repeating = true })
    hl.bind("XF86AudioMute",           hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),       { locked = true })
    hl.bind("XF86MonBrightnessUp",     hl.dsp.exec_cmd("brightnessctl set 5%+"),                            { locked = true, repeating = true })
    hl.bind("XF86MonBrightnessDown",   hl.dsp.exec_cmd("brightnessctl set 5%-"),                            { locked = true, repeating = true })
end)
