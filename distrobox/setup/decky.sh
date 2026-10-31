#!/usr/bin/env bash
# Bootstrap for the `decky` (Ubuntu) box. Usage: decky.sh <container-home>
set -u
here=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=common.sh
. "$here/common.sh"

resolve_user "${1:?usage: decky.sh <container-home>}" || exit 0

# ---- knobs -------------------------------------------------------------------
NODE_MAJOR=24     # template only needs >=16.14; pi needs >=20.6
PNPM_MAJOR=9      # what the template README asks for. v10 reads the same v9 lockfile.
# ------------------------------------------------------------------------------

# 1. Node from nodejs.org (Ubuntu's apt node is ancient), checksum-verified.
node_major() { node --version 2>/dev/null | sed -E 's/^v([0-9]+).*/\1/'; }
if [ "$(node_major)" != "$NODE_MAJOR" ]; then
  log "installing Node $NODE_MAJOR"
  base="https://nodejs.org/dist/latest-v${NODE_MAJOR}.x"
  line=$(curl -fsSL "$base/SHASUMS256.txt" | grep -E ' node-v[0-9.]+-linux-x64\.tar\.xz$' | head -1)
  if [ -z "$line" ]; then
    warn "could not read Node release list (offline?). Will retry next start."
  else
    file=${line##* }
    tmp=$(mktemp -d)
    if curl -fsSL -o "$tmp/$file" "$base/$file" \
       && (cd "$tmp" && printf '%s\n' "$line" | sha256sum -c --quiet -); then
      tar -xJf "$tmp/$file" -C /usr/local --strip-components=1 \
        --exclude='*/CHANGELOG.md' --exclude='*/README.md' --exclude='*/LICENSE'
    else
      warn "Node download or checksum failed"
    fi
    rm -rf "$tmp"
  fi
fi

# 2. pnpm, pinned to what the template documents.
if command -v npm >/dev/null 2>&1 \
   && [ "$(pnpm --version 2>/dev/null | cut -d. -f1)" != "$PNPM_MAJOR" ]; then
  log "installing pnpm@$PNPM_MAJOR"
  npm install -g --prefix /usr/local --no-fund --no-audit "pnpm@$PNPM_MAJOR" || warn "pnpm install failed"
fi

# 3. docker CLI (static client only; the daemon is the host's, via the mounted socket).
#    The Decky CLI shells out to `docker` and pulls ghcr.io/steamdeckhomebrew/builder itself.
if ! command -v docker >/dev/null 2>&1; then
  log "installing docker CLI"
  tgz=$(curl -fsSL https://download.docker.com/linux/static/stable/x86_64/ \
        | grep -o 'docker-[0-9][0-9.]*\.tgz' | sort -uV | tail -1)
  if [ -n "$tgz" ]; then
    tmp=$(mktemp -d)
    if curl -fsSL -o "$tmp/$tgz" "https://download.docker.com/linux/static/stable/x86_64/$tgz" \
       && tar -xzf "$tmp/$tgz" -C "$tmp"; then
      install -m 0755 "$tmp/docker/docker" /usr/local/bin/docker
    else
      warn "docker CLI download failed"
    fi
    rm -rf "$tmp"
  else
    warn "could not find a docker CLI release (offline?)"
  fi
fi
host_docker_access

# 4. Ubuntu ships `fd` as `fdfind`.
[ -x /usr/bin/fdfind ] && ln -sf /usr/bin/fdfind /usr/local/bin/fd

# 5. pi
npm_global pi @mariozechner/pi-coding-agent

log "decky box ready"
