# /etc/nixos/flake.nix
{
  description = "NixOS configuration for Apple Silicon (Unstable)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    catppuccin.url = "github:catppuccin/nix";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixpkgs-stable = {
      url = "github:NixOS/nixpkgs/c5ae371f1a6a7fd27823";
    };

    apple-silicon = {
      url = "github:nix-community/nixos-apple-silicon";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-nightly = {
      url = "github:nix-community/flake-firefox-nightly";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zjstatus = {
      url = "github:dj95/zjstatus";
    };

    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --- CHANGED INPUT HERE ---
    # Pointing to local path. flake = false ensures it is treated as raw source code.
    g-tui-go = {
      url = "path:/home/garth/files/code/g-tui-go";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, catppuccin, home-manager, apple-silicon, zen-browser, firefox-nightly, sops-nix, zjstatus, antigravity-nix, g-tui-go, ... }@inputs:
    let
      system = "aarch64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = with inputs; [
          firefox-nightly.overlays.default
          (final: prev: {
            mesa = inputs.nixpkgs-stable.legacyPackages.${final.system}.mesa;
          })
          (final: prev: {
            zjstatus = zjstatus.packages.${prev.system}.default;
          })
          (import ./overlays)
        ];
        config = {
          allowUnfreePredicate = pkg: builtins.elem (pkg.pname or pkg.name) [
            "intelephense"
            "firefox-nightly-bin"
            "firefox-nightly-bin-unwrapped"
          ];
        };
      };
    in
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };

        modules = [
          { nixpkgs.pkgs = pkgs; }

          apple-silicon.nixosModules.apple-silicon-support
          catppuccin.nixosModules.catppuccin
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops

          ./configuration.nix

          {
            environment.systemPackages = with pkgs; [
              # FIX: Use stdenv.hostPlatform.system instead of pkgs.system
              antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
              chromium
            ];

            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.useGlobalPkgs = true;

            # CRITICAL FIX: Allows Home Manager to backup existing mutable files
            # (like our GTK settings) instead of failing with a "clobbered" error.
            home-manager.backupFileExtension = "hm-backup";

            home-manager.users.garth = {
              imports = [
                ./home-garth.nix
                catppuccin.homeModules.catppuccin
                sops-nix.homeManagerModules.sops
              ];
              home.stateVersion = "25.11";
            };
          }
        ];
      };

      homeManagerModules.home-garth-test = import (inputs.self + "/home-garth-test.nix") { inherit pkgs inputs; lib = inputs.nixpkgs.lib; };

      devShells.aarch64-linux.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          go
          gopls
        ];
      };
    };
}
