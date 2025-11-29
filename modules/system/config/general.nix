# modules/system/config/general.nix
{ config, pkgs, lib, ... }:

{
  boot.kernelModules = [ "uinput" ];
  networking.hostName = "nixos";

  programs.dconf.enable = true;

  networking.extraHosts = ''
    127.0.0.1 garth.localhost.com.au
  '';

  # CHANGED: Removed manual nameservers comment to ensure NextDNS module is the sole authority

  time.timeZone = "Australia/Sydney";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";
}
