# modules/home/waybar/wifi-status-script.nix
{ pkgs, ... }:

pkgs.writeShellScriptBin "waybar-wifi-status" ''
  #!${pkgs.bash}/bin/bash
  set -euo pipefail
  export PATH="${pkgs.lib.makeBinPath [ 
    pkgs.coreutils pkgs.gnugrep pkgs.gnused pkgs.gawk pkgs.iproute2 pkgs.iwd 
  ]}:$PATH"

  INTERFACE=$(ip link show | grep -oP 'wlan\d+' | sort | head -n 1)
  if [ -z "$INTERFACE" ]; then
      echo "{\"text\": \" No Interface\", \"tooltip\": \"No wireless interface found\", \"class\": \"disconnected\"}"
      exit 0
  fi

  STATUS=$(iwctl station "$INTERFACE" show || echo "State disconnected")
  STATE=$(echo "$STATUS" | grep "State" | awk '{$1=""; print $0}' | xargs)

  if [[ "$STATE" == "connected" ]]; then
    SSID=$(echo "$STATUS" | grep "Connected network" | sed 's/.*Connected network\s*//' | xargs)
    if [ -z "$SSID" ]; then SSID="Hidden"; fi
    echo "{\"text\": \" $SSID\", \"tooltip\": \"Interface: $INTERFACE\nSSID: $SSID\nState: Connected\", \"class\": \"connected\"}"
  elif [[ "$STATE" == "connecting" || "$STATE" == "authenticating" || "$STATE" == "associating" ]]; then
    echo "{\"text\": \" Connecting...\", \"tooltip\": \"Interface: $INTERFACE\nState: $STATE\", \"class\": \"scanning\"}"
  else
    echo "{\"text\": \" Disconnected\", \"tooltip\": \"Interface: $INTERFACE\nState: $STATE\", \"class\": \"disconnected\"}"
  fi
''
