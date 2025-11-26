# modules/home/garth/git.nix
{ config, pkgs, lib, inputs, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Garth Trickett";
        email = "garthtrickett@gmail.com";
      };
      pull = {
        rebase = true;
      };
      rebase = {
        autoStash = true;
      };
      init = {
        defaultBranch = "main";
      };
    };
  };
}
