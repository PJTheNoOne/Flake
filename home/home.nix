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

    sdrangel

    pavucontrol

    fzf #fuzzy finder
    ghostty

    onlyoffice-bin
    
    overskride

    libkrb5
    keyutils
    wireshark
    net-tools

    dconf-editor
    pdfarranger
    rquickshare
  
    pciutils 
  ];


  programs.git = {
    enable = true;
    userEmail = "pauldavidjacobson@gmail.com";
    userName = "PJTheNoOne";
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
}
