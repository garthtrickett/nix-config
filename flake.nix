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

  # --- CACHIX CONFIGURATION BLOCK (Used during 'nixos-rebuild') ---
  nixConfig = {
    # Allows Nix to apply these settings without requiring interactive confirmation
    accept-flake-config = true;

    # Adds the NixOS Apple Silicon community cache as a binary substituter.
    extra-substituters = [
      "https://nixos-apple-silicon.cachix.org"
    ];

    # Adds the required public key to verify the integrity of the binaries.
    extra-trusted-public-keys = [
      "nixos-apple-silicon.cachix.org-1:b8n3W6k0uJ+L6G1oK1tHw92hU8XgJ+wU8F+Y3g4Z2n4="
    ];
  };
  # -----------------------------------

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
