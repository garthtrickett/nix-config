# modules/home/garth/caddy.nix
{ config, pkgs, lib, inputs, ... }:

{
  systemd.user.services.mkcert-install = {
    Unit = {
      Description = "Install mkcert's local CA into trust stores";
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.mkcert}/bin/mkcert -install";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
  xdg.configFile."caddy/Caddyfile".text = ''
    {
      pki {
        ca local
      }
    }
    garth.localhost.com.au, *.garth.localhost.com.au {
      reverse_proxy localhost:8080
    }
  '';
  systemd.user.services.caddy = {
    Unit = {
      Description = "Caddy Web Server";
      After = [ "network.target" "mkcert-install.service" ];
      Requires = [ "mkcert-install.service" ];
    };
    Service = {
      ExecStart = "${pkgs.caddy}/bin/caddy run --config ${config.xdg.configHome}/caddy/Caddyfile";
      Restart = "always";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
