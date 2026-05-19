{ pkgs, ... }:
{
  #virtualisation.docker.enable = true;
  #users.users.pj.extraGroups = [ "docker" ];
  
  #services.lmStudio = { enable = true; gpu = "intel"; };
  home-manager.users.pj = {
    home.packages = with pkgs; [
      code-cursor
      ollama
      docker-compose
    ];
  };
}
