############################################################
##########           START home-garth.nix            ##########
############################################################

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

    # Define the user-specific secrets that Home Manager needs.
    secrets.GEMINI_API_KEY = {
      path = "${config.home.homeDirectory}/.config/gemini/api-key";
      mode = "0400";
    };

    # 🔑 SSH Key Deployment (Raw Output)
    # We output the raw secret here. The 'format-ssh-key' service below 
    # will read this, format it (if needed), and write it to id_ed25519.
    secrets.ssh_private_key = {
      path = "${config.home.homeDirectory}/.ssh/id_ed25519_raw";
      mode = "0600";
    };
  };

  # -------------------------------------------------------------------
  # 🔧 FIX SSH KEY FORMATTING (RUNTIME SERVICE)
  # -------------------------------------------------------------------
  # This service fixes the issue where sops/yaml flattens the SSH key.
  # It runs at runtime (systemd), avoiding the 'pure evaluation' build error.
  systemd.user.services.format-ssh-key = {
    Unit = {
      Description = "Format SSH Key from Sops Raw Output";
      # Run immediately after sops-nix has decrypted the secrets
      After = [ "sops-nix.service" ];
      Wants = [ "sops-nix.service" ];
    };
    Service = {
      Type = "oneshot";
      # Script: Checks if raw key is single-line. If so, formats it. If not, copies it.
      ExecStart =
        let
          script = pkgs.writeShellScript "format-ssh-key-script" ''
            RAW_KEY="${config.home.homeDirectory}/.ssh/id_ed25519_raw"
            FINAL_KEY="${config.home.homeDirectory}/.ssh/id_ed25519"

            if [ ! -f "$RAW_KEY" ]; then
              echo "No raw key found at $RAW_KEY. Sops might not be ready."
              exit 0
            fi

            # Check line count. If < 2, it implies a flattened single-line key.
            LINE_COUNT=$(${pkgs.coreutils}/bin/wc -l < "$RAW_KEY")

            if [ "$LINE_COUNT" -lt 2 ]; then
               echo "Detected single-line SSH key. Formatting..."
               cat "$RAW_KEY" | \
               ${pkgs.gnused}/bin/sed 's/-----END OPENSSH PRIVATE KEY-----/\n&/' | \
               ${pkgs.gnused}/bin/sed 's/-----BEGIN OPENSSH PRIVATE KEY-----/&\n/' | \
               ${pkgs.gfold}/bin/fold -w 64 > "$FINAL_KEY"
            else
               echo "SSH key appears valid (multi-line). Copying..."
               cp "$RAW_KEY" "$FINAL_KEY"
            fi

            # Ensure correct permissions (Read/Write for user only)
            chmod 600 "$FINAL_KEY"
            echo "SSH key successfully deployed to $FINAL_KEY"
          '';
        in
        "${script}";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
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
  # 🛡️ SSH CONFIGURATION
  # -------------------------------------------------------------------
  programs.ssh = {
    enable = true;

    matchBlocks = {
      "*" = {
        setEnv = { TERM = "xterm-256color"; };
        addKeysToAgent = "yes";
      };
      "vultr" = {
        hostname = "139.84.201.119";
        user = "root";
        # Point SSH to the FINAL formatted key, not the raw one
        identityFile = "${config.home.homeDirectory}/.ssh/id_ed25519";
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
  # 📝 ZSH SHELL
  # -------------------------------------------------------------------
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    initContent = ''
      # --- API KEYS ---
      # The path is guaranteed to exist and is linked by Home Manager
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
    pkgs.libnotify
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
