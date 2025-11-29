# /etc/nixos/configuration.nix

############################################################
##########          START configuration.nix          ##########
############################################################

{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/battery-limiter.nix
    ./modules/system/ydotool.nix
    ./modules/system/keyd.nix
    ./modules/system/waybar-scripts.nix
    ./modules/system/keyboard-backlight-toggle.nix
    ./modules/system/config/nix.nix
    ./modules/system/config/general.nix
    ./modules/system/config/swap.nix
    ./modules/system/config/graphical-environment.nix
    ./modules/system/config/xdg-portal.nix
    ./modules/system/config/apple-silicon.nix
    ./modules/system/config/virtualization.nix
    ./modules/system/config/sudo.nix
    ./modules/system/config/audio-battery-user.nix
    ./modules/system/config/secrets.nix
    ./modules/system/config/power.nix
    ./modules/system/config/bluetooth.nix
    ./modules/system/config/system-packages.nix
  ];
}
