{ inputs, config, nixpkgs, pkgs, pkgs-stable, ... }: {

  services.displayManager.ly.enable = true;
  services.displayManager.ly.settings = {
    animation = "matrix";
    auth_fails = 3;
    battery_id = "BAT0";
    bigclock = "en";
    bigclock_12hr = false;
    bigclock_seconds = true;
    vi_mode = true;
  };

  services.fprintd.enable = true;

  

  security.pam.services = {
    ly.fprintAuth = true;
    ly.rules.auth.fprintd.order = config.security.pam.services.ly.rules.auth.unix.order + 75;
    hyprlock.rules.auth.fprintd.order = config.security.pam.services.hyprlock.rules.auth.unix.order + 75;
    sudo.rules.auth.fprintd.order = config.security.pam.services.sudo.rules.auth.unix.order + 75;
    hyprlock.rules.auth.fprintd.settings.timeout = 3;
    sudo.rules.auth.fprintd.settings.timeout = 3;

  };

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
    #home.file.".config/ghostty/config".source = ./config;
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
      nautilus

      wl-clipboard
    ];

    programs.ghostty = {
      enable = true;
      settings = {
        term = "xterm-256color";
      };
      enableBashIntegration = true;
      settings = {
        theme = "Abernathy";
        background-opacity = "0.95";
      };
    };
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
