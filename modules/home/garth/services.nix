# modules/home/garth/services.nix
{ config, pkgs, lib, inputs, ... }:

{
  services.polkit-gnome.enable = true;
  services.disable-touchpad-while-typing.enable = true;

  services.hyprsunset = {
    enable = true;
    settings =
      {
        profile = [
          {
            time = "7:30";
            identity = true;
          }
          {
            time = "21:00";
            temperature = 3000;
            gamma = 0.8;
          }
        ];
      };
  };
}
