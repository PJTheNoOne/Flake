{ lib, inputs, config, pkgs, ... }:{

  fonts.packages = builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);

  home-manager.users.pj = {
    home.packages = with pkgs; [
      waybar
    ];

    home.file.".config/waybar/config.jsonc".source = ./config.jsonc;
    home.file.".config/waybar/config-global.jsonc".source = ./config-global.jsonc;
    home.file.".config/waybar/style.css".source = ./style.css;
  };
}
