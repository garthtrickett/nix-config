# /etc/nixos/overlays/theme.nix
final: prev:

let
  themeData = final.callPackage ./theme-data { }; # Call default.nix in theme-data dir
in
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
      
          local found=$(find -L "$HOME/.nix-profile/share/themes" "/run/current-system/sw/share/themes" -maxdepth 1 -type d -iname "*$keyword*" 2>/dev/null | sort | head -n 1)
      
          if [ -n "$found" ]; then
            basename "$found"
          else
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
            if ! grep -q "gtk-application-prefer-dark-theme" "$file"; then
                 echo "gtk-application-prefer-dark-theme=$dark_val" >> "$file"
            fi
            sed -i "s/^gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=$dark_val/" "$file"
            sed -i "s@^gtk-theme-name=.*@gtk-theme-name=$theme_name@" "$file"
          else
            echo "WARNING: $file not writable."
          fi
        }

        update_zellij_runtime() {
          local new_theme="$1"
          if command -v zellij >/dev/null 2>&1; then
              echo "Updating Zellij configuration..."
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
          cp "${themeData.firefoxLatteCss}" "$FIREFOX_THEME_FILE"

          # Waybar (Latte)
          cp "${themeData.waybarLatteCss}" "$WB_THEME_FILE"

          # Hyprland (Latte)
          cp "${themeData.hyprlandLatteConf}" "$HYPR_THEME_FILE"
          hyprctl reload

          # Apps
          if [ -w "$HX_CONFIG" ]; then 
            sed -i 's/theme = ".*"/theme = "catppuccin_latte"/' "$HX_CONFIG"
            pkill -USR1 hx || true
          fi
      
          # ZELLIJ: Switch to our custom contrast theme
          if [ -w "$ZELLIJ_CONFIG" ]; then 
            sed -i 's/theme ".*"/theme "latte-contrast"/' "$ZELLIJ_CONFIG"
            update_zellij_runtime "latte-contrast"
          fi

          # Alacritty (Latte)
          cp "${themeData.alacrittyLatteToml}" "$ALACRITTY_THEME_FILE"
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
          cp "${themeData.firefoxMacchiatoCss}" "$FIREFOX_THEME_FILE"

          # Waybar (Macchiato)
          cp "${themeData.waybarMacchiatoCss}" "$WB_THEME_FILE"

          # Hyprland (Macchiato)
          cp "${themeData.hyprlandMacchiatoConf}" "$HYPR_THEME_FILE"
          hyprctl reload

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
          cp "${themeData.alacrittyMacchiatoToml}" "$ALACRITTY_THEME_FILE"
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
