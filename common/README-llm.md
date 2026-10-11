# local-llm: llama.cpp router service

Module: `common/llm.nix` (option namespace `services.local-llm`).
Imported by every host in `flake.nix` that wants local inference.

This file is for a future you, or a future LLM, picking this up cold. It records
what the service is, why it looks the way it does, and what has and hasn't been
verified.

## What it is

A single systemd service running `llama-server` from llama.cpp in **router mode**,
built with **Vulkan**.

- Router mode means `llama-server` is started **without** `--model`. It scans a directory of GGUF files and loads/unloads models on demand. Passing `--model` silently switches it to single-model mode, which defeats the purpose.
- Vulkan means one package works on Intel iGPUs (`anv`) and AMD GPUs (`radv`) with no per-host forks.
- It listens on `0.0.0.0:8080`, but the firewall only opens that port on `tailscale0`, and only when Tailscale is enabled on the host. Reachable from localhost and the tailnet, nothing else. The module never enables Tailscale itself; that is managed elsewhere.
- API is OpenAI-compatible under `/v1` (e.g. `/v1/models`, `/v1/chat/completions`).

## Hosts

| Host            | Hardware                                        | Role                                                                  |
| --------------- | ----------------------------------------------- | --------------------------------------------------------------------- |
| `craftingtable` | AMD CPU, 32 GB RAM, Radeon 7700XT (12 GiB VRAM) | Runs the module                                                       |
| `commandblock`  | Intel laptop, integrated GPU, 32 GB shared RAM  | Runs the module                                                       |
| `shulker`       | TrueNAS tower                                   | **Not managed here.** Configured elsewhere. Runs Ollama on port 11435 |

Shulker is not covered by this module. Pi talks to it as a plain OpenAI-compatible
endpoint with a hand-written model list (see "Pi" below).

## Enabling it on a host

```nix
services.local-llm = {
  enable = true;
  user = "pj";   # gets write access to the models directory
};

```

That's the whole minimum. Everything else has a default.

## Options

| Option                  | Default                            | Notes                                                                                                                   |
| ----------------------- | ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `enable`                | `false`                            |                                                                                                                         |
| `user`                  | none (required)                    | Added to the `llama` group so they can write models without sudo                                                        |
| `package`               | `pkgs.llama-cpp-vulkan`            | Needs a llama.cpp build with router mode                                                                                |
| `port`                  | `8080`                             | llama.cpp default. Pi `baseUrl`s must match                                                                             |
| `modelsDir`             | `/var/lib/llama-models`            | Shared with the `llama` group; should be group-writable                                                                                           |
| `maxLoadedModels`       | `1`                                | Models kept in memory at once. Raise per host only with spare VRAM/RAM                                                  |
| `contextSize`           | `32768`                            | Per loaded model. `null` = each model's native context (can exhaust memory)                                             |
| `gpuLayers`             | `999`                              | "As many as fit"                                                                                                        |
| `openTailscaleFirewall` | `config.services.tailscale.enable` | Opens the port on `tailscale0` only. On by default whenever Tailscale is enabled. Set `false` to keep it localhost-only |
| `environment`           | `{ }`                              | Extra service env, e.g. `GGML_VK_VISIBLE_DEVICES`                                                                       |
| `extraArgs`             | `[ ]`                              | Extra `llama-server` flags, appended last so they win                                                                   |

Per-host overrides live in the host's own config, not in the module. Examples:

```nix
# craftingtable: bigger context, pick the discrete GPU
services.local-llm.contextSize = 65536;
services.local-llm.environment.GGML_VK_VISIBLE_DEVICES = "0"; # check index first

```

Pick the GPU index from `vulkaninfo --summary`. If the Ryzen has an iGPU, index 0
may not be the 7700XT.

## Adding models

Models are plain GGUF files stored under `modelsDir` (default:
`/var/lib/llama-models`). Nix does not fetch or pin model weights.

### Download from Hugging Face with `llama-hf-download`

The module installs a `llama-hf-download` helper. Run it as your normal login
user, passing a Hugging Face repository ID:

```sh
llama-hf-download OWNER/REPOSITORY
```

The helper:

1. Lists the repository's GGUF files and groups recognizable filenames by
   quantization (for example, `Q4_K_M`, `Q5_K_M`, `Q8_0`, or `IQ4_XS`).
2. Shows each quantization's estimated total size in GiB and the number of files.
3. Prompts you to choose a quantization and confirms before downloading.
4. Downloads every GGUF file it identified for that quantization, including
   split/sharded files, into a staging directory.
5. Checks that the selected files exist and are non-empty, then moves the
   download into a repository-named directory under `modelsDir`.

For example, repository `OWNER/REPOSITORY` is installed at:

```text
/var/lib/llama-models/OWNER-REPOSITORY/
```

The helper requires network access to Hugging Face. Private or gated repositories
may also require a Hugging Face token configured for the account running the
command. Quantization detection depends on filenames; repositories with unusual
GGUF naming may not be recognized correctly.

### Permissions

The login user configured by `services.local-llm.user` is added to the `llama`
group. The model directory should be group-writable and have the setgid bit set
(mode `2775`), so new files and directories inherit the `llama` group.

After changing group membership, log out and back in, then verify it with:

```sh
id
test -w /var/lib/llama-models && echo "model directory is writable"
```

The helper does not need `sudo` to download and install files. It must be run by
a user who has write permission to `modelsDir`. Do not make the model directory
world-writable as a workaround.

### Loading newly downloaded models

After installation, the helper tries the configured server's
`/models?reload=1` endpoint. Not every llama.cpp build supports that exact
reload endpoint. If the server does not confirm the request, the model files
are still installed, but you may need to reload the model list using a method
supported by your build or restart the service through your normal
administrator workflow.

