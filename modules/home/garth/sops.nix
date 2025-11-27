# modules/home/garth/sops.nix
{ config, pkgs, lib, inputs, ... }:

let
  allServers = {
    # --- CORE ---
    filesystem = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [ "-y" "@modelcontextprotocol/server-filesystem" "${config.home.homeDirectory}/" ];
    };
    postgres = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [ "-y" "@modelcontextprotocol/server-postgres" "${config.sops.placeholder.database_url}" ];
    };
    github = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [ "-y" "@modelcontextprotocol/server-github" ];
      env = { GITHUB_PERSONAL_ACCESS_TOKEN = "${config.sops.placeholder.github_token}"; };
    };
    memory = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [ "-y" "@modelcontextprotocol/server-memory" ];
    };
    brave-search = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [ "-y" "@modelcontextprotocol/server-brave-search" ];
      env = { BRAVE_API_KEY = "${config.sops.placeholder.brave_api_key}"; };
    };
    sequential-thinking = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [ "-y" "@modelcontextprotocol/server-sequential-thinking" ];
    };

    # --- HEAVY / EXPERIMENTAL ---
    puppeteer = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [ "-y" "@modelcontextprotocol/server-puppeteer" ];
      env = {
        PUPPETEER_EXECUTABLE_PATH = "${pkgs.chromium}/bin/chromium";
        PUPPETEER_SKIP_CHROMIUM_DOWNLOAD = "true";
      };
    };
    shadcn = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [ "-y" "@jpisnice/shadcn-ui-mcp-server" ];
      env = { GITHUB_PERSONAL_ACCESS_TOKEN = "${config.sops.placeholder.github_token}"; };
    };
    desktop-commander = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [ "-y" "@wonderwhy-er/desktop-commander" ];
    };
    TestSprite = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [ "-y" "@testsprite/testsprite-mcp@latest" ];
      env = { API_KEY = "${config.sops.placeholder.testsprite_api_key}"; };
    };
    next-devtools = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [ "-y" "next-devtools-mcp@latest" ];
    };
    effect-mcp = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [ "-y" "@niklaserik/effect-mcp" ];
    };
    context7 = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [ "-y" "@upstash/context7-mcp@latest" ];
    };
  };

in
{
  sops = {
    age.keyFile = "/home/garth/.config/sops/age/keys.txt";
    defaultSopsFile = inputs.self + "/secrets.yaml";

    secrets.GEMINI_API_KEY = { path = "${config.home.homeDirectory}/.config/gemini/api-key"; mode = "0400"; };
    secrets.brave_api_key = { };
    secrets.github_token = { };
    secrets.database_url = { };
    secrets.testsprite_api_key = { };
    secrets.aws_access_key_id = { };
    secrets.aws_secret_access_key = { };

    templates."aws/credentials".content = ''
      [default]
      aws_access_key_id = ${config.sops.placeholder.aws_access_key_id}
      aws_secret_access_key = ${config.sops.placeholder.aws_secret_access_key}
    '';
    templates."aws/credentials".path = "${config.home.homeDirectory}/.aws/credentials";

    templates."aws/config".content = ''
      [default]
      region = ap-southeast-2
      output = json
    '';
    templates."aws/config".path = "${config.home.homeDirectory}/.aws/config";

    # 1. POOL FILE (Source of Truth for TUI)
    templates."antigravity/mcp-pool.json" = {
      path = "${config.home.homeDirectory}/.config/Antigravity/mcp-pool.json";
      content = builtins.toJSON { mcpServers = allServers; };
    };

    # 2. INIT FILE (Renamed from mcp.json to avoid conflict)
    # This file is only used to seed the live config if it's missing.
    templates."antigravity/mcp-init.json" = {
      path = "${config.home.homeDirectory}/.config/Antigravity/mcp-init.json";
      content = builtins.toJSON { mcpServers = { inherit (allServers) filesystem memory github; }; };
    };

    # 3. CLAUDE CONFIG
    templates."Claude/claude_desktop_config.json" = {
      path = "${config.home.homeDirectory}/.config/Claude/claude_desktop_config.json";
      content = builtins.toJSON { mcpServers = { inherit (allServers) filesystem memory github; }; };
    };
  };
}
