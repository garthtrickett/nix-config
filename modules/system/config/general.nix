############################################################
##########          START modules/system/config/general.nix          ##########
############################################################

# modules/system/config/general.nix
{ config, pkgs, lib, ... }:

{
  boot.kernelModules = [ "uinput" ];
  networking.hostName = "nixos";

  programs.dconf.enable = true;

  # FIX: Open development ports.
  # Even with trustedInterfaces, explicitly allowing these ports ensures
  # that if Docker binds via the userland proxy, traffic isn't dropped.
  # 5432 = Postgres, 8080 = Your Caddy upstream
  networking.firewall.allowedTCPPorts = [ 5432 8080 ];

  networking.extraHosts = ''
    127.0.0.1 garth.localhost.com.au, db.localtest.me
  '';

  # CHANGED: Removed manual nameservers comment to ensure NextDNS module is the sole authority

  time.timeZone = "Australia/Sydney";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";
}
