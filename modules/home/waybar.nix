# modules/home/waybar.nix
{ pkgs, ... }:

let
  wifiStatusScript = import ./waybar/wifi-status-script.nix { inherit pkgs; };
  mullvadStatusScript = import ./waybar/mullvad-status-script.nix { inherit pkgs; };

  baseWaybarStyle = builtins.readFile ./waybar/style.css;

  # Clean styling using your theme colors
  extraWaybarStyle = ''
    ${baseWaybarStyle}

    #custom-mullvad {
        background-color: #24273a;
        color: #cad3f5;
        padding: 0 10px;
        margin: 0 5px;
        border-radius: 10px;
        font-weight: bold;
    }

    #custom-mullvad.connected {
        background-color: #a6da95; /* Green */
        color: #24273a; /* Dark text for contrast */
    }

    #custom-mullvad.disconnected {
        background-color: #ed8796; /* Red */
        color: #24273a;
    }

    #custom-mullvad.connecting {
        background-color: #eed49f; /* Yellow */
        color: #24273a;
    }
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
    style = extraWaybarStyle;

    settings = import ./waybar/settings.nix { inherit pkgs wifiStatusScript mullvadStatusScript; };
  };
}
