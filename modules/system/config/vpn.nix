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
  # 🤖 AUTO-CONFIGURE MULLVAD
  # -------------------------------------------------------------------
  systemd.services.mullvad-setup = {
    description = "Configure Mullvad (DNS + LAN + Lockdown)";
    wants = [ "mullvad-daemon.service" ];
    after = [ "mullvad-daemon.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "configure-mullvad" ''
        # Small sleep to ensure the daemon socket is fully ready
        sleep 2
        ${pkgs.mullvad-vpn}/bin/mullvad dns set custom 45.90.28.160 45.90.30.160
        ${pkgs.mullvad-vpn}/bin/mullvad lan set allow
        # CRITICAL: Ensure lockdown mode is off so internet works when VPN is disconnected
        ${pkgs.mullvad-vpn}/bin/mullvad lockdown-mode set off
      ''}";
    };
  };

  # -------------------------------------------------------------------
  # 🧱 FIREWALL CONFIGURATION
  # -------------------------------------------------------------------
  networking.firewall.checkReversePath = "loose";
  environment.systemPackages = [ pkgs.mullvad-vpn ];
}
