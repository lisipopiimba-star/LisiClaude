import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    required property var cfg
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "lisios-wallpaper"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "black"

    Image {
        anchors.fill: parent
        source: "file://" + cfg.wallpaper
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        opacity: status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: cfg.dur(600) } }
    }
}
