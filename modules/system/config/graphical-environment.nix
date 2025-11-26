# modules/system/config/graphical-environment.nix
{ config, pkgs, lib, ... }:

{
  services.xserver.enable = true;
  services.desktopManager.gnome.enable = false;
  services.displayManager.gdm.enable = true;
  services.displayManager.sessionPackages = [ pkgs.hyprland ];
}
