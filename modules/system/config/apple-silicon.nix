# modules/system/config/apple-silicon.nix
{ config, pkgs, lib, inputs, ... }:

{
  hardware.asahi.peripheralFirmwareDirectory = inputs.self + "/firmware";
  networking.wireless.iwd = { enable = true; settings.General.EnableNetworkingConfiguration = true; };
  services.resolved.enable = true;
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "eurosign:e";
  services.printing.enable = true;
}
