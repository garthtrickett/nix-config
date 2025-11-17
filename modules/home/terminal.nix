# /etc/nixos/modules/home/terminal.nix
{ ... }:

{
  # -------------------------------------------------------------------
  #  TERMINAL (ALACRITTY) & ZELLIJ
  # -------------------------------------------------------------------
  programs.alacritty = {
    enable = true;
    settings = {
      selection.save_to_clipboard = true;
      window.opacity = 0.9;
      font = {
        normal.family = "FiraCode Nerd Font";
        size = 12;
      };
    };
  };

  xdg.configFile."zellij/config.kdl".text = ''
    theme "catppuccin-macchiato";
    pane_frames false;
    default_shell "zsh";
    copy_on_select true;
    layout "default";
    show_startup_tips false;
    unbind "Alt h" "Alt l" "Alt t" "Alt e";

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

  xdg.configFile."zellij/layouts/default.kdl".text = ''
    layout {
        default_tab_template {
            children
            pane size=1 borderless=true {
                plugin location="zellij:tab-bar" {
                    format_left ""
                }
            }
        }
        tab {
            pane
        }
    }
  '';
}
