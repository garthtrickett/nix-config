# /etc/nixos/modules/system/config/nextdns.nix
{ config, pkgs, lib, ... }:

{
  services.nextdns = {
    enable = true;
    # REPLACE "YOUR_PROFILE_ID" with the ID from your NextDNS dashboard (e.g. "abcdef")
    arguments = [ "-config" "b9cd6d" "-report-client-info" "-auto-activate" ];
  };

  # Disable systemd-resolved to prevent port 53 conflicts (NextDNS runs its own listener)
  services.resolved.enable = lib.mkForce false;

  # Tell NetworkManager not to touch /etc/resolv.conf
  networking.networkmanager.dns = "none";
}

