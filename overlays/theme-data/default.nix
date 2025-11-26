# overlays/theme-data/default.nix
{ pkgs, ... }: # pkgs will be passed by callPackage

{
  firefoxLatteCss = pkgs.writeText "firefox-latte.css" (builtins.readFile ./firefox-latte.css);
  waybarLatteCss = pkgs.writeText "waybar-latte.css" (builtins.readFile ./waybar-latte.css);
  hyprlandLatteConf = pkgs.writeText "hyprland-latte.conf" (builtins.readFile ./hyprland-latte.conf);
  alacrittyLatteToml = pkgs.writeText "alacritty-latte.toml" (builtins.readFile ./alacritty-latte.toml);

  firefoxMacchiatoCss = pkgs.writeText "firefox-macchiato.css" (builtins.readFile ./firefox-macchiato.css);
  waybarMacchiatoCss = pkgs.writeText "waybar-macchiato.css" (builtins.readFile ./waybar-macchiato.css);
  hyprlandMacchiatoConf = pkgs.writeText "hyprland-macchiato.conf" (builtins.readFile ./hyprland-macchiato.conf);
  alacrittyMacchiatoToml = pkgs.writeText "alacritty-macchiato.toml" (builtins.readFile ./alacritty-macchiato.toml);
}
