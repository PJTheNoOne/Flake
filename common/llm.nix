{ config, lib, pkgs, ... }:

# One module, one job: run llama.cpp's router (many GGUFs, loaded on demand)
# on Vulkan, reachable from localhost and Tailscale, and nothing else.
#
# No `let ... in` on purpose: every option is read as
# config.services.local-llm.<name>, so you can grep for where anything comes from.
{
  options.services.local-llm = {
    enable = lib.mkEnableOption "llama.cpp router (Vulkan), reachable via localhost, plus Tailscale when it is enabled";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.llama-cpp-vulkan;
      description = ''
        llama.cpp built with Vulkan. One package for Intel (anv) and AMD (radv),
        so no per-host forks. Needs a build recent enough to have router mode.
      '';
    };

    user = lib.mkOption {
      type = lib.types.str;
      description = "Human user who gets write access to the models directory.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
    };

    modelsDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/llama-models";
      description = "Drop GGUF files here. Single files at top level, multi-file models in subdirectories.";
    };

    maxLoadedModels = lib.mkOption {
      type = lib.types.ints.positive;
      default = 1;
      description = "How many models the router keeps in memory at once. Raise it only if you have the VRAM.";
    };

    contextSize = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = 32768;
      description = ''
        Context window per loaded model, in tokens. Set to null to let each model
        use its native context, which can be enormous and will happily eat all
        your VRAM. Per-model sizes belong in llama.cpp model presets, not here.
      '';
    };

    gpuLayers = lib.mkOption {
      type = lib.types.int;
      default = 999;
      description = "Layers to offload to the GPU. 999 means as many as fit.";
    };

    openTailscaleFirewall = lib.mkOption {
      type = lib.types.bool;
      default = config.services.tailscale.enable;
      defaultText = lib.literalExpression "config.services.tailscale.enable";
      description = ''
        Open the port on tailscale0 only, never on any other interface. Defaults to
        on whenever Tailscale is enabled on this host. This module never enables
        Tailscale itself, so manage that wherever you like.
      '';
    };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Extra environment for the service, e.g. GGML_VK_VISIBLE_DEVICES to pick a GPU.";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra llama-server flags, appended last so they win.";
    };
  };

  config = lib.mkIf config.services.local-llm.enable {

    assertions = [
      {
        assertion = config.networking.firewall.enable;
        message = ''
          services.local-llm binds 0.0.0.0 and relies on the firewall to restrict it
          to tailscale0. With the firewall off, that is your whole LAN.
        '';
      }
    ];

    # Mesa already ships anv and radv. Nothing else is needed for Vulkan compute.
    hardware.graphics.enable = true;

    environment.systemPackages = [
      config.services.local-llm.package # llama-cli and friends for poking at models by hand
      pkgs.vulkan-tools # vulkaninfo --summary: does this machine see its GPU?
    ];

    users.groups.llama = { };

    users.users.llama = {
      isSystemUser = true;
      group = "llama";
      extraGroups = [ "render" "video" ]; # access to /dev/dri
      description = "llama.cpp router service account";
    };

    # You write to the models directory through the llama group, no sudo.
    # The leading 2 (setgid) keeps new files group-owned by llama.
    users.users.${config.services.local-llm.user}.extraGroups = [ "llama" ];

    systemd.tmpfiles.rules = [
      "d ${config.services.local-llm.modelsDir} 2775 llama llama -"
    ];

    systemd.services.local-llm = {
      description = "llama.cpp router (Vulkan)";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      environment = config.services.local-llm.environment;

      serviceConfig = {
        # No --model flag: that would switch llama-server to single-model mode.
        ExecStart = lib.escapeShellArgs (
          [
            (lib.getExe' config.services.local-llm.package "llama-server")
            "--models-dir" config.services.local-llm.modelsDir
            "--models-max" (toString config.services.local-llm.maxLoadedModels)
            "--host" "0.0.0.0"
            "--port" (toString config.services.local-llm.port)
            "-ngl" (toString config.services.local-llm.gpuLayers)
            "--jinja"
          ]
          ++ lib.optionals (config.services.local-llm.contextSize != null) [
            "-c" (toString config.services.local-llm.contextSize)
          ]
          ++ config.services.local-llm.extraArgs
        );

        User = "llama";
        Group = "llama";
        Restart = "on-failure";
        RestartSec = 5;

        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ config.services.local-llm.modelsDir ];
      };
    };

    # Remote access is Tailscale or nothing. The port is opened on tailscale0 only,
    # never in allowedTCPPorts (which would open it on every interface).
    # Tailscale itself is managed elsewhere; this only punches the firewall hole.
    networking.firewall.interfaces."tailscale0".allowedTCPPorts =
      lib.mkIf config.services.local-llm.openTailscaleFirewall [
        config.services.local-llm.port
      ];
  };
}
