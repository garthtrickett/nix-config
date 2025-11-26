# modules/system/config/system-packages.nix
{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    keyd
    toggle-battery-limit
    tailscale
    jq
    waybar-tailscale-status
    tailscale-exit-node-selector
    envsubst
    postgresql
    brightnessctl
    # firefox-nightly-bin  <-- REMOVED: Now managed by Home Manager
    libnotify
  ];
  programs.zsh.enable = true;
  programs.mtr.enable = true;
  programs.gnupg.agent = { enable = true; enableSSHSupport = true; };
  services.openssh.enable = true;
  system.stateVersion = "25.11";
}
