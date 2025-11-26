# modules/system/config/virtualization.nix
{ config, pkgs, lib, ... }:

{
  virtualisation.docker.enable = true;
  boot.binfmt.emulatedSystems = [ "x86_64-linux" ];
  boot.binfmt.preferStaticEmulators = true;
}
