# /etc/nixos/home-garth.nix
{ config, pkgs, ... }:

{
  # -------------------------------------------------------------------
  # 🔑 SESSION SERVICES
  # -------------------------------------------------------------------
  # Enables the Polkit agent for authentication in graphical sessions.
  services.polkit-gnome.enable = true;

  # -------------------------------------------------------------------
  # ✨ XSESSION & SCALING FOR XWAYLAND APPS (The Fix)
  # -------------------------------------------------------------------
  # We must enable the xsession module to unlock the xresources options.
  xsession.enable = true;

  # This sets the DPI for older XWayland applications so their fonts scale correctly.
  xresources.settings = {
    "Xft.dpi" = 192; # 96 DPI * 2 = 192 (for 200% scaling)
    "Xcursor.size" = 48; # Scales the mouse cursor in these apps.
  };

  # -------------------------------------------------------------------
  # 🖥️ HYPRLAND WINDOW MANAGER
  # -------------------------------------------------------------------
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      # --- Monitors ---
      # Set scale to '2' for 200% scaling on HiDPI/Retina display.
      monitor = [
        ",preferred,auto,2"
      ];

      # --- Startup Applications ---
      "exec-once" = [
        "${pkgs.kitty}/bin/kitty"
      ];

      # --- Keybindings ---
      bind = [
        "SUPER, 1, workspace, 1"
        "SUPER, Q, exec, killall Hyprland"
      ];

      # --- Input Devices ---
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad = { natural_scroll = true; };
      };

      # --- General Settings ---
      general = {
        "gaps_in" = 5;
        "gaps_out" = 10;
        border_size = 2;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        layout = "dwindle";
      };
    };
  };

  # -------------------------------------------------------------------
  # ✨ HiDPI & SCALING FOR NATIVE WAYLAND APPS
  # -------------------------------------------------------------------
  # Set environment variables for modern GTK and Qt toolkits.
  home.sessionVariables = {
    GDK_SCALE = "2";
    QT_SCALE_FACTOR = "2";
  };
  
  # Ensure the GTK cursor theme also respects the scaled size.
  gtk.cursorTheme.size = 48;

  # -------------------------------------------------------------------
  # 📝 HELIX TEXT EDITOR
  # -------------------------------------------------------------------
  programs.helix = {
    enable = true;
    settings = {
      theme = "catppuccin_macchiato";
      editor = {
        line-number = "relative";
        cursorline = true;
      };
    };
  };

  # -------------------------------------------------------------------
  # 📦 USER PACKAGES
  # -------------------------------------------------------------------
  home.packages = with pkgs; [
    kitty
    waybar
    wofi
    swaylock
    swayidle
    brightnessctl
    wl-clipboard
    xdg-user-dirs
  ];
}
