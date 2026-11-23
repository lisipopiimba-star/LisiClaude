import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

// Меню приложений. Открывается кнопкой Lisi AI на нижней панели (или SUPER+Пробел).
PanelWindow {
    id: win
    required property var cfg
    property bool open: false

    WlrLayershell.namespace: "lisios-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    visible: open || card.opacity > 0.01

    onOpenChanged: if (open) { search.text = ""; search.forceActiveFocus() }

    readonly property var results: {
        const q = search.text.trim().toLowerCase()
        const all = DesktopEntries.applications.values.filter(e => !e.noDisplay)
        const f = q === "" ? all : all.filter(e => (e.name || "").toLowerCase().indexOf(q) >= 0
                                            || (e.genericName || "").toLowerCase().indexOf(q) >= 0)
        return f.sort((a, b) => a.name.localeCompare(b.name))
    }
    function launch(e) { e.execute(); win.open = false }

    // клик вне меню закрывает его
    MouseArea { anchors.fill: parent; onClicked: win.open = false }

    Rectangle {
        id: card
        width: 680; height: 580
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 92 }
        radius: 26
        color: "#e6141420"
        border.color: "#2effffff"; border.width: 1
        opacity: win.open ? 1 : 0
        scale: win.open ? 1 : 0.92
        transformOrigin: Item.Bottom
        Behavior on opacity { NumberAnimation { duration: cfg.dur(200); easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: cfg.dur(260); easing.type: Easing.OutBack } }

        Column {
            anchors { fill: parent; margins: 22 }
            spacing: 14

            // --- Lisi AI / поиск
            Rectangle {
                width: parent.width; height: 52; radius: 16; color: "#33ffffff"
                Row {
                    anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                    spacing: 12
                    Image { width: 26; height: 26; source: "file://" + cfg.logo; fillMode: Image.PreserveAspectFit; anchors.verticalCenter: parent.verticalCenter }
                    TextField {
                        id: search
                        width: parent.width - 40; height: parent.height
                        placeholderText: cfg.t("search")
                        color: "white"; placeholderTextColor: "#9090a8"; font.pixelSize: 16
                        background: Item {}
                        onAccepted: if (win.results.length > 0) win.launch(win.results[0]); else aiNote.visible = true
                        onTextChanged: aiNote.visible = false
                        Keys.onEscapePressed: win.open = false
                    }
                }
            }
            Text {
                id: aiNote
                visible: false
                width: parent.width; wrapMode: Text.WordWrap
                color: "#ffd98a"; font.pixelSize: 13
                text: cfg.t("ai_off")
            }

            Text { text: cfg.t("apps"); color: "#a1a1b5"; font.pixelSize: 12; font.bold: true }

            GridView {
                id: grid
                width: parent.width; height: parent.height - 52 - 14 * 3 - 20
                cellWidth: width / 6; cellHeight: 96
                clip: true
                model: ScriptModel { values: win.results }
                delegate: Item {
                    required property var modelData
                    width: grid.cellWidth; height: grid.cellHeight
                    Rectangle { anchors.fill: parent; anchors.margins: 4; radius: 14; color: ma.containsMouse ? "#2effffff" : "transparent" }
                    Column {
                        anchors.centerIn: parent; spacing: 6; width: parent.width - 10
                        IconImage { anchors.horizontalCenter: parent.horizontalCenter; implicitSize: 44; source: Quickshell.iconPath(modelData.icon, "application-x-executable") }
                        Text { width: parent.width; text: modelData.name; color: "white"; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight }
                    }
                    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: win.launch(modelData) }
                }
                Text { visible: grid.count === 0; anchors.centerIn: parent; text: cfg.t("none"); color: "#a1a1b5" }
            }
        }
    }
}
