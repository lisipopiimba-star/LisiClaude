//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import QtQuick

// LisiOS shell: обои, верхняя панель, нижняя панель (dock), меню Lisi AI, уведомления, центр управления, сплэш.
ShellRoot {
    // id намеренно не совпадают с именами свойств (cfg/status), чтобы привязки «cfg: cfgObj»
    // не зависели от порядка разрешения имён в QML
    Cfg { id: cfgObj }
    Status { id: statusObj }

    Variants {
        model: Quickshell.screens
        Scope {
            required property var modelData
            Wallpaper { screen: modelData; cfg: cfgObj }
            TopBar { screen: modelData; cfg: cfgObj; status: statusObj; onControlRequested: cc.open = !cc.open }
            Dock { screen: modelData; cfg: cfgObj; onLauncherRequested: launcher.open = !launcher.open }
        }
    }

    Launcher { id: launcher; cfg: cfgObj }
    ControlCenter { id: cc; cfg: cfgObj; status: statusObj }
    Notifications { cfg: cfgObj }
    Splash { cfg: cfgObj }

    IpcHandler {
        target: "launcher"
        function toggle(): void { launcher.open = !launcher.open }
    }
    IpcHandler {
        target: "controlcenter"
        function toggle(): void { cc.open = !cc.open }
    }
}
