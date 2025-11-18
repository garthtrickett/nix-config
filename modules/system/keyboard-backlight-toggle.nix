# /etc/nixos/modules/system/keyboard-backlight-toggle.nix
{ config, pkgs, ... }:

{
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "toggle-keyboard-backlight" ''
      #!${pkgs.stdenv.shell}
      
      CURRENT_BRIGHTNESS=$(brightnessctl --device=kbd_backlight get)
      MAX_BRIGHTNESS=$(brightnessctl --device=kbd_backlight max)

      if [ "$CURRENT_BRIGHTNESS" -gt 0 ]; then
        brightnessctl --device=kbd_backlight set 0
      else
        brightnessctl --device=kbd_backlight set "$MAX_BRIGHTNESS"
      fi
    '')
  ];
}
