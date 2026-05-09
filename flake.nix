{
  description = "hogoshi's NixOS configuration";

  inputs = {
    millennium.url = "github:SteamClientHomebrew/Millennium?dir=packages/nix";

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, home-manager, spicetify-nix, ... }:
    let
      # true  = VPN only + minimal Hyprland (for initial setup behind Russia firewall)
      # false = full system (NVIDIA, apps, cachix, etc.)
      setupMode = false;

      # true = Zen Browser, false = Firefox
      useZen = true;

      system = "x86_64-linux";
    in {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs setupMode useZen; };
        modules = [
          ./hosts/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs    = true;
            home-manager.useUserPackages  = true;
            home-manager.extraSpecialArgs = { inherit inputs setupMode useZen; };
            home-manager.users.hogoshi    = import ./home;
          }
        ];
      };
    };
}
