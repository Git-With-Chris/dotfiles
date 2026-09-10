<#
    Points the RStudio Terminal tab at pwsh + starship (same shell as WezTerm)
    and turns off the websocket transport that makes the terminal freeze.

    RUN THIS WITH RSTUDIO CLOSED - RStudio rewrites rstudio-prefs.json on exit
    and will clobber the changes otherwise.
#>

$ErrorActionPreference = 'Stop'

# RStudio reads prefs at startup and writes them back on exit, so applying
# changes while it runs achieves nothing and can be clobbered. Wait it out
# rather than racing it.
if (Get-Process rstudio -ErrorAction SilentlyContinue) {
    Write-Host 'RStudio is running. Close it now - waiting up to 3 minutes...' -ForegroundColor Yellow
    $deadline = (Get-Date).AddMinutes(3)
    while (Get-Process rstudio -ErrorAction SilentlyContinue) {
        if ((Get-Date) -gt $deadline) { Write-Error 'Timed out waiting for RStudio to close.' }
        Start-Sleep -Milliseconds 500
    }
    Write-Host 'RStudio closed.' -ForegroundColor Green
}

# It writes prefs during shutdown; let that finish before we overwrite them.
Start-Sleep -Seconds 3

$prefs = Join-Path $env:APPDATA 'RStudio\rstudio-prefs.json'

# Portable PowerShell 7 kept under Tools\, alongside starship.exe.
# Deliberately NOT %LOCALAPPDATA%\Microsoft\WindowsApps\pwsh.exe - that is a
# 0-byte app-execution reparse stub, not a real executable, so RStudio cannot
# attach it to the terminal pty and silently falls back to Git Bash.
$pwshPath = Join-Path $HOME 'Tools\PowerShell\pwsh.exe'

if (-not (Test-Path $pwshPath)) { Write-Error "pwsh not found at $pwshPath" }

$themeFile = Join-Path $env:APPDATA 'RStudio\themes\catppuccin-mocha.rstheme'
if (-not (Test-Path $themeFile)) { Write-Error "theme not found at $themeFile" }

Copy-Item $prefs "$prefs.bak" -Force
Write-Host "Backup written to $prefs.bak"

$json = Get-Content $prefs -Raw | ConvertFrom-Json

$settings = @{
    # Terminal tab runs pwsh -NoLogo, so the PowerShell profile (starship) loads.
    windows_terminal_shell = 'custom'
    custom_shell_command   = $pwshPath
    custom_shell_options   = '-NoLogo'

    # Terminal I/O over RPC instead of a local websocket. The websocket is what
    # gets torn down mid-session, leaving a dead terminal you have to recreate.
    terminal_websockets    = $false

    # Don't nag "terminal is busy" when a TUI like lazygit is in the foreground.
    busy_exclusion_list    = @('tmux', 'screen', 'lazygit')

    # Tested: dom did NOT restore 24-bit colour (RStudio quantises to 16 either
    # way) and it renders box-drawing characters with visible seams, which makes
    # TUIs like lazygit look broken. canvas is the better trade.
    terminal_renderer      = 'canvas'

    # Catppuccin Mocha - same palette as WezTerm and the starship prompt.
    # Theme file: %APPDATA%/RStudio/themes/catppuccin-mocha.rstheme
    editor_theme           = 'catppuccin-mocha'

    # Air - Posit's Rust R formatter (winget: Posit.Air). RStudio pipes the
    # buffer to this command's stdin and reads the result from stdout;
    # --stdin-file-path is what switches Air into that mode. The filename is
    # only used to pick the language, so a placeholder is fine.
    code_formatter                  = 'external'
    code_formatter_external_command = 'air format --stdin-file-path file.R'

    # In a project that has an air.toml, use that project's own Air settings
    # instead of the command above, so per-project config is honoured.
    use_air_formatter               = $true
}

foreach ($k in $settings.Keys) {
    $json | Add-Member -NotePropertyName $k -NotePropertyValue $settings[$k] -Force
}

$json | ConvertTo-Json -Depth 20 | Set-Content $prefs -Encoding utf8

Write-Host "`nApplied:" -ForegroundColor Green
$settings.Keys | Sort-Object | ForEach-Object { "  {0,-24} = {1}" -f $_, ($settings[$_] -join ',') }
Write-Host "`nStart RStudio and open a NEW Terminal tab (Alt+Shift+T)."
