############################################################
##########        START modules/home/waybar.nix        ##########
############################################################

# /etc/nixos/modules/home/waybar.nix
{ pkgs, ... }:

{
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
          font-family: "FiraCode Nerd Font", FontAwesome, sans-serif;
          font-size: 14px;
          border: none;
          border-radius: 0;
      }

      window#waybar {
          background-color: rgba(30, 30, 46, 0.85);
          color: #cdd6f4;
          transition-property: background-color;
          transition-duration: .5s;
          border-radius: 10px;
      }

      #workspaces {
          background-color: transparent;
          margin: 5px;
      }

      #workspaces button {
          padding: 2px 10px;
          margin: 0 3px;
          color: #cdd6f4;
          background-color: #313244;
          border-radius: 8px;
          transition: all 0.3s ease;
      }

      #workspaces button.active {
          background-color: #89b4fa;
          color: #1e1e2e;
      }

      #workspaces button:hover {
          background-color: #b4befe;
          color: #1e1e2e;
      }

      #window {
        font-weight: bold;
        margin-right: 15px;
      }

      #clock,
      #battery,
      #cpu,
      #memory,
      #network,
      #pulseaudio,
      #backlight,
      #custom-battery-limit,
      #custom-logout,
      #custom-tailscale {
          padding: 0 10px;
          margin: 5px 3px;
          color: #cdd6f4;
      }

      #pulseaudio { color: #89b4fa; }
      #memory { color: #a6e3a1; }
      #cpu { color: #fab387; }
      #backlight { color: #f9e2af; }
      #network { color: #b4befe; }
      #battery { color: #a6e3a1; }
      #battery.charging { color: #a6e3a1; }
      #battery.warning:not(.charging) { color: #fab387; }
      #battery.critical:not(.charging) {
          color: #f38ba8;
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

      #custom-tailscale {
        color: #f38ba8; /* Catppuccin Red for inactive */
      }
      
      #custom-tailscale.active {
        color: #a6e3a1; /* Catppuccin Green for active */
      }

      #custom-logout {
        color: #f38ba8;
        margin-right: 5px;
      }
    '';
    settings = {
      main-bar = {
        layer = "top";
        position = "top";
        modules-left = [ "hyprland/workspaces" "hyprland/window" ];
        modules-center = [ "cpu" "memory" ];
        modules-right = [ "custom/tailscale" "pulseaudio" "backlight" "network" "custom/battery" "clock" "custom/logout" ];
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
        network = {
          format-wifi = " {essid}";
          format-ethernet = " {ipaddr}";
          format-disconnected = " Disconnected";
          tooltip-format = "{ifname} via {gwaddr}";
          on-click = "iwgtk"; # <-- MODIFIED
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
        "custom/battery" = {
          format = "{}";
          exec = "waybar-battery-combined-status";
          return-type = "json";
          interval = 5;
        };
        "custom/tailscale" = {
          "format" = "{}";
          "return-type" = "json";
          "interval" = 10;
          "exec" = "waybar-tailscale-status";
          "on-click" = "tailscale-exit-node-selector";
        };
        "custom/logout" = {
          format = "󰗼";
          tooltip-format = "Logout";
          on-click = "hyprctl dispatch exit";
        };
      };
    };
  };
}
