# /etc/nixos/modules/system/sudo.nix
{ pkgs, ... }:

{
  # -------------------------------------------------------------------
  # 🛡️ SUDO RULES
  # -------------------------------------------------------------------
  # This sudo rule is required for passwordless manual execution of the battery limit toggle script.
  security.sudo.extraRules = [
    {
      users = [ "garth" ];
      commands = [
        {
          command = "${pkgs.toggle-battery-limit}/bin/toggle-battery-limit";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
