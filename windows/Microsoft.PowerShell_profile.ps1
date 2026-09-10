# PowerShell profile - Windows counterpart to ~/Tools/dotfiles/zsh/.
# Every block is guarded, so a missing tool degrades quietly instead of
# throwing an error on every new terminal.

# ── Terminal capabilities ───────────────────────────────────────────────────
# COLORTERM=truecolor is deliberately NOT set. Starship emits 24-bit colour
# regardless of it (verified), so it bought nothing there - but it tells every
# other TUI that 24-bit is safe, which is a lie in RStudio: RStudio quantises
# truecolor down to 16 slots, so the app's own RGB values replace the theme.

# tcell (which lazygit is built on) converts its named colours to hardcoded RGB
# when it thinks truecolor is available, bypassing the terminal palette. WezTerm
# advertises truecolor itself, so lazygit ends up drawing its own greens there
# while RStudio falls back to the Catppuccin palette. Force palette mode so the
# two agree and both follow the theme.
$env:TCELL_TRUECOLOR = 'disable'

# ── Environment (mirrors exports.zsh) ───────────────────────────────────────
# exports.zsh uses nvim; it isn't installed on Windows, and an unset EDITOR
# makes tools like `starship config` hang waiting on a console editor.
if (Get-Command code -ErrorAction Ignore) {
    $env:EDITOR = 'code --wait'
    $env:VISUAL = $env:EDITOR
}

if (Get-Command fd -ErrorAction Ignore) {
    $env:FZF_DEFAULT_COMMAND = 'fd --type f --hidden --follow --exclude .git'
}
$env:FZF_DEFAULT_OPTS = '--height 40% --layout=reverse --border'

# ── Starship prompt ─────────────────────────────────────────────────────────
$env:STARSHIP_CONFIG = "$HOME\Tools\dotfiles\starship\.config\starship\starship.toml"
$StarshipExe = "$HOME\Tools\Starship\starship.exe"

if (Test-Path $StarshipExe) {
    $init = & $StarshipExe init powershell --print-full-init | Out-String

    # The $fill module pads the prompt to exactly the reported terminal width.
    # RStudio's pane over-reports by one column, which wraps the last digit of
    # the right-aligned clock onto its own line. A one-column right margin is
    # invisible in WezTerm and fixes RStudio, so apply it everywhere.
    $target = '--terminal-width=$($Host.UI.RawUI.WindowSize.Width)'
    if ($init.Contains($target)) {
        $init = $init.Replace($target, '--terminal-width=$($Host.UI.RawUI.WindowSize.Width - 1)')
    }

    $init | Invoke-Expression
}

# ── zoxide (aliases.zsh: cd = z) ────────────────────────────────────────────
# --cmd cd replaces cd itself, so plain `cd` gets frecency jumping and `cdi`
# opens the interactive picker. Plain `cd <real path>` still works as before.
if (Get-Command zoxide -ErrorAction Ignore) {
    (zoxide init powershell --cmd cd | Out-String) | Invoke-Expression

    # RStudio's "Set Terminal to Current Directory" (Alt+T) sends the path
    # POSIX-escaped - `cd C\:/Users/...` - because with windows_terminal_shell
    # set to 'custom' it assumes a bash-like shell. PowerShell escapes with a
    # backtick, so that backslash survives literally, the path never resolves,
    # and zoxide reports it as "no match found". Strip it: the sequence \:
    # cannot occur in a real Windows path or in a zoxide query.
    Microsoft.PowerShell.Utility\Remove-Alias -Name cd -Force -ErrorAction Ignore
    function global:cd {
        $a = @($args)
        if ($a.Count -and $a[0] -is [string] -and $a[0].Contains('\:')) {
            $a[0] = $a[0].Replace('\:', ':')
        }
        __zoxide_z @a
    }
}

# ── Aliases (mirrors aliases.zsh) ───────────────────────────────────────────
# PowerShell aliases can't carry arguments, so anything with flags is a function.

if (Get-Command eza -ErrorAction Ignore) {
    # PowerShell resolves aliases before functions, so the built-in
    # ls -> Get-ChildItem alias would shadow the function below.
    Remove-Alias -Name ls -Force -ErrorAction Ignore

    # eza 0.23 on Windows lists nothing when invoked with no path at all,
    # so supply '.' whenever the caller passed only flags.
    function Invoke-Eza {
        $a = @($args)
        if (-not ($a | Where-Object { $_ -notlike '-*' })) { $a += '.' }
        & eza --icons=always --group-directories-first @a
    }

    function ls { Invoke-Eza @args }
    function ll { Invoke-Eza -lh @args }
    function la { Invoke-Eza -lah @args }
    function lt { Invoke-Eza --tree @args }
}

if (Get-Command bat -ErrorAction Ignore) {
    Remove-Alias -Name cat -Force -ErrorAction Ignore

    # bat detects when it's piped and emits plain text, so this stays safe in
    # pipelines. Call Get-Content by name if you need its -Raw/-Tail parameters.
    function cat { bat @args }
    function showal { bat $PROFILE }
}

function cl { Clear-Host }

if (Get-Command lazygit -ErrorAction Ignore) { Set-Alias lgit lazygit }

if (Get-Command jupyter -ErrorAction Ignore) {
    function jn { jupyter notebook @args }
    function jl { jupyter lab @args }
}
