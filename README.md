# Dotfiles

Personal macOS development environment managed using **GNU Stow**.

This repository contains configuration files ("dotfiles") for terminal,
shell, and developer tooling. All configs are symlinked into `$HOME`
using Stow to keep the home directory clean and reproducible.

---

## Philosophy

- Keep `$HOME` minimal
- Follow XDG directory conventions
- Separate **config**, **state**, and **runtime data**
- Each tool owns its own configuration package
- Easy setup on a new machine

---

## Directory Structure

dotfiles/
├── ghostty/
├── starship/
└── zsh/


Each folder represents a **Stow package** and mirrors the final
filesystem layout inside `$HOME`.

Example:


dotfiles/ghostty/.config/ghostty/config
↓
~/.config/ghostty/config


---

## Managed Components

### Ghostty
Terminal configuration.

Location:

~/.config/ghostty/config


---

### Zsh
Shell configuration with modular structure.


.zshrc → shell entry point
.zprofile → login environment setup

.config/zsh/
├── init.zsh
├── exports.zsh
├── aliases.zsh
└── functions.zsh


Responsibilities:

- `exports.zsh` → environment variables
- `aliases.zsh` → command shortcuts
- `functions.zsh` → custom shell functions
- `init.zsh` → loads modular config

---

### Starship
Shell prompt configuration.

Location:

~/.config/starship.toml


---

## History Management

Zsh history follows XDG conventions:


~/.local/state/zsh/history


This keeps runtime data out of `$HOME` and outside version control.

---

## Using Stow

From inside the dotfiles directory:


stow ghostty
stow zsh
stow starship


Remove a package:


stow -D <package>


---

## New Machine Setup

1. Install Homebrew
2. Install dependencies:

brew install stow starship

3. Clone dotfiles:

git clone <repo> ~/dotfiles

4. Apply configs:

cd ~/dotfiles
stow *


---

## Notes

- Runtime data is **not stored** in this repo.
- macOS system files (`.DS_Store`) are ignored.
- Configuration follows modern XDG layout where possible.