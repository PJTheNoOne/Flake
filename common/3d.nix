{ config, lib, pkgs, pkgs-stable, ... }:
{
  home-manager.users.pj = {
    home.packages = with pkgs-stable;[
      orca-slicer
    ];
  };

}
