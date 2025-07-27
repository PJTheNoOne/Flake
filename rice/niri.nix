{ inputs, config, nixpkgs, pkgs, pkgs-stable, ... }: {

  programs.niri = with nixpkgs; {
    enable = true;
  };

  home-manager.users.pj = {
    home.file.".config/niri/config.kdl".source = ./config.kdl;
    home.file.".config/hypr/hypridle.conf".source = ./hypridle.conf;
    home.file.".config/ghostty/config".source = ./config;
    home.packages = with pkgs; [
      # niri
      wireplumber
      playerctl
      brightnessctl
      fuzzel
      #swaylock
      mako

      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome

      swww
      waybar
      xwayland
      xwayland-satellite
    ];
  };
  
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
  };

  programs.hyprlock.enable = true;

  services.hypridle = { 
    enable = true;
  };

  services.xserver.enable = true;
  services.gnome.gnome-keyring.enable = true;
  programs.nautilus-open-any-terminal.enable = true;
}
