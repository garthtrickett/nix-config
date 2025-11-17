# /etc/nixos/modules/home/theme.nix
{ ... }:

{
  # -------------------------------------------------------------------
  # 🎨 CATPPUCCIN THEME
  # -------------------------------------------------------------------
  catppuccin = {
    enable = true;
    flavor = "macchiato";
    alacritty.enable = true;
    helix.enable = true;
    zellij.enable = true;
  };

  # -------------------------------------------------------------------
  # ✨ XSESSION & SCALING FOR XWAYLAND APPS
  # -------------------------------------------------------------------
  xsession.enable = true;
  xresources.properties = {
    "Xft.dpi" = 192;
    "Xcursor.size" = 48;
  };

  # -------------------------------------------------------------------
  # ✨ HiDPI & SCALING FOR NATIVE WAYLAND APPS
  # -------------------------------------------------------------------
  home.sessionVariables = { GDK_SCALE = "2"; QT_SCALE_FACTOR = "2"; };
  gtk.cursorTheme.size = 48;
}
