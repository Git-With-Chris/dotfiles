# Windows setup

Unlike macOS and Linux there is no Stow here, so nothing is symlinked — these
files are the source of truth and get **copied** into place.

## Where each file goes

| Repo file | Destination |
|---|---|
| `windows/Microsoft.PowerShell_profile.ps1` | `$PROFILE` — check with `echo $PROFILE`, it may be under OneDrive |
| `windows/lazygit-config.yml` | `%APPDATA%\lazygit\config.yml` |
| `windows/apply-rstudio-terminal.ps1` | anywhere; run it with RStudio closed |
| `wezterm/.config/wezterm/wezterm.lua` | `%USERPROFILE%\.wezterm.lua` |
| `starship/.config/starship/starship.toml` | referenced in place via `$env:STARSHIP_CONFIG` |
| `rstudio/.config/rstudio/themes/*.rstheme` | `%APPDATA%\RStudio\themes\` |
| `R/.Rprofile` | `~` as R sees it — `Rscript -e 'cat(path.expand("~"))'` |

`$PROFILE` and R's `~` both point into OneDrive on a redirected-Documents
machine, which is why neither is guessed above.

## Prerequisites

PowerShell 7 as a **real binary**, not the Store app-execution alias — the alias
in `WindowsApps` is a 0-byte reparse stub that RStudio cannot attach to a
terminal pty. The portable zip extracted to `~\Tools\PowerShell\` works.

Tools, all user-scope (no admin):

```powershell
winget install --scope user eza-community.eza sharkdp.bat ajeetdsouza.zoxide `
                            junegunn.fzf sharkdp.fd JesseDuffield.lazygit Posit.Air
```

Plus starship.exe in `~\Tools\Starship\` and JetBrainsMono Nerd Font installed
per-user (`%LOCALAPPDATA%\Microsoft\Windows\Fonts` + an `HKCU` Fonts entry).

## RStudio

`apply-rstudio-terminal.ps1` waits for RStudio to close, then merges its
preferences: pwsh as the terminal shell, RPC instead of websockets, the
Catppuccin theme and Air as the formatter. Run it with RStudio closed — RStudio
rewrites `rstudio-prefs.json` on exit and will otherwise clobber the changes.

## Why the prompt avoids truecolor

RStudio's terminal quantises 24-bit colour to the 16 ANSI slots, so
`starship.toml` uses ANSI colour names and the `.rstheme` maps those slots to
Catppuccin. Slots 8, 11 and 13 are repurposed for overlay1, peach and mauve,
which plain ANSI has no equivalent for. WezTerm's `config.colors` pins the same
16 values so both terminals render identically.
