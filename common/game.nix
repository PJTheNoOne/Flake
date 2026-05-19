{ pkgs, ... }:
{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  services.lact.enable = true;
  home-manager.users.pj = {
    home.packages = with pkgs; [
      steam
      steam-run
    ];
  };
}
