{ config, lib, pkgs, ... }:

let
  cfg = config.services.local-llm;
in
{
  options.services.local-llm = {
    enable = lib.mkEnableOption "Ollama (Vulkan backend) as a shared, host-agnostic LLM service";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.ollama-vulkan;
      description = ''
        Vulkan is the whole point here: `anv` (Intel), `radv` (AMD) and `nvk`/proprietary
        (Nvidia) all speak it, so this one package works unmodified on every host in the
        flake without you maintaining per-vendor branches. If a given host has a beefy
        Nvidia card and you want the extra throughput, override this to `pkgs.ollama-cuda`
        for that host specifically — everything else about this module stays the same.
      '';
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 11434; # Ollama's default; keep it unless something else fights for it
    };

    user = lib.mkOption {
      type = lib.types.str;
      description = "home-manager user to hand client tooling to.";
    };

    models = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Model tags to pull automatically on activation (e.g. [ "qwen2.5:7b" "llama3.2:3b" ]).
        Leave empty and pull manually with `ollama pull` if you'd rather not eat bandwidth
        on every rebuild.
      '';
    };
  };

  config = lib.mkIf cfg.enable {

    # Vendor-agnostic on purpose — this is what makes Vulkan the right call across
    # a fleet with mixed GPUs instead of forking the config per host.
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        mesa
        vulkan-loader
        intel-media-driver     # harmless no-op on non-Intel hosts, needed on the Xe laptop
        intel-compute-runtime
        vpl-gpu-rt
      ];
    };

    environment.systemPackages = with pkgs; [
      vulkan-tools   # vulkaninfo, to confirm each host actually sees its GPU
    ];

    services.ollama = {
      enable = true;
      package = cfg.package;
      host = cfg.host;
      port = cfg.port;
      loadModels = cfg.models;
    };

    home-manager.users.${cfg.user} = {
      home.packages = with pkgs; [
        vulkan-tools
      ];
    };
  };
}
