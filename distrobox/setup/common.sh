#!/usr/bin/env bash
# Shared helpers, sourced by android.sh / decky.sh.
#
# These run as ROOT inside the container, from distrobox `init_hooks`, on EVERY
# container start. So: idempotent, and near-instant when there is nothing to do.

log()  { printf '[setup] %s\n' "$*"; }
warn() { printf '[setup] WARN: %s\n' "$*" >&2; }

# resolve_user <container-home>
# distrobox creates the custom home owned by *you*, so learn uid/gid/name from
# it instead of hard-coding a username.
# shellcheck disable=SC2034  # USER_* are consumed by the scripts that source this file
resolve_user() {
  USER_HOME="$1"
  [ -d "$USER_HOME" ] || { warn "container home '$USER_HOME' does not exist"; return 1; }
  USER_UID=$(stat -c %u "$USER_HOME")
  USER_GID=$(stat -c %g "$USER_HOME")
  USER_NAME=$(getent passwd "$USER_UID" | cut -d: -f1)
  [ -n "$USER_NAME" ] || { warn "no passwd entry for uid $USER_UID"; return 1; }
}

# as_user <cmd...>: run as the container user with the custom HOME.
as_user() {
  runuser -u "$USER_NAME" -- env HOME="$USER_HOME" "$@"
}

# npm_global <binary> <package>: install a global npm package under /usr/local
# unless the binary already exists.
npm_global() {
  command -v "$1" >/dev/null 2>&1 && return 0
  log "npm: installing $2"
  npm install -g --prefix /usr/local --no-fund --no-audit "$2" || warn "failed to install $2"
}

# host_docker_access: the host's docker socket is bind-mounted by the .ini, but
# distrobox does not put you in the host's docker group. Make a group with the
# socket's gid and add the user to it.
host_docker_access() {
  local sock=/var/run/docker.sock gid grp
  [ -S "$sock" ] || { warn "no docker socket at $sock (volume missing from the .ini?)"; return 0; }
  gid=$(stat -c %g "$sock")
  [ "$gid" -eq 0 ] && return 0
  grp=$(getent group "$gid" | cut -d: -f1)
  if [ -z "$grp" ]; then
    grp=hostdocker
    groupadd -g "$gid" "$grp" || { warn "groupadd failed"; return 0; }
  fi
  id -nG "$USER_NAME" | tr ' ' '\n' | grep -qx "$grp" || usermod -aG "$grp" "$USER_NAME"
}
