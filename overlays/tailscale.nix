# /etc/nixos/overlays/tailscale.nix
final: prev:

{
  waybar-tailscale-status = final.writeShellScriptBin "waybar-tailscale-status" ''
    #!${final.bash}/bin/bash
    set -euo pipefail
    
    LOG_FILE="$HOME/.local/state/tailscale-waybar.log"
    mkdir -p "$(dirname "$LOG_FILE")"
    exec 2>> "$LOG_FILE"
    
    PATH=${final.jq}/bin:$PATH
    STATUS_JSON=$(${final.tailscale}/bin/tailscale status --json 2>/dev/null || echo "{}")
    
    EXIT_NODE_PEER_JSON=$(echo "$STATUS_JSON" | jq '
      .ExitNodeStatus.ID as $exit_node_id |
      if $exit_node_id == null then
        null
      else
        .Peer | to_entries[] | select(.value.ID == $exit_node_id) | .value
      end
    ')
    
    if [ -z "$EXIT_NODE_PEER_JSON" ] || [ "$EXIT_NODE_PEER_JSON" == "null" ]; then
      printf '{"text": "VPN 󰖪", "tooltip": "Tailscale Exit Node: Inactive", "class": "inactive"}'
    else
      HOSTNAME=$(echo "$EXIT_NODE_PEER_JSON" | jq -r '.HostName')
      COUNTRY_CODE=$(echo "$EXIT_NODE_PEER_JSON" | jq -r '.Location.CountryCode // "?"')
      printf '{"text": "VPN: %s 󰖢", "tooltip": "Exit Node: %s", "class": "active"}' "$COUNTRY_CODE" "$HOSTNAME"
    fi
  '';

  tailscale-exit-node-selector = final.writeShellScriptBin "tailscale-exit-node-selector" ''
    #!${final.bash}/bin/bash
    set -euo pipefail

    LOG_FILE="$HOME/.local/state/tailscale-waybar.log"
    mkdir -p "$(dirname "$LOG_FILE")"
    
    {
      echo "--- SELECTOR SCRIPT RUN $(date) ---"
      PATH=${final.jq}/bin:$PATH

      EXIT_NODES=$(${final.tailscale}/bin/tailscale status --json | \
        jq -r '.Peer | to_entries[] | select(.value.ExitNodeOption == true) | "\(.value.DNSName)\t\(.value.Location.City), \(.value.Location.Country) (\(.value.HostName))"')
      
      echo "Generated Node List:" >> "$LOG_FILE"
      echo "$EXIT_NODES" >> "$LOG_FILE"

      CHOICE=$( (echo "󰖪 Off"; echo "$EXIT_NODES") | ${final.fuzzel}/bin/fuzzel --dmenu --prompt="Select Exit Node > ")
      echo "User choice: [$CHOICE]"

      if [ -z "$CHOICE" ]; then
          echo "User cancelled (choice was empty)."
          exit 0
      fi

      if [ "$CHOICE" == "󰖪 Off" ]; then
          echo "Running command: sudo ${final.tailscale}/bin/tailscale set --exit-node """
          sudo ${final.tailscale}/bin/tailscale set --exit-node ""
      else
          NODE_HOSTNAME=$(${final.gawk}/bin/awk '{print $1}' <<< "$CHOICE")
          echo "Running command: sudo ${final.tailscale}/bin/tailscale set --exit-node "$NODE_HOSTNAME" --exit-node-allow-lan-access"
          sudo ${final.tailscale}/bin/tailscale set --exit-node "$NODE_HOSTNAME" --exit-node-allow-lan-access
      fi
      echo "Selector script finished successfully."
    } &>> "$LOG_FILE"
  '';
}
