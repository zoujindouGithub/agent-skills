# Restore this skill collection onto the current machine (Windows).
# Additive on purpose: never wipes ~/.codex/skills, because Codex owns the
# .system subtree there and recreates it on upgrade.
$ErrorActionPreference = "Stop"

$src    = Join-Path $PSScriptRoot "skills"
$agents = Join-Path $env:USERPROFILE ".agents\skills"
$codex  = Join-Path $env:USERPROFILE ".codex\skills"

if (-not (Test-Path $src)) { throw "skills/ not found next to this script" }

foreach ($target in @($agents, $codex)) {
    New-Item -ItemType Directory -Force -Path $target | Out-Null
    # /E copies subdirs incl. empties; deliberately no /MIR so .system survives.
    robocopy $src $target /E /NFL /NDL /NJH /NJS /NP /XF *.bak .DS_Store | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "robocopy failed with exit code $LASTEXITCODE -> $target" }
    Write-Host "restored -> $target"
}

Write-Host ""
Write-Host "Done. Restart omp / codex to pick up the skills."
