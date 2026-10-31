# distrobox/ — Android (Arch) + Decky (Ubuntu) dev boxes

```
distrobox/
├── distrobox.ini        # the two boxes
└── setup/
    ├── common.sh
    ├── android.sh       # Android SDK bootstrap
    └── decky.sh         # Node, pnpm 9, docker CLI
```

## Create

```sh
distrobox assemble create --file ~/nix/distrobox/distrobox.ini            # both
distrobox assemble create --file ~/nix/distrobox/distrobox.ini --name decky
```

`start_now=true`, so creation also runs the setup scripts (first run downloads
a lot: the SDK, Node, images). Watch for `[setup] ... ready`.

Rebuild one from scratch: add `--replace --name android`.
Delete: `distrobox assemble rm --file ~/nix/distrobox/distrobox.ini`.

## Use

```sh
cd ~/dev/my-app && distrobox enter android
cd ~/dev/my-plugin && distrobox enter decky
```

Keep projects under your real home (`~/dev/...`). Every path is identical
inside and out, which is also what lets the Decky CLI's docker mounts work.

## What `home=` does and doesn't do

Each box gets its own `$HOME` (`~/.local/share/distrobox/<name>`): its own
shell history, caches, Gradle, pnpm store, VS Code server, SDK. It is **not**
a security boundary: distrobox still mounts your real home at its real path,
and `/dev`, `/tmp`, the network and the process namespace are shared.

## Android

- JDK 17, SDK platform 35, build-tools 35.0.0, platform-tools, in
  `~/.local/share/distrobox/android/Android/Sdk`. Bump the knobs at the top of
  `setup/android.sh` and restart the box; it's idempotent.
- `sdkmanager`, `avdmanager`, `adb`, `fastboot` are symlinked into
  `/usr/local/bin`, so they work in any shell kind. There is exactly one adb
  (the SDK's) on purpose; AGP's `installDebug` uses it.
- Phone over USB: `adb devices` inside the box. Don't also run an adb server
  on the host.
- No emulator, no Android Studio. Add `sdkmanager "emulator" "system-images;..."`
  yourself if you want one.

## Decky

- Ubuntu 24.04, Node 24 (nodejs.org tarball, checksum verified), pnpm 9 (what
  the template README asks for; v10 reads the same lockfile), static docker CLI.
- The host docker socket is mounted and your user is added to a group with its
  gid. The Decky CLI shells out to `docker` and pulls
  `ghcr.io/steamdeckhomebrew/builder` itself on first backend build.
- The template's `.vscode/defsettings.json` points `deckkey` at
  `${env:HOME}/.ssh/id_rsa`. Inside the box `$HOME` is the box's home, so use
  your ssh-agent or point it at `/home/pj/.ssh/<key>`.
- The template's `setup.sh` downloads the `decky` CLI into each project's `cli/`.

## VS Code

Install the Dev Containers extension (Microsoft's build only, not VSCodium),
then "Dev Containers: Attach to Running Container...". Run
"Dev Containers: Open Container Configuration File" and set the user, or you'll
be root:

```json
{ "remoteUser": "pj" }
```

The VS Code server then lives in the box's home, and `JAVA_HOME`/`ANDROID_HOME`
are baked into the container, so the Java/Kotlin extensions find them.
For Decky you can also edit on the host and only build in the box.

## pi

Install in both boxes (`@mariozechner/pi-coding-agent`). Run it **inside** the
box so its shell tool uses the box's toolchain, not NixOS's. `PI_CODING_AGENT_DIR`
points at `/home/pj/nix/common/pi/agent`, so models/skills/auth are shared with
the host. Network is shared, so your local llama endpoint just works.

## Gotchas

- Hooks have the repo path (`/home/pj/nix/...`) and username hard-coded in the
  .ini. If the repo moves, hooks fail quietly each start.
- `pull=true` only matters at create time. Arch is rolling; `--replace` to refresh.
- Hook scripts download from dl.google.com, nodejs.org, download.docker.com.
  Offline start: they warn and retry next time.
