{ inputs, pkgs, ... }:{

  programs.bash.shellAliases = {
    l = "ls -alh";
    ll = "ls -l";
    ls = "ls --color=tty";
    gsteam = "GBM_BACKEND=nvidia-drm STEAM_GAMESCOPE_VRR_SUPPORTED=1 STEAM_MULTIPLE_XWAYLANDS=1 gamescope -W 1920 -H 1080 -r 120 -e --xwayland-count 2 --rt --adaptive-sync -- steam";
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
    gamescopeSession.enable = true;
     package = pkgs.steam.override {
       #withPrimus = true;
       #withJava = true;
       extraPkgs = pkgs: [ pkgs.SDL2 pkgs.libjpeg pkgs.vkd3d ];
     };

  };

  hardware.graphics.enable32Bit = true;

  boot.blacklistedKernelModules = [ "nouveau" ];

  programs.gamescope = {
    enable = true;
    capSysNice = true;
    args = [
      "-W 1920"
      "-H 1080"
      "-r 120"
      "-e"
      "--xwayland-count 3"
      #"--rt"
      "--adaptive-sync" 
      "--force-grab-cursor"
    ];
    env = {
      GBM_BACKEND = "nvidia-drm";
      STEAM_GAMESCOPE_VRR_SUPPORTED = "1";
      STEAM_MULTIPLE_XWAYLANDS = "1";
    };
  };

  home-manager.users.pj = {
    home.packages = with pkgs; [
      steam-run
      #gamescope
      mangohud
      mesa-demos
      xwayland-run
    ];
  };
}
