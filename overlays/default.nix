# /etc/nixos/overlays/default.nix
self: super:
let
  fixQemu = pkg: pkg.overrideAttrs (old: {
    configureFlags = (old.configureFlags or [ ]) ++ [
      "--disable-nettle"
      "--disable-gcrypt"
      "--disable-gnutls"
      "--disable-crypto-afalg"
    ];
    buildInputs = builtins.filter
      (x:
        let
          name = x.pname or x.name or "";
        in
          !(super.lib.strings.hasInfix "nettle" name ||
            super.lib.strings.hasInfix "gcrypt" name ||
            super.lib.strings.hasInfix "gnutls" name)
      )
      (old.buildInputs or [ ]);
  });
in
{
  # -------------------------------------------------------------------
  # 🌓 THEME TOGGLER SCRIPT
  # -------------------------------------------------------------------
  toggle-theme = super.writeShellScriptBin "toggle-theme" ''
    #!${super.stdenv.shell}

    # --- LOGGING FOR DEBUGGING ---
    LOG_FILE="/tmp/toggle-theme.log"
    exec > >(tee -a "$LOG_FILE") 2>&1
    echo "--- RUNNING THEME TOGGLE AT $(date) ---"

    set -e

    # --- FIX: GSETTINGS SCHEMAS ---
    # The script needs to know where the GNOME schemas are to change GTK settings
    export XDG_DATA_DIRS="${super.gsettings-desktop-schemas}/share/gsettings-schemas/${super.gsettings-desktop-schemas.name}:${super.gtk3}/share/gsettings-schemas/${super.gtk3.name}:$XDG_DATA_DIRS"

    # --- PATHS ---
    XDG_CONFIG_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}"
    STATE_FILE="$XDG_CONFIG_HOME/current_theme"

    # Config Files
    WB_THEME_FILE="$XDG_CONFIG_HOME/waybar/theme.css"
    HYPR_THEME_FILE="$XDG_CONFIG_HOME/hypr/theme.conf"
    HX_CONFIG="$XDG_CONFIG_HOME/helix/config.toml"
    ZELLIJ_CONFIG="$XDG_CONFIG_HOME/zellij/config.kdl"
    ALACRITTY_THEME_FILE="$XDG_CONFIG_HOME/alacritty/theme.toml"

    # --- HELPER: UPDATE ZELLIJ RUNTIME ---
    update_zellij_runtime() {
      local new_theme="$1"
      if command -v zellij >/dev/null 2>&1; then
          # Get list of sessions, strip ANSI colors, get first column (session name)
          SESSIONS=$(${super.zellij}/bin/zellij list-sessions 2>/dev/null | ${super.gnused}/bin/sed 's/\x1b\[[0-9;]*m//g' | ${super.gawk}/bin/awk '{print $1}')
      
          for session in $SESSIONS; do
              if [ -n "$session" ]; then
                   echo "Updating Zellij session: $session to $new_theme"
                   ${super.zellij}/bin/zellij action --session "$session" options --theme "$new_theme" || true
              fi
          done
      fi
    }

    # --- LOGIC ---
    if [ ! -f "$STATE_FILE" ]; then
      echo "dark" > "$STATE_FILE"
    fi

    CURRENT_MODE=$(cat "$STATE_FILE")
    echo "Current mode: $CURRENT_MODE"

    if [ "$CURRENT_MODE" = "dark" ]; then
      NEW_MODE="light"
      echo "Switching to Light Mode..."

      # 1. GTK
      ${super.glib}/bin/gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
      ${super.glib}/bin/gsettings set org.gnome.desktop.interface gtk-theme 'Catppuccin-Latte-Standard-Blue-Dark' || true

      # 2. Waybar (Latte)
    cat > "$WB_THEME_FILE" <<EOF
    @define-color base #eff1f5;
    @define-color mantle #e6e9ef;
    @define-color crust #dce0e8;
    @define-color text #4c4f69;
    @define-color subtext0 #6c6f85;
    @define-color subtext1 #5c5f77;
    @define-color surface0 #ccd0da;
    @define-color surface1 #bcc0cc;
    @define-color surface2 #acb0be;
    @define-color overlay0 #9ca0b0;
    @define-color overlay1 #8c8fa1;
    @define-color overlay2 #7c7f93;
    @define-color blue #1e66f5;
    @define-color lavender #7287fd;
    @define-color sapphire #209fb5;
    @define-color sky #04a5e5;
    @define-color teal #179299;
    @define-color green #40a02b;
    @define-color yellow #df8e1d;
    @define-color peach #fe640b;
    @define-color maroon #e64553;
    @define-color red #d20f39;
    @define-color mauve #8839ef;
    @define-color pink #ea76cb;
    @define-color flamingo #dd7878;
    @define-color rosewater #dc8a78;
    EOF

      # 3. Hyprland (Latte)
      echo 'general {
          col.active_border = rgba(1e66f5ee) rgba(40a02bee) 45deg
          col.inactive_border = rgba(bcc0ccaa)
      }' > "$HYPR_THEME_FILE"
      ${super.hyprland}/bin/hyprctl keyword general:col.active_border "rgba(1e66f5ee) rgba(40a02bee) 45deg"
      ${super.hyprland}/bin/hyprctl keyword general:col.inactive_border "rgba(bcc0ccaa)"

      # 4. Helix (Latte)
      if [ -w "$HX_CONFIG" ]; then
        ${super.gnused}/bin/sed -i 's/theme = ".*"/theme = "catppuccin_latte"/' "$HX_CONFIG"
        pkill -USR1 hx || true 
      fi

      # 5. Zellij (Latte)
      if [ -w "$ZELLIJ_CONFIG" ]; then
        ${super.gnused}/bin/sed -i 's/theme ".*"/theme "catppuccin-latte"/' "$ZELLIJ_CONFIG"
        update_zellij_runtime "catppuccin-latte"
      fi

      # 6. Alacritty (Latte)
    cat > "$ALACRITTY_THEME_FILE" <<EOF
    [colors.primary]
    background = "#eff1f5"
    foreground = "#4c4f69"
    dim_foreground = "#4c4f69"
    bright_foreground = "#4c4f69"
    [colors.cursor]
    text = "#eff1f5"
    cursor = "#dc8a78"
    [colors.search]
    matches = { foreground = "#eff1f5", background = "#8c8fa1" }
    focused_match = { foreground = "#eff1f5", background = "#40a02b" }
    footer_bar = { foreground = "#eff1f5", background = "#8c8fa1" }
    [colors.hints]
    start = { foreground = "#eff1f5", background = "#df8e1d" }
    end = { foreground = "#eff1f5", background = "#8c8fa1" }
    [colors.selection]
    text = "#eff1f5"
    background = "#dc8a78"
    [colors.normal]
    black = "#5c5f77"
    red = "#d20f39"
    green = "#40a02b"
    yellow = "#df8e1d"
    blue = "#1e66f5"
    magenta = "#ea76cb"
    cyan = "#179299"
    white = "#acb0be"
    [colors.bright]
    black = "#6c6f85"
    red = "#d20f39"
    green = "#40a02b"
    yellow = "#df8e1d"
    blue = "#1e66f5"
    magenta = "#ea76cb"
    cyan = "#179299"
    white = "#bcc0cc"
    [colors.dim]
    black = "#5c5f77"
    red = "#d20f39"
    green = "#40a02b"
    yellow = "#df8e1d"
    blue = "#1e66f5"
    magenta = "#ea76cb"
    cyan = "#179299"
    white = "#acb0be"
    EOF
  
      NOTIFY_ICON="weather-clear"
      NOTIFY_MSG="Light Mode Activated"

    else
      NEW_MODE="dark"
      echo "Switching to Dark Mode..."

      # 1. GTK
      ${super.glib}/bin/gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
      ${super.glib}/bin/gsettings set org.gnome.desktop.interface gtk-theme 'Catppuccin-Macchiato-Standard-Blue-Dark' || true

      # 2. Waybar (Macchiato)
    cat > "$WB_THEME_FILE" <<EOF
    @define-color base #24273a;
    @define-color mantle #1e2030;
    @define-color crust #181926;
    @define-color text #cad3f5;
    @define-color subtext0 #a5adcb;
    @define-color subtext1 #b8c0e0;
    @define-color surface0 #363a4f;
    @define-color surface1 #494d64;
    @define-color surface2 #5b6078;
    @define-color overlay0 #6e738d;
    @define-color overlay1 #8087a2;
    @define-color overlay2 #9399b2;
    @define-color blue #8aadf4;
    @define-color lavender #b7bdf8;
    @define-color sapphire #7dc4e4;
    @define-color sky #91d7e3;
    @define-color teal #8bd5ca;
    @define-color green #a6da95;
    @define-color yellow #eed49f;
    @define-color peach #f5a97f;
    @define-color maroon #ee99a0;
    @define-color red #ed8796;
    @define-color mauve #c6a0f6;
    @define-color pink #f5bde6;
    @define-color flamingo #f0c6c6;
    @define-color rosewater #f4dbd6;
    EOF

      # 3. Hyprland (Macchiato)
      echo 'general {
          col.active_border = rgba(8aadf4ee) rgba(a6da95ee) 45deg
          col.inactive_border = rgba(5b6078aa)
      }' > "$HYPR_THEME_FILE"
      ${super.hyprland}/bin/hyprctl keyword general:col.active_border "rgba(8aadf4ee) rgba(a6da95ee) 45deg"
      ${super.hyprland}/bin/hyprctl keyword general:col.inactive_border "rgba(5b6078aa)"

      # 4. Helix (Macchiato)
      if [ -w "$HX_CONFIG" ]; then
        ${super.gnused}/bin/sed -i 's/theme = ".*"/theme = "catppuccin_macchiato"/' "$HX_CONFIG"
        pkill -USR1 hx || true
      fi

      # 5. Zellij (Macchiato)
      if [ -w "$ZELLIJ_CONFIG" ]; then
        ${super.gnused}/bin/sed -i 's/theme ".*"/theme "catppuccin-macchiato"/' "$ZELLIJ_CONFIG"
        update_zellij_runtime "catppuccin-macchiato"
      fi

      # 6. Alacritty (Macchiato)
    cat > "$ALACRITTY_THEME_FILE" <<EOF
    [colors.primary]
    background = "#24273a"
    foreground = "#cad3f5"
    dim_foreground = "#7f849c"
    bright_foreground = "#cad3f5"
    [colors.cursor]
    text = "#24273a"
    cursor = "#f4dbd6"
    [colors.search]
    matches = { foreground = "#24273a", background = "#a5adcb" }
    focused_match = { foreground = "#24273a", background = "#a6da95" }
    footer_bar = { foreground = "#24273a", background = "#a5adcb" }
    [colors.hints]
    start = { foreground = "#24273a", background = "#eed49f" }
    end = { foreground = "#24273a", background = "#a5adcb" }
    [colors.selection]
    text = "#24273a"
    background = "#f4dbd6"
    [colors.normal]
    black = "#494d64"
    red = "#ed8796"
    green = "#a6da95"
    yellow = "#eed49f"
    blue = "#8aadf4"
    magenta = "#f5bde6"
    cyan = "#8bd5ca"
    white = "#b8c0e0"
    [colors.bright]
    black = "#5b6078"
    red = "#ed8796"
    green = "#a6da95"
    yellow = "#eed49f"
    blue = "#8aadf4"
    magenta = "#f5bde6"
    cyan = "#8bd5ca"
    white = "#a5adcb"
    [colors.dim]
    black = "#494d64"
    red = "#ed8796"
    green = "#a6da95"
    yellow = "#eed49f"
    blue = "#8aadf4"
    magenta = "#f5bde6"
    cyan = "#8bd5ca"
    white = "#b8c0e0"
    EOF

      NOTIFY_ICON="weather-clear-night"
      NOTIFY_MSG="Dark Mode Activated"
    fi

    # SAVE STATE
    echo "$NEW_MODE" > "$STATE_FILE"

    # RELOAD WAYBAR
    pkill -SIGUSR2 waybar || true

    # NOTIFY
    ${super.libnotify}/bin/notify-send -i "$NOTIFY_ICON" "Theme Toggle" "$NOTIFY_MSG"
    echo "Done."
  '';

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

  # Overlay 3: Fix qemu-user-static build on aarch64
  qemu = fixQemu super.qemu;
  qemu-user-static = fixQemu super.qemu-user-static;

  # Overlay 4: The exit node STATUS script for Waybar (with logging)
  waybar-tailscale-status = super.writeShellScriptBin "waybar-tailscale-status" ''
    #!${super.bash}/bin/bash
    set -euo pipefail
    
    LOG_FILE="$HOME/.local/state/tailscale-waybar.log"
    mkdir -p "$(dirname "$LOG_FILE")"
    exec 2>> "$LOG_FILE"
    
    PATH=${super.jq}/bin:$PATH
    STATUS_JSON=$(${super.tailscale}/bin/tailscale status --json 2>/dev/null || echo "{}")
    
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

  # Overlay 5: The exit node SELECTOR script (with logging)
  tailscale-exit-node-selector = super.writeShellScriptBin "tailscale-exit-node-selector" ''
    #!${super.bash}/bin/bash
    set -euo pipefail

    LOG_FILE="$HOME/.local/state/tailscale-waybar.log"
    mkdir -p "$(dirname "$LOG_FILE")"
    
    {
      echo "--- SELECTOR SCRIPT RUN $(date) ---"
      PATH=${super.jq}/bin:$PATH

      EXIT_NODES=$(${super.tailscale}/bin/tailscale status --json | \
        jq -r '.Peer | to_entries[] | select(.value.ExitNodeOption == true) | "\(.value.DNSName)\t\(.value.Location.City), \(.value.Location.Country) (\(.value.HostName))"')
      
      echo "Generated Node List:" >> "$LOG_FILE"
      echo "$EXIT_NODES" >> "$LOG_FILE"

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
          NODE_HOSTNAME=$(${super.gawk}/bin/awk '{print $1}' <<< "$CHOICE")
          echo "Running command: sudo ${super.tailscale}/bin/tailscale set --exit-node "$NODE_HOSTNAME" --exit-node-allow-lan-access"
          sudo ${super.tailscale}/bin/tailscale set --exit-node "$NODE_HOSTNAME" --exit-node-allow-lan-access
      fi
      echo "Selector script finished successfully."
    } &>> "$LOG_FILE"
  '';

  # Overlay 6: The Bluetooth headphone toggle script
  toggle-bt-headphones = super.writeShellApplication {
    name = "toggle-bt-headphones";
    runtimeInputs = with super; [ bash bluez pipewire libnotify gnugrep coreutils ];
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
