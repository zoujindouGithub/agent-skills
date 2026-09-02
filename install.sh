#!/usr/bin/env bash
# Restore this skill collection onto the current machine (Linux / macOS).
# Additive: never wipes ~/.codex/skills, Codex owns the .system subtree there.
set -euo pipefail

src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/skills"
[ -d "$src" ] || { echo "skills/ not found next to this script" >&2; exit 1; }

for target in "$HOME/.agents/skills" "$HOME/.codex/skills"; do
  mkdir -p "$target"
  # no --delete: keep whatever the host tool manages itself (e.g. .system)
  cp -R "$src/." "$target/"
  echo "restored -> $target"
done

echo
echo "Done. Restart omp / codex to pick up the skills."
