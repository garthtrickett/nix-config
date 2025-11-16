############################################################
##########          START flake.nix               ##########
############################################################

{
  description = "NixOS configuration for Apple Silicon (Unstable)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    catppuccin.url = "github:catppuccin/nix";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    apple-silicon = {
      url = "github:nix-community/nixos-apple-silicon";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, catppuccin, home-manager, apple-silicon, zen-browser, ... }@inputs:
  let
    system = "aarch64-linux";
    pkgs = import nixpkgs {
      inherit system;
      overlays = [
        # This overlay creates the 'toggle-battery-limit' package.
        (final: prev: {
          toggle-battery-limit = prev.writeShellScriptBin "toggle-battery-limit" ''
            #!${prev.stdenv.shell}

            # This script requires the SUDO_USER variable to be set by sudo.
            if [ -z "$SUDO_USER" ]; then
              if [ "$(whoami)" = "root" ]; then
                echo "This script needs the SUDO_USER variable to send a notification." >&2
                echo "Please run it as a regular user with sudo." >&2
              else
                echo "Please run this script with sudo." >&2
              fi
              exit 1
            fi

            # Function to drop privileges and send a notification to the original user.
            notify_user() {
              local message="$1"
              local user_uid=$(id -u "$SUDO_USER")
              # Set the DBUS address so notify-send can find the user's session.
              export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$user_uid/bus"
              # Execute notify-send as the original user.
              sudo -u "$SUDO_USER" ${prev.libnotify}/bin/notify-send "Battery Limiter" "$message"
            }
            
            # Function to find the correct path for the battery charge threshold.
            find_threshold_path() {
              if [ -f "/sys/class/power_supply/macsmc-battery/charge_control_end_threshold" ]; then
                echo "/sys/class/power_supply/macsmc-battery/charge_control_end_threshold"
              elif [ -f "/sys/class/power_supply/battery/charge_control_end_threshold" ]; then
                echo "/sys/class/power_supply/battery/charge_control_end_threshold"
              else
                return 1
              fi
            }

            THRESHOLD_PATH=$(find_threshold_path)
            
            if [ -z "$THRESHOLD_PATH" ]; then
              notify_user "Charge threshold control not found."
              exit 1
            fi

            # The configured limit is hardcoded here, matching configuration.nix
            CONFIGURED_LIMIT=80
            CURRENT_LIMIT=$(cat "$THRESHOLD_PATH")

            if [ "$CURRENT_LIMIT" -eq "$CONFIGURED_LIMIT" ]; then
              echo 100 > "$THRESHOLD_PATH"
              notify_user "Charge limit turned OFF (100%)"
            else
              echo "$CONFIGURED_LIMIT" > "$THRESHOLD_PATH"
              notify_user "Charge limit turned ON (''${CONFIGURED_LIMIT}%)"
            fi
          '';
        })
        (final: prev: {
           asahi-audio = prev.asahi-audio.override {
             triforce-lv2 = prev.triforce-lv2;
           };
        })
      ];
    };
  in
  {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };

      modules = [
        { nixpkgs.pkgs = pkgs; }

        apple-silicon.nixosModules.apple-silicon-support
        ./configuration.nix
        catppuccin.nixosModules.catppuccin
        home-manager.nixosModules.home-manager
        {
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.useGlobalPkgs = true;
          home-manager.users.garth = {
            imports = [
              ./home-garth.nix
              catppuccin.homeModules.catppuccin
            ];
            home.stateVersion = "25.11";
          };
        }
      ];
    };
  };
}
