# /etc/nixos/home-garth.nix
{ config, pkgs, ... }:

{
  # -------------------------------------------------------------------
  # 🔑 SESSION SERVICES
  # -------------------------------------------------------------------
  services.polkit-gnome.enable = true;

  # -------------------------------------------------------------------
  # 🖥️ HYPRLAND WINDOW MANAGER
  # -------------------------------------------------------------------
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      # --- Monitors ---
      # This is the primary fix for Hyprland itself.
      # We change the scale from '1' to '2' for 200% scaling.
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
  # ✨ HiDPI & SCALING CONFIGURATION (The Comprehensive Fix)
  # -------------------------------------------------------------------
  # This section ensures that all applications, not just Hyprland,
  # are scaled correctly on your high-resolution display.

  # Set environment variables for GTK and Qt applications.
  home.sessionVariables = {
    GDK_SCALE = "2";
    QT_SCALE_FACTOR = "2";
  };

  # Set XDG settings for font DPI and cursor size.
  # This helps scale fonts and legacy XWayland applications.
  xresources.settings = {
    "Xft.dpi" = 192; # Standard DPI is 96, so 96*2 = 192 for 200% scaling.
    "Xcursor.size" = 48;
  };
  
  # Ensure the GTK cursor theme also respects the scaled size.
  gtk.cursorTheme.size = 48;

  # -------------------------------------------------------------------
  # 📦 USER PACKAGES
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
