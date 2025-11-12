# /etc/nixos/home-garth.nix
{ config, pkgs, ... }:

{
  # -------------------------------------------------------------------
  # 🏠 HOME MANAGER BASE CONFIGURATION (The Definitive Fix)
  # -------------------------------------------------------------------
  # This is the foundational switch that enables all graphical session
  # services. It MUST be enabled for options like 'xsession' to work.
  targets.generic-graphical.enable = true;

  # -------------------------------------------------------------------
  # 🔑 SESSION SERVICES
  # -------------------------------------------------------------------
  # This now works correctly because the generic-graphical target is enabled.
  services.polkit-gnome.enable = true;

  # -------------------------------------------------------------------
  # ✨ XSESSION & SCALING FOR XWAYLAND APPS
  # -------------------------------------------------------------------
  # This also now works correctly because the generic-graphical target is enabled.
  xsession.enable = true;
  xresources.settings = {
    "Xft.dpi" = 192;
    "Xcursor.size" = 48;
  };

  # -------------------------------------------------------------------
  # 🖥️ HYPRLAND WINDOW MANAGER
  # -------------------------------------------------------------------
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      monitor = [ ",preferred,auto,2" ];
      "exec-once" = [ "${pkgs.kitty}/bin/kitty" ];
      bind = [
        "SUPER, 1, workspace, 1"
        "SUPER, Q, exec, killall Hyprland"
      ];
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad = { natural_scroll = true; };
      };
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
  home.sessionVariables = {
    GDK_SCALE = "2";
    QT_SCALE_FACTOR = "2";
  };
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
