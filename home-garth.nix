############################################################
##########          START home-garth.nix          ##########
############################################################

# /etc/nixos/home-garth.nix
{ config, pkgs, lib, inputs, ... }:

{
  imports = [ ./disable-touchpad-while-typing.nix ];

  # -------------------------------------------------------------------
  # 🎨 CATPPUCCIN THEME
  # -------------------------------------------------------------------
  catppuccin = {
    enable = true;
    flavor = "macchiato";
    alacritty.enable = true;
    helix.enable = true;
    # waybar.enable = true; # Disabled to use custom styling below
    zellij.enable = true;
  };

  # -------------------------------------------------------------------
  # 🔑 SESSION SERVICES
  # -------------------------------------------------------------------
  services.polkit-gnome.enable = true;
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
        # The keybinding for toggling the battery limit has been removed.
        "SUPER_, Q, killactive,"
        "SUPER, H, movefocus, l"
        "SUPER, L, movefocus, r"
        "SUPER, P, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        "SUPER, O, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        "SUPER, M, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" # <-- ADDED THIS LINE
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
    style = ''
      * {
          font-family: "FiraCode Nerd Font", FontAwesome, sans-serif;
          font-size: 14px;
          border: none;
          border-radius: 0;
      }

      window#waybar {
          background-color: rgba(30, 30, 46, 0.85); /* Dark background with transparency */
          color: #cdd6f4; /* Light text color */
          transition-property: background-color;
          transition-duration: .5s;
          border-radius: 10px; /* Rounded corners for the bar */
      }

      #workspaces {
          background-color: transparent;
          margin: 5px;
      }

      #workspaces button {
          padding: 2px 10px;
          margin: 0 3px;
          color: #cdd6f4;
          background-color: #313244; /* Darker background for buttons */
          border-radius: 8px; /* Rounded buttons */
          transition: all 0.3s ease;
      }

      #workspaces button.active {
          background-color: #89b4fa; /* Blue for active workspace */
          color: #1e1e2e;
      }

      #workspaces button:hover {
          background-color: #b4befe; /* Lighter purple on hover */
          color: #1e1e2e;
      }

      #window {
        font-weight: bold;
        margin-right: 15px;
      }

      /* Style for all modules */
      #clock,
      #battery,
      #cpu,
      #memory,
      #network,
      #pulseaudio,
      #backlight,
      #custom-battery-limit,
      #custom-logout {
          padding: 0 10px;
          margin: 5px 3px;
          color: #cdd6f4;
      }

      #pulseaudio {
          color: #89b4fa; /* Blue */
      }

      #memory {
          color: #a6e3a1; /* Green */
      }



      #cpu {
          color: #fab387; /* Orange */
      }

      #backlight {
        color: #f9e2af; /* Yellow */
      }

      #network {
          color: #b4befe; /* Lavender */
      }

      #battery {
          color: #a6e3a1; /* Green */
      }

      #battery.charging {
          color: #a6e3a1;
      }

      #battery.warning:not(.charging) {
          color: #fab387; /* Orange for warning */
      }

      #battery.critical:not(.charging) {
          color: #f38ba8; /* Red for critical */
          animation-name: blink;
          animation-duration: 0.5s;
          animation-timing-function: linear;
          animation-iteration-count: infinite;
          animation-direction: alternate;
      }

      @keyframes blink {
          to {
              background-color: #f38ba8;
              color: #1e1e2e;
          }
      }

      #custom-logout {
        color: #f38ba8; /* Red */
        margin-right: 5px;
      }
    '';
    settings = {
      main-bar = {
        layer = "top";
        position = "top";
        modules-left = [ "hyprland/workspaces" "hyprland/window" ];
        modules-center = [ "cpu" "memory" ];
        modules-right = [ "pulseaudio" "backlight" "network" "battery" "custom/battery-limit" "clock" "custom/logout" ];
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
        "custom/battery-limit" = {
          format = "{}";
          exec = "waybar-battery-status";
          return-type = "json";
          interval = 5;
          # The on-click handler has been removed.
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
    libinput
  ];
}
