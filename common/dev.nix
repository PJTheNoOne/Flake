{ config, pkgs, services, ... }:
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

  services.openssh = {
   enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      AllowUsers = [ "pj" ];
      MaxAuthTries = 3;
      #PerSourcePenalties = "crash:3600s authfail:3600s max:86400s";
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
      distrobox
    ];
    programs.vscode = {
      enable = true;
#      profiles.default.userSettings = {
#        "docker.host" = "unix:///run/podman/podman.sock";
#      };
    };
    programs.pi-coding-agent = {
      enable = true;
      extraPackages = [
        pkgs.nodejs
        pkgs.bun

      ];
      configDir = "/home/pj/nix/common/pi/agent";
      models = {
        providers = {
          ollama = {
            api = "openai-completions";
            apiKey = "ollama";
            baseUrl = "http://localhost:11434/v1";
            models = [
              { id = "qwen3.5:latest"; }
              { id = "qwen3.8:latest"; }
              { id = "qwen2.5:7b"; }
            ];
          };
        };
      };
    
      settings = {
        defaultProvider = "ollama";
        defaultModel = "qwen3.5:latest";
        defaultThinkingLevel = "medium";
        theme = "dark";
      };
    };
  };
}
