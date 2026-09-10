#!/usr/bin/env bash
#
# Replicate the local terminal/RStudio setup on a Linux box (RStudio Server).
#
#   git clone <this repo> ~/dotfiles && cd ~/dotfiles && ./install-linux.sh
#
# Needs no root. Everything lands under $HOME:
#   binaries -> ~/.local/bin
#   configs  -> ~/.config
#
# Safe to re-run. It never overwrites ~/.bashrc, and it merges RStudio prefs
# key-by-key rather than replacing the file.
#
#   --offline     skip downloads, use bootstrap/vendor/ only
#   --dry-run     print what would happen, change nothing
#   --skip-tools  configs only, no binaries

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="${HOME}/.local/bin"
CFG="${HOME}/.config"
VENDOR="${REPO}/bootstrap/vendor"
MANIFEST="${REPO}/bootstrap/manifest.txt"

OFFLINE=0
DRYRUN=0
SKIP_TOOLS=0
for a in "$@"; do
  case "$a" in
    --offline)    OFFLINE=1 ;;
    --dry-run)    DRYRUN=1 ;;
    --skip-tools) SKIP_TOOLS=1 ;;
    -h|--help)    sed -n '2,17p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "unknown option: $a" >&2; exit 2 ;;
  esac
done

RED=$'\033[31m'
GRN=$'\033[32m'
YLW=$'\033[33m'
DIM=$'\033[90m'
RST=$'\033[0m'
ok()    { printf '  %sok%s   %s\n'  "$GRN" "$RST" "$*"; }
skip()  { printf '  %s--%s   %s\n'  "$DIM" "$RST" "$*"; }
warn()  { printf '  %swarn%s %s\n'  "$YLW" "$RST" "$*"; }
err()   { printf '  %sFAIL%s %s\n'  "$RED" "$RST" "$*"; }
title() { printf '\n%s\n' "$*"; }
run()   { if [ "$DRYRUN" = 1 ]; then printf '  %s[dry-run]%s %s\n' "$DIM" "$RST" "$*"; else eval "$@"; fi; }

FAILED=0

# ── sanity ──────────────────────────────────────────────────────────────────
title "Environment"
[ -f "$MANIFEST" ] || { err "manifest missing: $MANIFEST"; exit 1; }
case "$(uname -m)" in
  x86_64|amd64) ok "architecture $(uname -m)" ;;
  *)
    err "the pinned binaries are x86_64 only; this box is $(uname -m)"
    err "install the tools another way, then re-run with --skip-tools"
    exit 1 ;;
esac
ok "$(uname -s) $(uname -r)"

DL=""
if command -v curl >/dev/null 2>&1; then
  DL=curl
elif command -v wget >/dev/null 2>&1; then
  DL=wget
fi
if [ "$OFFLINE" = 1 ]; then
  skip "offline mode - using bootstrap/vendor/"
elif [ -z "$DL" ]; then
  warn "neither curl nor wget found - falling back to offline mode"
  OFFLINE=1
else
  ok "downloader: $DL"
fi

run "mkdir -p '$BIN' '$CFG'"

# ── tools ───────────────────────────────────────────────────────────────────
fetch() {
  case "$DL" in
    curl) curl -fsSL --connect-timeout 20 --retry 2 -o "$2" "$1" ;;
    wget) wget -q --timeout=20 --tries=2 -O "$2" "$1" ;;
    *) return 1 ;;
  esac
}

install_tool() {
  local name="$1" version="$2" asset="$3" url="$4"
  local vendored="${VENDOR}/${asset}"
  local tmp arc found have

  if [ -x "${BIN}/${name}" ]; then
    have="$("${BIN}/${name}" --version 2>/dev/null | head -1)"
    skip "${name} already installed (${have:-unknown})"
    return 0
  fi

  tmp="$(mktemp -d)" || { err "${name}: mktemp failed"; return 1; }

  if [ -f "$vendored" ]; then
    arc="$vendored"
  elif [ "$OFFLINE" = 1 ]; then
    err "${name}: offline and ${asset} is not in bootstrap/vendor/"
    rm -rf "$tmp"; return 1
  else
    arc="${tmp}/${asset}"
    if ! fetch "$url" "$arc"; then
      err "${name}: download failed - put ${asset} in bootstrap/vendor/ and re-run"
      rm -rf "$tmp"; return 1
    fi
  fi

  if [ "$DRYRUN" = 1 ]; then
    printf '  %s[dry-run]%s install %s %s\n' "$DIM" "$RST" "$name" "$version"
    rm -rf "$tmp"; return 0
  fi

  if ! tar -xzf "$arc" -C "$tmp" 2>/dev/null; then
    err "${name}: could not extract ${asset}"
    rm -rf "$tmp"; return 1
  fi

  # Archive layouts differ between projects, so locate the binary rather than
  # assuming a path inside the tarball.
  found="$(find "$tmp" -type f -name "$name" -perm -u+x 2>/dev/null | head -1)"
  [ -n "$found" ] || found="$(find "$tmp" -type f -name "$name" 2>/dev/null | head -1)"
  if [ -z "$found" ]; then
    err "${name}: no binary named '${name}' inside ${asset}"
    rm -rf "$tmp"; return 1
  fi

  if install -m 0755 "$found" "${BIN}/${name}"; then
    ok "${name} ${version}"
    rm -rf "$tmp"; return 0
  fi
  err "${name}: install failed"
  rm -rf "$tmp"; return 1
}

