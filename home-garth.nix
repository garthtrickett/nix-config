# /etc/nixos/home-garth.nix
{ config, pkgs, ... }:

{
  # -------------------------------------------------------------------
  # 🔑 SESSION SERVICES
  # -------------------------------------------------------------------
  # Enables the Polkit agent for authentication in graphical sessions.
  services.polkit-gnome.enable = true;

  # -------------------------------------------------------------------
  # 🖥️ HYPRLAND WINDOW MANAGER
  # -------------------------------------------------------------------
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      monitor = [ ",preferred,auto,1" ];
      "exec-once" = [ "${pkgs.kitty}/bin/kitty" ];
      bind = [
        "SUPER, 1, workspace, 1"
        "SUPER, Q, exec, killall Hyprland"
      ];
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad = { natural_scroll = true; };
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
  # 📝 HELIX TEXT EDITOR - NEWLY ADDED
  # -------------------------------------------------------------------
  # This enables the Helix editor and manages its configuration.
  programs.helix = {
    enable = true;
    
    # You can define your Helix 'config.toml' settings here.
    # For example, to set the theme to 'catppuccin_macchiato':
    settings = {
      theme = "catppuccin_macchiato";
      editor = {
        line-number = "relative";
        cursorline = true;
      };
    };
    
    # You can also add extra packages for language servers, etc.
    # extraPackages = with pkgs; [ rust-analyzer ];
  };

  # -------------------------------------------------------------------
  # 📦 USER PACKAGES
  # -------------------------------------------------------------------
  # These packages are installed directly into the user's profile.
  home.packages = with pkgs; [
    # Note: We don't need 'helix' here because 'programs.helix.enable'
    #       installs it for us automatically.
    kitty
    waybar
    wofi
    swaylock
    swayidle
    brightnessctl
    wl-clipboard
    xdg-user-dirs
  ];
}
