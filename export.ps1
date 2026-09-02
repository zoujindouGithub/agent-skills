# Re-collect local skills into this repo before committing (Windows).
# Merge rule (mirrors export.sh):
#   base  = ~/.agents/skills      (hand-edited copy; wins on conflict)
#   plus  = skill dirs only in ~/.codex/skills
#   skip  = $skipDirs (.system is Codex-managed; obs-prod-status is machine-private)
$ErrorActionPreference = "Stop"

$dest = Join-Path $PSScriptRoot "skills"
$agents = Join-Path $env:USERPROFILE ".agents\skills"
$codex  = Join-Path $env:USERPROFILE ".codex\skills"

# Fail closed: never publish an empty/partial collection.
$found = @($agents, $codex) | Where-Object {
    (Test-Path $_) -and (Get-ChildItem $_ -Recurse -Filter "SKILL.md" -File -ErrorAction SilentlyContinue | Select-Object -First 1)
}
if ($found.Count -eq 0) {
    throw "no SKILL.md under either root (agents: $agents | codex: $codex). Set `$env:USERPROFILE or run from the account that owns the skills."
}

if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
New-Item -ItemType Directory -Force -Path $dest | Out-Null

$skipExt = @(".bak")
# Dirs never published: .system is recreated by Codex; obs-prod-status holds
# private host aliases and ops scripts that must stay off GitHub.
$skipDirs = @(".system", "obs-prod-status")
function Import-Tree($from, $to) {
    Get-ChildItem $from -Recurse -File | Where-Object {
        $skipExt -notcontains $_.Extension -and $_.Name -ne ".DS_Store"
    } | ForEach-Object {
        $rel = $_.FullName.Substring($from.Length).TrimStart('\')
        $out = Join-Path $to $rel
        New-Item -ItemType Directory -Force -Path (Split-Path $out) | Out-Null
        Copy-Item $_.FullName $out -Force
    }
}

if (Test-Path $agents) {
    Get-ChildItem $agents -Directory | Where-Object { $skipDirs -notcontains $_.Name } | ForEach-Object {
        Import-Tree $_.FullName (Join-Path $dest $_.Name)
    }
}

$have = @{}
Get-ChildItem $dest -Directory | ForEach-Object { $have[$_.Name] = $true }

if (Test-Path $codex) {
    Get-ChildItem $codex -Directory | Where-Object { $skipDirs -notcontains $_.Name -and -not $have.ContainsKey($_.Name) } | ForEach-Object {
        Import-Tree $_.FullName (Join-Path $dest $_.Name)
        Write-Host "added from .codex: $($_.Name)"
    }
}

$n = (Get-ChildItem $dest -Directory).Count
Write-Host "collected $n skills into skills/"
