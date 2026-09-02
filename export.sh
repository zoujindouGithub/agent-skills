#!/usr/bin/env bash
# Re-collect local skills into this repo before committing (Linux / macOS).
#
# Merge rule (mirrors export.ps1):
#   base  = <home>/.agents/skills   (hand-edited copy; wins on conflict)
#   plus  = skill dirs only in <home>/.codex/skills
#   skip  = SKIP_DIRS (.system is Codex-managed; obs-prod-status is machine-private)
#
# Home resolution: $SKILLS_HOME wins, else $HOME. Some shells (Git Bash child
# processes) resolve $HOME to a phantom MSYS home that no agent tool reads, so
# the roots are verified and this script aborts rather than publishing an
# empty/partial collection.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dest="$repo/skills"
home="${SKILLS_HOME:-${HOME:-}}"
agents="$home/.agents/skills"
codex="$home/.codex/skills"

# Space-padded so the substring test below matches whole names only.
SKIP_DIRS=" .system obs-prod-status "

[ -n "$home" ] || { echo "ERROR: no home dir; set SKILLS_HOME=/path/to/profile" >&2; exit 1; }

found=0
for root in "$agents" "$codex"; do
  [ -d "$root" ] || continue
  if find "$root" -mindepth 2 -maxdepth 3 -name SKILL.md -print -quit | grep -q .; then
    found=$((found + 1))
  fi
done
if [ "$found" -eq 0 ]; then
  echo "ERROR: no SKILL.md under either root (resolved home: $home)" >&2
  echo "       Agents-side: $agents" >&2
  echo "       Codex-side : $codex" >&2
  echo "       Re-run with an explicit home, e.g. SKILLS_HOME=/c/Users/you ./export.sh" >&2
  exit 1
fi

rm -rf "$dest"
mkdir -p "$dest"

collect_from() { # $1 = dir to walk, $2 = dest subdir
  (cd "$1" && find . -type f ! -name '*.bak' ! -name '.DS_Store' -print0 |
    while IFS= read -r -d '' f; do
      mkdir -p "$2/$(dirname "$f")"
      cp "$f" "$2/$f"
    done)
}

if [ -d "$agents" ]; then
  for d in "$agents"/*/; do
    [ -d "$d" ] || continue
    name="$(basename "$d")"
    case "$SKIP_DIRS" in *" $name "*) continue ;; esac
    mkdir -p "$dest/$name"
    collect_from "$d" "$dest/$name"
  done
fi

if [ -d "$codex" ]; then
  for d in "$codex"/*/; do
    [ -d "$d" ] || continue
    name="$(basename "$d")"
    case "$SKIP_DIRS" in *" $name "*) continue ;; esac
    [ -d "$dest/$name" ] && continue
    mkdir -p "$dest/$name"
    collect_from "$d" "$dest/$name"
    echo "added from .codex: $name"
  done
fi

n=$(find "$dest" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
m=$(find "$dest" -type f | wc -l | tr -d ' ')
echo "home=$home"
echo "collected $n skills / $m files into skills/"
