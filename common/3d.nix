{ config, lib, pkgs, ... }:
{
  home-manager.users.pj = {
    home.packages = with pkgs;[
      orca-slicer
    ]
  };

}
