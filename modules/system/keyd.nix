# /etc/nixos/modules/system/keyd.nix
{ ... }:

{
  # -------------------------------------------------------------------
  # ⌨️ KEY REMAPPING DAEMON (keyd)
  # -------------------------------------------------------------------
  services.keyd = {
    enable = true;
    keyboards."default" = {
      ids = [ "*" ];
      settings.main = {
        capslock = "overload(control, escape)";
      };
    };
  };
}
