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

    # REMOVED: Input for the trackpad utility
  };

  outputs = { self, nixpkgs, home-manager, apple-silicon, ... }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      # REMOVED: No longer passing the trackpad source
      specialArgs = { };
      modules = [
        apple-silicon.nixosModules.apple-silicon-support
        ./configuration.nix
        home-manager.nixosModules.home-manager
      ];
    };
  };
}
