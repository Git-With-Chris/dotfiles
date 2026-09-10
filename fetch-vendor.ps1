<#
.SYNOPSIS
  Download the Linux binaries listed in bootstrap/manifest.txt into
  bootstrap/vendor/, so install-linux.sh can run on a server with no internet.

.DESCRIPTION
  Run this HERE (on Windows), then copy the whole repo to the server - or just
  bootstrap/vendor/ if the repo is already cloned there - and run:

      ./install-linux.sh --offline

  Downloads only what is missing, so it is cheap to re-run.

.PARAMETER Force
  Re-download assets that are already present.
#>
[CmdletBinding()]
param([switch]$Force)

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

$repo     = $PSScriptRoot
$manifest = Join-Path $repo 'bootstrap\manifest.txt'
$vendor   = Join-Path $repo 'bootstrap\vendor'

if (-not (Test-Path $manifest)) { Write-Error "manifest not found: $manifest" }
New-Item -ItemType Directory -Force -Path $vendor | Out-Null

$entries = Get-Content $manifest |
  Where-Object { $_.Trim() -and -not $_.TrimStart().StartsWith('#') } |
  ForEach-Object {
    $f = $_ -split '\|'
    if ($f.Count -ne 4) { Write-Warning "skipping malformed line: $_"; return }
    [pscustomobject]@{ Name = $f[0]; Version = $f[1]; Asset = $f[2]; Url = $f[3] }
  }

Write-Host "`nFetching $($entries.Count) Linux assets into bootstrap/vendor/`n"

$failed = 0
foreach ($e in $entries) {
  $dest = Join-Path $vendor $e.Asset
  if ((Test-Path $dest) -and -not $Force) {
    $mb = '{0:N1} MB' -f ((Get-Item $dest).Length / 1MB)
    Write-Host ("  --   {0,-9} {1,-9} already present ({2})" -f $e.Name, $e.Version, $mb)
    continue
  }
  try {
    Invoke-WebRequest -Uri $e.Url -OutFile $dest -TimeoutSec 180
    $mb = '{0:N1} MB' -f ((Get-Item $dest).Length / 1MB)
    Write-Host ("  ok   {0,-9} {1,-9} {2}" -f $e.Name, $e.Version, $mb) -ForegroundColor Green
  } catch {
    Write-Host ("  FAIL {0,-9} {1,-9} {2}" -f $e.Name, $e.Version, $_.Exception.Message) -ForegroundColor Red
    if (Test-Path $dest) { Remove-Item $dest -Force }
    $failed++
  }
}

$total = (Get-ChildItem $vendor -File -Filter '*.tar.gz' -EA Ignore |
          Measure-Object Length -Sum).Sum
Write-Host ("`nvendor/ now holds {0:N1} MB" -f ($total / 1MB))

if ($failed) {
  Write-Host "$failed asset(s) failed - re-run to retry just those." -ForegroundColor Yellow
  exit 1
}
Write-Host @"

Next: copy this repo (or just bootstrap/vendor/) to the server, then run

    ./install-linux.sh --offline
"@
