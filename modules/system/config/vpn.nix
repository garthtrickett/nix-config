# /etc/nixos/modules/system/config/vpn.nix
{ config, pkgs, lib, ... }:

{
  # -------------------------------------------------------------------
  # 🔒 MULLVAD VPN
  # -------------------------------------------------------------------

  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn; # Includes the GUI
  };

  # -------------------------------------------------------------------
  # 🧱 FIREWALL CONFIGURATION
  # -------------------------------------------------------------------

  # NixOS, by default, drops packets that come in on an interface different 
  # from the one they would go out on (Reverse Path Filtering). 
  # This often breaks VPN connections. "loose" fixes this.
  networking.firewall.checkReversePath = "loose";

  environment.systemPackages = [ pkgs.mullvad-vpn ];
}
