# Starship setup
eval "$(starship init zsh)"

# Completion
autoload -Uz compinit
compinit

# fzf
source <(fzf --zsh)

# zoxide
eval "$(zoxide init zsh)"

# Autosuggestions
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_USE_ASYNC=1
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Syntax highlighting (must be last)
source /opt/homebrew/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
zle_highlight+=(paste:none)