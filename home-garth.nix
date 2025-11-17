############################################################
##########          START home-garth.nix          ##########
############################################################

# /etc/nixos/home-garth.nix
{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./disable-touchpad-while-typing.nix
    ./modules/home/theme.nix
    ./modules/home/hyprland.nix
    ./modules/home/waybar.nix
    ./modules/home/terminal.nix
    ./modules/home/helix.nix # This line is important
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
  # 📝 ZSH SHELL
  # -------------------------------------------------------------------
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
    jujutsu # The Git-compatible DVCS
    caddy   # The Caddy web server
    mkcert  # For creating locally-trusted development certificates
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
    iwgtk
    unzip
  ];

  # -------------------------------------------------------------------
  # ⚙️ AUTOMATED MKCERT & CADDY CONFIGURATION
  # -------------------------------------------------------------------

  # This systemd user service automates the 'mkcert -install' command.
  systemd.user.services.mkcert-install = {
    Unit = {
      Description = "Install mkcert's local CA into trust stores";
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.mkcert}/bin/mkcert -install";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # This block declaratively creates the Caddyfile in ~/.config/caddy/Caddyfile
  xdg.configFile."caddy/Caddyfile".text = ''
    # Global options block
    {
      # This tells Caddy to use the mkcert local Certificate Authority (CA).
      pki {
        ca local
      }
    }

    # Site configuration
    garth.localhost.com.au, *.garth.localhost.com.au {
      # This rule proxies all requests to a local web service running on port 8080.
      reverse_proxy localhost:8080
    }
  '';

  # This defines the Caddy service that runs for your user.
  systemd.user.services.caddy = {
    Unit = {
      Description = "Caddy Web Server";
      # Ensures Caddy starts after the network is up and after mkcert has run.
      After = [ "network.target" "mkcert-install.service" ];
      Requires = [ "mkcert-install.service" ];
    };
    Service = {
      # This tells Caddy to run and where to find its configuration file.
      ExecStart = "${pkgs.caddy}/bin/caddy run --config ${config.xdg.configHome}/caddy/Caddyfile";
      Restart = "always";
      RestartSec = 5;
    };
    Install = {
      # This ensures the service starts automatically when you log in.
      WantedBy = [ "default.target" ];
    };
  };
}
