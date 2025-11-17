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
    secrets.GEMINI_API_KEY = { };
  };

  # -------------------------------------------------------------------
  # ⚙️ GLOBAL ENVIRONMENT & SESSION VARIABLES
  # -------------------------------------------------------------------
  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "hx";
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
  #  Git & Jujutsu Configuration
  # -------------------------------------------------------------------
  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = "Garth Trickett";
        email = "garthtrickett@gmail.com";
      };
      aliases = {
        # CORRECTED: Use the modern `util exec` syntax for shell commands.
        sync = [ "util" "exec" "--" "bash" "-c" "jj git fetch && jj rebase -r @ -d main@origin" ];
        start = [ "util" "exec" "--" "bash" "-c" "jj new main@origin" ];
        sp = [ "util" "exec" "--" "bash" "-c" "jj git fetch && jj rebase -r @ -d main@origin && jj git push --change=@" ];
      };
      ui = {
        editor = "helix";
      };
    };
  };


  # -------------------------------------------------------------------
  # 📦 USER PACKAGES
  # -------------------------------------------------------------------

  programs.starship = {
    enable = true;

    # Optional: Enable integration for your specific shell (often not needed if you enable the shell program in Home Manager too)
    enableZshIntegration = true;
    # enableBashIntegration = true; 

    # 2. Configure Starship settings (optional, but recommended)
    settings = {
      # Replaces the content of your traditional ~/.config/starship.toml
      add_newline = false; # Set to false to disable the blank line above the prompt

      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[✗](bold red)";
      };

      # Define the prompt format
      format = "$all$line_break$character";
    };
  };

  # -------------------------------------------------------------------
  # 📦 USER PACKAGES
  # -------------------------------------------------------------------
  home.packages = with pkgs;
    [
      (inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default)
      gh
      jujutsu # The Git-compatible DVCS
      caddy # The Caddy web server
      mkcert # For creating locally-trusted development certificates
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
      libreoffice
      libnotify
      gnugrep
      gnused
      dunst
      libinput
      iwgtk
      unzip
      sops
      age
      wf-recorder
      ffmpeg
      file-roller # The archive manager
      nemo-fileroller # Nemo integration for file-roller
      pulseaudio
      toggle-bt-headphones
      bun
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
