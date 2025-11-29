{ config, pkgs, lib, ... }:

{
  services.nextdns = {
    enable = true;
    # Your specific Profile ID from the text you provided
    arguments = [ "-config" "b9cd6d" "-report-client-info" "-auto-activate" ];
  };

  # Disable systemd-resolved to prevent port 53 conflicts
  services.resolved.enable = lib.mkForce false;

  # Tell NetworkManager not to touch /etc/resolv.conf
  networking.networkmanager.dns = "none";
}
