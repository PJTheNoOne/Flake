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

    enableIntegratedGpu = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Ollama refuses to use integrated GPUs (Xe included) unless explicitly told to —
        it treats shared-memory iGPUs as a "you asked for this" opt-in rather than a
        default. Sets OLLAMA_IGPU_ENABLE=1. Turn this off if you'd genuinely rather it
        fall back to CPU on laptops with weak iGPUs.
      '';
    };

    extraEnvironmentVariables = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Extra OLLAMA_* environment variables, merged with the iGPU toggle above.";
    };

    remoteOllama = {
      enable = lib.mkEnableOption ''
        exposing Ollama's API beyond this machine, reachable ONLY via Tailscale — for
        when another machine (e.g. one running its own Open WebUI) needs to reach this
        box's Ollama directly. Nothing on the physical LAN/Wi-Fi interface can reach this
        port, ever, regardless of subnet, firewall rules elsewhere, or what network this
        laptop happens to be on. The only two ways in are the Tailscale interface and
        localhost — there is no third path in this module, by design.
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
      # 0.0.0.0 when remote access is on, but see the firewall block below — the only
      # interfaces actually allowed through to this port are tailscale0 and loopback.
      # Binding wide and then filtering at the firewall is what lets both localhost and
      # Tailscale work off a single Ollama listener; Ollama itself can't be told to
      # listen on two specific interfaces and no others.
      host = if cfg.remoteOllama.enable then "0.0.0.0" else cfg.host;
      port = cfg.port;
      loadModels = cfg.models;
      environmentVariables = lib.mkMerge [
        (lib.mkIf cfg.enableIntegratedGpu { OLLAMA_IGPU_ENABLE = "1"; })
        cfg.extraEnvironmentVariables
      ];
    };

    home-manager.users.${cfg.user} = {
      home.packages = with pkgs; [
        vulkan-tools
      ];
    };

    services.tailscale.enable = lib.mkIf cfg.remoteOllama.enable true;

    # --- The only door in besides localhost: Tailscale, nothing else -----------
    # Ollama's port is opened on the tailscale0 interface exclusively. It is never
    # added to networking.firewall.allowedTCPPorts (which would open it on every
    # interface) and there is no IP-allowlist branch left in this module — physical
    # LAN/Wi-Fi gets nothing, no matter what subnet or IP this laptop lands on.
    networking.firewall.interfaces."tailscale0".allowedTCPPorts =
      lib.mkIf cfg.remoteOllama.enable [ cfg.port ];
  };
}
