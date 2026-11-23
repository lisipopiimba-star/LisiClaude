#!/bin/sh
# Опрос состояния системы для панели (вызывается из Status.qml)
echo "wifi=$(nmcli radio wifi 2>/dev/null)"
echo "ssid=$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | grep '^yes' | head -1 | cut -d: -f2)"
echo "bt=$(bluetoothctl show 2>/dev/null | awk '/Powered:/{print $2}')"
echo "vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)"
echo "bat=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)"
echo "chg=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1)"
echo "bri=$(brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d %)"
echo "gm=$(cat "${XDG_RUNTIME_DIR:-/tmp}/lisios-gamemode.json" 2>/dev/null | tr -d '\n')"
