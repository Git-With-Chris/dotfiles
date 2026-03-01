# Setup zsh
[ -f ~/.config/zsh/exports.zsh ]   && source ~/.config/zsh/exports.zsh
[ -f ~/.config/zsh/options.zsh ]   && source ~/.config/zsh/options.zsh
[ -f ~/.config/zsh/aliases.zsh ]   && source ~/.config/zsh/aliases.zsh
[ -f ~/.config/zsh/functions.zsh ] && source ~/.config/zsh/functions.zsh
[ -f ~/.config/zsh/plugins.zsh ]   && source ~/.config/zsh/plugins.zsh

# Starship setup
eval "$(starship init zsh)"

