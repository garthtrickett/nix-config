# modules/home/garth/jujutsu.nix
{ config, pkgs, lib, inputs, ... }:

{
  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = "Garth Trickett";
        email = "garthtrickett@gmail.com";
      };
      aliases = {
        sync = [ "util" "exec" "--" "bash" "-c" "jj git fetch && jj rebase -r @ -d main@origin" ];
        start = [ "util" "exec" "--" "bash" "-c" "jj new main@origin" ];
        sp = [ "util" "exec" "--" "bash" "-c" "jj git fetch && jj rebase -r @ -d main@origin && jj git push --change=@" ];
      };
      ui = {
        editor = "helix";
      };
    };
  };
}
