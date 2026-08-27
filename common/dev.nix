{ pkgs, ... }:
{
  # virtualisation.docker.enable = true;
  # users.users.pj.extraGroups = [ "docker" ];
  users.users.pj.extraGroups = [ "kvm" "libvirtd" "docker"];

  virtualisation.containers.enable = true;
  virtualisation = {
    # podman = {
    #   enable = true;
    #   # Create a `docker` alias for podman, to use it as a drop-in replacement
    #   dockerCompat = true;
    #   # Required for containers under podman-compose to be able to talk to each other.
    #   defaultNetwork.settings.dns_enabled = true;
    # };
    docker = {
      enable = true;
    };
  };
  #services.lmStudio = { enable = true; gpu = "intel"; };
  home-manager.users.pj = {
    home.packages = with pkgs; [
      # code
      # ollama
      docker-compose
    ];
    programs.vscode = {
      enable = true;
#      profiles.default.userSettings = {
#        "docker.host" = "unix:///run/podman/podman.sock";
#      };
    };
  };
}
