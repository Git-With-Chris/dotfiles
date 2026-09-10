# Linux / RStudio Server setup

Replicates the local terminal setup on a Linux box: starship prompt, Catppuccin
theme, the CLI tools, the R console tweak and the Air formatter.

Everything installs under `$HOME` — **no root required**.

```
binaries -> ~/.local/bin
configs  -> ~/.config   (symlinked back to this repo)
```

## If the server has internet

```bash
git clone https://github.com/Git-With-Chris/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install-linux.sh
exec bash -l
```

## If it doesn't

Run this on Windows first to pre-download the Linux binaries:

```powershell
.\fetch-vendor.ps1
```

That fills `bootstrap/vendor/` (~24 MB). Those tarballs are **gitignored**, so
cloning on the server won't bring them — copy `bootstrap/vendor/` across
yourself (scp, a mounted share, or RStudio Server's own file uploader), then:

```bash
./install-linux.sh --offline
```

## Options

| Flag | Effect |
|---|---|
| `--dry-run` | Print every action, change nothing. Run this first. |
| `--offline` | Never download; use `bootstrap/vendor/` only. |
| `--skip-tools` | Configs only, no binaries. |

Re-running is safe: installed tools are skipped, existing config files are
backed up with a timestamp before being replaced, and `~/.bashrc` is only ever
appended to — once.

## What it changes

| Path | What |
|---|---|
| `~/.local/bin/*` | starship, eza, bat, fd, fzf, zoxide, lazygit, air |
| `~/.config/starship/starship.toml` | prompt (symlink) |
| `~/.config/dotfiles/bashrc` | aliases, PATH, tool init (symlink) |
| `~/.config/lazygit/config.yml` | lazygit theme (symlink) |
| `~/.config/rstudio/themes/` | Catppuccin Mocha `.rstheme` (symlink) |
| `~/.Rprofile` | blank line between output and prompt (symlink) |
| `~/.bashrc` | one appended line sourcing the above |
| `~/.config/rstudio/rstudio-prefs.json` | keys merged, rest preserved |

## The font — read this one

RStudio Server renders in **your browser**, so the font must be installed on the
machine you browse *from*, not on the server. It's already on your Windows
laptop. On any other client, install **JetBrainsMono Nerd Font**, or the prompt
icons render as empty boxes.

Check under *Tools → Global Options → Appearance*; it should offer
`JetBrainsMono NFM`.

## Why the prompt uses ANSI colour names

RStudio's terminal quantises 24-bit colour down to the 16 ANSI slots, so
`starship.toml` is written in ANSI names rather than hex. The `.rstheme` maps
those 16 slots to Catppuccin, which is what makes the prompt look right.

Three slots are repurposed, because Catppuccin duplicates its bright row and
plain ANSI has no equivalent for these:

| Slot | Value | Used by |
|---|---|---|
| 8 (bright black) | `#7f849c` overlay1 | clock, command duration |
| 11 (bright yellow) | `#fab387` peach | background jobs |
| 13 (bright magenta) | `#cba6f7` mauve | git branch |

## Known gaps

- **air** is the only dynamically-linked binary (Posit ship no musl build). On a
  very old distro it may fail with `GLIBC_2.xx not found`. The other seven are
  static and run anywhere x86_64.
- **x86_64 only.** On ARM the script stops early; install the tools another way
  and re-run with `--skip-tools`.
- The prefs merge needs `Rscript` on PATH — always true on an RStudio Server.
  If it isn't, the script prints the keys for you to paste in manually.
