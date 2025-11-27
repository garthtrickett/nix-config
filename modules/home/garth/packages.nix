# modules/home/garth/packages.nix
{ config, pkgs, lib, inputs, ... }:

{
  home.packages = [
    (inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default)
    pkgs.gh
    pkgs.jujutsu
    pkgs.caddy
    pkgs.mkcert
    pkgs.alacritty
    pkgs.zellij
    pkgs.zjstatus
    pkgs.fuzzel
    pkgs.hyprshot
    pkgs.nemo
    pkgs.swaylock
    pkgs.zathura
    pkgs.swayidle
    pkgs.brightnessctl
    pkgs.wl-clipboard
    pkgs.xdg-user-dirs
    pkgs.ydotool
    pkgs.procps
    pkgs.nerd-fonts.fira-code
    pkgs.hyprsunset
    pkgs.libreoffice
    pkgs.gnugrep
    pkgs.gnused
    pkgs.gfold
    pkgs.dunst
    pkgs.libinput
    pkgs.iwgtk
    pkgs.unzip
    pkgs.vlc
    pkgs.sops
    pkgs.age
    pkgs.wf-recorder
    pkgs.ffmpeg
    pkgs.file-roller
    pkgs.nemo-fileroller
    pkgs.pulseaudio
    pkgs.toggle-bt-headphones
    pkgs.bun
    pkgs.gemini-cli
    pkgs.awscli2
    pkgs.file
    pkgs.glib
    # CRITICAL: These packages provide the schemas needed for gsettings to work 
    # and for Firefox to read the theme changes via DBus.
    pkgs.gsettings-desktop-schemas
    pkgs.gtk3
    # ADDED: Node.js is strictly required for 'npx' based MCP servers
    pkgs.nodejs
  ];
}
