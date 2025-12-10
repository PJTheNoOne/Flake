{ ... }:{
  home-manager.user.pj = {
    
    services.kanshi = {
      enable = true;
      systemdTarget = "niri.target"; # Change to "sway-session.target" if using Sway
      
      settings = [
        # Profile: Just laptop (glasses/eDP-1 only)
        {
          profile.name = "laptop";
          profile.outputs = [
            {
              criteria = "eDP-1";
              status = "enable";
              mode = "1920x1080@120.003";
              position = "0,0";
            }
            {
              criteria = "HDMI-A-1";
              status = "disable";
            }
          ];
        }
        
        # Profile: Both displays (external left, laptop right)
        {
          profile.name = "dual";
          profile.outputs = [
            {
              criteria = "HDMI-A-1";
              status = "enable";
              mode = "1920x1080@90.000";
              position = "0,0";
            }
            {
              criteria = "eDP-1";
              status = "enable";
              mode = "1920x1080@120.003";
              position = "1920,0";
            }
          ];
        }
        
        # Profile: Just external monitor
        {
          profile.name = "glass";
          profile.outputs = [
            {
              criteria = "HDMI-A-1";
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
              criteria = "HDMI-A-1";
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
      ];
    };
  };
}
