{ inputs, config, pkgs, ... }:{

#  programs.bash.shellAliases = {
#     l = "ls -alh";
#     ll = "ls -l";
#     ls = "ls --color=tty";
#     gsteam = "GBM_BACKEND=nvidia-drm STEAM_GAMESCOPE_VRR_SUPPORTED=1 STEAM_MULTIPLE_XWAYLANDS=1 gamescope -W 1920 -H 1080 -r 120 -e --xwayland-count 2 --rt --adaptive-sync -- steam";
#  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
    # gamescopeSession.enable = true;
     package = pkgs.steam.override {
       #withPrimus = true;
       #withJava = true;
       extraPkgs = pkgs: [ pkgs.SDL2 pkgs.libjpeg pkgs.vkd3d ];
     };

  };


  boot.blacklistedKernelModules = [ "nouveau" ];

  programs.gamescope = {
    enable = true;
#     capSysNice = true;
#     args = [
#       "-W 1920"
#       "-H 1080"
#       "-r 120"
#       "-e"
#       "--xwayland-count 3"
#       #"--rt"
#       "--adaptive-sync" 
#       "--force-grab-cursor"
#     ];
#     env = {
#       GBM_BACKEND = "nvidia-drm";
#       STEAM_GAMESCOPE_VRR_SUPPORTED = "1";
#       STEAM_MULTIPLE_XWAYLANDS = "1";
#     };
  };

  home-manager.users.pj = {
    home.packages = with pkgs; [
      #steam-run
      #gamescope
      mangohud
      mesa-demos
      # xwayland-run
    ];
  };

  hardware.opengl = {
    enable = true;
    
    # Extra packages for AMD
    extraPackages = with pkgs; [
      rocm-opencl-icd
      rocm-opencl-runtime
      amdvlk
    ];
    
    # 32-bit support for AMD
    extraPackages32 = with pkgs; [
      driversi686Linux.amdvlk
    ];
  };

  # AMD GPU configuration
  boot.initrd.kernelModules = [ "amdgpu" ];
  services.xserver.videoDrivers = [ "amdgpu" "nvidia" ];

  # NVIDIA configuration
  hardware.nvidia = {
    # Enable the NVIDIA settings menu
    nvidiaSettings = true;

    open = true;
    
    # Use the production driver (or "beta" for beta drivers)
    package = config.boot.kernelPackages.nvidiaPackages.production;
    
    # Enable power management (IMPORTANT for laptops)
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    
    # Enable modesetting (required for Wayland)
    modesetting.enable = true;
    
    # Prime configuration for hybrid graphics
    prime = {
      # Enable PRIME offload mode
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      
      # Alternative: sync mode (always uses both GPUs)
      # sync.enable = true;
      
      # Your specific Bus IDs
      amdgpuBusId = "PCI:4:0:0";   # AMD Radeon Vega (integrated)
      nvidiaBusId = "PCI:1:0:0";   # NVIDIA RTX 2060 Max-Q
    };
  };

  # Optional: Environment variables for better compatibility
  environment.variables = {
    # For Wayland + NVIDIA
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  # Optional: Install useful GPU utilities
  environment.systemPackages = with pkgs; [
    nvidia-vaapi-driver
    libva-utils
    pciutils
    glxinfo
    vulkan-tools
    radeontop  # AMD GPU monitoring
    nvtop      # Both AMD and NVIDIA GPU monitoring
  ];


}
