############################################################
##########          START modules/system/waybar-scripts.nix          ##########
############################################################

# /etc/nixos/modules/system/waybar-scripts.nix
{ config, pkgs, ... }:

{
  # This module creates a custom script for Waybar that depends on system-level configuration.
  # By adding the script to environment.systemPackages, it becomes available in the PATH for all users.
  environment.systemPackages = [
    # Script 1: Battery Status (Existing)
    (pkgs.writeShellScriptBin "waybar-battery-combined-status" ''
            #!${pkgs.stdenv.shell}
      
            find_threshold_path() {
              if [ -f "/sys/class/power_supply/macsmc-battery/charge_control_end_threshold" ]; then
                echo "/sys/class/power_supply/macsmc-battery/charge_control_end_threshold"
              elif [ -f "/sys/class/power_supply/battery/charge_control_end_threshold" ]; then
                echo "/sys/class/power_supply/battery/charge_control_end_threshold"
              else
                exit 1
              fi
            }
            THRESHOLD_PATH=$(find_threshold_path)
      
            BATTERY_CAPACITY=$(cat /sys/class/power_supply/macsmc-battery/capacity)
            BATTERY_STATUS=$(cat /sys/class/power_supply/macsmc-battery/status)

            ICON=""
            if [ "$BATTERY_STATUS" = "Charging" ]; then
              ICON=""
            else
              if [ "$BATTERY_CAPACITY" -gt 90 ]; then
                ICON=""
              elif [ "$BATTERY_CAPACITY" -gt 70 ]; then
                ICON=""
              elif [ "$BATTERY_CAPACITY" -gt 50 ]; then
                ICON=""
              elif [ "$BATTERY_CAPACITY" -gt 30 ]; then
                ICON=""
              else
                ICON=""
              fi
            fi

      LOCK_ICON=""
            TOOLTIP="Battery: $BATTERY_CAPACITY%"
      
            if [ -f "$THRESHOLD_PATH" ]; then
              CONFIGURED_LIMIT=${toString config.services.battery-limiter.threshold}
              CURRENT_LIMIT=$(cat "$THRESHOLD_PATH")
        
              if [ "$CURRENT_LIMIT" -eq "$CONFIGURED_LIMIT" ]; then
                # Limit is ON (e.g., 80% limit is set and active)
                LOCK_ICON=" 󰌾"  # Lock icon
                TOOLTIP="Battery charge limit is ON ($CONFIGURED_LIMIT%)"
              else
                # Limit is OFF (e.g., 100% limit is set or current threshold is higher than configured)
                LOCK_ICON=" 󰌿"  # Unlock icon
                TOOLTIP="Battery charge limit is OFF (Unrestricted)"
              fi
            fi
            printf '{"text": "%s %s%%%s", "tooltip": "%s"}' "$ICON" "$BATTERY_CAPACITY" "$LOCK_ICON" "$TOOLTIP"
    '')

    # Script 2: Custom Wifi Status (New)
    # This bypasses Waybar's internal network module which often gets stuck 
    # displaying the old SSID even after roaming, while the tooltip updates.
    (pkgs.writeShellScriptBin "waybar-wifi-status" ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      # Detect interface (usually wlan0 on Asahi)
      INTERFACE=$(ip link show | grep wlan | awk -F: '{print $2}' | tr -d ' ' | head -n 1)
      INTERFACE=''${INTERFACE:-wlan0}

      # Use iwctl to get the absolute truth from iwd
      STATUS=$(${pkgs.iwd}/bin/iwctl station "$INTERFACE" show)
      
      # Check state
      STATE=$(echo "$STATUS" | grep "State" | awk '{print $2}')

      if [ "$STATE" = "connected" ]; then
        # Extract SSID, removing labels and whitespace
        SSID=$(echo "$STATUS" | grep "Connected network" | sed 's/.*Connected network\s*//')
        
        # Output JSON
        echo "{\"text\": \" $SSID\", \"tooltip\": \"Interface: $INTERFACE\nSSID: $SSID\nState: Connected\", \"class\": \"connected\"}"
      else
        echo "{\"text\": \" Disconnected\", \"tooltip\": \"Interface: $INTERFACE\nState: Disconnected\", \"class\": \"disconnected\"}"
      fi
    '')
  ];
}
