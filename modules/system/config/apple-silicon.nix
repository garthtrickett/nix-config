# modules/system/config/apple-silicon.nix
{ config, pkgs, lib, inputs, ... }:

{
  hardware.asahi.peripheralFirmwareDirectory = inputs.self + "/firmware";
  networking.wireless.iwd = { enable = true; settings.General.EnableNetworkingConfiguration = true; };
  services.resolved.enable = true;
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "eurosign:e";
  services.printing.enable = true;

  # --- BOOTLOADER SPACE FIX ---
  # Limit the number of generations in the boot menu to 10.
  # This ensures old kernels are deleted from /boot automatically.
  boot.loader.grub.configurationLimit = 10;
  boot.loader.systemd-boot.configurationLimit = 10;
}
