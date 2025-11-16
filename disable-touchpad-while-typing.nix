{ config, pkgs, lib, ... }:

let
  cfg = config.services.disable-touchpad-while-typing;

  # This script uses swayidle to watch for keyboard activity.
  # On activity ("before-sleep"), it disables the touchpad.
  # After 1 second of inactivity ("timeout"), it re-enables the touchpad.
  disable-touchpad-script = pkgs.writeShellScriptBin "disable-touchpad-while-typing" ''
    #!${pkgs.runtimeShell}
    ${pkgs.swayidle}/bin/swayidle -w \
      timeout 1 '${pkgs.hyprland}/bin/hyprctl keyword input:touchpad:enabled true' \
      before-sleep '${pkgs.hyprland}/bin/hyprctl keyword input:touchpad:enabled false'
  '';

in
{
  # This section defines a new option so you can easily enable/disable this feature.
  options.services.disable-touchpad-while-typing = {
    enable = lib.mkEnableOption "Enable script to disable touchpad while typing";
  };

  # This section creates the systemd user service if the option is enabled.
  config = lib.mkIf cfg.enable {
    systemd.user.services.disable-touchpad-while-typing = {
      Unit = {
        Description = "Disable touchpad while typing";
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${disable-touchpad-script}/bin/disable-touchpad-while-typing";
        Restart = "always";
        RestartSec = 3;
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
