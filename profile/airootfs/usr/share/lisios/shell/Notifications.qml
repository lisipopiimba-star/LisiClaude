import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

// Уведомления (сервер org.freedesktop.Notifications)
Scope {
    id: root
    required property var cfg

    NotificationServer {
        id: server
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        keepOnReload: false
        onNotification: n => { n.tracked = true }
    }

    PanelWindow {
        WlrLayershell.namespace: "lisios-notifications"
        WlrLayershell.layer: WlrLayer.Overlay
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; right: true }
        margins { top: 38; right: 12 }
        implicitWidth: 360
        implicitHeight: Math.max(1, stack.implicitHeight)
        color: "transparent"
        visible: server.trackedNotifications.values.length > 0

        Column {
            id: stack
            width: parent.width
            spacing: 10
            Repeater {
                model: server.trackedNotifications
                delegate: Rectangle {
                    id: item
                    required property var modelData
                    width: stack.width
                    height: txt.implicitHeight + 28
                    radius: 18; color: "#ee161622"; border.color: "#2effffff"; border.width: 1
                    opacity: 0; x: 30
                    Component.onCompleted: { opacity = 1; x = 0 }
                    Behavior on opacity { NumberAnimation { duration: cfg.dur(220) } }
                    Behavior on x { NumberAnimation { duration: cfg.dur(260); easing.type: Easing.OutCubic } }
                    Column {
                        id: txt
                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 16 }
                        spacing: 4
                        Text { width: parent.width; text: item.modelData.summary; color: "white"; font.bold: true; font.pixelSize: 14; elide: Text.ElideRight }
                        Text { width: parent.width; visible: text !== ""; text: item.modelData.body; color: "#c8c8da"; font.pixelSize: 13; wrapMode: Text.WordWrap; maximumLineCount: 4; elide: Text.ElideRight }
                    }
                    MouseArea { anchors.fill: parent; onClicked: item.modelData.dismiss() }
                    Timer {
                        interval: item.modelData.expireTimeout > 0 ? item.modelData.expireTimeout * 1000 : 6000
                        running: true
                        onTriggered: item.modelData.dismiss()
                    }
                }
            }
        }
    }
}
