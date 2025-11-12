# /etc/nixos/home-garth.nix
{ config, pkgs, ... }:

{
  # -------------------------------------------------------------------
  # 🔑 SESSION SERVICES - THE CRITICAL FIX
  # -------------------------------------------------------------------
  # Enable the Polkit agent. This is the "butler" that allows your
  # Hyprland session to perform privileged actions. Without this,
  # the login process can fail with an "auth error".
  services.polkit-gnome.enable = true;

  # -------------------------------------------------------------------
  #  HYPRLAND CONFIGURATION
  # -------------------------------------------------------------------
  wayland.windowManager.hyprland = {
    enable = true;
    
    settings = {
      # --- Monitors ---
      monitor = [
        ",preferred,auto,1"
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
        touchpad = {
          natural_scroll = true;
        };
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
  # USER PACKAGES
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
