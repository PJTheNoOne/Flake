{ inputs, config, nixpkgs, pkgs, pkgs-stable, ... }: {

  services.displayManager.ly.enable = true;

  programs.niri = with nixpkgs; {
    enable = true;
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;
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

      ghostty

      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome

      swww
      waybar
      xwayland
      xwayland-satellite
      nautilus

      wl-clipboard
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
