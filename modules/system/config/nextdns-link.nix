# /etc/nixos/modules/system/config/nextdns-link.nix
{ config, pkgs, lib, ... }:

{
  # -------------------------------------------------------------------
  # 💓 NEXTDNS IP LINKER HEARTBEAT
  # -------------------------------------------------------------------
  # Since we use Mullvad VPN, our Public IP changes constantly.
  # This service pings NextDNS every 5 minutes to say "This new VPN IP is me!"
  # This ensures the IPv4 DNS servers (45.90.xx.xx) configured in Mullvad
  # actually apply your profile (b9cd6d) instead of the generic default profile.

  systemd.services.nextdns-link-ip = {
    description = "Update NextDNS Linked IP";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      # Your specific Link IP URL from the dashboard text you provided
      ExecStart = "${pkgs.curl}/bin/curl -s https://link-ip.nextdns.io/b9cd6d/979e1ae69740bbc0";
    };
  };

  systemd.timers.nextdns-link-ip = {
    description = "Run NextDNS Link IP update every 5 minutes";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1m";
      OnUnitActiveSec = "5m";
    };
  };
}
