# /etc/nixos/overlays/bluetooth.nix
final: prev:

{
  toggle-bt-headphones = final.writeShellApplication {
    name = "toggle-bt-headphones";
    runtimeInputs = with final; [ bash bluez pipewire libnotify gnugrep coreutils ];
    text = ''
      set -euo pipefail
      BT_MAC="F4:9D:8A:30:F2:A8"
      PW_SINK_NAME="''${BT_MAC//:/_}"
      notify() {
        notify-send "Bluetooth" "$1" -i "audio-headphones-bluetooth"
      }
      if bluetoothctl info "$BT_MAC" | grep -q "Connected: yes"; then
        notify "Disconnecting headphones..."
        bluetoothctl disconnect "$BT_MAC"
        INTERNAL_SINK_ID=$(wpctl status | grep -A 3 Sinks | grep -v 'bluez' | grep -oP '^\s*\K\d+' | head -n 1)
        if [ -n "$INTERNAL_SINK_ID" ]; then
          wpctl set-default "$INTERNAL_SINK_ID"
        fi
        notify "Headphones disconnected."
      else
        notify "Connecting headphones..."
        bluetoothctl power on
        if ! bluetoothctl connect "$BT_MAC"; then
          sleep 1
          bluetoothctl connect "$BT_MAC"
        fi
        
        # shellcheck disable=SC2034
        for i in {1..5}; do
          SINK_ID=$(wpctl status | grep "bluez" | grep "$PW_SINK_NAME" | grep -oP '^\s*\K\d+')
          if [ -n "$SINK_ID" ]; then
            wpctl set-default "$SINK_ID"
            notify "Headphones connected and active."
            exit 0
          fi
          sleep 1
        done
        notify "Error: Could not find audio sink after connecting."
        exit 1
      fi
    '';
  };
}
