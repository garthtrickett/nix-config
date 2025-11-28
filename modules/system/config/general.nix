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

  # FIX: Fallback Bootstrapping DNS
  # When the Tailscale tunnel is DOWN (because internet is fresh), 
  # we need these servers to resolve 'controlplane.tailscale.com' 
  # so the tunnel can start. Once the tunnel is UP, Tailscale/NextDNS 
  # takes over priority.
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

  time.timeZone = "Australia/Sydney";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";
}
