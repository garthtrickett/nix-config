# /etc/nixos/home-garth.nix
{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./disable-touchpad-while-typing.nix
    ./modules/home/theme.nix
    ./modules/home/hyprland.nix
    ./modules/home/waybar.nix
    ./modules/home/zellij.nix
    ./modules/home/helix.nix
    ./modules/home/garth/sops.nix
    ./modules/home/garth/environment.nix
    ./modules/home/garth/services.nix
    ./modules/home/garth/ssh.nix
    ./modules/home/garth/git.nix
    ./modules/home/garth/firefox.nix
    ./modules/home/garth/zsh.nix
    ./modules/home/garth/starship.nix
    ./modules/home/garth/packages.nix
    ./modules/home/garth/caddy.nix

    # New separate file for Gemini TUI
  ];
}
