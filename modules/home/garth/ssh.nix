# modules/home/garth/ssh.nix
{ config, pkgs, lib, inputs, ... }:

{
  programs.ssh = {
    enable = true;

    matchBlocks = {
      "*" = {
        setEnv = { TERM = "xterm-256color"; };
        addKeysToAgent = "yes";
      };
    };
  };
}
