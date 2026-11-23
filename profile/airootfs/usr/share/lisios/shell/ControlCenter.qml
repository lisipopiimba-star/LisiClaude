import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Системная панель управления: Wi-Fi, Bluetooth, громкость, яркость, питание.
PanelWindow {
    id: win
    required property var cfg
    required property var status
    property bool open: false

    WlrLayershell.namespace: "lisios-control"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    visible: open || card.opacity > 0.01
    onOpenChanged: if (open) status.refresh()

    MouseArea { anchors.fill: parent; onClicked: win.open = false }

    Rectangle {
        id: card
        width: 340; height: col.implicitHeight + 36
        anchors { top: parent.top; right: parent.right; topMargin: 38; rightMargin: 12 }
        radius: 22; color: "#ec141420"; border.color: "#2effffff"; border.width: 1
        opacity: win.open ? 1 : 0
        transform: Translate { y: win.open ? 0 : -14; Behavior on y { NumberAnimation { duration: cfg.dur(220); easing.type: Easing.OutCubic } } }
        Behavior on opacity { NumberAnimation { duration: cfg.dur(180) } }

        Column {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
            spacing: 14

            Row {
                spacing: 10
                Repeater {
                    model: [
                        { k: "wifi", on: status.wifiOn, sub: status.ssid },
                        { k: "bluetooth", on: status.btOn, sub: "" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        width: (col.width - 10) / 2; height: 64; radius: 16
                        color: modelData.on ? "#ff5a00" : "#33ffffff"
                        Behavior on color { ColorAnimation { duration: cfg.dur(150) } }
                        Column {
                            anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                            Text { text: cfg.t(modelData.k); color: "white"; font.bold: true; font.pixelSize: 14 }
                            Text { text: modelData.on ? (modelData.sub || cfg.t("on")) : cfg.t("off"); color: "#d8d8ee"; font.pixelSize: 12 }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: modelData.k === "wifi" ? status.setWifi(!status.wifiOn) : status.setBt(!status.btOn)
                        }
                    }
                }
            }

            // Game Mode: приоритет выбранных игр (настройка игр - в приложении LisiOS Game Mode)
            Rectangle {
                width: parent.width; height: 64; radius: 16
                color: status.gmOn ? "#ff5a00" : "#33ffffff"
                Behavior on color { ColorAnimation { duration: cfg.dur(150) } }
                Column {
                    anchors { left: parent.left; leftMargin: 14; right: parent.right; rightMargin: 90; verticalCenter: parent.verticalCenter }
                    Text { text: cfg.t("gamemode"); color: "white"; font.bold: true; font.pixelSize: 14 }
                    Text { width: parent.width; elide: Text.ElideRight; text: cfg.t("gm_" + status.gmState); color: "#e8e8e8"; font.pixelSize: 12 }
                }
                Text { anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }; text: "⚙"; color: "white"; font.pixelSize: 18
                    MouseArea { anchors { fill: parent; margins: -10 }; onClicked: { win.open = false; Quickshell.execDetached(["lisios-gamemode", "gui"]) } } }
                MouseArea { anchors { left: parent.left; top: parent.top; bottom: parent.bottom; right: parent.right; rightMargin: 44 }; onClicked: status.setGameMode(!status.gmOn) }
            }

            Column {
                width: parent.width; spacing: 6
                Text { text: cfg.t("volume"); color: "#a1a1b5"; font.pixelSize: 12 }
                Slider2 { width: parent.width; value: status.volume; onMoved: v => status.setVolume(v) }
            }
            Column {
                width: parent.width; spacing: 6
                visible: status.brightness >= 0
                Text { text: cfg.t("brightness"); color: "#a1a1b5"; font.pixelSize: 12 }
                Slider2 { width: parent.width; value: Math.max(0, status.brightness) / 100; onMoved: v => status.setBrightness(Math.max(5, v * 100)) }
            }

            Row {
                spacing: 8
                Repeater {
                    model: [
                        { t: "settings", c: ["lisios-settings"] },
                        { t: "restart", c: ["systemctl", "reboot"] },
                        { t: "shutdown", c: ["systemctl", "poweroff"] },
                        { t: "logout", wm: "exit" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        width: (col.width - 24) / 4; height: 40; radius: 12
                        color: bma.containsMouse ? "#4dffffff" : "#26ffffff"
                        Text { anchors.centerIn: parent; text: cfg.t(modelData.t); color: "white"; font.pixelSize: 11; width: parent.width - 6; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight }
                        MouseArea { id: bma; anchors.fill: parent; hoverEnabled: true; onClicked: { win.open = false; if (modelData.wm) cfg.wm(modelData.wm); else Quickshell.execDetached(modelData.c) } }
                    }
                }
            }
        }
    }
}
