# modules/home/waybar.nix
{ pkgs, ... }:

let
  wifiStatusScript = import ./waybar/wifi-status-script.nix { inherit pkgs; }; # Import the script

  waybarStyle = builtins.readFile ./waybar/style.css; # Read the CSS file
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
    style = waybarStyle; # Use the imported style

    settings = import ./waybar/settings.nix { inherit pkgs wifiStatusScript; }; # Import the settings
  };
}