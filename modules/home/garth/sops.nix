# modules/home/garth/sops.nix
{ config, pkgs, lib, inputs, ... }:

let
  # Define the MCP config content once to reuse it in multiple locations
  mcpConfigContent = ''
    {
      "mcpServers": {
        "filesystem": {
          "command": "${pkgs.nodejs}/bin/npx",
          "args": [
            "-y",
            "@modelcontextprotocol/server-filesystem",
            "${config.home.homeDirectory}/Desktop"
          ]
        },
        "postgres": {
          "command": "${pkgs.nodejs}/bin/npx",
          "args": [
            "-y",
            "@modelcontextprotocol/server-postgres",
            "${config.sops.placeholder.database_url}"
          ]
        },
        "github": {
          "command": "${pkgs.nodejs}/bin/npx",
          "args": [
            "-y",
            "@modelcontextprotocol/server-github"
          ],
          "env": {
            "GITHUB_PERSONAL_ACCESS_TOKEN": "${config.sops.placeholder.github_token}"
          }
        },
        "memory": {
          "command": "${pkgs.nodejs}/bin/npx",
          "args": [
            "-y",
            "@modelcontextprotocol/server-memory"
          ]
        },
        "brave-search": {
          "command": "${pkgs.nodejs}/bin/npx",
          "args": [
            "-y",
            "@modelcontextprotocol/server-brave-search"
          ],
          "env": {
            "BRAVE_API_KEY": "${config.sops.placeholder.brave_api_key}"
          }
        },
        "puppeteer": {
          "command": "${pkgs.nodejs}/bin/npx",
          "args": [
            "-y",
            "@modelcontextprotocol/server-puppeteer"
          ],
          "env": {
            "PUPPETEER_EXECUTABLE_PATH": "${pkgs.chromium}/bin/chromium",
            "PUPPETEER_SKIP_CHROMIUM_DOWNLOAD": "true"
          }
        },
        "sequential-thinking": {
          "command": "${pkgs.nodejs}/bin/npx",
          "args": [
            "-y",
            "@modelcontextprotocol/server-sequential-thinking"
          ]
        },
        "desktop-commander": {
          "command": "${pkgs.nodejs}/bin/npx",
          "args": [
            "-y",
            "@wonderwhy-er/desktop-commander"
          ]
        },
        "context7": {
          "command": "${pkgs.nodejs}/bin/npx",
          "args": [
            "-y",
            "@upstash/context7-mcp@latest"
          ]
        }
      }
    }
  '';
in
{
  sops = {
    age.keyFile = "/home/garth/.config/sops/age/keys.txt";
    defaultSopsFile = inputs.self + "/secrets.yaml";

    secrets.GEMINI_API_KEY = {
      path = "${config.home.homeDirectory}/.config/gemini/api-key";
      mode = "0400";
    };

    secrets.brave_api_key = { };
    secrets.github_token = { };
    secrets.database_url = { };

    secrets.aws_access_key_id = { };
    secrets.aws_secret_access_key = { };

    templates."aws/credentials" = {
      path = "${config.home.homeDirectory}/.aws/credentials";
      content = ''
        [default]
        aws_access_key_id = ${config.sops.placeholder.aws_access_key_id}
        aws_secret_access_key = ${config.sops.placeholder.aws_secret_access_key}
      '';
    };

    templates."aws/config" = {
      path = "${config.home.homeDirectory}/.aws/config";
      content = ''
        [default]
        region = ap-southeast-2
        output = json
      '';
    };

    # 1. Antigravity/Superassistant Proxy specific location
    templates."antigravity/mcp.json" = {
      path = "${config.home.homeDirectory}/.config/Antigravity/mcp.json";
      content = mcpConfigContent;
    };

    # 2. Universal/Standard location (for Claude Desktop, Zed, or generic tools)
    templates."Claude/claude_desktop_config.json" = {
      path = "${config.home.homeDirectory}/.config/Claude/claude_desktop_config.json";
      content = mcpConfigContent;
    };
  };
}
