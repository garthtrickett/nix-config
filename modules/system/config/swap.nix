# modules/system/config/swap.nix
{ config, pkgs, lib, ... }:

{
  swapDevices = [
    { device = "/swap/swapfile"; size = 4096; } # 4GB Swap File
  ];
  systemd.tmpfiles.rules = [
    "d /swap 0755 root root"
  ];
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    mkdir -p /swap
  '';

  services.earlyoom = {
    enable = true;
    freeMemThreshold = 10;
    freeSwapThreshold = 50;
    extraArgs = [ "-n" ];
  };
}
