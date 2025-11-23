# /etc/nixos/modules/home/theme.nix
{ config, pkgs, lib, ... }:

{
  # -------------------------------------------------------------------
  # 🎨 CATPPUCCIN THEME BASE
  # -------------------------------------------------------------------
  catppuccin = {
    enable = true;
    # We default to macchiato, but the toggle script will override specific apps
    flavor = "macchiato";

    # Disable module management for apps we want to toggle dynamically.
    # We will manage their config files manually via the toggle script.
    helix.enable = false;
    alacritty.enable = false;

    # DISABLE WAYBAR HERE so it doesn't inject the read-only css import
    waybar.enable = false;

    # ENABLE ZELLIJ HERE so the theme definitions (hex codes) are generated.
    # Our activation script below will still make the file writable.
    zellij.enable = true;
  };

  # -------------------------------------------------------------------
  # 🎭 GTK & CURSOR THEME
  # -------------------------------------------------------------------
  # We must enable GTK so the theme packages are linked and available for Firefox
  # We use lib.mkForce on packages to override Catppuccin module defaults
  gtk = {
    enable = true;
    theme = {
      name = "catppuccin-macchiato-blue-standard";
      package = lib.mkForce (pkgs.catppuccin-gtk.override {
        accents = [ "blue" ];
        size = "standard";
        tweaks = [ "rimless" "black" ];
        variant = "macchiato";
      });
    };
    cursorTheme = {
      name = "catppuccin-macchiato-dark-cursors";
      package = lib.mkForce pkgs.catppuccin-cursors.macchiatoDark;
      size = 48;
    };
    iconTheme = {
      name = "Papirus-Dark";
      # Force usage of standard Papirus instead of Catppuccin's fork to resolve conflict
      package = lib.mkForce pkgs.papirus-icon-theme;
    };
  };

  # Ensure the Latte theme is ALSO available for the toggle script to switch to
  home.packages = [
    pkgs.toggle-theme
    (pkgs.catppuccin-gtk.override {
      accents = [ "blue" ];
      size = "standard";
      tweaks = [ "rimless" "black" ];
      variant = "latte";
    })
  ];

  # -------------------------------------------------------------------
  # ✨ MUTABLE CONFIGS FOR RUNTIME TOGGLING
  # -------------------------------------------------------------------
  # NixOS normally makes ~/.config files read-only symlinks.
  # To allow 'toggle-theme' to edit them, we must break the symlinks 
  # and copy the files to the user directory during activation.
  home.activation.makeConfigsWritable = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    
    # 1. Helper function
    make_writable() {
      local file="$1"
      local source="$2"
      
      # Only act if the target is a symlink (meaning it's managed by Nix)
      # or if it doesn't exist yet.
      if [ -L "$file" ] || [ ! -f "$file" ]; then
        echo "Making $file writable for theme toggling..."
        mkdir -p "$(dirname "$file")"
        
        # If source exists (from Nix store), copy it. Otherwise create empty/default.
        if [ -f "$source" ]; then
          cp --remove-destination "$(readlink -f "$source" || echo "$source")" "$file"
        else
          # Create default if needed
          touch "$file"
        fi
        chmod +w "$file"
      fi
    }

    # 2. Make Waybar CSS writable (so we can import theme.css)
    mkdir -p ${config.xdg.configHome}/waybar
    if [ ! -f ${config.xdg.configHome}/waybar/theme.css ]; then
       # Default to Dark on first run
       echo "@define-color base #24273a;" > ${config.xdg.configHome}/waybar/theme.css
    fi

    # 3. Make Hyprland Theme config writable
    mkdir -p ${config.xdg.configHome}/hypr
    if [ ! -f ${config.xdg.configHome}/hypr/theme.conf ]; then
       echo "" > ${config.xdg.configHome}/hypr/theme.conf
    fi

    # 4. Helix Config
    HX_PATH="${config.xdg.configHome}/helix/config.toml"
    if [ -L "$HX_PATH" ]; then
       cp --remove-destination "$(readlink "$HX_PATH")" "$HX_PATH"
       chmod +w "$HX_PATH"
    fi

    # 5. Zellij Config
    # We copy this even if Zellij module is enabled, to allow mutability
    ZJ_PATH="${config.xdg.configHome}/zellij/config.kdl"
    if [ -L "$ZJ_PATH" ]; then
       cp --remove-destination "$(readlink "$ZJ_PATH")" "$ZJ_PATH"
       chmod +w "$ZJ_PATH"
    fi

    # 6. Alacritty Theme File
    mkdir -p ${config.xdg.configHome}/alacritty
    if [ ! -f ${config.xdg.configHome}/alacritty/theme.toml ]; then
       touch ${config.xdg.configHome}/alacritty/theme.toml
    fi
  '';

  # -------------------------------------------------------------------
  # ✨ XSESSION & SCALING
  # -------------------------------------------------------------------
  xsession.enable = true;
  xresources.properties = {
    "Xft.dpi" = 192;
    "Xcursor.size" = 48;
  };

  home.sessionVariables = { GDK_SCALE = "2"; QT_SCALE_FACTOR = "2"; };
}
