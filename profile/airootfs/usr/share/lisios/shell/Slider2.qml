import QtQuick

// Простой ползунок в стиле LisiOS
Item {
    id: root
    property real value: 0.5
    signal moved(real v)
    height: 22

    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 8; radius: 4; color: "#33ffffff" }
    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width * Math.min(1, Math.max(0, root.value)); height: 8; radius: 4; color: "#ff5a00" }
    Rectangle {
        x: parent.width * Math.min(1, Math.max(0, root.value)) - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: 18; height: 18; radius: 9; color: "white"
    }
    MouseArea {
        anchors.fill: parent
        function set(mx) { root.moved(Math.min(1, Math.max(0, mx / width))) }
        onPressed: mouse => set(mouse.x)
        onPositionChanged: mouse => { if (pressed) set(mouse.x) }
    }
}
