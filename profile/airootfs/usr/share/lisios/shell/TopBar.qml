import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: bar
    required property var cfg
    required property var status
    signal controlRequested()

    WlrLayershell.namespace: "lisios-topbar"
    anchors { top: true; left: true; right: true }
    implicitHeight: 30
    color: "transparent"

    SystemClock { id: clock; precision: SystemClock.Minutes }
    readonly property var active: ToplevelManager.activeToplevel

    Rectangle {
        anchors.fill: parent
        color: "#b8101018"

        // ---- слева: логотип, «светофор» активного окна, название
        Row {
            anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
            spacing: 14

            Row {
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter
                Image { source: "file://" + cfg.logo; height: 18; width: 18; fillMode: Image.PreserveAspectFit; anchors.verticalCenter: parent.verticalCenter; smooth: true }
                Text { text: "LisiOS"; color: "white"; font.bold: true; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
            }

            // три кнопки окна: закрыть / свернуть / развернуть
            Row {
                spacing: 8
                visible: bar.active !== null && bar.active !== undefined
                anchors.verticalCenter: parent.verticalCenter
                Repeater {
                    model: [
                        { c: "#ff5f57", a: "close" },
                        { c: "#febc2e", a: "minimize" },
                        { c: "#28c840", a: "maximize" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        width: 13; height: 13; radius: 7; color: modelData.c
                        scale: ma.containsMouse ? 1.18 : 1
                        Behavior on scale { NumberAnimation { duration: cfg.dur(120) } }
                        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: cfg.wm(modelData.a) }
                    }
                }
            }
            Text {
                text: bar.active ? bar.active.title : cfg.t("desktop")
                color: "#e6e6f0"; font.pixelSize: 13
                width: Math.min(implicitWidth, 420); elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // ---- справа: состояние и часы
        MouseArea {
            anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
            width: sysRow.implicitWidth + 8; height: parent.height
            onClicked: bar.controlRequested()
            Row {
                id: sysRow
                anchors.centerIn: parent
                spacing: 14
                Text { visible: status.battery >= 0; text: (status.charging ? "⚡" : "🔋") + status.battery + "%"; color: "white"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                Text { text: status.muted ? "🔇" : "🔊"; color: "white"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "ᛒ"; color: status.btOn ? "white" : "#70707f"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "⌁ " + (status.wifiOn ? status.ssid : cfg.t("off")); color: status.wifiOn ? "white" : "#70707f"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    text: clock.date.toLocaleString(Qt.locale(cfg.lang === "ru" ? "ru_RU" : "en_US"), "ddd d MMM  HH:mm")
                    color: "white"; font.pixelSize: 13; font.bold: true; anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
