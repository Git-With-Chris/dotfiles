# Package: eza (ls/tree replacement)
alias ls='eza --icons=always --group-directories-first'
alias ll='eza -lh --icons=always --group-directories-first'
alias la='eza -lah --icons=always --group-directories-first'
alias tree='eza --tree --icons=always --group-directories-first'

# Package: bat (cat replacement)
alias cat='bat'

# Package: zoxide (cd replacement)
alias cd='z'

# Package: lazygit (git replacement)
alias lgit='lazygit'

# Show all aliases
alias showal='bat ~/.config/zsh/aliases.zsh'