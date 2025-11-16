# /etc/nixos/toggle-touchpad.nix
{ pkgs, ... }:

pkgs.writeShellScriptBin "toggle-touchpad" ''
  #!/usr/bin/env bash
  set -euo pipefail

  # Ensure XDG_RUNTIME_DIR is set for the status file path
  if [ -z "$XDG_RUNTIME_DIR" ]; then
    export XDG_RUNTIME_DIR=/run/user/$(${pkgs.coreutils}/bin/id -u)
  fi

  # --- Device and State Setup ---
  STATUS_FILE="$XDG_RUNTIME_DIR/touchpad.status"
  
  # HACK from your original script to ensure Hyprland properties are fresh
  ${pkgs.hyprland}/bin/hyprctl keyword device:a true > /dev/null 2>&1
  
  # Your original device detection logic
  HYPRLAND_DEVICE="$(${pkgs.hyprland}/bin/hyprctl devices | ${pkgs.gnugrep}/bin/grep -i 'trackpad\|touchpad' | ${pkgs.gnused}/bin/sed '/2-synaptics-touchpad/d; s/.*	//')"
  HYPRLAND_VARIABLE="device[''${HYPRLAND_DEVICE}]:enabled"

  # --- Functions to control the touchpad ---
  
  # Function to explicitly enable the touchpad
  enable_touchpad() {
    ${pkgs.hyprland}/bin/hyprctl --batch -r -- keyword "$HYPRLAND_VARIABLE" true
    echo "true" > "$STATUS_FILE"
  }
  
  # Function to explicitly disable the touchpad
  disable_touchpad() {
    ${pkgs.hyprland}/bin/hyprctl --batch -r -- keyword "$HYPRLAND_VARIABLE" false
    echo "false" > "$STATUS_FILE"
  }

  # --- Main Logic ---
  # The script now acts based on the first argument provided.
  case "''${1:-}" in
    enable)
      enable_touchpad
      ;;
    disable)
      disable_touchpad
      ;;
    *)
      # Default behavior if no argument is given.
      # This part is no longer used but kept for completeness.
      if [ "$(${pkgs.coreutils}/bin/cat "$STATUS_FILE" 2>/dev/null)" = "false" ]; then
        enable_touchpad
      else
        disable_touchpad
      fi
      ;;
  esac
''
