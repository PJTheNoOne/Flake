{ pkgs, ... }:{
  hardware.bluetooth = {
    enable = true; 
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };
#  services.blueman.enable = true;
#  hardware.pulseaudio = {
#    enable = true;
#    package = pkgs.pulseaudioFull;
#  };
### Gameing ###

  hardware = {
      graphics = {
          enable = true;
          enable32Bit = true;
      };
      logitech.wireless.enable = true; 
#      amdgpu.amdvlk = {
#          enable = true;
#          support32Bit.enable = true;
#      };
  };
}
