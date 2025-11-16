# /etc/nixos/home-garth.nix
{ config, pkgs, lib, inputs, ... }:

{
  # Import the new home-manager module for the service.
  imports = [ ./disable-touchpad-while-typing.nix ];

  # -------------------------------------------------------------------
  # 🎨 CATPPUCCIN THEME
  # -------------------------------------------------------------------
  catppuccin = {
    enable = true;
    flavor = "macchiato";
    alacritty.enable = true;
    helix.enable = true;
    waybar.enable = true;
    zellij.enable = true;
  };

  # -------------------------------------------------------------------
  # 🔑 SESSION SERVICES
  # -------------------------------------------------------------------
  services.polkit-gnome.enable = true;
  # Enable the new automated service.
  services.disable-touchpad-while-typing.enable = true;

  # -------------------------------------------------------------------
  # ✨ XSESSION & SCALING FOR XWAYLAND APPS
  # -------------------------------------------------------------------
  xsession.enable = true;
  xresources.properties = {
    "Xft.dpi" = 192;
    "Xcursor.size" = 48;
  };
  # -------------------------------------------------------------------
  # 🖥️ HYPRLAND WINDOW MANAGER
  # -------------------------------------------------------------------
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      monitor = [ ",preferred,auto,2" ];
      "exec-once" = [
        "dunst"
      ];
      "exec" = [
      ];

      env = [ "YDOTOOL_SOCKET,/run/ydotoold.sock" ];
      bind = [
        "SUPER, T, exec, alacritty -e zellij"
        "SUPER_SHIFT, O, exec, fuzzel"
        # MODIFIED: Removed the manual toggle keybinding as requested.
        # "SUPER_SHIFT, T, exec, toggle-touchpad"
        "SUPER_, Q, killactive,"
        "SUPER, H, movefocus, l"
        "SUPER, L, movefocus, r"
        "SUPER, P, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        "SUPER, O, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        "SUPER, U, exec, brightnessctl set 5%-"
        "SUPER, I, exec, brightnessctl set 5%+"
        "SUPER, 1, workspace, 1"
        "SUPER, 2, workspace, 2"
        "SUPER, 3, workspace, 3"
        "SUPER, 4, workspace, 4"
        "SUPER, 5, workspace, 5"
        "SUPER, 6, workspace, 6"
        "SUPER, 7, workspace, 7"
        "SUPER, 8, workspace, 8"
        "SUPER, 9, workspace, 9"
        "SUPER_SHIFT, 1, movetoworkspace, 1"
        "SUPER_SHIFT, 2, movetoworkspace, 2"
        "SUPER_SHIFT, 3, movetoworkspace, 3"
        "SUPER_SHIFT, 4, movetoworkspace, 4"
        "SUPER_SHIFT, 5, movetoworkspace, 5"
        "SUPER_SHIFT, 6, movetoworkspace, 6"
        "SUPER_SHIFT, 7, movetoworkspace, 7"
        "SUPER_SHIFT, 8, movetoworkspace, 8"
        "SUPER_SHIFT, 9, movetoworkspace, 9"
      ];
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad = {
            natural_scroll = false;
            # Defer to our custom module for disable-while-typing logic.
            disable_while_typing = false;
            tap-to-click = true;
           };
      };
      general = {
        "gaps_in" = 5;
        "gaps_out" = 10;
        border_size = 2;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        layout = "dwindle";
      };
    };
  };
  # -------------------------------------------------------------------
  # 📊 WAYBAR SYSTEMD USER SERVICE (Robust Method)
  # -------------------------------------------------------------------
  systemd.user.services.waybar = {
    Unit = {
      Description = "Waybar";
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.waybar}/bin/waybar";
      Restart = "always";
      RestartSec = 3;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
  # -------------------------------------------------------------------
  # 🌇 HYPRSUNSET SYSTEMD USER SERVICE
  # -------------------------------------------------------------------
  systemd.user.services.hyprsunset = {
    Unit = {
      Description = "Day/night gamma adjustments for Hyprland";
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.hyprsunset}/bin/hyprsunset";
      Restart = "always";
      RestartSec = 3;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
  # -------------------------------------------------------------------
  # 📊 WAYBAR CONFIGURATION
  # -------------------------------------------------------------------
  programs.waybar = {
    enable = true;
    settings = {
      main-bar = {
        layer = "top";
        position = "top";
        modules-left = [ "hyprland/workspaces" "hyprland/window" ];
        modules-center = [ "cpu" "memory" ];
        modules-right = [ "pulseaudio" "backlight" "network" "battery" "clock" "custom/logout" ];
        "hyprland/workspaces" = {
          format = "{name}";
          format-icons = { "1" = ""; "2" = ""; "3" = ""; };
        };
        clock = {
          format = " {0:%H:%M}";
          format-alt = " {0:%A, %d %B}";
          tooltip-format = "<big>{0:%Y %B}</big>\n<small>{0:%A, %d}</small>";
          on-click = "";
        };
        cpu = { interval = 10; format = " {usage}%"; tooltip = false; };
        memory = { interval = 10; format = " {percentage}%"; };
        battery = {
          format = "{icon} {capacity}%";
          format-charging = " {capacity}%";
          format-icons = [ "" "" "" "" "" ];
          states = { good = 90; warning = 30; critical = 15; };
        };
        network = {
          format-wifi = " {essid}";
          format-ethernet = " {ipaddr}";
          format-disconnected = " Disconnected";
          tooltip-format = "{ifname} via {gwaddr}";
          on-click = "nm-connection-editor";
        };
        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = " Muted";
          format-icons = { default = [ "" "" "" ]; };
          on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          on-scroll-up = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
          on-scroll-down = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
        };
        backlight = {
          device = "apple-panel-bl";
          format = "{icon} {percent}%";
          format-icons = [ "" "" ];
          on-scroll-up = "brightnessctl set 5%+";
          on-scroll-down = "brightnessctl set 5%-";
        };
        "custom/logout" = {
          format = "󰗼";
          tooltip-format = "Logout";
          on-click = "hyprctl dispatch exit";
        };
      };
    };
  };
  # -------------------------------------------------------------------
  # ✨ HiDPI & SCALING FOR NATIVE WAYLAND APPS
  # -------------------------------------------------------------------
  home.sessionVariables = { GDK_SCALE = "2"; QT_SCALE_FACTOR = "2"; };
  gtk.cursorTheme.size = 48;

  # -------------------------------------------------------------------
  # 📝 HELIX TEXT EDITOR
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

  # -------------------------------------------------------------------
  # 🐚 ZSH SHELL CONFIGURATION
  # -------------------------------------------------------------------
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      # The rebuild alias has been replaced by a more robust function below
    };
    initContent = ''
      # A robust rebuild command that works from any directory
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
  #  TERMINAL (ALACRITTY) CONFIGURATION
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

  # -------------------------------------------------------------------
  # 🚀 ZELLIJ CONFIGURATION
  # -------------------------------------------------------------------
  xdg.configFile."zellij/config.kdl".text = ''
    theme "catppuccin-macchiato"
    pane_frames false
    default_shell "zsh"
    copy_on_select true
    layout "default"
    show_startup_tips false

    keybinds {
        unbind "Alt h" "Alt l" "Alt t" "Alt e"
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
    }
  '';

  # -------------------------------------------------------------------
  # 📦 USER PACKAGES
  # -------------------------------------------------------------------
  home.packages = with pkgs;
  [
    (inputs.zen-browser.packages.${pkgs.system}.default)
    # MODIFIED: Removed toggle-touchpad-script. The service calls it directly,
    # so it's no longer needed in your user's PATH.
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
    libinput # Add libinput as a dependency for the new service
  ];
}
