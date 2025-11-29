# modules/system/config/general.nix
{ config, pkgs, lib, ... }:

{
  boot.kernelModules = [ "uinput" ];
  networking.hostName = "nixos";

  programs.dconf.enable = true;

  networking.extraHosts = ''
    127.0.0.1 garth.localhost.com.au
  '';

  # CRITICAL FIX 3: Commented out. 
  # This allows the Hotspot's DHCP DNS to work, which allows Tailscale to connect.
  # Once Tailscale connects, it will inject its own DNS preferences via systemd-resolved.
  # networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

  time.timeZone = "Australia/Sydney";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";
}
