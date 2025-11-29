# modules/system/config/apple-silicon.nix
{ config, pkgs, lib, inputs, ... }:

{
  hardware.asahi.peripheralFirmwareDirectory = inputs.self + "/firmware";

  services.resolved.enable = true;

  # CRITICAL FIX 1: Prevent dhcpcd from fighting IWD
  networking.useDHCP = false;

  services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "eurosign:e";
  services.printing.enable = true;
  systemd.oomd.enable = true;

  networking.wireless.iwd = {
    enable = true;
    settings = {
      General = {
        EnableNetworkingConfiguration = true;
        AddressRandomization = "disabled";
        RoamRetryInterval = 15;
      };
      Network = {
        EnableIPv6 = false;
        NameResolvingService = "systemd";

        # CRITICAL FIX 2: Removed RoutePriorityOffset to prioritize WiFi
      };
    };
  };

  boot.loader.grub.configurationLimit = 10;
  boot.loader.systemd-boot.configurationLimit = 10;
}
