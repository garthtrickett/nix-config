# /etc/nixos/home-garth.nix
{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./disable-touchpad-while-typing.nix
    ./modules/home/theme.nix
    ./modules/home/hyprland.nix
    ./modules/home/waybar.nix
    ./modules/home/zellij.nix
    ./modules/home/helix.nix
  ];
  # -------------------------------------------------------------------
  # 🔑 SECRETS MANAGEMENT WITH SOPS
  # -------------------------------------------------------------------
  sops = {
    age.keyFile = "/home/garth/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets.yaml;

    secrets.GEMINI_API_KEY = {
      path = "${config.home.homeDirectory}/.config/gemini/api-key";
      mode = "0400";
    };

    secrets.aws_access_key_id = { };
    secrets.aws_secret_access_key = { };

    templates."aws/credentials" = {
      path = "${config.home.homeDirectory}/.aws/credentials";
      content = ''
        [default]
        aws_access_key_id = ${config.sops.placeholder.aws_access_key_id}
        aws_secret_access_key = ${config.sops.placeholder.aws_secret_access_key}
      '';
    };

    templates."aws/config" = {
      path = "${config.home.homeDirectory}/.aws/config";
      content = ''
        [default]
        region = ap-southeast-2
        output = json
      '';
    };
  };


  # -------------------------------------------------------------------
  # ⚙️ GLOBAL ENVIRONMENT & SESSION VARIABLES
  # -------------------------------------------------------------------
  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "hx";
    MOZ_ENABLE_WAYLAND = "1";
    # Fix for Electron/Chromium apps on Hyprland (prevents silent crashes)
    NIXOS_OZONE_WL = "1";
    # Ensure applications can find the GSettings schemas
    XDG_DATA_DIRS = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS";
  };

  # -------------------------------------------------------------------
  # 🔑 SESSION SERVICES
  # -------------------------------------------------------------------
  services.polkit-gnome.enable = true;
  services.disable-touchpad-while-typing.enable = true;

  # -------------------------------------------------------------------
  # 🛡️ SSH CONFIGURATION
  # -------------------------------------------------------------------
  programs.ssh = {
    enable = true;

    matchBlocks = {
      "*" = {
        setEnv = { TERM = "xterm-256color"; };
        addKeysToAgent = "yes";
      };
    };
  };

  # -------------------------------------------------------------------
  # 🌇 HYPRSUNSET SERVICE
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
  # 🚀 GIT CONFIGURATION (Trunk-Based)
  # -------------------------------------------------------------------
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

  # -------------------------------------------------------------------
  # 🦊 FIREFOX NIGHTLY CONFIGURATION
  # -------------------------------------------------------------------
  programs.firefox = {
    enable = true;
    # Use the nightly binary from your overlay
    package = pkgs.firefox-nightly-bin;

    profiles.garth = {
      id = 0;
      name = "garth";
      isDefault = true;

      settings = {
        # 0 = Dark, 1 = Light, 2 = System (Automatic), 3 = Browser
        # This forces the "Website appearance" setting to Automatic
        "layout.css.prefers-color-scheme.content-override" = 2;

        # Force Firefox to use the XDG Portal for settings (DBus)
        # This is CRITICAL for reading the theme signal
        "widget.use-xdg-desktop-portal.settings" = 1;

        # Optional: General Wayland smoothness tweaks
        "gfx.webrender.all" = true;
        
        # Allow userChrome.css to be loaded
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
      };
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
      # --- API KEYS ---
      if [ -f "${config.sops.secrets.GEMINI_API_KEY.path}" ]; then
        export GEMINI_API_KEY=$(cat ${config.sops.secrets.GEMINI_API_KEY.path})
      fi

      # --- HELPER FUNCTIONS ---
      rebuild() {
        (
          TARGET_DIR="$HOME/nixos-config"
          if [ ! -d "$TARGET_DIR" ]; then
            TARGET_DIR="/etc/nixos"
          fi
          
          cd "$TARGET_DIR"
          
          # If we are in a git repo, we must stage new files so Nix Flakes can see them
          if git rev-parse --git-dir >/dev/null 2>&1; then
            echo "==> Staging changes for Flake..."
            git add .
          fi

          echo "==> Building system from $TARGET_DIR" &&
          sudo nixos-rebuild switch --flake .#nixos "$@" &&
          echo "==> Done"
        )
      }

      # --- GIT ALIASES ---
      alias gsync="git fetch origin && git rebase origin/main"
      alias gcom="git add . && git commit -m"
      alias gam="git add . && git commit --amend --no-edit"
      alias gmain="git checkout main && git pull origin main"
      alias gclean="git fetch -p && git branch -vv | grep ': gone]' | awk '{print \$1}' | xargs git branch -D 2>/dev/null"
      alias gnuke="git branch | grep -v 'main' | xargs git branch -D 2>/dev/null"

      # --- GIT WORKFLOW FUNCTIONS ---
      function gstart() {
        if [ -z "$1" ]; then
          echo "Error: Please provide a branch name."
          echo "Usage: gstart <branch-name>"
          return 1
        fi
        git checkout -b "$1"
      }

      function gpr() {
        git push --force-with-lease -u origin HEAD
        gh pr create --web || true
      }

      # --- ZELLIJ AUTO-RENAMING LOGIC ---
      if [[ -n "$ZELLIJ" ]]; then
        autoload -Uz add-zsh-hook

        function zellij_tab_name_update_pre() {
          local cmd_line=$1
          local cmd_name=''${cmd_line%% *}
          if [[ -n "$cmd_name" && "$cmd_name" != "z" ]]; then
            nohup zellij action rename-tab "$cmd_name" >/dev/null 2>&1 &!
          fi
        }

        function zellij_tab_name_update_post() {
          local current_dir=$(print -P "%1~")
          nohup zellij action rename-tab "$current_dir" >/dev/null 2>&1 &!
        }

        add-zsh-hook preexec zellij_tab_name_update_pre
        add-zsh-hook precmd zellij_tab_name_update_post
      fi
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
    enableZshIntegration = true;
    settings = {
      add_newline = false;
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[✗](bold red)";
      };
      format = "$all$line_break$character";
    };
  };

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
