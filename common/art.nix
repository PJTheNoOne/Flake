{ config, lib, pkgs, ... }:
{
  home-manager.users.pj = {
    home.packages = with pkgs; [
      inkscape-with-extensions
      gimp
      rawtherapee
      ffmpeg
      mpv
      davinci-resolve
      blender
      onlyoffice-desktopeditors
    ];
  };

  environment.systemPackages = with pkgs; lib.mkIf (config.networking.hostName == "commandblock") [
    intel-compute-runtime
    ocl-icd
    clinfo
  ];

  hardware.graphics = lib.mkIf (config.networking.hostName == "commandblock") {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-compute-runtime
      intel-media-driver
      intel-vaapi-driver
      vpl-gpu-rt
    ];
    extraPackages32 = with pkgs; [
      driversi686Linux.intel-media-driver
      driversi686Linux.intel-vaapi-driver
    ];
  };

  services.udev.extraRules = ''
  # Cricut
  SUBSYSTEM=="usb", ATTR{idVendor}=="04b8", MODE="0666", GROUP="users"
'';
  users.users.pj = {
    extraGroups = [ "dialout" ];
  };
}
