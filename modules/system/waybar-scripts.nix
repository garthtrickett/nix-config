############################################################
##########          START modules/system/waybar-scripts.nix          ##########
############################################################

# /etc/nixos/modules/system/waybar-scripts.nix
{ config, pkgs, ... }:

{
  # This module creates a custom script for Waybar that depends on system-level configuration.
  # By adding the script to environment.systemPackages, it becomes available in the PATH for all users.
  environment.systemPackages = [
    # Script 1: Battery Status
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
          LOCK_ICON=" 󰌾"
          TOOLTIP="Battery charge limit is ON ($CONFIGURED_LIMIT%)"
        else
          LOCK_ICON=" 󰌿"
          TOOLTIP="Battery charge limit is OFF (Unrestricted)"
        fi
      fi
      printf '{"text": "%s %s%%%s", "tooltip": "%s"}' "$ICON" "$BATTERY_CAPACITY" "$LOCK_ICON" "$TOOLTIP"
    '')
  ];
}
