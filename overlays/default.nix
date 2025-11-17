# /etc/nixos/overlays/default.nix
self: super: {

  # Overlay 1: The battery limit toggle script
  toggle-battery-limit = super.writeShellScriptBin "toggle-battery-limit" ''
    #!${super.stdenv.shell}
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
      sudo -u "$SUDO_USER" ${super.libnotify}/bin/notify-send "Battery Limiter" "$message"
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

  # Overlay 2: The asahi-audio override
  asahi-audio = super.asahi-audio.override {
     triforce-lv2 = super.triforce-lv2;
  };

  # -------------------------------------------------------------------
  # ⬇️ REWRITTEN TAILSCALE SCRIPTS WITH LOGGING ⬇️
  # -------------------------------------------------------------------

  # Overlay 3: The exit node STATUS script for Waybar (with logging)
  waybar-tailscale-status = super.writeShellScriptBin "waybar-tailscale-status" ''
    #!${super.bash}/bin/bash
    set -euo pipefail
    
    LOG_FILE="$HOME/.local/state/tailscale-waybar.log"
    mkdir -p "$(dirname "$LOG_FILE")"
    exec 2>> "$LOG_FILE"
    
    echo "--- STATUS CHECK $(date) ---" >> "$LOG_FILE"
    
    PATH=${super.jq}/bin:$PATH
    STATUS_JSON=$(${super.tailscale}/bin/tailscale status --json 2>/dev/null || echo "{}")
    
    # New robust logic: Use the ExitNodeStatus.ID to look up the full peer details.
    EXIT_NODE_PEER_JSON=$(echo "$STATUS_JSON" | jq '
      .ExitNodeStatus.ID as $exit_node_id |
      if $exit_node_id == null then
        null
      else
        .Peer | to_entries[] | select(.value.ID == $exit_node_id) | .value
      end
    ')
    
    echo "Found Exit Node Peer JSON: [$EXIT_NODE_PEER_JSON]" >> "$LOG_FILE"

    if [ -z "$EXIT_NODE_PEER_JSON" ] || [ "$EXIT_NODE_PEER_JSON" == "null" ]; then
      printf '{"text": "VPN 󰖪", "tooltip": "Tailscale Exit Node: Inactive", "class": "inactive"}'
    else
      HOSTNAME=$(echo "$EXIT_NODE_PEER_JSON" | jq -r '.HostName')
      COUNTRY_CODE=$(echo "$EXIT_NODE_PEER_JSON" | jq -r '.Location.CountryCode // "?"')
      printf '{"text": "VPN: %s 󰖢", "tooltip": "Exit Node: %s", "class": "active"}' "$COUNTRY_CODE" "$HOSTNAME"
    fi
  '';

  # Overlay 4: The exit node SELECTOR script (with logging)
  tailscale-exit-node-selector = super.writeShellScriptBin "tailscale-exit-node-selector" ''
    #!${super.bash}/bin/bash
    set -euo pipefail

    LOG_FILE="$HOME/.local/state/tailscale-waybar.log"
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # Wrap the main logic to redirect all its output (stdout and stderr) to the log file
    {
      echo "--- SELECTOR SCRIPT RUN $(date) ---"
      
      PATH=${super.jq}/bin:$PATH

      # The jq query now outputs the full DNS Name, a tab character, and then the user-friendly display string.
      EXIT_NODES=$(${super.tailscale}/bin/tailscale status --json | \
        jq -r '.Peer | to_entries[] | select(.value.ExitNodeOption == true) | "\(.value.DNSName)\t\(.value.Location.City), \(.value.Location.Country) (\(.value.HostName))"')
      
      echo "Generated Node List:" >> "$LOG_FILE"
      echo "$EXIT_NODES" >> "$LOG_FILE"

      # Fuzzel will display the full line, but the command below will correctly parse it.
      CHOICE=$( (echo "󰖪 Off"; echo "$EXIT_NODES") | ${super.fuzzel}/bin/fuzzel --dmenu --prompt="Select Exit Node > ")
      echo "User choice: [$CHOICE]"

      if [ -z "$CHOICE" ]; then
          echo "User cancelled (choice was empty)."
          exit 0
      fi

      if [ "$CHOICE" == "󰖪 Off" ]; then
          echo "Running command: sudo ${super.tailscale}/bin/tailscale set --exit-node """
          sudo ${super.tailscale}/bin/tailscale set --exit-node ""
      else
          # Use 'awk' to extract the first field (the full DNS Name) from the selected line.
          NODE_HOSTNAME=$(${super.gawk}/bin/awk '{print $1}' <<< "$CHOICE")
          echo "Running command: sudo ${super.tailscale}/bin/tailscale set --exit-node "$NODE_HOSTNAME" --exit-node-allow-lan-access"
          sudo ${super.tailscale}/bin/tailscale set --exit-node "$NODE_HOSTNAME" --exit-node-allow-lan-access
      fi
      echo "Selector script finished successfully."
    } &>> "$LOG_FILE"
  '';
}
