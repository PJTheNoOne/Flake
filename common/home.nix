{ config, pkgs, inputs, nixpkgs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # https://nixos.wiki/wiki/Tailscale
  services.tailscale.enable = true;
  services.tailscale.useRoutingFeatures = "both";

  #networking.nameservers = [ "100.100.100.100" "8.8.8.8" "1.1.1.1" ];
  networking.search = [ "end-ulmer.ts.net" ];

  environment.variables.EDITOR = "nvim";

  services.gvfs.enable = true;

  environment.shellAliases = {
        nixos-update="nix flake update && sudo nixos-rebuild switch --flake ~/nix/";
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  security.sudo.extraConfig = ''
    Defaults insults
  '';

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        # Shows battery charge of connected devices on supported
        # Bluetooth adapters. Defaults to 'false'.
        Experimental = true;
        # When enabled other devices can connect faster to us, however
        # the tradeoff is increased power consumption. Defaults to
        # 'false'.
        FastConnectable = true;
      };
      Policy = {
        # Enable all controllers when they are found. This includes
        # adapters present on start as well as adapters that are plugged
        # in later on. Defaults to 'true'.
        AutoEnable = true;
      };
    };
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.pj = {
  
    xdg.mimeApps = {
      enable = true;
      
      defaultApplications = {
        "text/html" = "app.zen_browser.zen";
        "x-scheme-handler/http" = "app.zen_browser.zen";
        "x-scheme-handler/https" = "app.zen_browser.zen";
        "x-scheme-handler/about" = "app.zen_browser.zen";
        "x-scheme-handler/unknown" = "app.zen_browser.zen";
      };
    };
  
    home.username = "pj";
    home.homeDirectory = "/home/pj";
  
    home.packages = with pkgs; [
      unzip
      fzf #fuzzy finder
      #onlyoffice-desktopeditors
      #pdfarranger
      pciutils 
      prismlauncher
      solaar
      bluetui
      net-tools
    ];
  
    programs.git = {
      enable = true;
      settings = {
        user.email = "pauldavidjacobson@gmail.com";
        user.name = "PJTheNoOne";
      };
    };
  
    programs.tmux = {
      enable = true;
      plugins = with pkgs; [
        tmuxPlugins.better-mouse-mode
      ];
    };
  
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
  #    extraConfig = lib.fileContents ../path/to/your/init.vim;
      plugins = [
        pkgs.vimPlugins.nvim-tree-lua
        {
          plugin = pkgs.vimPlugins.vim-startify;
          config = "let g:startify_change_to_vcs_root = 0";
        }
      ];
    };
  
    xdg.configFile."containers/registries.conf".text = ''
      [registries.search]
      registries = ['docker.io']
    '';
  
    home.stateVersion = "25.11";
    programs.home-manager.enable = true;
  };
}
