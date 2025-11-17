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
  };

  outputs = { self, nixpkgs, catppuccin, home-manager, apple-silicon, zen-browser, ... }@inputs:
  let
    system = "aarch64-linux";
    pkgs = import nixpkgs {
      inherit system;
      # The overlays are now cleanly imported from the new file.
      overlays = [ (import ./overlays) ];
    };
  in
  {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };

      modules = [
        # This makes our customized pkgs set available to all modules.
        { nixpkgs.pkgs = pkgs; }

        # Import NixOS modules from flakes
        apple-silicon.nixosModules.apple-silicon-support
        catppuccin.nixosModules.catppuccin
        home-manager.nixosModules.home-manager

        # Import local NixOS configuration
        ./configuration.nix

        # Configure Home Manager
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
