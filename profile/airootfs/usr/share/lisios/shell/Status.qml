import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root
    property bool wifiOn: false
    property string ssid: ""
    property bool btOn: false
    property real volume: 0.5
    property bool muted: false
    property int battery: -1
    property bool charging: false
    property int brightness: -1
    property bool gmOn: false          // Game Mode включён (кнопка/настройка)
    property string gmState: "off"     // off | waiting | active | throttling | no_privilege

    function parse(txt) {
        for (const line of txt.split("\n")) {
            const i = line.indexOf("="); if (i < 0) continue
            const k = line.slice(0, i), v = line.slice(i + 1).trim()
            if (k === "wifi") wifiOn = v === "enabled"
            else if (k === "ssid") ssid = v
            else if (k === "bt") btOn = v === "yes"
            else if (k === "vol") { const m = v.match(/([0-9.]+)/); if (m) volume = parseFloat(m[1]); muted = v.indexOf("MUTED") >= 0 }
            else if (k === "bat") battery = v === "" ? -1 : parseInt(v)
            else if (k === "chg") charging = v === "Charging" || v === "Full"
            else if (k === "bri") brightness = v === "" ? -1 : parseInt(v)
            else if (k === "gm") {
                try { const g = JSON.parse(v); gmOn = g.enabled === true; gmState = g.state || "off" }
                catch (e) { gmOn = false; gmState = "off" }
            }
        }
    }
    function refresh() { if (!poll.running) poll.running = true }
    function setWifi(on) { Quickshell.execDetached(["nmcli", "radio", "wifi", on ? "on" : "off"]); wifiOn = on }
    function setBt(on) { Quickshell.execDetached(["bluetoothctl", "power", on ? "on" : "off"]); btOn = on }
    function setVolume(v) { Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", v.toFixed(2)]); volume = v }
    function setGameMode(on) { Quickshell.execDetached(["lisios-gamemode", on ? "on" : "off"]); gmOn = on; gmState = on ? "waiting" : "off" }
    function setBrightness(p) { Quickshell.execDetached(["brightnessctl", "set", Math.round(p) + "%"]); brightness = Math.round(p) }

    Process {
        id: poll
        command: ["sh", "/usr/share/lisios/shell/status.sh"]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }
    Timer { interval: 4000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
}
