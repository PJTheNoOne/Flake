{ config, pkgs, services, ... }:
{
  # virtualisation.docker.enable = true;
  # users.users.pj.extraGroups = [ "docker" ];
  users.users.pj.extraGroups = [ "kvm" "libvirtd" "docker"];

  # Everything else (port, context, models directory, GPU layers) has a default
  # in common/llm.nix. Per-host tweaks belong in the host's own config, because
  # this file is imported by every host. See README-llm.md.
  services.local-llm = {
    enable = true;
    user = "pj";
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
  home-manager.users.pj = {
    home.packages = with pkgs; [
      docker-compose
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
      settings = {
        retry = {
          enabled = false;  # flip back to true once you're done debugging
          provider = {
            timeoutMs = 3600000;
          };
        };
        httpIdleTimeoutMs = 0;
      };
      configDir = "/home/pj/nix/common/pi/agent";

      # The local router needs no entry here: Pi's built-in llama.cpp support
      # defaults to http://127.0.0.1:8080. Run `/login llama.cpp` once, then
      # `/llama` to load a model and `/model` to pick it.
      #
      # The old craftingtable / commandblock / localhost providers pointed at
      # Ollama on :11434, which no longer exists, so they are gone. Reaching another
      # host's router from Pi is the pi-llama-cpp extension's job (see README-llm.md).
      #
      # shulker still runs Ollama and is not managed by this module, so Pi keeps
      # a hand-written entry for it.
      models = {
        providers = {
          shulker = {
            api = "openai-completions";
            apiKey = "ollama";
            baseUrl = "http://shulker.end-ulmer.ts.net:11435/v1";
            models = [
              { id = "gemma4:12b"; }
              { id = "qwen3.5:0.8b"; }
              { id = "qwen3.5:122b"; }
              { id = "qwen3.8:latest"; }
              { id = "fatgus:latest"; }
            ];
          };
        };
      };
    };
  };
}
