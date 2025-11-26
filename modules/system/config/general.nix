# modules/system/config/general.nix
{ config, pkgs, lib, ... }:

{
  boot.kernelModules = [ "uinput" ];
  networking.hostName = "nixos";

  # CRITICAL: Enables the dconf DBus service. 
  programs.dconf.enable = true;

  networking.extraHosts = ''
    127.0.0.1 garth.localhost.com.au
  '';
  time.timeZone = "Australia/Sydney";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";
}
