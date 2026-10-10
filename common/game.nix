{ pkgs, lib, config, ... }:
{
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom=DE
  '';

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.lact.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };

  home-manager.users.pj = { config, ... }: {
    xdg.configFile."openxr/1/active_runtime.json".text = ''
      {
        "file_format_version": "1.0.0",
        "runtime": {
          "VALVE_runtime_is_steamvr": true,
          "library_path": "${config.home.homeDirectory}/.local/share/Steam/steamapps/common/SteamVR/bin/linux64/vrclient.so",
          "name": "SteamVR"
        }
      }
    '';
    home.packages = with pkgs; [
#      steam
#      steam-run
      bs-manager
    ];
  };
}
