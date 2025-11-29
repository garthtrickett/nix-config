############################################################
##########          START modules/system/config/vpn.nix          ##########
############################################################

# /etc/nixos/modules/system/config/vpn.nix
{ config, pkgs, lib, ... }:

{
  # -------------------------------------------------------------------
  # 🔒 MULLVAD VPN
  # -------------------------------------------------------------------

  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };

  # -------------------------------------------------------------------
  # 🤖 AUTO-CONFIGURE MULLVAD DNS
  # -------------------------------------------------------------------
  # This service runs once on boot to tell Mullvad:
  # "Use NextDNS IPv4 servers for all traffic inside the tunnel."

  systemd.services.mullvad-dns-setup = {
    description = "Configure Mullvad to use NextDNS";
    wants = [ "mullvad-daemon.service" ];
    after = [ "mullvad-daemon.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.mullvad-vpn}/bin/mullvad dns set custom 45.90.28.160 45.90.30.160";
    };
  };

  # -------------------------------------------------------------------
  # 🧱 FIREWALL CONFIGURATION
  # -------------------------------------------------------------------

  networking.firewall.checkReversePath = "loose";
  environment.systemPackages = [ pkgs.mullvad-vpn ];
}
