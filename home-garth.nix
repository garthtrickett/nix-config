{ config, pkgs, ... }:

{
  # This section configures Hyprland for the user 'garth'.
  # The option is 'wayland.windowManager.hyprland' in Home Manager.
  wayland.windowManager.hyprland = {
    enable = true;

    # This creates the configuration file at ~/.config/hypr/hyprland.conf
    extraConfig = ''
      # See https://wiki.hyprland.org/Configuring/Variables/ for more

      # Set default monitor to display the workspace
      monitor=,preferred,auto,1

      # Execute a terminal (kitty) on startup
      exec = ${pkgs.kitty}/bin/kitty

      # Set a workspace keybinding: Super + 1
      bind = SUPER, 1, workspace, 1
      
      # Exit Hyprland keybinding: Super + Q
      bind = SUPER, Q, exec, killall Hyprland
    '';
  };

  # Ensure necessary programs are available in the user's PATH.
  # These packages are installed for 'garth' only.
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
