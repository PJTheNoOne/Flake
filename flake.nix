{
  description = "Flake";
  
  nixConfig = {
    extra-substituters = [
      #"https://colmena.cachix.org"
      "https://cache.nixos.org/"
    ];
    extra-trusted-public-keys = [
      #"colmena.cachix.org-1:7BzpDnjjH8ki2CT3f6GdOk7QAzPOl+1t3LvTLXqYcSg="
    ];
  };

  inputs = {
    niri.url = "github:YaLTer/niri";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager = { url = "github:nix-community/home-manager"; inputs.nixpkgs.follows = "nixpkgs"; };
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    ghostty.url = "github:ghostty-org/ghostty";
  };
  outputs = { self, niri, nixpkgs, nixpkgs-stable, ghostty, home-manager, nix-flatpak, ... }@inputs: {
    nixosConfigurations.craftingtable = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      specialArgs = {
        pkgs-stable = import nixpkgs-stable {
          inherit system;
          config.allowUnfree = true;
        };
        nixpkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        inherit inputs; 
      };
      modules = [
      {
        nixpkgs.pkgs = specialArgs.nixpkgs;
      }
        ./configuration.nix
        nix-flatpak.nixosModules.nix-flatpak
        ./flatpak.nix
        ./rice/niri.nix
        ./rice/waybar.nix
        ./virt/virt.nix
        ./home/other.nix
        ./game/game.nix
	./syst/syst.nix
        home-manager.nixosModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.pj = import ./home/home.nix;
          home-manager.backupFileExtension = "bkp";
          home-manager.extraSpecialArgs = { inherit inputs; };
        }
      ];
    };
  };
}