if [ "$SKIP_TOOLS" = 1 ]; then
  title "Tools"
  skip "--skip-tools given"
else
  title "Tools -> ${BIN}"
  while IFS='|' read -r name version asset url; do
    case "$name" in ''|\#*) continue ;; esac
    install_tool "$name" "$version" "$asset" "$url" || FAILED=$((FAILED + 1))
  done < "$MANIFEST"
fi

# ── configs ─────────────────────────────────────────────────────────────────
link() {
  local src="${REPO}/$1" dst="$2" stamp
  [ -e "$src" ] || { err "missing in repo: $1"; return 1; }
  if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
    skip "$(basename "$dst") already linked"
    return 0
  fi
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    stamp="$(date +%Y%m%d%H%M%S)"
    run "cp -a '$dst' '${dst}.bak.${stamp}'"
    warn "$(basename "$dst") existed - backed up as $(basename "$dst").bak.${stamp}"
  fi
  run "mkdir -p '$(dirname "$dst")'"
  run "ln -sfn '$src' '$dst'"
  ok "$(basename "$dst")"
}

title "Configuration"
link "starship/.config/starship/starship.toml" "${CFG}/starship/starship.toml" || FAILED=$((FAILED + 1))
link "bash/.config/dotfiles/bashrc"            "${CFG}/dotfiles/bashrc"        || FAILED=$((FAILED + 1))
link "lazygit/.config/lazygit/config.yml"      "${CFG}/lazygit/config.yml"     || FAILED=$((FAILED + 1))
link "rstudio/.config/rstudio/themes/catppuccin-mocha.rstheme" "${CFG}/rstudio/themes/catppuccin-mocha.rstheme" || FAILED=$((FAILED + 1))
link "R/.Rprofile"                             "${HOME}/.Rprofile"             || FAILED=$((FAILED + 1))

# ── ~/.bashrc hook ──────────────────────────────────────────────────────────
title "Shell hook"
BASHRC="${HOME}/.bashrc"
if [ -f "$BASHRC" ] && grep -qF '.config/dotfiles/bashrc' "$BASHRC"; then
  skip "~/.bashrc already sources the dotfiles bashrc"
elif [ "$DRYRUN" = 1 ]; then
  printf '  %s[dry-run]%s append source hook to ~/.bashrc\n' "$DIM" "$RST"
else
  [ -f "$BASHRC" ] && cp -a "$BASHRC" "${BASHRC}.bak.$(date +%Y%m%d%H%M%S)"
  {
    printf '\n# dotfiles\n'
    printf '[ -f "$HOME/.config/dotfiles/bashrc" ] && . "$HOME/.config/dotfiles/bashrc"\n'
  } >> "$BASHRC"
  ok "hook appended to ~/.bashrc (original backed up)"
fi

# ── RStudio preferences ─────────────────────────────────────────────────────
title "RStudio preferences"
PREFS="${CFG}/rstudio/rstudio-prefs.json"
WANT="${REPO}/bootstrap/rstudio-prefs.json"
MERGE="${REPO}/bootstrap/merge-prefs.R"

RSCRIPT_BIN=""
command -v Rscript >/dev/null 2>&1 && RSCRIPT_BIN=Rscript

if [ -z "$RSCRIPT_BIN" ]; then
  err "Rscript not on PATH - cannot merge preferences safely"
  warn "add these keys to ${PREFS} by hand:"
  sed 's/^/      /' "$WANT"
  FAILED=$((FAILED + 1))
elif [ "$DRYRUN" = 1 ]; then
  printf '  %s[dry-run]%s merge keys from bootstrap/rstudio-prefs.json into %s\n' \
    "$DIM" "$RST" "$PREFS"
else
  run "mkdir -p '$(dirname "$PREFS")'"
  [ -f "$PREFS" ] && cp -a "$PREFS" "${PREFS}.bak.$(date +%Y%m%d%H%M%S)"
  if "$RSCRIPT_BIN" "$MERGE" "$PREFS" "$WANT"; then
    ok "merged (previous file backed up alongside it)"
  else
    err "preferences merge failed - nothing was written"
    FAILED=$((FAILED + 1))
  fi
fi

# ── summary ─────────────────────────────────────────────────────────────────
title "Next steps"
cat <<'NEXT'
  1. Reload your shell:  exec bash -l
  2. Reload the RStudio Server browser tab so it re-reads preferences,
     then restart R (Ctrl+Shift+F10) to pick up ~/.Rprofile.

  Font: RStudio Server renders in YOUR BROWSER, so the Nerd Font has to be on
  the machine you browse FROM, not on the server. It is already installed on
  your Windows laptop. On any other client, install "JetBrainsMono Nerd Font"
  or the prompt icons will show as empty boxes.
  Check under Tools > Global Options > Appearance.
NEXT

if [ "$FAILED" -gt 0 ]; then
  printf '\n%sFinished with %d problem(s) - see the FAIL lines above.%s\n' "$YLW" "$FAILED" "$RST"
  exit 1
fi
printf '\n%sAll done.%s\n' "$GRN" "$RST"
