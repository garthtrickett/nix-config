# /etc/nixos/modules/home/zellij.nix
{ config, pkgs, ... }:

{
  # -------------------------------------------------------------------
  #  TERMINAL (ALACRITTY)
  # -------------------------------------------------------------------
  programs.alacritty = {
    enable = true;
    settings = {
      # Import the dynamic theme file (managed by toggle-theme script)
      general.import = [ "~/.config/alacritty/theme.toml" ];

      selection.save_to_clipboard = true;
      window.opacity = 0.9;

      font = {
        normal.family = "FiraCode Nerd Font";
        size = 12;
      };

      # Explicitly define cursor style to avoid legacy warnings/defaults
      cursor = {
        style = {
          shape = "Block";
          blinking = "On";
        };
      };
    };
  };

  # -------------------------------------------------------------------
  #  TERMINAL MULTIPLEXER (ZELLIJ)
  # -------------------------------------------------------------------

  # FIX: Force overwrite to avoid "clobbered" backup errors caused by 
  # the mutable config handling in theme.nix
  xdg.configFile."zellij/config.kdl".force = true;

  programs.zellij = {
    enable = true;
    settings = {
      # Default to macchiato, script will sed this line in the mutable copy
      theme = "catppuccin-macchiato";

      # FIX: Start in "Locked" mode so keys (like Alt+F) go to the shell immediately
      default_mode = "locked";

      pane_frames = false;
      default_shell = "zsh";
      copy_on_select = true;
      default_layout = "status-bar";
      show_startup_tips = false;

      # DEFINE CUSTOM HIGH-CONTRAST THEME FOR LIGHT MODE
      themes = {
        latte-contrast = {
          bg = "#eff1f5";
          fg = "#4c4f69";
          red = "#d20f39";
          # Darkened Green (Standard is #40a02b)
          green = "#358523";
          blue = "#1e66f5";
          # Darkened Yellow/Orange (Standard is #df8e1d)
          yellow = "#8F5E13";
          magenta = "#8839ef";
          orange = "#fe640b";
          cyan = "#04a5e5";
          # Darkened Black/Grey for text visibility (Standard is #acb0be)
          black = "#5c5f77";
          white = "#4c4f69";
        };
      };
    };
    extraConfig = ''
      unbind "Alt h" "Alt l" "Alt t" "Alt e" "Alt f"
      keybinds {
          locked {
              bind "Ctrl a" { SwitchToMode "Normal"; }
          }
          normal {
              bind "n" { NewTab; SwitchToMode "Locked"; }
              bind "x" { CloseTab; SwitchToMode "Locked"; }
              bind "h" { GoToPreviousTab; SwitchToMode "Locked"; }
              bind "l" { GoToNextTab; SwitchToMode "Locked"; }
              bind "1" { GoToTab 1; SwitchToMode "Locked"; }
              bind "2" { GoToTab 2; SwitchToMode "Locked"; }
              bind "3" { GoToTab 3; SwitchToMode "Locked"; }
              bind "4" { GoToTab 4; SwitchToMode "Locked"; }
              bind "5" { GoToTab 5; SwitchToMode "Locked"; }
              bind "6" { GoToTab 6; SwitchToMode "Locked"; }
              bind "7" { GoToTab 7; SwitchToMode "Locked"; }
              bind "8" { GoToTab 8; SwitchToMode "Locked"; }
              bind "9" { GoToTab 9; SwitchToMode "Locked"; }
          }
      }
    '';
  };

  # This declarative layout correctly loads zjstatus
  xdg.configFile."zellij/layouts/status-bar.kdl".text = ''
    layout {
        default_tab_template {
            children
            pane size=1 borderless=true {
                plugin location="file://${pkgs.zjstatus}/bin/zjstatus.wasm" {
                    format_left "{tabs}"
                    format_center ""
                    format_right ""
                    format_space ""

                    border_enabled "false"
                    hide_frame_for_single_pane "true"

                    tab_normal "#[fg=overlay1,bg=mantle] {index} {name} "
                    tab_active "#[fg=mantle,bg=blue,bold] {index}. {name} "

                    command_git_branch_command "git rev-parse --abbrev-ref HEAD"
                    command_git_branch_format "#[fg=text,bg=mantle] {stdout} "
                    command_git_branch_interval "10"
                    command_git_branch_rendermode "static"
                    
                    datetime "#[fg=text,bg=mantle] {format} "
                    datetime_format "%A, %d %B %Y %H:%M"
                }
            }
        }
    }
  '';
}
