# /etc/nixos/modules/system/waybar-scripts.nix
{ config, pkgs, ... }:

{
  # This module creates a custom script for Waybar that depends on system-level configuration.
  # By adding the script to environment.systemPackages, it becomes available in the PATH for all users.
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "waybar-battery-status" ''
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
      
      if [ ! -f "$THRESHOLD_PATH" ]; then
        exit 0
      fi

      # This is the critical line that requires this script to be a NixOS module.
      # It reads the system-wide configuration value for the battery limiter.
      CONFIGURED_LIMIT=${toString config.services.battery-limiter.threshold}
      CURRENT_LIMIT=$(cat "$THRESHOLD_PATH")

      if [ "$CURRENT_LIMIT" -eq "$CONFIGURED_LIMIT" ]; then
        printf '{"text": "󰌾", "tooltip": "Battery charge limit is ON (%s%%)"}' "$CONFIGURED_LIMIT"
      else
        printf '{"text": "", "tooltip": "Battery charge limit is OFF"}'
      fi
    '')
  ];
}
