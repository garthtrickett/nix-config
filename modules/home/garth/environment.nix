# modules/home/garth/environment.nix
{ config, pkgs, lib, inputs, ... }:

{
  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "hx";
    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_OZONE_WL = "1";
    XDG_DATA_DIRS = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS";
    MCP_CONFIG_FILE = "${config.home.homeDirectory}/.config/Antigravity/mcp.json";
  };

  # Activation script: Handles initialization
  home.activation.fixGeminiAndMcpConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # 1. Fix Missing Runtime Directory for Gemini
    if [ ! -d "/tmp/gemini/ide" ]; then
      mkdir -p "/tmp/gemini/ide"
    fi

    # 2. Initialize MCP Config (Safe Seed)
    MCP_DIR="${config.home.homeDirectory}/.config/Antigravity"
    MCP_LIVE="$MCP_DIR/mcp.json"
    MCP_INIT="$MCP_DIR/mcp-init.json"

    if [ ! -d "$MCP_DIR" ]; then mkdir -p "$MCP_DIR"; fi

    # ONLY copy init config if live config is missing.
    # This prevents your TUI changes from being wiped on rebuild/reboot.
    if [ ! -f "$MCP_LIVE" ] && [ -f "$MCP_INIT" ]; then
       echo "Seeding MCP config from default..."
       cp -L "$MCP_INIT" "$MCP_LIVE"
       chmod 644 "$MCP_LIVE"
    fi
    
    # If mcp.json somehow became a symlink (legacy), break it.
    if [ -L "$MCP_LIVE" ]; then
       echo "Making MCP config mutable..."
       cp --remove-destination "$(readlink "$MCP_LIVE")" "$MCP_LIVE"
       chmod 644 "$MCP_LIVE"
    fi

    # 3. Gemini Settings Logic
    GEMINI_DIR="${config.home.homeDirectory}/.gemini"
    SETTINGS_FILE="$GEMINI_DIR/settings.json"
    SOURCE_TEMPLATE="${config.home.homeDirectory}/.config/Antigravity/mcp.json"

    if [ ! -d "$GEMINI_DIR" ]; then mkdir -p "$GEMINI_DIR"; fi
    if [ -L "$SETTINGS_FILE" ]; then rm "$SETTINGS_FILE"; fi

    if [ -f "$SOURCE_TEMPLATE" ]; then
       cat "$SOURCE_TEMPLATE" > "$SETTINGS_FILE"
       chmod 644 "$SETTINGS_FILE"
    fi

    chmod u+w "$GEMINI_DIR"
    [ -f "$SETTINGS_FILE" ] && chmod u+w "$SETTINGS_FILE"
  '';
}
