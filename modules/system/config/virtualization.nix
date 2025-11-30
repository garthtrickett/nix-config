# modules/system/config/virtualization.nix
{ config, pkgs, lib, ... }:

{
  virtualisation.docker.enable = true;
  boot.binfmt.emulatedSystems = [ "x86_64-linux" ];
  boot.binfmt.preferStaticEmulators = true;

  # FIX: Trust the Docker network interface.
  # This allows traffic to flow freely between the host and containers.
  # Without this, the firewall drops packets on the docker0 bridge, causing
  # "Connection closed unexpectedly" errors when hitting mapped ports.
  networking.firewall.trustedInterfaces = [ "docker0" ];
  environment.systemPackages = [ pkgs.docker-compose ];
}


