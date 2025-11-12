# /etc/nixos/home-garth.nix
{ config, pkgs, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    
    # We are replacing 'extraConfig' with the structured 'settings' option.
    settings = {
      # --- Monitors ---
      # 'monitor=' lines go here. Each line is a string in a list.
      monitor = [
        ",preferred,auto,1"
      ];

      # --- Startup Applications ---
      # 'exec-once =' is better for startup apps. Each command is a string in a list.
      "exec-once" = [
        "${pkgs.kitty}/bin/kitty"
        # You could add more here, like:
        # "waybar"
        # "swww init"
      ];

      # --- Keybindings ---
      # All 'bind =' lines go into a list of strings.
      bind = [
        "SUPER, 1, workspace, 1"
        "SUPER, Q, exec, killall Hyprland"
      ];

      # --- Input Devices ---
      # You can now configure nested settings like 'input'.
      input = {
        kb_layout = "us";
        follow_mouse = 1;

        touchpad = {
          natural_scroll = true;
        };
      };

      # --- General Settings ---
      # Notice that keys with dots in them must be quoted.
      general = {
        "gaps_in" = 5;
        "gaps_out" = 10;
        border_size = 2;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        layout = "dwindle";
      };

      # Add other Hyprland sections here as needed...
      # decoration = { ... };
      # animations = { ... };
      # dwindle = { ... };
      # master = { ... };
    };
  };

  # Your packages list remains the same.
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
