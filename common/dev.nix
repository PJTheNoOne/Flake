{ pkgs, services, ... }:
{
  # virtualisation.docker.enable = true;
  # users.users.pj.extraGroups = [ "docker" ];
  users.users.pj.extraGroups = [ "kvm" "libvirtd" "docker"];

  services.local-llm = {
    enable = true;
    user = "pj"; # or whatever the host's actual home-manager user is
    models = [ "qwen2.5:7b" ]; # optional, leave [] if you'd rather pull by hand
    remoteOllama.enable = true;
    extraEnvironmentVariables = {OLLAMA_CONTEXT_LENGTH = "65536";
      GGML_VK_VISIBLE_DEVICES = "0"; 
      OLLAMA_VULKAN= "1";
    };
  };

  environment.systemPackages = [ pkgs.distrobox ];

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
      nodejs
    ];
    programs.vscode = {
      enable = true;
#      profiles.default.userSettings = {
#        "docker.host" = "unix:///run/podman/podman.sock";
#      };
    };
  };
}
