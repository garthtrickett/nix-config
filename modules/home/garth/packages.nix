# modules/home/garth/packages.nix
{ config, pkgs, lib, inputs, ... }:

{
  home.packages = [
    (inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default)
    pkgs.gh
    pkgs.jujutsu
    pkgs.caddy
    pkgs.mkcert
    pkgs.alacritty
    pkgs.zellij
    pkgs.zjstatus
    pkgs.fuzzel
    pkgs.hyprshot
    pkgs.nemo
    pkgs.swaylock
    pkgs.zathura
    pkgs.swayidle
    pkgs.brightnessctl
    pkgs.wl-clipboard
    pkgs.xdg-user-dirs
    pkgs.ydotool
    pkgs.procps
    pkgs.nerd-fonts.fira-code
    pkgs.hyprsunset
    pkgs.libreoffice
    pkgs.gnugrep
    pkgs.gnused
    pkgs.gfold
    pkgs.dunst
    pkgs.libinput
    pkgs.iwgtk
    pkgs.unzip
    pkgs.vlc
    pkgs.sops
    pkgs.age
    pkgs.wf-recorder
    pkgs.ffmpeg
    pkgs.file-roller
    pkgs.nemo-fileroller
    pkgs.pulseaudio
    pkgs.toggle-bt-headphones
    pkgs.bun
    pkgs.gemini-cli
    pkgs.awscli2
    pkgs.file
    pkgs.glib
    pkgs.gsettings-desktop-schemas
    pkgs.gtk3
    pkgs.nodejs
    # TUI DEPENDENCIES
    pkgs.gum
    pkgs.jq

    # --- MCP MANAGER TUI (ROBUST VERSION) ---
    (pkgs.writeShellScriptBin "mcp-manager" ''
      #!${pkgs.bash}/bin/bash
      set -e

      POOL_FILE="$HOME/.config/Antigravity/mcp-pool.json"
      LIVE_FILE="$HOME/.config/Antigravity/mcp.json"
      TEMP_FILE=$(mktemp)

      # 1. Read available servers from the pool
      ALL_SERVERS=$(jq -r '.mcpServers | keys[]' "$POOL_FILE" | sort)

      # 2. Read currently active servers
      if [ -f "$LIVE_FILE" ]; then
        ACTIVE_SERVERS=$(jq -r '.mcpServers | keys[]' "$LIVE_FILE" 2>/dev/null || echo "")
        SELECTED_CSV=$(echo "$ACTIVE_SERVERS" | paste -sd, -)
      else
        SELECTED_CSV="filesystem,memory,github,brave-search"
      fi

      echo "Select MCP Servers to Enable:"
      
      # 3. Render the TUI
      CHOICES=$(echo "$ALL_SERVERS" | ${pkgs.gum}/bin/gum choose --no-limit --height=15 --selected="$SELECTED_CSV")

      if [ -z "$CHOICES" ]; then
        echo "No servers selected. Exiting without changes."
        sleep 1
        exit 1
      fi

      echo "Building configuration..."

      # 4. JSON Reconstruction (Write to TEMP first)
      JSON_ARRAY=$(echo "$CHOICES" | jq -R . | jq -s .)

      jq -n --slurpfile pool "$POOL_FILE" --argjson selected "$JSON_ARRAY" '
        {
          mcpServers: ($pool[0].mcpServers | with_entries(select(.key as $k | $selected | index($k))))
        }
      ' > "$TEMP_FILE"

      # 5. ATOMIC REPLACE (Crucial Fix)
      # We use 'mv -f' to forcefully overwrite LIVE_FILE. 
      # This breaks any existing symlinks created by Nix/Sops and ensures the file is writable.
      mv -f "$TEMP_FILE" "$LIVE_FILE"
      chmod 644 "$LIVE_FILE"

      # 6. Restart Service & Notify
      echo "Restarting MCP Service..."
      systemctl --user restart mcp-superassistant-proxy
      
      pkill -SIGRTMIN+8 waybar || true

      echo "Done! Configuration updated."
      sleep 1
    '')

    # --- WAYBAR STATUS SCRIPT ---
    (pkgs.writeShellScriptBin "waybar-mcp-status" ''
      #!${pkgs.bash}/bin/bash
      LIVE_FILE="$HOME/.config/Antigravity/mcp.json"
      
      if [ ! -f "$LIVE_FILE" ]; then 
        echo '{"text": "MCP 🚫", "tooltip": "No Config Found", "class": "inactive"}'
        exit 0
      fi

      IS_HEAVY=$(grep -E "puppeteer|shadcn|testsprite" "$LIVE_FILE" || true)
      COUNT=$(jq '.mcpServers | length' "$LIVE_FILE")

      if [ -n "$IS_HEAVY" ]; then
         echo "{\"text\": \"🤖 $COUNT\", \"tooltip\": \"MCP Heavy Mode: $COUNT agents active\", \"class\": \"heavy\"}"
      else
         echo "{\"text\": \"🧠 $COUNT\", \"tooltip\": \"MCP Core Mode: $COUNT tools active\", \"class\": \"lite\"}"
      fi
    '')
  ];
}
