{
  description = "NixOS configuration for Apple Silicon (Unstable with Cachix)";

  inputs = {
    # Pointing back to the unstable channels as requested
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # This will follow the unstable nixpkgs, which is correct.
    apple-silicon = {
      url = "github:nix-community/nixos-apple-silicon";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, apple-silicon, ... }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        apple-silicon.nixosModules.apple-silicon-support
        ./configuration.nix
        home-manager.nixosModules.home-manager
      ];
    };
  };
}
