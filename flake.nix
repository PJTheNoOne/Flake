{
  description = "Flake";
  
  inputs = {
    niri.url = "github:YaLTer/niri";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager = { url = "github:nix-community/home-manager"; inputs.nixpkgs.follows = "nixpkgs"; };
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    ghostty.url = "github:ghostty-org/ghostty";
  };
  outputs = { self, niri, nixpkgs, nixpkgs-stable, ghostty, home-manager, nix-flatpak, ... }: {
    nixosConfigurations.craftingtable = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      #specialArgs = { inherit nixpkgs; };
      modules = [
        {
          nixpkgs.config.allowUnfree = true;
          _module.args.pkgs-stable = import nixpkgs-stable {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
        }
        home-manager.nixosModules.home-manager 
        ./hosts/craftingtable/configuration.nix
        #./hosts/craftingtable/extend.nix
        ./common/home.nix
        #nix-flatpak.nixosModules.nix-flatpak
        #./common/flatpak.nix
        #./common/rice/niri.nix
        #./common/rice/waybar.nix
      ];
    };
    nixosConfigurations.lectern = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      #specialArgs = { inherit nixpkgs; };
      modules = [
        {
          nixpkgs.config.allowUnfree = true;
          _module.args.pkgs-stable = import nixpkgs-stable {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
        }
        home-manager.nixosModules.home-manager 
        ./hosts/lectern/configuration.nix
        #./hosts/lectern/extend.nix
        ./common/home.nix
        #nix-flatpak.nixosModules.nix-flatpak
        #./common/flatpak.nix
        #./common/rice/niri.nix
        #./common/rice/waybar.nix
      ];
    };
    nixosConfigurations.autocrafter = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      #specialArgs = { inherit nixpkgs; };
      modules = [
        {
          nixpkgs.config.allowUnfree = true;
          _module.args.pkgs-stable = import nixpkgs-stable {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
        }
        home-manager.nixosModules.home-manager 
        ./hosts/autocrafter/configuration.nix
        ./hosts/autocrafter/extend.nix
        ./common/home.nix
        nix-flatpak.nixosModules.nix-flatpak
        ./common/flatpak.nix
        ./common/rice/niri.nix
        ./common/rice/waybar.nix
      ];
    };
    nixosConfigurations.commandblock = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      #specialArgs = { inherit nixpkgs; };
      modules = [
        {
          nixpkgs.config.allowUnfree = true;
          _module.args.pkgs-stable = import nixpkgs-stable {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
        }
        home-manager.nixosModules.home-manager 
        ./hosts/commandblock/configuration.nix
        ./hosts/commandblock/extend.nix
        ./common/home.nix
        nix-flatpak.nixosModules.nix-flatpak
        ./common/flatpak.nix
        ./common/niri/niri.nix
        ./common/niri/waybar.nix
      ];
    };
  };
}
