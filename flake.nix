{
  description = "hogoshi's NixOS configuration";

  inputs = {
    millennium.url = "path:./modules/programs/millennium-nix";

    nixpkgs.url = "https://github.com/nixos/nixpkgs/archive/nixos-unstable.tar.gz";

    home-manager = {
      url = "https://github.com/nix-community/home-manager/archive/master.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "https://github.com/Gerg-L/spicetify-nix/archive/master.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "https://github.com/youwen5/zen-browser-flake/archive/master.tar.gz";
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
