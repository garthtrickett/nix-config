############################################################
##########         START home-garth.nix           ##########
############################################################

# MODIFIED: Accepts 'inputs' to get the zen-browser package
{ config, pkgs, lib, inputs, ... }:

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
      
      "exec-once" = [ 
        "alacritty -e zellij"
      ];
      "exec" = [
      ];
      
      env = [ "YDOTOOL_SOCKET,/run/ydotoold.sock" ];
      # MODIFIED: Added new keybindings for volume, brightness, and closing windows
      bind = [
        "SUPER, R, exec, ~/.config/hypr/scripts/rebuild"
        "SUPER_SHIFT, Q, killactive,"

        "SUPER, H, movefocus, l"
        "SUPER, L, movefocus, r"

        # Volume control
        "SUPER, P, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        "SUPER, O, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"

        # Brightness control
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
  # 📊 WAYBAR CONFIGURATION
  # -------------------------------------------------------------------
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
          # This format is from your working config
          format = " {0:%H:%M}";
          tooltip-format = "<big>{0:%Y %B}</big>\n<small>{0:%A, %d}</small>";
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
      theme = "catppuccin_macchiato";
      editor = { line-number = "relative"; cursorline = true; };
    };
  };

  # -------------------------------------------------------------------
  # 🐚 ZSH SHELL CONFIGURATION (NEW)
  # -------------------------------------------------------------------
  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableSyntaxHighlighting = true;
  };

  # -------------------------------------------------------------------
  # 📦 USER PACKAGES
  # -------------------------------------------------------------------
  home.packages = with pkgs;
  [
    # MODIFIED: Added new packages
    (inputs.zen-browser.packages.${pkgs.system}.default)
    gh
    alacritty
    zellij
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
