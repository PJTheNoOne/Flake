{ pkgs, home-manager, ... }:{
  # https://nixos.wiki/wiki/Android
  users.groups.kvm = {};
  users.groups.adbusers = {};
  users.users.pj.extraGroups = [ "kvm" "adbusers" ];
  programs.adb.enable = true;

  home-manager.users.pj = {
    home.packages = with pkgs; [ android-studio-stable ];
  };
}
