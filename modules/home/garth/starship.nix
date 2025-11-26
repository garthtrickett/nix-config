# modules/home/garth/starship.nix
{ config, pkgs, lib, inputs, ... }:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = false;
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[✗](bold red)";
      };
      format = "$all$line_break$character";
    };
  };
}
