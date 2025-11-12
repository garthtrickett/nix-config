{
  description = "NixOS configuration for Apple Silicon (Unstable with Cachix)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    apple-silicon = {
      url = "github:nix-community/nixos-apple-silicon";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # This nixConfig block makes the build fast from the very start.
  nixConfig = {
    accept-flake-config = true;
    extra-substituters = [
      "https://nixos-apple-silicon.cachix.org"
    ];
    # Using the official, widely documented public key for security.
    extra-trusted-public-keys = [
      "nixos-apple-silicon.cachix.org-1:8psDu5SA5dAD7qA0zMy5UT292TxeEPzIz8VVEr2Js20="
    ];
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
