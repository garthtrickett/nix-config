# modules/home/waybar/settings.nix
{ pkgs, wifiStatusScript, ... }: # Pass pkgs and wifiStatusScript as arguments

{
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
}
