# modules/system/config/apple-silicon.nix
{ config, pkgs, lib, inputs, ... }:

{
  hardware.asahi.peripheralFirmwareDirectory = inputs.self + "/firmware";

  services.resolved.enable = true;

  services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "eurosign:e";
  services.printing.enable = true;
  systemd.oomd.enable = true;

  networking.wireless.iwd = {
    enable = true;
    settings = {
      General = {
        EnableNetworkingConfiguration = true;
        # Keep disabled to prevent hotspot rejection
        AddressRandomization = "disabled";
        RoamRetryInterval = 15;
      };
      Network = {
        # FIX: Android Hotspots often fail with IPv6 (464XLAT issues).
        # Disabling IPv6 forces a stable IPv4 connection, which is required
        # for the Tailscale tunnel to establish reliably over cellular.
        EnableIPv6 = false;

        # Use systemd-resolved for DNS
        NameResolvingService = "systemd";

        # Prioritize this interface so we use it when wifi connects
        RoutePriorityOffset = 300;
      };
    };
  };


  # --- BOOTLOADER SPACE FIX ---
  # Limit the number of generations in the boot menu to 10.
  boot.loader.grub.configurationLimit = 10;
  boot.loader.systemd-boot.configurationLimit = 10;
}
