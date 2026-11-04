{ config, pkgs, services, lib, ... }:
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
    contextSize = lib.mkIf (config.networking.hostName == "commandblock") 32768;
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

  programs.nix-ld.enable = true;

  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    zlib
    openssl
    curl
    glib
  ];

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

  # CHANGED: now a function so we get the home-manager `config`
  home-manager.users.pj = { config, pkgs, lib, ... }:
  let
    piDir = config.programs.pi-coding-agent.configDir;

    # Editable bits of the pi config dir, mirrored into pi's DEFAULT location
    # (~/.pi/agent) as out-of-store symlinks. Anything that hardcodes the default
    # path (docs, skill installers, other agents, pi started without
    # PI_CODING_AGENT_DIR) ends up in the one real place, and edits are live
    # with no rebuild.
    piMirrored = [ "extensions" "skills" "prompts" "themes" "settings.json" "models.json" ];
    piLinks = lib.listToAttrs (map (name: {
      name = ".pi/agent/${name}";
      value.source = config.lib.file.mkOutOfStoreSymlink "${piDir}/${name}";
    }) piMirrored);
  in
  {
    home.packages = with pkgs; [
      docker-compose
      distrobox
      claude-code
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

      # `pi install npm:...` / `pi install git:...` write the `packages` list into
      # settings.json. As a read-only store symlink that fails. Declared keys above
      # are re-applied on every switch; anything pi adds is kept.
      mutableSettings = true;

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
    };

    # Make sure the mirrored directories exist so the links never dangle.
    home.activation.piDirs = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
      for d in extensions skills prompts themes; do
        $DRY_RUN_CMD mkdir -p "${piDir}/$d"
      done
    '';

    home.file = piLinks // {
      # docs + examples linked from the installed pi package. They follow the
      # package version, so a nixpkgs bump + rebuild updates them automatically.
      # Docs come from the built package (they survived the build)
      "${piDir}/docs".source =
        "${config.programs.pi-coding-agent.package}/lib/node_modules/pi-monorepo/docs";

      # Examples were stripped from the build, so take them from the package's own source
      "${piDir}/examples".source =
        "${config.programs.pi-coding-agent.package.src}/packages/coding-agent/examples";
    };
  };
}
