# modules/system/config/bluetooth.nix
{ config, pkgs, lib, ... }:

{
  hardware.bluetooth.enable = true;
  hardware.bluetooth.settings = {
    General = { Experimental = "true"; AutoEnable = "true"; FastConnectable = "true"; };
    Policy = { AutoEnable = "true"; AutoConnect = "true"; };
  };
  services.blueman.enable = true;
}
