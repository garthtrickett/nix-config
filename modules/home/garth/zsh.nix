# modules/home/garth/zsh.nix
{ config, pkgs, lib, inputs, ... }:

{
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
      alias gsync="git fetch origin && git rebase origin/staging"
      alias gcom="git add . && git commit -m"
      alias gam="git add . && git commit --amend --no-edit"
      alias gstage="git checkout staging && git pull origin staging"
      alias gclean="git fetch -p && git branch -vv | grep ': gone]' | awk '{print \$1}' | xargs git branch -D 2>/dev/null"
      alias gnuke="git branch | grep -v 'staging' | xargs git branch -D 2>/dev/null"

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
}
