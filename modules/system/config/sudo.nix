# modules/system/config/sudo.nix
{ config, pkgs, lib, ... }:

{
  security.sudo.extraRules = [
    {
      users = [ "garth" ];
      commands = [
        {
          command = "${pkgs.toggle-battery-limit}/bin/toggle-battery-limit";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${pkgs.tailscale}/bin/tailscale set --exit-node *";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/nixos-rebuild";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
