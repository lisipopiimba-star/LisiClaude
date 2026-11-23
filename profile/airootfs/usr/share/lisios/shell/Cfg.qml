import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Настройки оболочки: /etc/lisios/config.json, поверх - ~/.config/lisios/config.json (меняется в «Системных настройках»)
Scope {
    id: root
    property string lang: "ru"
    property real speed: 1.0
    property string wallpaper: "/usr/share/lisios/wallpapers/default.png"
    property string logo: "/usr/share/lisios/branding/logo.png"
    property string aiEndpoint: ""
    property var sysCfg: ({})
    property var usrCfg: ({})

    function dur(ms) { return Math.max(1, Math.round(ms / Math.max(0.1, root.speed))) }

    // Hyprland 0.57+ принимает в `dispatch` только Lua-выражения (hl.dsp.*), более старые - классические
    // диспетчеры. Какой вариант активен, сообщает lisios-session через LISIOS_HYPR_LUA.
    readonly property bool hyprLua: Quickshell.env("LISIOS_HYPR_LUA") === "1"
    // Действия оконного менеджера для кнопок панели: close | minimize | maximize | exit
    function wm(action) {
        const lua = {
            close: "hl.dsp.window.close()",
            minimize: 'hl.dsp.window.move({ workspace = "special:minimized", follow = false })',
            maximize: 'hl.dsp.window.fullscreen({ mode = "maximized" })',
            exit: "hl.dsp.exit()"
        }
        const legacy = {
            close: "killactive",
            minimize: "movetoworkspacesilent special:minimized",
            maximize: "fullscreen 1",
            exit: "exit"
        }
        const d = (root.hyprLua ? lua : legacy)[action]
        if (d) Hyprland.dispatch(d)
    }

    function merge() {
        const c = Object.assign({}, sysCfg, usrCfg)
        if (c.lang === "ru" || c.lang === "en") lang = c.lang
        if (typeof c.animation_speed === "number") speed = c.animation_speed
        if (c.wallpaper) wallpaper = c.wallpaper
        if (c.ai && c.ai.endpoint) aiEndpoint = c.ai.endpoint; else aiEndpoint = ""
        const home = Quickshell.env("HOME")
        // пользовательский логотип имеет приоритет
        logo = "/usr/share/lisios/branding/logo.png"
    }

    FileView {
        path: "/etc/lisios/config.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: { try { root.sysCfg = JSON.parse(text()) } catch (e) { root.sysCfg = ({}) } root.merge() }
    }
    FileView {
        path: Quickshell.env("HOME") + "/.config/lisios/config.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: { try { root.usrCfg = JSON.parse(text()) } catch (e) { root.usrCfg = ({}) } root.merge() }
        onLoadFailed: { root.usrCfg = ({}); root.merge() }
    }

    readonly property var strings: ({
        ru: {
            search: "Поиск приложений или вопрос Lisi AI", apps: "Приложения", ai: "Lisi AI",
            ai_off: "Lisi AI пока не подключён. Укажите адрес API в «Системных настройках».",
            ai_ask: "Спросить Lisi AI", none: "Ничего не найдено", settings: "Системные настройки",
            about: "О LisiOS", wifi: "Wi-Fi", bluetooth: "Bluetooth", on: "Вкл", off: "Выкл",
            volume: "Громкость", brightness: "Яркость", restart: "Перезагрузить", shutdown: "Выключить",
            logout: "Выйти", gamemode: "Game Mode", gm_off: "Выкл", gm_waiting: "Ждёт игру", gm_active: "Игра в приоритете", gm_throttling: "Игра в приоритете, фон смягчён", gm_no_privilege: "Нет прав (polkit)", desktop: "Рабочий стол", files: "Файлы", browser: "Браузер", terminal: "Терминал"
        },
        en: {
            search: "Search apps or ask Lisi AI", apps: "Applications", ai: "Lisi AI",
            ai_off: "Lisi AI is not connected yet. Set the API address in System Settings.",
            ai_ask: "Ask Lisi AI", none: "Nothing found", settings: "System Settings",
            about: "About LisiOS", wifi: "Wi-Fi", bluetooth: "Bluetooth", on: "On", off: "Off",
            volume: "Volume", brightness: "Brightness", restart: "Restart", shutdown: "Shut down",
            logout: "Log out", gamemode: "Game Mode", gm_off: "Off", gm_waiting: "Waiting for a game", gm_active: "Game prioritised", gm_throttling: "Game prioritised, background eased", gm_no_privilege: "No permission (polkit)", desktop: "Desktop", files: "Files", browser: "Browser", terminal: "Terminal"
        }
    })
    function t(k) { const s = strings[lang] || strings.en; return s[k] || strings.en[k] || k }
}
