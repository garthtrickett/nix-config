# modules/system/config/tailscale.nix
{ config, pkgs, lib, ... }:

{
  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets.tailscale_auth_key.path;
    extraUpFlags = [ "--accept-dns=true" ];
    useRoutingFeatures = "client";
  };
}
