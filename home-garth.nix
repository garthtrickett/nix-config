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
    ./modules/home/helix.nix
  ];
  
  # -------------------------------------------------------------------
  # 🔑 SECRETS MANAGEMENT WITH SOPS
  # -------------------------------------------------------------------
  # This block is required so that Home Manager knows how to
  # decrypt its own secrets. It does not inherit this from the
  # system configuration.
  sops = {
    age.keyFile = "/home/garth/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets.yaml;
    
    # Define the user-specific secrets that Home Manager needs.
    secrets.GEMINI_API_KEY = {};
  };
  
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
      # Load Gemini API Key from sops
      if [ -f "${config.sops.secrets.GEMINI_API_KEY.path}" ];
      then
        export GEMINI_API_KEY=$(cat ${config.sops.secrets.GEMINI_API_KEY.path})
      fi

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
    hyprshot
    nemo
    swaylock
    zathura
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
    sops # Add sops and age to ensure they are installed
    age
    
    wf-recorder
    ffmpeg
  ];

  # -------------------------------------------------------------------
  # ⚙️ AUTOMATED MKCERT & CADDY CONFIGURATION
  # -------------------------------------------------------------------
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
  xdg.configFile."caddy/Caddyfile".text = ''
    {
      pki {
        ca local
      }
    }
    garth.localhost.com.au, *.garth.localhost.com.au {
      reverse_proxy localhost:8080
    }
  '';
  systemd.user.services.caddy = {
    Unit = {
      Description = "Caddy Web Server";
      After = [ "network.target" "mkcert-install.service" ];
      Requires = [ "mkcert-install.service" ];
    };
    Service = {
      ExecStart = "${pkgs.caddy}/bin/caddy run --config ${config.xdg.configHome}/caddy/Caddyfile";
      Restart = "always";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
