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

    # MODIFIED: Temporarily disabled due to build failure
    # zjstatus = {
    #   url = "github:dj95/zjstatus";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs = { self, nixpkgs, catppuccin, home-manager, apple-silicon, zen-browser, ... }@inputs:
  let
    system = "aarch64-linux";
    pkgs = import nixpkgs {
      inherit system;
      overlays = [
        # MODIFIED: Temporarily disabled due to build failure
        # (final: prev: {
        #   zjstatus = zjstatus.packages.${prev.system}.default;
        # })
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
