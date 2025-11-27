############################################################
##########          START modules/home/garth/services.nix          ##########
############################################################

# modules/home/garth/services.nix
{ config, pkgs, lib, inputs, ... }:

{
  services.polkit-gnome.enable = true;
  services.disable-touchpad-while-typing.enable = true;

  services.hyprsunset = {
    enable = true;
    settings =
      {
        profile = [
          {
            time = "7:30";
            identity = true;
          }
          {
            time = "21:00";
            temperature = 3000;
            gamma = 0.8;
          }
        ];
      };
  };

  # -------------------------------------------------------------------
  # 🤖 MCP SUPERASSISTANT PROXY
  # -------------------------------------------------------------------
  systemd.user.services.mcp-superassistant-proxy = {
    Unit = {
      Description = "MCP Superassistant Proxy Daemon";
      # Start after network is up and secrets (config file) are generated
      After = [ "network-online.target" "sops-nix.service" ];
      Wants = [ "network-online.target" ];
    };

    Service = {
      Type = "simple";
      # The -y flag forces npx to install the package without prompting
      ExecStart = "${pkgs.nodejs}/bin/npx -y @srbhptl39/mcp-superassistant-proxy@latest --config ${config.home.homeDirectory}/.config/Antigravity/mcp.json";

      # Restart automatically if it crashes (e.g. temporary network issue)
      Restart = "always";
      RestartSec = 10;

      # Ensure Node is in the path for the service execution
      Environment = "PATH=${lib.makeBinPath [ pkgs.nodejs pkgs.bash ]}:/run/current-system/sw/bin";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
