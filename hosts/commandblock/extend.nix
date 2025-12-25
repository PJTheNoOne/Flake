{ pkgs, lib, ... }:{

  networking.hostName = lib.mkForce "commandblock";
  # Enable usbmuxd service
  services.usbmuxd = {
    enable = true;
    package = pkgs.usbmuxd2;  # usbmuxd2 is generally better
  };

  # Add libimobiledevice tools if you want to actually do anything useful
  environment.systemPackages = with pkgs; [
    libimobiledevice
    ifuse  # if you want to mount the filesystem
    usbutils
  ];

  # Your user needs to be in the right group
  users.users.pj.extraGroups = [ "usbmux" ];

  home-manager.users.pj = {
    
    services.kanshi = {
      enable = true;
      systemdTarget = "niri.target"; # Change to "sway-session.target" if using Sway
      
      settings = [

        # Profile: Just external monitor
        {
          profile.name = "glass";
          profile.outputs = [
            {
              criteria = "Nreal One Unknown";
              status = "enable";
              mode = "1920x1080@90.000";
              position = "0,0";
            }
            {
              criteria = "eDP-1";
              status = "disable";
            }
          ];
        }

        # Profile: Just external monitor
        {
          profile.name = "wide";
          profile.outputs = [
            {
              criteria = "Nreal One Unknown";
              status = "enable";
              mode = "3840x1080@60.000";
              position = "0,0";
            }
            {
              criteria = "eDP-1";
              status = "disable";
            }
          ];
        }
        # Profile: Just laptop (glasses/eDP-1 only)
        {
          profile.name = "laptop";
          profile.outputs = [
            {
              criteria = "eDP-1";
              status = "enable";
              mode = "1920x1200@60.003";
              position = "0,0";
            }
            # {
            #   criteria = "Nreal One Unknown";
            #   status = "disable";
            # }
          ];
        }
        
        # Profile: Both displays (external left, laptop right)
        {
          profile.name = "dual";
          profile.outputs = [
            {
              criteria = "Nreal One Unknown";
              status = "enable";
              mode = "1920x1080@90.000";
              position = "0,0";
            }
            {
              criteria = "eDP-1";
              status = "enable";
              mode = "1920x1200@60.003";
              position = "1920,0";
            }
          ];
        }
      ];
    };
  };
}
