# /etc/nixos/modules/system/ydotool.nix
{ config, pkgs, ... }:

{
  # -------------------------------------------------------------------
  # ⚙️ YDOTOOL SYSTEM SERVICE
  # -------------------------------------------------------------------
  systemd.services.ydotoold = {
    description = "ydotool daemon";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udev-settle.service" ];
    serviceConfig = {
      Restart = "always";
      ExecStart = ''
        ${pkgs.ydotool}/bin/ydotoold \
          --socket-path=/run/ydotoold.sock \
          --socket-own=${config.users.users.garth.name}:${config.users.groups.input.name} \
          --socket-mode=0660
      '';
    };
  };

  # -------------------------------------------------------------------
  # ⚙️ UDEV RULE & GROUP FOR YDOTOOL
  # -------------------------------------------------------------------
  # This rule allows members of the 'input' group to access the uinput device.
  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", MODE="0660"
  '';

  # Create the 'input' group used by ydotool.
  users.groups.input = {};
}
