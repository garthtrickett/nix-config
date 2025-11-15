{ config, pkgs, lib, ... }:

{
  # -------------------------------------------------------------------
  # 🔑 SESSION SERVICES
  # -------------------------------------------------------------------
  services.polkit-gnome.enable = true;
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
      
      # FIX: Waybar is no longer started here.
      # It will be managed by its own systemd user service.
      "exec-once" = [ 
        "alacritty"
      ];
      "exec" = [
      ];
      
      env = [ "YDOTOOL_SOCKET,/run/ydotoold.sock" ];
      bind = [
        "SUPER, R, exec, ~/.config/hypr/scripts/rebuild"
        "SUPER, 1, workspace, 1"
        "SUPER, 2, workspace, 2"
        "SUPER, 3, workspace, 3"
        "SUPER, 4, workspace, 4"
        "SUPER, 5, workspace, 5"
        "SUPER, 6, workspace, 6"
        "SUPER, 7, workspace, 7"
        "SUPER, 8, workspace, 8"
        "SUPER, 9, workspace, 9"
        "SUPER, Q, exec, killall Hyprland"
      ];
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad = {
            natural_scroll = false;
            disable_while_typing = true;
            tap-to-click = false;
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
  # 🚀 HOME MANAGER ACTIVATION HOOKS (REMOVED)
  # -------------------------------------------------------------------
  # The unreliable activation script has been completely removed.
  
  # -------------------------------------------------------------------
  # 📊 WAYBAR SYSTEMD USER SERVICE (NEW)
  # -------------------------------------------------------------------
  # This is the new, robust way to manage Waybar.
  systemd.user.services.waybar = {
    Unit = {
      Description = "Waybar";
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      # Use the waybar package defined by programs.waybar
      ExecStart = "${pkgs.waybar}/bin/waybar";
      # Automatically restart the service if it fails
      Restart = "always";
      RestartSec = 3;
    };
    Install = {
      # Start the service as part of the graphical session
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # -------------------------------------------------------------------
  # 📊 WAYBAR CONFIGURATION
  # -------------------------------------------------------------------
  # This block remains to configure the appearance and modules of Waybar.
  programs.waybar = {
    enable = true;
    style = ''
      * {
        border: none;
        font-family: monospace;
        font-size: 13px;
        color: #cad3f5;
      }
      window#waybar {
        background: rgba(30, 30, 46, 0.7);
        border-bottom: 3px solid rgba(137, 180, 250, 0.8);
      }
      #workspaces button {
        padding: 0 5px;
        color: #cad3f5;
      }
      #workspaces button.focused {
        background: #89b4fa;
        color: #1e1e2e;
      }
      #clock, #battery, #cpu, #memory, #network {
        padding: 0 10px;
        margin: 0 3px;
        background-color: #363a4f;
      }
    '';
    
    settings = {
      main-bar = { 
        layer = "top";
        position = "top";

        modules-left = [ "hyprland/workspaces" "hyprland/window" ];
        modules-center = [ "cpu" "memory" ];
        modules-right = [ "network" "battery" "clock" ];

        "hyprland/workspaces" = {
          format = "{name}";
          format-icons = {
            "1" = "";
            "2" = "";
            "3" = "";
          };
        };

        clock = {
          format = " (%H:%M)";
          tooltip-format = "<big>(%Y %B)</big>\n<small>(%A, %d)</small>";
        };

        cpu = {
          interval = 10;
          format = " {usage}%";
          tooltip = false;
        };

        memory = {
          interval = 10;
          format = " {percentage}%";
          
        };

        battery = {
          format = "{icon} {capacity}%";
          format-charging = " {capacity}%";
          format-icons = [ "" "" "" "" "" ];
          states = {
            good = 90;
            warning = 30;
            critical = 15;
          };
        };

        network = {
          format-wifi = " {essid}";
          format-ethernet = " {ipaddr}";
          format-disconnected = " Disconnected";
          tooltip-format = "{ifname} via {gwaddr}";
          on-click = "nm-connection-editor";
        };
      };
    };
  };
  # -------------------------------------------------------------------
  # ✨ HiDPI & SCALING FOR NATIVE WAYLAND APPS
  # -------------------------------------------------------------------
  home.sessionVariables = {
    GDK_SCALE = "2";
    QT_SCALE_FACTOR = "2";
  };
  gtk.cursorTheme.size = 48;

  # -------------------------------------------------------------------
  # 📝 HELIX TEXT EDITOR
  # -------------------------------------------------------------------
  programs.helix = {
    enable = true;
    settings = {
      theme = "catppuccin_macchiato";
      editor = {
        line-number = "relative";
        cursorline = true;
      };
    };
  };
  # -------------------------------------------------------------------
  # 📦 USER PACKAGES
  # -------------------------------------------------------------------
  home.packages = with pkgs;
  [
    gh
    alacritty
    wofi
    swaylock
    swayidle
    brightnessctl
    wl-clipboard
    xdg-user-dirs
    ydotool
    procps
    nerd-fonts.fira-code
  ];
}
