{ self, system, inputs, pkgs, nix-alien, ... }:

{
  xdg.mimeApps = {
    enable = true;
    
    defaultApplications = {
      "text/html" = "app.zen_browser.zen";
      "x-scheme-handler/http" = "app.zen_browser.zen";
      "x-scheme-handler/https" = "app.zen_browser.zen";
      "x-scheme-handler/about" = "app.zen_browser.zen";
      "x-scheme-handler/unknown" = "app.zen_browser.zen";
    };
  };

  home.username = "pj";
  home.homeDirectory = "/home/pj";

  home.sessionVariables = {
    #GDK_BACKEND = "wayland,x11";
    #QT_QPA_PLATFORM = "wayland;xcb";
    ##SDL_VIDEODRIVER = "x11";
    #CLUTTER_BACKEND = "wayland";
    #XDG_CURRENT_DESKTOP = "Hyprland";
    #XDG_SESSION_TYPE = "wayland";
    #XDG_SESSION_DESKTOP = "Hyprland";
    #WLR_NO_HARDWARE_CURSORS = "1";
    #STEAM_FORCE_DESKTOPUI_SCALING= "1";
  };

  home.packages = with pkgs; [
    orca-slicer
    ffmpeg
    dav1d

    unzip

    #sdrangel

    pavucontrol

    fzf #fuzzy finder
    ghostty

    onlyoffice-desktopeditors
    
    overskride

    libkrb5
    keyutils
    wireshark
    net-tools

    dconf-editor
    pdfarranger
    rquickshare
  
    pciutils 

    prismlauncher
    solaar

    claude-code
    bluetui
    
    scrcpy
  ];
  

  programs.git = {
    enable = true;
    settings = {
      user.email = "pauldavidjacobson@gmail.com";
      user.name = "PJTheNoOne";
    };
  };

  programs.tmux = {
    enable = true;
    plugins = with pkgs; [
      tmuxPlugins.better-mouse-mode
    ];
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
#    extraConfig = lib.fileContents ../path/to/your/init.vim;
    plugins = [
      pkgs.vimPlugins.nvim-tree-lua
      {
        plugin = pkgs.vimPlugins.vim-startify;
        config = "let g:startify_change_to_vcs_root = 0";
      }
    ];
  };

  programs.vifm.enable = true;

  programs.vscode = {
    enable = true;
  };

  xdg.configFile."containers/registries.conf".text = ''
    [registries.search]
    registries = ['docker.io']
  '';

  #programs.kitty.enable = true;
  
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;

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
}
