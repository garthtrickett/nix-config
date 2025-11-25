# /etc/nixos/modules/home/theme.nix
{ config, pkgs, lib, ... }:

{
  # -------------------------------------------------------------------
  # 🎨 CATPPUCCIN THEME BASE
  # -------------------------------------------------------------------
  catppuccin = {
    enable = true;
    flavor = "macchiato";
    helix.enable = false;
    alacritty.enable = false;
    waybar.enable = false;
    zellij.enable = true;
    # CRITICAL: Disable Firefox styling so it doesn't conflict with our 
    # manual profile management and dynamic system theme detection.
    firefox.enable = false;
  };

  # -------------------------------------------------------------------
  # 🎭 GTK & CURSOR THEME
  # -------------------------------------------------------------------
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
      package = lib.mkForce pkgs.papirus-icon-theme;
    };
  };

  # FIX: Force overwrite GTK settings to avoid "clobbered" backup errors.
  xdg.configFile."gtk-3.0/settings.ini".force = true;
  xdg.configFile."gtk-4.0/settings.ini".force = true;

  # Install the Latte variant so we can switch to it
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
  # ✨ MUTABLE CONFIGS
  # -------------------------------------------------------------------
  home.activation.makeConfigsWritable = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    make_writable() {
      local file="$1"
      local source="$2"
      if [ -L "$file" ] || [ ! -f "$file" ]; then
        mkdir -p "$(dirname "$file")"
        if [ -f "$source" ]; then
          cp --remove-destination "$(readlink -f "$source" || echo "$source")" "$file"
        else
          touch "$file"
        fi
        chmod +w "$file"
      fi
    }

    # Waybar
    mkdir -p ${config.xdg.configHome}/waybar
    if [ ! -f ${config.xdg.configHome}/waybar/theme.css ]; then
       echo "@define-color base #24273a;" > ${config.xdg.configHome}/waybar/theme.css
    fi

    # Hyprland
    mkdir -p ${config.xdg.configHome}/hypr
    if [ ! -f ${config.xdg.configHome}/hypr/theme.conf ]; then
       echo "" > ${config.xdg.configHome}/hypr/theme.conf
    fi

    # Helix & Zellij
    HX_PATH="${config.xdg.configHome}/helix/config.toml"
    if [ -L "$HX_PATH" ]; then
       cp --remove-destination "$(readlink "$HX_PATH")" "$HX_PATH"
       chmod +w "$HX_PATH"
    fi
    ZJ_PATH="${config.xdg.configHome}/zellij/config.kdl"
    if [ -L "$ZJ_PATH" ]; then
       cp --remove-destination "$(readlink "$ZJ_PATH")" "$ZJ_PATH"
       chmod +w "$ZJ_PATH"
    fi

    # Alacritty
    mkdir -p ${config.xdg.configHome}/alacritty
    if [ ! -f ${config.xdg.configHome}/alacritty/theme.toml ]; then
       touch ${config.xdg.configHome}/alacritty/theme.toml
    fi

    # GTK Settings
    GTK3_SETTINGS="${config.xdg.configHome}/gtk-3.0/settings.ini"
    if [ -L "$GTK3_SETTINGS" ]; then
       cp --remove-destination "$(readlink "$GTK3_SETTINGS")" "$GTK3_SETTINGS"
       chmod +w "$GTK3_SETTINGS"
    fi
    GTK4_SETTINGS="${config.xdg.configHome}/gtk-4.0/settings.ini"
    if [ -L "$GTK4_SETTINGS" ]; then
       cp --remove-destination "$(readlink "$GTK4_SETTINGS")" "$GTK4_SETTINGS"
       chmod +w "$GTK4_SETTINGS"
    fi
  '';

  # -------------------------------------------------------------------
  # ✨ SESSION VARIABLES
  # -------------------------------------------------------------------
  xsession.enable = true;
  xresources.properties = {
    "Xft.dpi" = 192;
    "Xcursor.size" = 48;
  };

  home.sessionVariables = {
    GDK_SCALE = "2";
    QT_SCALE_FACTOR = "2";
  };
}
