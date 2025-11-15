############################################################
##########          START flake.nix               ##########
############################################################

{
  description = "NixOS configuration for Apple Silicon (Unstable)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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

  outputs = { self, nixpkgs, home-manager, apple-silicon, zen-browser, ... }@inputs:
  let
    system = "aarch64-linux";
    pkgs = import nixpkgs {
      inherit system;
      overlays = [
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

        home-manager.nixosModules.home-manager
        {
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.useGlobalPkgs = true;
          home-manager.users.garth = {
            imports = [ ./home-garth.nix ];
            home.stateVersion = "25.11";
          };
        }
      ];
    };
  };
}
