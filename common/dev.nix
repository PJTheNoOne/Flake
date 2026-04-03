{ pkgs, ... }:
{
  home-manager.users.pj = {
    home.packages = with pkgs; [
      cursor
      ollama
    ];
  };
}
