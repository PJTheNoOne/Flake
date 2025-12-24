{ pkgs, ... }:
{
  home-manager.users.pj = {
    home.packages = with pkgs; [
      inkscape-with-extensions
      gimp
    ];
  };
}
