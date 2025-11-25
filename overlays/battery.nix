# /etc/nixos/overlays/battery.nix
final: prev:

{
  toggle-battery-limit = final.writeShellScriptBin "toggle-battery-limit" ''
    #!${final.stdenv.shell}
    if [ -z "$SUDO_USER" ]; then
      if [ "$(whoami)" = "root" ]; then
        echo "This script needs the SUDO_USER variable to send a notification." >&2
        echo "Please run it as a regular user with sudo." >&2
      else
        echo "Please run this script with sudo." >&2
      fi
      exit 1
    fi
    notify_user() {
      local message="$1"
      local user_uid=$(id -u "$SUDO_USER")
      export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$user_uid/bus"
      sudo -u "$SUDO_USER" ${final.libnotify}/bin/notify-send "Battery Limiter" "$message"
    }
    find_threshold_path() {
      if [ -f "/sys/class/power_supply/macsmc-battery/charge_control_end_threshold" ]; then
        echo "/sys/class/power_supply/macsmc-battery/charge_control_end_threshold"
      elif [ -f "/sys/class/power_supply/battery/charge_control_end_threshold" ]; then
        echo "/sys/class/power_supply/battery/charge_control_end_threshold"
      else
        return 1
      fi
    }
    THRESHOLD_PATH=$(find_threshold_path)
    if [ -z "$THRESHOLD_PATH" ]; then
      notify_user "Charge threshold control not found."
      exit 1
    fi
    CONFIGURED_LIMIT=80
    CURRENT_LIMIT=$(cat "$THRESHOLD_PATH")
    if [ "$CURRENT_LIMIT" -eq "$CONFIGURED_LIMIT" ]; then
      echo 100 > "$THRESHOLD_PATH"
      notify_user "Charge limit turned OFF (100%)"
    else
      echo "$CONFIGURED_LIMIT" > "$THRESHOLD_PATH"
      notify_user "Charge limit turned ON (''${CONFIGURED_LIMIT}%)"
    fi
  '';
}

