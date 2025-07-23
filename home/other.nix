{ pkgs,  ... }:{

  # https://nixos.wiki/wiki/Tailscale
  services.tailscale.enable = true;
  services.tailscale.useRoutingFeatures = "both";
  networking.nameservers = [ "100.100.100.100" "8.8.8.8" "1.1.1.1" ];
  networking.search = [ "end-ulmer.ts.net" ];

  services.udev.enable = true;

  hardware.rtl-sdr.enable = true;
#  services.udev.packages = [ pkgs.rtl-sdr ];
  boot.blacklistedKernelModules = [ "dvb_usb_rtl28xxu" ];
  users.groups.plugdev =  {};
  users.groups.wireshark = {};
  security.wrappers.dumpcap = {
    source = "${pkgs.wireshark}/bin/dumpcap";
    capabilities = "cap_net_raw,cap_net_admin+eip";
    owner = "root";
    group = "wireshark";
    permissions = "u+rx,g+rx";
  };
  users.users.pj.extraGroups = [ "plugdev" "wireshark" ];

#  programs.wireshark = {
#    enable = true;
#    usbmon.enable = true;
#  };

  environment.variables.EDITOR = "nvim";

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;
  };

  services.gvfs.enable = true;

  environment.shellAliases = {
        nixos-update="nix flake update && sudo nixos-rebuild switch --flake /etc/nixos/";
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
}

