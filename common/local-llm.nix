{ config, lib, pkgs, ... }:
{
  # Install llama.cpp with GPU support
  environment.systemPackages = with pkgs; [
    vllm
  ];
}
{ config, lib, pkgs, ... }:

let
  cfg = config.services.local-llm;

  # Vanilla llama.cpp built with Vulkan compute enabled. This is what
  # actually talks to Xe — Mesa's `anv` Vulkan driver does the work,
  # no Intel oneAPI/SYCL toolchain nonsense required.
  llama-cpp-vulkan = pkgs.llama-cpp.override { vulkanSupport = true; };
in
{
  options.services.local-llm = {
    enable = lib.mkEnableOption "local LLM inference server (llama.cpp / Vulkan / Intel Xe)";

    modelPath = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to a GGUF model file. This module will not fetch one for you —
        go download a quantized model yourself, this isn't a magic trick.
      '';
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Bind address. Leave this alone unless you enjoy exposing an LLM to your LAN.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
    };

    gpuLayers = lib.mkOption {
      type = lib.types.int;
      default = 99;
      description = "Layers to offload to GPU. 99 = 'as many as fit', which is what you want.";
    };

    contextSize = lib.mkOption {
      type = lib.types.int;
      default = 4096;
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "pj";
      description = "The home-manager user to hand convenience tools to.";
    };

    extraFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra flags passed straight to llama-server, for when you know better than the defaults.";
    };
  };

  config = lib.mkIf cfg.enable {

    # This block is the entire point. Skip it and you're running
    # inference on the CPU like it's 2015.
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver   # VAAPI, in case you also want video accel
        intel-compute-runtime
        vpl-gpu-rt
        mesa
      ];
    };

    environment.systemPackages = with pkgs; [
      intel-gpu-tools   # intel_gpu_top — watch the Xe engine actually spin up
      vulkan-tools      # vulkaninfo — sanity check the driver is even seen
      llama-cpp-vulkan
    ];

    users.groups.llm = { };
    users.users.llm = {
      isSystemUser = true;
      group = "llm";
      extraGroups = [ "render" "video" ]; # needed to touch /dev/dri
      description = "local-llm service account";
    };

    systemd.services.local-llm = {
      description = "llama.cpp inference server (Vulkan / Intel Xe)";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        ExecStart = ''
          ${llama-cpp-vulkan}/bin/llama-server \
            --model ${cfg.modelPath} \
            --host ${cfg.host} \
            --port ${toString cfg.port} \
            --n-gpu-layers ${toString cfg.gpuLayers} \
            --ctx-size ${toString cfg.contextSize} \
            ${lib.concatStringsSep " " cfg.extraFlags}
        '';
        Restart = "on-failure";
        RestartSec = 5;
        User = "llm";
        Group = "llm";
        DeviceAllow = [ "/dev/dri rw" ];
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadOnlyPaths = [ (builtins.dirOf cfg.modelPath) ];
      };
    };

    # Kept in your existing style — just a client-side convenience,
    # not the thing doing the actual work.
    home-manager.users.${cfg.user} = {
      home.packages = with pkgs; [
        vulkan-tools
      ];
    };
  };
}
