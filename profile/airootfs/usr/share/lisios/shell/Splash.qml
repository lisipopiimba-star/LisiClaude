import QtQuick
import Quickshell
import Quickshell.Wayland

// Загрузочная анимация: чёрный экран -> логотип плавно появляется -> улетает вверх -> открывается рабочий стол.
Variants {
    id: root
    required property var cfg
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData
        WlrLayershell.namespace: "lisios-splash"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        visible: true

        Rectangle { id: black; anchors.fill: parent; color: "black" }
        Image {
            id: logo
            source: "file://" + root.cfg.logo
            height: Math.max(120, parent.height * 0.20)
            fillMode: Image.PreserveAspectFit
            smooth: true
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
            opacity: 0
        }

        Text {
            id: brand
            text: "LisiOS"
            color: "#ffad55"
            font.pixelSize: 38
            font.letterSpacing: 12
            horizontalAlignment: Text.AlignHCenter
            x: (parent.width - width) / 2
            y: logo.y + logo.height + 24
            opacity: 0
        }

        SequentialAnimation {
            running: true
            PauseAnimation { duration: root.cfg.dur(350) }
            ParallelAnimation {
                NumberAnimation { target: logo; property: "opacity"; to: 1; duration: root.cfg.dur(900); easing.type: Easing.InOutCubic }
                NumberAnimation { target: brand; property: "opacity"; to: 1; duration: root.cfg.dur(900); easing.type: Easing.InOutCubic }
            }
            PauseAnimation { duration: root.cfg.dur(700) }
            ParallelAnimation {
                NumberAnimation { target: logo; property: "y"; to: -logo.height - 60; duration: root.cfg.dur(1000); easing.type: Easing.InCubic }
                NumberAnimation { target: logo; property: "opacity"; to: 0; duration: root.cfg.dur(1000); easing.type: Easing.InQuad }
                NumberAnimation { target: brand; property: "opacity"; to: 0; duration: root.cfg.dur(1000); easing.type: Easing.InQuad }
                NumberAnimation { target: brand; property: "y"; to: -brand.height - 40; duration: root.cfg.dur(1000); easing.type: Easing.InCubic }
                SequentialAnimation {
                    PauseAnimation { duration: root.cfg.dur(250) }
                    NumberAnimation { target: black; property: "opacity"; to: 0; duration: root.cfg.dur(900); easing.type: Easing.InOutQuad }
                }
            }
            ScriptAction { script: win.visible = false }
        }
    }
}
