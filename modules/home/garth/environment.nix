# modules/home/garth/environment.nix
{ config, pkgs, lib, inputs, ... }:

{
  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "hx";
    MOZ_ENABLE_WAYLAND = "1";
    # Fix for Electron/Chromium apps on Hyprland (prevents silent crashes)
    NIXOS_OZONE_WL = "1";
    # Ensure applications can find the GSettings schemas
    XDG_DATA_DIRS = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS";

    # ADDED: Point generic tools to the MCP config
    MCP_CONFIG_FILE = "${config.home.homeDirectory}/.config/antigravity/mcp.json";
  };
}
