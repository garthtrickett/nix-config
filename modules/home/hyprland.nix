# /etc/nixos/modules/home/hyprland.nix
{ config, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      monitor = [ ",preferred,auto,2" ];
      "exec-once" = [
        "dunst"
        "toggle-theme"
      ];
      source = [ "~/.config/hypr/theme.conf" ];
      env = [ "YDOTOOL_SOCKET,/run/ydotoold.sock" ];

      # WINDOW RULES FOR THE TUI
      # This ensures the MCP Manager opens as a nice floating window in the center
      windowrulev2 = [
        "float, title:^(MCP Manager)$"
        "size 600 500, title:^(MCP Manager)$"
        "center, title:^(MCP Manager)$"
      ];

      bind = [
        "SUPER, T, exec, alacritty -e zellij"
        "SUPER_SHIFT, T, exec, toggle-theme"

        # 🔥 THE NEW KEYBIND
        # Launches Alacritty with a specific title so the window rules apply, running mcp-manager
        "SUPER_SHIFT, M, exec, alacritty -t 'MCP Manager' -e mcp-manager"

        "SUPER_SHIFT, O, exec, fuzzel"
        "SUPER_SHIFT,S,exec,hyprshot --mode region --output ''$HOME/Screenshots/$(date +''%Y-%m-%d_%H-%M-%S'').png'' --copy"
        "SUPER, E, exec, nemo"
        "SUPER, F, fullscreen,"
        "SUPER_, Q, killactive,"
        "SUPER, H, movefocus, l"
        "SUPER, L, movefocus, r"
        "SUPER, P, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        "SUPER, O, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        "SUPER, M, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
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
        "SUPER_SHIFT, K, exec, toggle-keyboard-backlight"
        "SUPER_SHIFT, R, exec, pkill -SIGINT wf-recorder"
        "SUPER, B, exec, toggle-bt-headphones"
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
}
