# /etc/nixos/home-garth.nix
{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./disable-touchpad-while-typing.nix
    ./modules/home/theme.nix
    ./modules/home/hyprland.nix
    ./modules/home/waybar.nix
    ./modules/home/terminal.nix
  ];

  # -------------------------------------------------------------------
  # 🔑 SESSION SERVICES
  # -------------------------------------------------------------------
  services.polkit-gnome.enable = true;
  services.disable-touchpad-while-typing.enable = true;

  # -------------------------------------------------------------------
  # 🌇 HYPRSUNSET SERVICE (Using the modern 'settings' option)
  # -------------------------------------------------------------------
  services.hyprsunset = {
    enable = true;
    settings =
      {

  profile = [
    {
      time = "7:30";
      identity = true;
    }
    {
      time = "21:00";
      temperature = 3000;
      gamma = 0.8;
    }
  ];
};

  };

  # -------------------------------------------------------------------
  # 📝 HELIX TEXT EDITOR & ZSH SHELL
  # -------------------------------------------------------------------
  programs.helix = {
    enable = true;
    settings = {
      editor = {
        line-number = "relative";
        cursorline = true;
        bufferline = "always";
      };
    };
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initContent = ''
      rebuild() {
        (
          cd /etc/nixos &&
          echo "==> Temporarily changing directory to /etc/nixos" &&
          sudo nixos-rebuild switch --flake .#nixos "$@" &&
          echo "==> Returning to original directory"
        )
      }
    '';
  };

  # -------------------------------------------------------------------
  # 📦 USER PACKAGES
  # -------------------------------------------------------------------
  home.packages = with pkgs;
  [
    (inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default)
    gh
    alacritty
    zellij
    fuzzel
    swaylock
    swayidle
    brightnessctl
    wl-clipboard
    xdg-user-dirs
    ydotool
    procps
    nerd-fonts.fira-code
    hyprsunset
    libnotify
    gnugrep
    gnused
    dunst
    libinput
  ];
}
