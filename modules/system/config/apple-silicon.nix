# modules/system/config/apple-silicon.nix
{ config, pkgs, lib, inputs, ... }:

{
  hardware.asahi.peripheralFirmwareDirectory = inputs.self + "/firmware";

  # CHANGED: Disabled to allow NextDNS to manage DNS
  services.resolved.enable = false;

  # CRITICAL FIX 1: Prevent legacy dhcpcd from fighting NetworkManager
  networking.useDHCP = false;

  # --- NETWORK MANAGER CONFIGURATION ---
  # This provides robust switching, hotspot support, and DNS management.
  networking.networkmanager = {
    enable = true;
    # Tell NetworkManager to use iwd for the actual hardware communication
    wifi.backend = "iwd";
  };

  services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "eurosign:e";
  services.printing.enable = true;
  systemd.oomd.enable = true;

  networking.wireless.iwd = {
    enable = true;
    settings = {
      General = {
        # CRITICAL FIX 2: Disable iwd's internal IP management.
        # We want NetworkManager to handle DHCP and DNS, not iwd.
        EnableNetworkingConfiguration = false;
        AddressRandomization = "disabled";
        RoamRetryInterval = 15;
      };
      Network = {
        EnableIPv6 = false;
        # We remove NameResolvingService so iwd doesn't touch /etc/resolv.conf
      };
    };
  };

  boot.loader.grub.configurationLimit = 10;
  boot.loader.systemd-boot.configurationLimit = 10;
}
