############################################################
##########          START home-garth.nix          ##########
############################################################

# /etc/nixos/home-garth.nix
{ config, pkgs, inputs, ... }:

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

    # Define the user-specific secrets that Home Manager needs.
    secrets.GEMINI_API_KEY = { };
  };
  # -------------------------------------------------------------------
  # ⚙️ GLOBAL ENVIRONMENT & SESSION VARIABLES
  # -------------------------------------------------------------------
  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "hx";
    MOZ_ENABLE_WAYLAND = "1";
  };

  # -------------------------------------------------------------------
  # 🔑 SESSION SERVICES
  # -------------------------------------------------------------------
  services.polkit-gnome.enable = true;
  services.disable-touchpad-while-typing.enable = true;

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
  # Fixed structure based on evaluation warnings
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
  # 📝 ZSH SHELL
  # -------------------------------------------------------------------
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Switched back to initContent as per evaluation warning
    initContent = ''
      # --- API KEYS ---
      if [ -f "${config.sops.secrets.GEMINI_API_KEY.path}" ]; then
        export GEMINI_API_KEY=$(cat ${config.sops.secrets.GEMINI_API_KEY.path})
      fi

      # --- HELPER FUNCTIONS ---
      rebuild() {
        (
          cd /etc/nixos &&
          echo "==> Temporarily changing directory to /etc/nixos" &&
          sudo nixos-rebuild switch --flake .#nixos "$@" &&
          echo "==> Returning to original directory"
        )
      }

      # --- GIT ALIASES ---
      alias gsync="git fetch origin && git rebase origin/main"
      alias gcom="git add . && git commit -m"
      alias gam="git add . && git commit --amend --no-edit"
      alias gmain="git checkout main && git pull origin main"
      
      # CLEAN: Prune deleted remote branches and force-delete local branches marked [gone].
      alias gclean="git fetch -p && git branch -vv | grep ': gone]' | awk '{print \$1}' | xargs git branch -D 2>/dev/null"

      # NUKE: Force delete ALL local branches except main (Use with caution!)
      alias gnuke="git branch | grep -v 'main' | xargs git branch -D 2>/dev/null"

      # --- GIT WORKFLOW FUNCTIONS ---
      
      # START: Create a new branch from your CURRENT location.
      function gstart() {
        if [ -z "$1" ]; then
          echo "Error: Please provide a branch name."
          echo "Usage: gstart <branch-name>"
          return 1
        fi
        git checkout -b "$1"
      }

      # PR: Push current branch and open GitHub PR page.
      function gpr() {
        # Force push safely (allows overwriting your own history, but not others)
        git push --force-with-lease -u origin HEAD
        
        # Create PR (suppress error if PR already exists)
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

  home.packages = with pkgs;
    [
      (inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default)
      gh
      jujutsu
      caddy
      mkcert
      alacritty
      zellij
      zjstatus
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
      vlc
      sops
      age
      wf-recorder
      ffmpeg
      file-roller
      nemo-fileroller
      pulseaudio
      toggle-bt-headphones
      bun
      gemini-cli
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
