############################################################
##########          START modules/system/config/nextdns.nix          ##########
############################################################

{ config, pkgs, lib, ... }:

{
  services.nextdns = {
    enable = true;
    arguments = [ "-config" "b9cd6d" "-report-client-info" "-auto-activate" ];
  };

  # Disable systemd-resolved
  services.resolved.enable = lib.mkForce false;

  # CRITICAL FIX 1: Disable NixOS's resolvconf management.
  # This prevents the 'network-setup' service from crashing with "signature mismatch"
  # when it sees that NetworkManager or Mullvad has touched /etc/resolv.conf.
  networking.resolvconf.enable = false;

  # CRITICAL FIX 2: Tell NetworkManager to manage DNS directly.
  # "default" = use ISP/Router DNS (DHCP) when VPN is off.
  networking.networkmanager.dns = "default";

  # Insert localhost (NextDNS) at the top of the list so it is preferred.
  networking.networkmanager.insertNameservers = [ "127.0.0.1" ];
}
