# agent-skills

Personal [SKILL.md](https://agentskills.io)-style skill collection for `omp` / Codex / Claude Code — 40 skills, synced across machines.

## Layout

```
skills/<name>/SKILL.md   # one directory per skill
install.ps1 / install.sh # restore this machine from the repo
export.ps1 / export.sh   # re-collect this machine's skills into the repo
```

Skills are read from two roots by the host tools:

| Root | Read by |
| :-- | :-- |
| `~/.agents/skills` | omp (primary, cross-agent) |
| `~/.codex/skills` | Codex (omp reads it too) |

`install.*` writes both roots. It is **additive** — it never deletes, so the
Codex-managed `~/.codex/skills/.system` subtree survives untouched.

## Restore on a new machine

```bash
git clone git@github.com:<your-user>/agent-skills.git
cd agent-skills

# Windows (PowerShell)
./install.ps1

# Linux / macOS
./install.sh
```

Restart `omp` / Codex afterwards. If you only run omp, `~/.agents/skills` is the
root that matters.

## Publish changes back

Edit skills in `~/.agents/skills` (omp's root), then:

```bash
./export.ps1    # or ./export.sh
git add -A && git commit -m "skills: update" && git push
```

`export.*` merges with a fixed precedence: `~/.agents/skills` wins on conflict,
plus any skill that exists only under `~/.codex/skills`. `*.bak` is dropped and
the `SKIP_DIRS` list (`.system`, `obs-prod-status`) is never collected. Both
scripts abort if the resolved roots hold no `SKILL.md`, so a misconfigured
`$HOME` can never publish an empty collection.

## Notes

- `obs-prod-status` (references private host aliases + ops scripts) is
  deliberately **not** synced. Keep this repo **private** anyway: skill names
  and edit history reveal internal tooling.
- No credentials live here; secrets stay in `~/.omp/agent/.env` and `~/.ssh/`,
  both gitignored.
