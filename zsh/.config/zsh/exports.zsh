# Editor
export EDITOR="nvim"
export VISUAL="nvim"

# History
HISTFILE="$HOME/.local/state/zsh/history"
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_VERIFY

# Set XDG base config directory (default is ~/.config)
export XDG_CONFIG_HOME="$HOME/.config"

# NodeJS
export PATH="/opt/homebrew/opt/node@24/bin:$PATH"

# Starship
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
export STARSHIP_CACHE="$HOME/.config/starship/cache"

# fzf
export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"