For manually added files, use the same group permissions and reload/restart
procedure. Do not assume a file appearing on disk means every router build
will immediately discover it.

## Checking that it works

```
systemctl status local-llm
journalctl -u local-llm -f
curl localhost:8080/health
curl localhost:8080/v1/models

```

GPU visibility, including from the service's own account:

```
vulkaninfo --summary
sudo -u llama vulkaninfo --summary

```

If the second command fails while the first works, the `llama` user lacks access
to `/dev/dri` (it should be in `render` and `video`).

Reaching a remote host over Tailscale:

```
curl http://<host>.end-ulmer.ts.net:8080/v1/models

```

## Security model

- Binds `0.0.0.0`, but the port is opened **only** on `tailscale0` via `networking.firewall.interfaces."tailscale0".allowedTCPPorts`, and only when `openTailscaleFirewall` is true (default: Tailscale is enabled on the host).
- The module does **not** enable Tailscale. If a host has it off, the service is localhost-only.
- It is deliberately **not** in `networking.firewall.allowedTCPPorts`, which would open it on every interface including the LAN.
- A module assertion fails the build if `networking.firewall.enable` is false, because with no firewall the bind address exposes the whole LAN.
- No API key is configured. Anyone on the tailnet can use it. Add `--api-key` through `extraArgs` if that stops being acceptable.
- Service runs as the `llama` system user with `ProtectSystem=strict`, `ProtectHome=true`, `NoNewPrivileges`, and write access only to `modelsDir`.
- `llama-hf-download` is intended to run as the logged-in user with `llama` group write access; it should not use `sudo` or change model ownership to root.

## Design decisions (so nobody relitigates them)

- **Not vLLM.** It targets CUDA/ROCm, wants to own the GPU and preload one model, and has no useful Vulkan or Intel iGPU path. Wrong tool for this fleet.
- **Not Ollama.** Replaced for better multi-model handling, tighter control over Vulkan and context, and a first-class integration with Pi. Shulker still runs Ollama independently.
- **Models are not declared in Nix.** Pinning multi-GB GGUFs by hash is painful and the user chose a plain directory instead.
- **Default context is explicit (32768), not auto.** Omitting `-c` makes each model use its native context, which can be huge. Set `contextSize = null` to opt in.
- **One model loaded by default.** A 12 GiB GPU and a shared-memory laptop both prefer a few seconds of swap over an out-of-memory failure.
- **Tailscale is managed elsewhere.** The module only reacts to it: the firewall rule follows `config.services.tailscale.enable` unless overridden.
- **No `let ... in`.** The author finds it hard to parse. Options are read as `config.services.local-llm.<name>` throughout. Keep it that way.

## Pi (the coding agent)

Pi is the client. Findings from its docs:

- Pi has a **built-in llama.cpp integration** for **one** router: `/login llama.cpp` or env `LLAMA_BASE_URL` / `LLAMA_API_KEY`. `/llama` loads, unloads, and downloads models; `/model` selects one.
- For Ollama, vLLM, and other compatible servers (like shulker), Pi needs an explicit `models` array in `models.json`. There is no discovery there.
- Pi reloads `models.json` each time `/model` opens.
- Seeing several hosts' routers in one `/model` list is **not** covered by the built-in integration. The community extension **`pi-llama-cpp`** (MIT, no runtime dependencies, install with `pi install npm:pi-llama-cpp`) adds multi-server support. Servers go in `llamaSettings.servers` in `~/.pi/agent/settings.json` or a semicolon-separated `LLAMA_SERVER_URL`.

The source of `pi-llama-cpp` was read at version 0.16.0. It only contacts the URLs
you configure, runs a shell command only for API keys prefixed with `!`, and writes
only its own key in `settings.json`. That was a grep-based scan plus a read of the
sensitive files, not a full line-by-line audit.

### Status

**Pi is not migrated yet.** The server module comes first, and the Pi side is to be
tested manually before committing to the extension. Pi `baseUrl`s for
craftingtable and commandblock need to move from `:11434` to `:8080`.

Open questions to verify when testing:

- Does `pi-llama-cpp` conflict with the built-in llama.cpp provider if both point at the same router?
- Does `/model` show per-model context windows from the extension?
- How cleanly does `pi install` fit a Nix-managed Pi config?
- The extension edits `settings.json` through its TUI. If Nix makes that file read-only, the editor can't save. Plan: Nix owns the config, the editor is view-only.

### Editing config files without rebuilding

Nix cannot auto-refresh the store when a flake file is saved. `./file` is copied
into the store at build time. To link to a live file instead, use home-manager's:

```nix
config.lib.file.mkOutOfStoreSymlink "/home/pj/nix/common/pi/settings.json"

```

It needs an absolute path string, not `./`. Pi's `configDir` already uses this
approach.

## Unverified at time of writing

The module was written but **not built or run**. These were taken from memory or
docs and should be checked first if something breaks:

1. `pkgs.llama-cpp-vulkan` exists in the pinned nixpkgs. If not, use `pkgs.llama-cpp.override { vulkanSupport = true; }` as the `package` default.
2. `llama-server --help` lists `--models-dir` and `--models-max`.
3. The `llama` user can use the GPU (`sudo -u llama vulkaninfo --summary`).
4. `ProtectSystem=strict` with write access only to `modelsDir` may be too tight if llama.cpp wants a cache directory. Symptoms show up in `journalctl -u local-llm` when downloading with `-hf`.

## Cleanup history

Before this module there were three files all defining `services.local-llm`: an
Ollama (Vulkan) module, a llama.cpp module, and a `vllm` package stub. Only one could
be live. They were replaced by `common/llm.nix`; the others should stay deleted.
The old host config also set `OLLAMA_*` variables, which do nothing now.