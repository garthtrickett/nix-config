# modules/system/config/secrets.nix
{ config, pkgs, lib, inputs, ... }:

{
  sops = {
    defaultSopsFile = inputs.self + "/secrets.yaml";
    age.keyFile = "/home/garth/.config/sops/age/keys.txt";
  };

  sops.secrets.tailscale_auth_key = {
    owner = "tailscaled";
    group = "tailscaled";
  };
}
