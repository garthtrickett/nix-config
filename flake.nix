# /etc/nixos/flake.nix
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
  };

  outputs = { self, nixpkgs, catppuccin, home-manager, apple-silicon, zen-browser, firefox-nightly, sops-nix, zjstatus, ... }@inputs:
    let
      system = "aarch64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = with inputs; [
          firefox-nightly.overlays.default
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
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.useGlobalPkgs = true;
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
    };
}
