# modules/system/config/tailscale.nix
{ config, pkgs, lib, ... }:

{
  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets.tailscale_auth_key.path;

    # FIX: 
    # 1. --mtu=1280: Cellular networks often drop packets > 1400 bytes. 
    #    Tailscale is 1280 safe, but forcing it prevents negotiation hangs.
    # 2. --accept-dns=true: Needed for NextDNS.
    extraUpFlags = [ "--accept-dns=true" "--reset" "--mtu=1280" ];

    useRoutingFeatures = "client";

    # FIX: Open firewall allows NAT traversal logic to work better 
    # behind restrictive Android Hotspot NATs.
    openFirewall = true;
  };
}
