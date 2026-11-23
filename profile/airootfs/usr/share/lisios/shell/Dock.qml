import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

// Нижняя панель LisiOS. Левая кнопка открывает меню приложений.
PanelWindow {
    id: dock
    required property var cfg
    signal launcherRequested()

    WlrLayershell.namespace: "lisios-dock"
    anchors { bottom: true }
    margins { bottom: 8 }
    implicitWidth: row.implicitWidth + 28
    implicitHeight: 74
    exclusiveZone: 66
    color: "transparent"

    readonly property var pinned: [
        { id: "thunar", key: "files", cmd: ["thunar"], icon: "system-file-manager" },
        { id: "firefox", key: "browser", cmd: ["firefox"], icon: "firefox" },
        { id: "kitty", key: "terminal", cmd: ["kitty"], icon: "utilities-terminal" },
        { id: "lisios-settings", key: "settings", cmd: ["lisios-settings"], icon: "preferences-system" }
    ]
    function running(id) {
        const list = ToplevelManager.toplevels.values
        for (let i = 0; i < list.length; i++) if ((list[i].appId || "").toLowerCase().indexOf(id) >= 0) return true
        return false
    }

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 6
        radius: 24
        color: "#c0161620"
        border.color: "#26ffffff"
        border.width: 1

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 12

            // Меню приложений LisiOS
            Item {
                width: 54; height: 54
                anchors.verticalCenter: parent.verticalCenter
                scale: aiMa.containsMouse ? 1.18 : 1
                Behavior on scale { NumberAnimation { duration: cfg.dur(160); easing.type: Easing.OutBack } }
                Rectangle { anchors.fill: parent; radius: 16; color: "#181818"; border.color: "#f07812"; border.width: 1 }
                Image { anchors.centerIn: parent; width: 36; height: 36; source: "file://" + cfg.logo; fillMode: Image.PreserveAspectFit; smooth: true }
                MouseArea { id: aiMa; anchors.fill: parent; hoverEnabled: true; onClicked: dock.launcherRequested() }
            }
            Rectangle { width: 1; height: 40; color: "#30ffffff"; anchors.verticalCenter: parent.verticalCenter }

            Repeater {
                model: dock.pinned
                delegate: Item {
                    required property var modelData
                    width: 54; height: 54
                    anchors.verticalCenter: parent.verticalCenter
                    scale: ma.containsMouse ? 1.22 : 1
                    transformOrigin: Item.Bottom
                    Behavior on scale { NumberAnimation { duration: cfg.dur(160); easing.type: Easing.OutBack } }
                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: 46
                        source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                    }
                    Rectangle {
                        visible: dock.running(modelData.id)
                        width: 5; height: 5; radius: 3; color: "white"
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: -4 }
                    }
                    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: Quickshell.execDetached(modelData.cmd) }
                }
            }
        }
    }
}
