{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    keyd
    toggle-battery-limit
    jq
    envsubst
    postgresql
    brightnessctl
    libnotify
    # Added nm-applet since we are switching to NetworkManager.
    # This provides the system tray icon to select Wifi networks easily.
    networkmanagerapplet
  ];
  programs.zsh.enable = true;
  programs.mtr.enable = true;
  programs.gnupg.agent = { enable = true; enableSSHSupport = true; };
  services.openssh.enable = true;
  system.stateVersion = "25.11";
}
