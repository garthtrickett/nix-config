# /etc/nixos/modules/home/waybar.nix
{ pkgs, ... }:

let
  wifiStatusScript = pkgs.writeShellScriptBin "waybar-wifi-status" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail
    export PATH="${pkgs.lib.makeBinPath [ 
      pkgs.coreutils pkgs.gnugrep pkgs.gnused pkgs.gawk pkgs.iproute2 pkgs.iwd 
    ]}:$PATH"

    INTERFACE=$(ip link show | grep -oP 'wlan\d+' | sort | head -n 1)
    if [ -z "$INTERFACE" ]; then
        echo "{\"text\": \" No Interface\", \"tooltip\": \"No wireless interface found\", \"class\": \"disconnected\"}"
        exit 0
    fi

    STATUS=$(iwctl station "$INTERFACE" show || echo "State disconnected")
    STATE=$(echo "$STATUS" | grep "State" | awk '{$1=""; print $0}' | xargs)

    if [[ "$STATE" == "connected" ]]; then
      SSID=$(echo "$STATUS" | grep "Connected network" | sed 's/.*Connected network\s*//' | xargs)
      if [ -z "$SSID" ]; then SSID="Hidden"; fi
      echo "{\"text\": \" $SSID\", \"tooltip\": \"Interface: $INTERFACE\nSSID: $SSID\nState: Connected\", \"class\": \"connected\"}"
    elif [[ "$STATE" == "connecting" || "$STATE" == "authenticating" || "$STATE" == "associating" ]]; then
      echo "{\"text\": \" Connecting...\", \"tooltip\": \"Interface: $INTERFACE\nState: $STATE\", \"class\": \"scanning\"}"
    else
      echo "{\"text\": \" Disconnected\", \"tooltip\": \"Interface: $INTERFACE\nState: $STATE\", \"class\": \"disconnected\"}"
    fi
  '';
in
{
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

  programs.waybar = {
    enable = true;
    style = ''
      /* 
         IMPORT THE DYNAMIC THEME FILE 
         This file is written by the 'toggle-theme' script.
      */
      @import "theme.css";

      * {
          font-family: "FiraCode Nerd Font", FontAwesome, sans-serif;
          font-size: 14px;
          border: none;
          border-radius: 0;
      }

      window#waybar {
          background-color: @base; /* Uses variable from theme.css */
          color: @text;
          transition-property: background-color;
          transition-duration: .5s;
          border-radius: 10px;
          opacity: 0.9; 
      }

      #workspaces {
          background-color: transparent;
          margin: 5px;
      }

      #workspaces button {
          padding: 2px 10px;
          margin: 0 3px;
          color: @text;
          background-color: @surface1;
          border-radius: 8px;
          transition: all 0.3s ease;
      }

      #workspaces button.active {
          background-color: @blue;
          color: @base;
      }

      #workspaces button:hover {
          background-color: @lavender;
          color: @base;
      }

      #window {
        font-weight: bold;
        margin-right: 15px;
        color: @text;
      }

      #clock, #battery, #cpu, #memory, #network, #pulseaudio, #backlight, 
      #custom-battery-limit, #custom-logout, #custom-tailscale, #custom-wifi,
      #custom-theme {
          padding: 0 10px;
          margin: 5px 3px;
          color: @text;
      }

      #pulseaudio { color: @blue; }
      #memory { color: @green; }
      #cpu { color: @peach; }
      #backlight { color: @yellow; }
      #network { color: @lavender; }

      #custom-wifi { color: @lavender; }
      #custom-wifi.disconnected { color: @red; }
      #custom-wifi.scanning { color: @peach; }
      
      #battery { color: @green; }
      #battery.charging { color: @green; }
      #battery.warning:not(.charging) { color: @peach; }
      #battery.critical:not(.charging) {
          color: @red;
          animation-name: blink;
          animation-duration: 0.5s;
          animation-iteration-count: infinite;
          animation-direction: alternate;
      }

      @keyframes blink {
          to {
              background-color: @red;
              color: @base;
          }
      }

      #custom-tailscale { color: @red; }
      #custom-tailscale.active { color: @green; }

      #custom-logout {
        color: @red;
        margin-right: 5px;
      }
      
      #custom-theme {
        color: @mauve;
        margin-right: 10px;
      }
    '';
    settings = {
      main-bar = {
        layer = "top";
        position = "top";
        modules-left = [ "hyprland/workspaces" "hyprland/window" ];
        modules-center = [ "cpu" "memory" "network#speed" ];
        modules-right = [ "custom/theme" "custom/tailscale" "pulseaudio" "backlight" "custom/wifi" "custom/battery" "clock" "custom/logout" ];
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
        "network#speed" = {
          interval = 1;
          format = "{bandwidthDownBytes}   {bandwidthUpBytes} ";
          format-disconnected = "";
          tooltip = false;
        };
        "custom/wifi" = {
          exec = "${wifiStatusScript}/bin/waybar-wifi-status";
          return-type = "json";
          interval = 1;
          format = "{}";
          on-click = "iwgtk";
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
          exec = "/run/current-system/sw/bin/waybar-battery-combined-status";
          return-type = "json";
          interval = 5;
        };
        "custom/tailscale" = {
          "format" = "{}";
          "return-type" = "json";
          "interval" = 10;
          "exec" = "/run/current-system/sw/bin/waybar-tailscale-status";
          "on-click" = "tailscale-exit-node-selector";
        };
        "custom/logout" = {
          format = "󰗼";
          tooltip-format = "Logout";
          on-click = "hyprctl dispatch exit";
        };
        "custom/theme" = {
          format = "/";
          tooltip-format = "Toggle Dark/Light Mode";
          on-click = "${pkgs.toggle-theme}/bin/toggle-theme";
        };
      };
    };
  };
}
