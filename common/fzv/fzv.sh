#!/usr/bin/env bash
# fzv — fuzzy-find with ripgrep + fzf, open the pick in vi.
#
#   fzv [DIR]        live-search file CONTENTS under DIR (default: .)
#                    and open vi at the matching line
#   fzv -f [DIR]     fuzzy-search file NAMES under DIR and open in vi
#
# Editor defaults to vi; override with FZV_EDITOR=nvim (or whatever).
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: fzv [-f] [DIR]
  (no flag)  search file contents, open vi at the matching line
  -f         search file names, open the file in vi
  -h         show this help
Env: FZV_EDITOR  editor to use (default: vi)
USAGE
}

mode=content
while getopts ":fh" opt; do
  case "$opt" in
    f) mode=files ;;
    h) usage; exit 0 ;;
    *) usage >&2; exit 1 ;;
  esac
done
shift $((OPTIND - 1))

dir="${1:-.}"
cd "$dir"

editor="${FZV_EDITOR:-vi}"
command -v "$editor" >/dev/null 2>&1 || editor=vim

# Hidden files included, .git excluded; .gitignore is still respected.
rg_base="rg --hidden --glob '!.git'"

if [[ "$mode" == files ]]; then
  if command -v bat >/dev/null 2>&1; then
    preview='bat --color=always --style=numbers {}'
  else
    preview='head -200 {}'
  fi

  file="$(eval "$rg_base --files" | fzf \
    --prompt 'files> ' \
    --preview "$preview" \
    --preview-window 'right,60%,border-left')" || exit 0

  exec "$editor" "$file"
fi

# Content mode: fzf is just the input box; ripgrep reruns on every keystroke.
rg_cmd="$rg_base --column --line-number --no-heading --color=always --smart-case --"

if command -v bat >/dev/null 2>&1; then
  preview='bat --color=always --style=numbers --highlight-line {2} {1}'
else
  preview='nl -ba {1}'
fi

selected="$(fzf \
  --ansi --disabled \
  --prompt 'rg> ' \
  --delimiter : \
  --bind "change:reload:sleep 0.1; [ -n {q} ] && $rg_cmd {q} || true" \
  --preview "$preview" \
  --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
  < /dev/null)" || exit 0

IFS=: read -r file line _ <<<"$selected"
exec "$editor" "+$line" "$file"
