{ config, lib, pkgs, ... }:

{
  options.services.local-llm = {
    enable = lib.mkEnableOption "local llama.cpp Vulkan router";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.llama-cpp-vulkan;
      description = "llama.cpp package with Vulkan support.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "pj";
      description = "Regular user allowed to manage local models.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
    };

    modelsDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/llama-models";
    };

    maxLoadedModels = lib.mkOption {
      type = lib.types.int;
      default = 2;
    };

    contextSize = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
    };

    gpuLayers = lib.mkOption {
      type = lib.types.int;
      default = 99;
    };

    openTailscaleFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };
  };

  config = lib.mkIf config.services.local-llm.enable {
    assertions = [
      {
        assertion = config.services.local-llm.maxLoadedModels > 0;
        message = "services.local-llm.maxLoadedModels must be greater than zero.";
      }
      {
        assertion = config.services.local-llm.gpuLayers >= 0;
        message = "services.local-llm.gpuLayers must be non-negative.";
      }
    ];

    hardware.graphics.enable = true;

    environment.systemPackages = [
      config.services.local-llm.package
      pkgs.vulkan-tools
      pkgs.curl
      (pkgs.python3.withPackages (ps: [
        ps.huggingface-hub
      ]))

      (pkgs.writeShellApplication {
        name = "llama-hf-download";

        runtimeInputs = [
          pkgs.coreutils
          pkgs.findutils
          pkgs.gnugrep
          pkgs.gawk
          pkgs.curl
          (pkgs.python3.withPackages (ps: [
            ps.huggingface-hub
          ]))
        ];

        text = ''
          set -euo pipefail

          if [ "$#" -ne 1 ]; then
            echo "Usage: llama-hf-download OWNER/REPOSITORY" >&2
            exit 2
          fi

          repo="$1"

          if [[ ! "$repo" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]]; then
            echo "Invalid repository name: $repo" >&2
            echo "Expected OWNER/REPOSITORY." >&2
            exit 2
          fi

          models_dir="${config.services.local-llm.modelsDir}"
          port="${toString config.services.local-llm.port}"
          model_name="''${repo//\//-}"
          destination="$models_dir/$model_name"

          if [ ! -d "$models_dir" ] || [ ! -w "$models_dir" ]; then
            echo "Cannot write to $models_dir." >&2
            echo "Check your membership in the llama group and log in again." >&2
            exit 1
          fi

          if [ -e "$destination" ]; then
            echo "Destination already exists: $destination" >&2
            echo "Move or remove it before downloading this repository again." >&2
            exit 1
          fi

          stage="$(mktemp -d "$models_dir/.staging-XXXXXX")"
          published=0

          cleanup() {
            if [ "$published" -eq 0 ] && [ -d "$stage" ]; then
              rm -rf -- "$stage"
            fi
          }
          trap cleanup EXIT

          selector="$stage/.llama-hf-selector.py"

          cat > "$selector" <<'PY'
          import os
          import re
          import sys
          from pathlib import Path
          from huggingface_hub import HfApi, snapshot_download

          repo = os.environ["LLAMA_HF_REPO"]
          stage = Path(os.environ["LLAMA_HF_STAGE"])

          quant_re = re.compile(
              r"(?i)(?:^|[-_.])(UD-)?"
              r"(IQ\d+_[A-Z0-9]+|Q\d+_[A-Z0-9]+|BF16|F16|F32)"
              r"(?=(?:-\d{5}-of-\d{5})?\.gguf$)"
          )

          try:
              api = HfApi()
              entries = api.list_repo_tree(
                  repo_id=repo,
                  recursive=True,
                  expand=True,
              )

              files = [
                  entry for entry in entries
                  if getattr(entry, "path", "").lower().endswith(".gguf")
                  and getattr(entry, "size", None) is not None
              ]

              if not files:
                  sys.exit("No GGUF files with known sizes were found.")

              groups = {}

              for entry in files:
                  match = quant_re.search(entry.path)
                  if not match:
                      continue

                  prefix = "UD-" if match.group(1) else ""
                  quant = prefix + match.group(2).upper()
                  groups.setdefault(quant, []).append(entry)

              if not groups:
                  sys.exit(
                      "No recognizable quantizations were found in GGUF filenames."
                  )

              choices = []

              print(f"\nRepository: {repo}\n")
              print("Available quantizations:\n")

              for quant in sorted(groups):
                  members = groups[quant]
                  total_bytes = sum(member.size for member in members)
                  gib = total_bytes / (1024 ** 3)
                  print(
                      f"{len(choices) + 1:>2}. {quant:<12} "
                      f"{gib:8.2f} GiB  ({len(members)} file(s))"
                  )
                  choices.append((quant, members))

              print()
              while True:
                  answer = input("Choose a quantization number: ").strip()
                  if answer.isdigit() and 1 <= int(answer) <= len(choices):
                      break
                  print("Enter one of the listed numbers.")

              quant, members = choices[int(answer) - 1]

              print(f"\nSelected: {quant}")
              print("Files to download:")
              for member in members:
                  print(f"  {member.path}")

              total_bytes = sum(member.size for member in members)
              print(f"\nTotal: {total_bytes / (1024 ** 3):.2f} GiB")

              confirm = input("Download these files? [y/N] ").strip().lower()
              if confirm not in ("y", "yes"):
                  sys.exit("Cancelled.")

              patterns = [member.path for member in members]

              snapshot_download(
                  repo_id=repo,
                  allow_patterns=patterns,
                  local_dir=str(stage),
              )

              missing = [
                  member.path
                  for member in members
                  if not (stage / member.path).is_file()
                  or (stage / member.path).stat().st_size == 0
              ]

              if missing:
                  sys.exit(
                      "Download incomplete; missing or empty files:\n"
                      + "\n".join(missing)
                  )

              print(f"\nDownloaded {len(members)} file(s) successfully.")

          except KeyboardInterrupt:
              sys.exit("\nCancelled.")
          except Exception as exc:
              sys.exit(f"\nDownload failed: {exc}")
          PY

          export LLAMA_HF_REPO="$repo"
          export LLAMA_HF_STAGE="$stage"

          python "$selector"
          rm -f "$selector"

          if ! find "$stage" -type f -name '*.gguf' -print -quit | grep -q .; then
            echo "No GGUF files were downloaded." >&2
            exit 1
          fi

          # Use the caller's group access; do not change ownership to root
          # or the llama service account.
          find "$stage" -type d -exec chmod 2775 {} +
          find "$stage" -type f -exec chmod 0664 {} +

          if [ -e "$destination" ]; then
            echo "Destination appeared during download: $destination" >&2
            exit 1
          fi

          mv -- "$stage" "$destination"
          published=1

          echo
          echo "Model installed at: $destination"

          # Ask the router to reload its model list if this endpoint is
          # supported by the installed llama.cpp build.
          if curl --max-time 5 -fsS \
            "http://127.0.0.1:$port/models?reload=1"; then
            echo
            echo "Requested model-list reload."
          else
            echo
            echo "The download succeeded, but the router did not confirm a reload."
            echo "You may need to reload or restart the service separately."
          fi
        '';
      })
    ];

    users.groups.llama = {};

    users.users.llama = {
      isSystemUser = true;
      group = "llama";
      extraGroups = [ "render" "video" ];
    };

    users.users.${config.services.local-llm.user}.extraGroups = [ "llama" ];

    systemd.tmpfiles.rules = [
      "d ${config.services.local-llm.modelsDir} 2775 llama llama -"
    ];

    systemd.services.local-llm = {
      description = "llama.cpp Vulkan model router";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "simple";
        User = "llama";
        Group = "llama";
        SupplementaryGroups = [ "render" "video" ];
        WorkingDirectory = config.services.local-llm.modelsDir;
        Restart = "on-failure";
        RestartSec = "5s";
        StateDirectory = "llama-models";
        StateDirectoryMode = "2775";
        Environment = [
          "HOME=/var/lib/llama"
        ];
        EnvironmentFile = pkgs.writeText "local-llm-environment" (
          lib.concatStringsSep "\n" (
            lib.mapAttrsToList (name: value: "${name}=${value}")
              config.services.local-llm.environment
          )
        );
        ExecStart = lib.escapeShellArgs (
          [
            "${config.services.local-llm.package}/bin/llama-server"
            "--models-dir"
            config.services.local-llm.modelsDir
            "--models-max"
            (toString config.services.local-llm.maxLoadedModels)
            "--host"
            "0.0.0.0"
            "--port"
            (toString config.services.local-llm.port)
            "-ngl"
            (toString config.services.local-llm.gpuLayers)
            "--jinja"
          ]
          ++ lib.optionals (config.services.local-llm.contextSize != null) [
            "--ctx-size"
            (toString config.services.local-llm.contextSize)
          ]
          ++ config.services.local-llm.extraArgs
        );
      };
    };

    networking.firewall.interfaces."tailscale0".allowedTCPPorts =
      lib.mkIf config.services.local-llm.openTailscaleFirewall [
        config.services.local-llm.port
      ];
  };
}