# /etc/nixos/overlays/theme.nix
final: prev:

{
  toggle-theme = final.writeShellScriptBin "toggle-theme" ''
        #!${final.stdenv.shell}

        # --- LOGGING CONFIGURATION ---
        LOG_FILE="/tmp/toggle-theme.log"
        # Redirect stdout and stderr to the log file, but pipe through tee to keep stdout visible if run manually
        exec > >(while read line; do echo "[$(date '+%H:%M:%S')] $line"; done | tee -a "$LOG_FILE") 2>&1
    
        echo "--- STARTING THEME TOGGLE ---"

        # --- ENVIRONMENT SETUP ---
        export PATH="${final.lib.makeBinPath [ 
          final.coreutils 
          final.gnugrep 
          final.gnused 
          final.gawk 
          final.glib 
          final.procps 
          final.findutils
          final.libnotify
          final.hyprland
          final.zellij
        ]}:$PATH"

        # Fix GSettings Schemas so the script can change settings without crashing
        export XDG_DATA_DIRS="${final.gsettings-desktop-schemas}/share/gsettings-schemas/${final.gsettings-desktop-schemas.name}:${final.gtk3}/share/gsettings-schemas/${final.gtk3.name}:$XDG_DATA_DIRS"

        # --- VARIABLES ---
        XDG_CONFIG_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}"
        STATE_FILE="$XDG_CONFIG_HOME/current_theme"

        WB_THEME_FILE="$XDG_CONFIG_HOME/waybar/theme.css"
        HYPR_THEME_FILE="$XDG_CONFIG_HOME/hypr/theme.conf"
        HX_CONFIG="$XDG_CONFIG_HOME/helix/config.toml"
        ZELLIJ_CONFIG="$XDG_CONFIG_HOME/zellij/config.kdl"
        ALACRITTY_THEME_FILE="$XDG_CONFIG_HOME/alacritty/theme.toml"
        GTK3_CONFIG="$XDG_CONFIG_HOME/gtk-3.0/settings.ini"
        GTK4_CONFIG="$XDG_CONFIG_HOME/gtk-4.0/settings.ini"
        FIREFOX_THEME_FILE="$XDG_CONFIG_HOME/firefox/theme.css"

        # --- HELPER FUNCTIONS ---

        setup_firefox_userchrome() {
          echo "Setting up Firefox userChrome.css..."
          local profiles_ini="$HOME/.mozilla/firefox/profiles.ini"
          if [ ! -f "$profiles_ini" ]; then
            echo "WARNING: profiles.ini not found. Cannot set up Firefox userChrome.css."
            return
          fi
          
          local profile_path=$(awk 'BEGIN { RS = "" } /Default=1/ { for (i = 1; i <= NF; i++) { if ($i ~ /^Path=/) { split($i, a, "="); print a[2]; exit; } } }' "$profiles_ini")
          
          if [ -z "$profile_path" ]; then
            echo "WARNING: Default profile not found in profiles.ini. Cannot set up Firefox userChrome.css."
            return
          fi
          
          local profile_dir="$HOME/.mozilla/firefox/$profile_path"
          local chrome_dir="$profile_dir/chrome"

          mkdir -p "$chrome_dir"
          
          if [ ! -f "$chrome_dir/userChrome.css" ]; then
            cat > "$chrome_dir/userChrome.css" <<EOF
    /* Import this theme's colors */
    @import url("file://$FIREFOX_THEME_FILE");
    EOF
          fi
        }
    
        find_theme_name() {
          local keyword="$1"
          
          # FIX: Added -L (follow symlinks) so find works with Nix profiles.
          # FIX: Added sort to ensure we pick the base theme over variants like -hdpi or -xhdpi
          local found=$(find -L "$HOME/.nix-profile/share/themes" "/run/current-system/sw/share/themes" -maxdepth 1 -type d -iname "*$keyword*" 2>/dev/null | sort | head -n 1)
          
          if [ -n "$found" ]; then
            basename "$found"
          else
            # Updated fallback to include the likely suffix if detection fails, 
            # though detection should work now with -L.
            echo "catppuccin-$keyword-blue-standard+rimless,black" | tr '[:upper:]' '[:lower:]'
          fi
        }

        update_gsettings() {
          local scheme="$1"
          local theme="$2"
      
          echo "Updating GSettings..."
          gsettings set org.gnome.desktop.interface color-scheme "$scheme"
          gsettings set org.gnome.desktop.interface gtk-theme "$theme"
      
          # Verify
          echo "  [VERIFY] Color Scheme: $(gsettings get org.gnome.desktop.interface color-scheme)"
          echo "  [VERIFY] GTK Theme: $(gsettings get org.gnome.desktop.interface gtk-theme)"
        }

        update_gtk_file() {
          local file="$1"
          local dark_val="$2"
          local theme_name="$3"
      
          if [ -w "$file" ]; then
            echo "Updating $file ..."
            # Ensure key exists
            if ! grep -q "gtk-application-prefer-dark-theme" "$file"; then
                 echo "gtk-application-prefer-dark-theme=$dark_val" >> "$file"
            fi
            sed -i "s/^gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=$dark_val/" "$file"
            # Use @ as delimiter to handle paths or + characters safely in the theme name
            sed -i "s@^gtk-theme-name=.*@gtk-theme-name=$theme_name@" "$file"
          else
            echo "WARNING: $file not writable."
          fi
        }

        update_zellij_runtime() {
          local new_theme="$1"
          if command -v zellij >/dev/null 2>&1; then
              echo "Updating Zellij configuration..."
              # Filter out EXITED sessions to avoid spamming logs with "dead" session errors
              SESSIONS=$(zellij list-sessions 2>/dev/null | grep -v "EXITED" | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $1}')
              
              count=$(echo "$SESSIONS" | wc -w)
              if [ "$count" -gt 0 ]; then
                 echo "  (Config updated. $count active sessions detected - changes will apply on restart/reload)"
              else
                 echo "  (Config updated. No active sessions.)"
              fi
          fi
        }

        # --- MAIN ---

        setup_firefox_userchrome
        if [ ! -f "$STATE_FILE" ]; then echo "dark" > "$STATE_FILE"; fi
        CURRENT_MODE=$(cat "$STATE_FILE")
        echo "Current mode: $CURRENT_MODE"

        if [ "$CURRENT_MODE" = "dark" ]; then
          # -> LIGHT MODE
          NEW_MODE="light"
          THEME_NAME=$(find_theme_name "Latte")
          echo "Detected Light Theme Name: $THEME_NAME"
      
          update_gsettings 'prefer-light' "$THEME_NAME"
          update_gtk_file "$GTK3_CONFIG" "0" "$THEME_NAME"
          update_gtk_file "$GTK4_CONFIG" "0" "$THEME_NAME"

          # Firefox (Latte)
          cat > "$FIREFOX_THEME_FILE" <<EOF
    :root {
      --rosewater: #dc8a78; --flamingo: #dd7878; --pink: #ea76cb; --mauve: #8839ef;
      --red: #d20f39; --maroon: #e64553; --peach: #fe640b; --yellow: #df8e1d;
      --green: #40a02b; --teal: #179299; --sky: #04a5e5; --sapphire: #209fb5;
      --blue: #1e66f5; --lavender: #7287fd; --text: #4c4f69; --subtext1: #5c5f77;
      --subtext0: #6c6f85; --overlay2: #7c7f93; --overlay1: #8c8fa1; --overlay0: #9ca0b0;
      --surface2: #acb0be; --surface1: #bcc0cc; --surface0: #ccd0da; --crust: #dce0e8;
      --mantle: #e6e9ef; --base: #eff1f5;
    }
    EOF

          # Waybar (Latte)
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

          # Hyprland (Latte)
          echo 'general {
              col.active_border = rgba(1e66f5ee) rgba(40a02bee) 45deg
              col.inactive_border = rgba(bcc0ccaa)
          }' > "$HYPR_THEME_FILE"
          hyprctl keyword general:col.active_border "rgba(1e66f5ee) rgba(40a02bee) 45deg"
          hyprctl keyword general:col.inactive_border "rgba(bcc0ccaa)"

          # Apps
          if [ -w "$HX_CONFIG" ]; then 
            sed -i 's/theme = ".*"/theme = "catppuccin_latte"/' "$HX_CONFIG"
            pkill -USR1 hx || true
          fi
          if [ -w "$ZELLIJ_CONFIG" ]; then 
            sed -i 's/theme ".*"/theme "catppuccin-latte"/' "$ZELLIJ_CONFIG"
            update_zellij_runtime "catppuccin-latte"
          fi

          # Alacritty (Latte)
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
          NOTIFY_MSG="Light Mode Activated"

        else
          # -> DARK MODE
          NEW_MODE="dark"
          THEME_NAME=$(find_theme_name "Macchiato")
          echo "Detected Dark Theme Name: $THEME_NAME"

          update_gsettings 'prefer-dark' "$THEME_NAME"
          update_gtk_file "$GTK3_CONFIG" "1" "$THEME_NAME"
          update_gtk_file "$GTK4_CONFIG" "1" "$THEME_NAME"

          # Firefox (Macchiato)
          cat > "$FIREFOX_THEME_FILE" <<EOF
    :root {
      --rosewater: #f5e0dc; --flamingo: #f2cdcd; --pink: #f5c2e7; --mauve: #cba6f7;
      --red: #f38ba8; --maroon: #eba0ac; --peach: #fab387; --yellow: #f9e2af;
      --green: #a6e3a1; --teal: #94e2d5; --sky: #89dceb; --sapphire: #74c7ec;
      --blue: #89b4fa; --lavender: #b4befe; --text: #cdd6f4; --subtext1: #bac2de;
      --subtext0: #a6adc8; --overlay2: #9399b2; --overlay1: #7f849c; --overlay0: #6c7086;
      --surface2: #585b70; --surface1: #45475a; --surface0: #313244; --crust: #1e1e2e;
      --mantle: #181825; --base: #1e1e2e;
    }
    EOF

          # Waybar (Macchiato)
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

          # Hyprland (Macchiato)
          echo 'general {
              col.active_border = rgba(8aadf4ee) rgba(a6da95ee) 45deg
              col.inactive_border = rgba(5b6078aa)
          }' > "$HYPR_THEME_FILE"
          hyprctl keyword general:col.active_border "rgba(8aadf4ee) rgba(a6da95ee) 45deg"
          hyprctl keyword general:col.inactive_border "rgba(5b6078aa)"

          # Apps
          if [ -w "$HX_CONFIG" ]; then 
            sed -i 's/theme = ".*"/theme = "catppuccin_macchiato"/' "$HX_CONFIG"
            pkill -USR1 hx || true
          fi
          if [ -w "$ZELLIJ_CONFIG" ]; then 
            sed -i 's/theme ".*"/theme "catppuccin-macchiato"/' "$ZELLIJ_CONFIG"
            update_zellij_runtime "catppuccin-macchiato"
          fi

          # Alacritty (Macchiato)
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
    [colors.footer_bar]
    foreground = "#24273a"
    background = "#a5adcb"
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
          NOTIFY_MSG="Dark Mode Activated"
        fi

        # Finalize
        echo "$NEW_MODE" > "$STATE_FILE"
    
        echo "Reloading Waybar..."
        pkill -SIGUSR2 waybar || echo "Waybar not running"
    
        notify-send "Theme Toggle" "$NOTIFY_MSG"
        echo "--- COMPLETED SUCCESSFULLY ---"
  '';
}
