# lm-studio.nix
# NixOS module: LM Studio headless API + web-search-mcp in Docker
# GPU support: NVIDIA (container toolkit) | AMD ROCm | Intel Arc/Xe (compute-runtime)
#
# ── USAGE IN YOUR FLAKE ───────────────────────────────────────────────────────
# 1. Add ./lm-studio.nix to your modules list in flake.nix
# 2. In your host config, set:
#
#    virtualisation.docker.enable = true;
#
#    services.lmStudio = {
#      enable = true;
#      gpu    = "nvidia";   # or "amd" or "intel" or "none"
#    };
#
# 3. sudo nixos-rebuild switch --flake .#yourHost
# ─────────────────────────────────────────────────────────────────────────────

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.lmStudio;

  # ── Dockerfile ──────────────────────────────────────────────────────────────
  # One image, GPU runtime is injected at *run-time* via docker run flags.
  # The image itself just needs the right userspace compute libraries baked in
  # for whichever vendor you chose.
  dockerfile = pkgs.writeText "lm-studio-Dockerfile" ''
    FROM ubuntu:22.04
    ENV DEBIAN_FRONTEND=noninteractive

    # ── Base system packages ──────────────────────────────────────────────────
    RUN apt-get update && apt-get install -y \
        curl wget ca-certificates gnupg lsb-release \
        libglib2.0-0 libgl1 libvulkan1 libxcb-* \
        libxkbcommon-x11-0 libdbus-1-3 libegl1 libfontconfig1 \
        libxrandr2 libxss1 libxtst6 xvfb \
        libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 \
        libxcomposite1 libxdamage1 libxfixes3 libgbm1 libasound2 \
        && rm -rf /var/lib/apt/lists/*

    # ── Node.js 20 ────────────────────────────────────────────────────────────
    RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
        && apt-get install -y nodejs \
        && rm -rf /var/lib/apt/lists/*

    # ── GPU userspace libraries (build-arg selects vendor) ───────────────────
    ARG GPU_VENDOR=none

    # --- NVIDIA: nothing to install in the image itself.
    # The nvidia-container-toolkit on the *host* injects CUDA/driver libs
    # transparently at runtime. No image changes needed.

    # --- AMD: ROCm OpenCL + HIP runtime from the official AMD repo
    RUN if [ "$GPU_VENDOR" = "amd" ]; then \
          apt-get update && \
          mkdir -p /etc/apt/keyrings && \
          curl -fsSL https://repo.radeon.com/rocm/rocm.gpg.key \
            | gpg --dearmor -o /etc/apt/keyrings/rocm.gpg && \
          echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] \
            https://repo.radeon.com/rocm/apt/6.3 jammy main" \
            > /etc/apt/sources.list.d/rocm.list && \
          apt-get update && \
          apt-get install -y rocm-opencl-runtime hip-runtime-amd && \
          rm -rf /var/lib/apt/lists/*; \
        fi

    # --- Intel Arc/Xe: Intel compute-runtime (NEO) + Level Zero
    # Drivers must be installed on the host; inside the container we install
    # the userspace ICD so OpenCL/Level Zero API calls route correctly.
    RUN if [ "$GPU_VENDOR" = "intel" ]; then \
          apt-get update && \
          mkdir -p /etc/apt/keyrings && \
          curl -fsSL https://repositories.intel.com/gpu/intel-graphics.key \
            | gpg --dearmor -o /etc/apt/keyrings/intel-graphics.gpg && \
          echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/intel-graphics.gpg] \
            https://repositories.intel.com/gpu/ubuntu jammy unified" \
            > /etc/apt/sources.list.d/intel-graphics.list && \
          apt-get update && \
          apt-get install -y \
            intel-opencl-icd \
            intel-level-zero-gpu \
            level-zero \
            intel-media-va-driver-non-free \
            libmfx1 libmfxgen1 libvpl2 && \
          rm -rf /var/lib/apt/lists/*; \
        fi

    # ── LM Studio CLI (lms) ───────────────────────────────────────────────────
    RUN curl -fsSL https://installer.lmstudio.ai/linux/x86_64/lms/latest/download \
        -o /usr/local/bin/lms \
        && chmod +x /usr/local/bin/lms \
        && lms --version

    # ── web-search-mcp ────────────────────────────────────────────────────────
    WORKDIR /opt/web-search-mcp
    RUN curl -fsSL \
        https://github.com/mrkrsl/web-search-mcp/archive/refs/heads/main.tar.gz \
        | tar -xz --strip-components=1 \
        && npm install \
        && npx playwright install --with-deps chromium firefox \
        && npm run build

    # ── Runtime dirs ──────────────────────────────────────────────────────────
    RUN mkdir -p /root/.lmstudio/models

    EXPOSE ${toString cfg.apiPort}
    EXPOSE ${toString cfg.mcpPort}

    COPY entrypoint.sh /entrypoint.sh
    RUN chmod +x /entrypoint.sh
    ENTRYPOINT ["/entrypoint.sh"]
  '';

  # ── Entrypoint ──────────────────────────────────────────────────────────────
  entrypoint = pkgs.writeText "lm-studio-entrypoint.sh" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo "[entrypoint] GPU_VENDOR=${"\${GPU_VENDOR:-none}"}"

    # AMD: most software hard-codes /opt/rocm. Symlink if not already there.
    if [ "${"\${GPU_VENDOR:-none}"}" = "amd" ]; then
      if [ -d /usr/lib/x86_64-linux-gnu/rocm ] && [ ! -L /opt/rocm ]; then
        ln -sfn /usr/lib/x86_64-linux-gnu/rocm /opt/rocm || true
      fi
      # Required for Polaris/pre-Vega cards. Harmless on newer ones.
      export ROC_ENABLE_PRE_VEGA=1
    fi

    echo "[entrypoint] Starting LM Studio server on port ${toString cfg.apiPort}..."
    lms server start \
      --port ${toString cfg.apiPort} \
      --cors \
      --no-browser &
    LMS_PID=$!

    echo "[entrypoint] Starting web-search-mcp on port ${toString cfg.mcpPort}..."
    cd /opt/web-search-mcp
    PORT=${toString cfg.mcpPort} node dist/index.js &
    MCP_PID=$!

    echo "[entrypoint] Running — LMS=$LMS_PID MCP=$MCP_PID"
    trap "echo 'Shutting down...'; kill $LMS_PID $MCP_PID 2>/dev/null; wait" SIGTERM SIGINT
    wait -n
  '';

  # ── docker run GPU flags per vendor ─────────────────────────────────────────
  #   nvidia  → container toolkit injects everything via --runtime=nvidia
  #   amd     → expose /dev/kfd (compute) + /dev/dri (render), add to groups
  #   intel   → expose /dev/dri + by-path symlinks for Arc/Xe multi-GPU
  #   none    → nothing, enjoy your CPU-powered patience exercise
  gpuRunFlags = {
    none   = "";
    nvidia = "--gpus all --runtime=nvidia";
    amd    = "--device=/dev/kfd --device=/dev/dri --group-add video --group-add render";
    intel  = "--device=/dev/dri:/dev/dri -v /dev/dri/by-path:/dev/dri/by-path";
  };

in
{
  # ── Option declarations ──────────────────────────────────────────────────────
  options.services.lmStudio = {

    enable = mkEnableOption "LM Studio headless API + web-search-mcp (Docker)";

    gpu = mkOption {
      type    = types.enum [ "none" "nvidia" "amd" "intel" ];
      default = "none";
      description = ''
        GPU vendor to enable inside the container.

          "none"   — CPU only. Universally works. Universally slow for large models.

          "nvidia" — NVIDIA GPU via container toolkit.
                     Requires on the host:
                       hardware.nvidia.modesetting.enable = true;
                       virtualisation.docker.enableNvidia = true;

          "amd"    — AMD GPU via ROCm (/dev/kfd + /dev/dri passthrough).
                     Requires on the host:
                       hardware.amdgpu.opencl.enable = true;
                     GCN1/GCN2 cards also need kernel params (see comments below).
                     Polaris and older also need ROC_ENABLE_PRE_VEGA=1 (set automatically).

          "intel"  — Intel Arc / Xe iGPU via compute-runtime (OpenCL NEO + Level Zero).
                     Requires on the host:
                       hardware.graphics.extraPackages = [ pkgs.intel-compute-runtime ];
                       boot.kernelParams = [ "i915.enable_guc=3" ];
                     The Arc dedicated GPU is still on the i915/xe kernel driver on Linux —
                     don't let the marketing naming confuse you.
      '';
    };

    apiPort = mkOption {
      type    = types.port;
      default = 1234;
      description = "LM Studio OpenAI-compatible REST API port.";
    };

    mcpPort = mkOption {
      type    = types.port;
      default = 3000;
      description = "web-search-mcp HTTP bridge port.";
    };

    modelsDir = mkOption {
      type    = types.str;
      default = "/var/lib/lmstudio/models";
      description = "Host path for model files (.gguf etc). Mounted read-only into the container.";
    };

    dataDir = mkOption {
      type    = types.str;
      default = "/var/lib/lmstudio";
      description = "Host path for LM Studio config/logs. Mounted read-write.";
    };

    imageName = mkOption {
      type    = types.str;
      default = "lmstudio-mcp";
      description = "Local Docker image tag.";
    };

    maxContentLength = mkOption {
      type    = types.int;
      default = 50000;
      description = "MAX_CONTENT_LENGTH env var passed to web-search-mcp.";
    };

    maxBrowsers = mkOption {
      type    = types.int;
      default = 2;
      description = "MAX_BROWSERS for web-search-mcp. Don't go wild — it's a container.";
    };
  };

  # ── Implementation ───────────────────────────────────────────────────────────
  config = mkIf cfg.enable {

    # ── Sanity assertions ──────────────────────────────────────────────────────
    assertions = [
      {
        assertion = config.virtualisation.docker.enable;
        message   = "services.lmStudio.enable requires virtualisation.docker.enable = true.";
      }
      {
        assertion = cfg.gpu != "nvidia" || (config.virtualisation.docker.enableNvidia or false);
        message   = ''
          services.lmStudio.gpu = "nvidia" requires:
            virtualisation.docker.enableNvidia = true;
            hardware.nvidia.modesetting.enable = true;
        '';
      }
    ];

    # ── Host GPU driver configuration ─────────────────────────────────────────
    # Conditional blocks so this single module works correctly on all three
    # machines — just set gpu = "nvidia" | "amd" | "intel" per host.

    hardware.graphics = mkMerge [
      { enable = true; }

      # Intel Arc/Xe: compute-runtime for OpenCL/Level Zero, media driver for VA-API
      (mkIf (cfg.gpu == "intel") {
        extraPackages = with pkgs; [
          intel-compute-runtime  # OpenCL NEO + Level Zero (Arc/Xe compute, not just video)
          intel-media-driver     # VA-API iHD (required for Arc; replaces the old i965 driver)
          vpl-gpu-rt             # oneVPL / Intel QSV runtime
        ];
      })

      # AMD: ROCm OpenCL ICD
      (mkIf (cfg.gpu == "amd") {
        extraPackages = with pkgs; [
          rocmPackages.clr.icd   # ROCm OpenCL ICD loader registration
        ];
      })
    ];

    # Intel Arc: enable GuC/HuC firmware submission — Arc requires this for full compute
    boot.kernelParams = mkIf (cfg.gpu == "intel") [
      "i915.enable_guc=3"
    ];

    # Intel: tell VA-API to use the modern iHD backend (not the legacy i965)
    environment.sessionVariables = mkIf (cfg.gpu == "intel") {
      LIBVA_DRIVER_NAME = "iHD";
    };

    # Intel Arc: needs redistributable firmware blobs from linux-firmware
    hardware.enableRedistributableFirmware = mkIf (cfg.gpu == "intel") (mkDefault true);

    # AMD: ROCm symlink + host dirs
    # Most software (including lms) hard-codes /opt/rocm — we symlink the Nix store paths.
    # GCN1/GCN2 note: if your AMD GPU is older than GCN3 (pre-Fiji/Polaris),
    # also add to boot.kernelParams: [ "amdgpu.si_support=1" "radeon.si_support=0" ]
    # (GCN1) or [ "amdgpu.cik_support=1" "radeon.cik_support=0" ] (GCN2).
    systemd.tmpfiles.rules = mkMerge [
      [
        "d ${cfg.dataDir}       0750 root docker - -"
        "d ${cfg.modelsDir}     0750 root docker - -"
        "d /etc/lmstudio-docker 0750 root root   - -"
      ]
      (mkIf (cfg.gpu == "amd") (
        let rocmEnv = pkgs.symlinkJoin {
              name  = "rocm-combined";
              paths = with pkgs.rocmPackages; [ rocblas hipblas clr ];
            };
        in [ "L+ /opt/rocm - - - - ${rocmEnv}" ]
      ))
    ];

    # ── Write build context to /etc at activation ──────────────────────────────
    system.activationScripts.lmStudioDockerfiles = {
      text = ''
        cp ${dockerfile}  /etc/lmstudio-docker/Dockerfile
        cp ${entrypoint}  /etc/lmstudio-docker/entrypoint.sh
        chmod +x /etc/lmstudio-docker/entrypoint.sh
      '';
      deps = [];
    };

    # ── Build service (oneshot, Docker layer-cached) ───────────────────────────
    systemd.services.lmstudio-build = {
      description   = "Build LM Studio + web-search-mcp Docker image [gpu=${cfg.gpu}]";
      wantedBy      = [ "multi-user.target" ];
      after         = [ "docker.service" ];
      requires      = [ "docker.service" ];
      serviceConfig = {
        Type            = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "lmstudio-docker-build" ''
          set -euo pipefail
          cd /etc/lmstudio-docker
          echo "Building ${cfg.imageName}:latest — GPU_VENDOR=${cfg.gpu}"
          ${pkgs.docker}/bin/docker build \
            --build-arg GPU_VENDOR=${cfg.gpu} \
            --tag ${cfg.imageName}:latest \
            --file Dockerfile \
            .
          echo "Image built successfully."
        '';
      };
    };

    # ── Run service ────────────────────────────────────────────────────────────
    systemd.services.lmstudio = {
      description = "LM Studio headless API + web-search-mcp [${cfg.gpu}]";
      wantedBy    = [ "multi-user.target" ];
      after       = [ "docker.service" "lmstudio-build.service" "network-online.target" ];
      requires    = [ "docker.service" "lmstudio-build.service" ];
      wants       = [ "network-online.target" ];

      preStart = ''
        ${pkgs.docker}/bin/docker rm -f lmstudio 2>/dev/null || true
      '';

      serviceConfig = {
        Type       = "simple";
        Restart    = "on-failure";
        RestartSec = "10s";

        ExecStart = pkgs.writeShellScript "lmstudio-docker-run" ''
          set -euo pipefail
          exec ${pkgs.docker}/bin/docker run \
            --name lmstudio \
            --rm \
            --init \
            -p ${toString cfg.apiPort}:${toString cfg.apiPort} \
            -p ${toString cfg.mcpPort}:${toString cfg.mcpPort} \
            -v ${cfg.modelsDir}:/root/.lmstudio/models:ro \
            -v ${cfg.dataDir}:/root/.lmstudio:rw \
            -e GPU_VENDOR=${cfg.gpu} \
            -e MAX_CONTENT_LENGTH=${toString cfg.maxContentLength} \
            -e MAX_BROWSERS=${toString cfg.maxBrowsers} \
            -e BROWSER_HEADLESS=true \
            -e ENABLE_RELEVANCE_CHECKING=true \
            ${gpuRunFlags.${cfg.gpu}} \
            ${cfg.imageName}:latest
        '';

        ExecStop = "${pkgs.docker}/bin/docker stop lmstudio";
      };
    };

    # ── Open firewall ──────────────────────────────────────────────────────────
    networking.firewall.allowedTCPPorts = mkIf config.networking.firewall.enable [
      cfg.apiPort
      cfg.mcpPort
    ];
  };
}
