#######################################
# ENVIRONMENT VARIABLES & PATH SETUP
#######################################
export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/starship/starship.toml"
export EDITOR=/bin/nvim

#######################################
# ZINIT PLUGIN MANAGER & PLUGINS
#######################################
export ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# Plugins
zinit ice lucid as"program" pick"bin/git-dsf"
zinit load so-fancy/diff-so-fancy
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit light romkatv/gitstatus
zinit light zsh-users/zsh-history-substring-search

# Oh My Zsh Plugin Snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo

#######################################
# SHELL INTEGRATIONS
#######################################
eval "$(starship init zsh)"
eval "$(zoxide init --cmd cd zsh)"
eval "$(thefuck --alias)"
eval "$(atuin init zsh)"

#######################################
# COMPLETION SETTINGS
#######################################
autoload -Uz compinit && compinit
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu no

# fzf-tab config
zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=tab:accept
zstyle ':fzf-tab:*' use-fzf-default-opts yes
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

export FZF_TMUX=1
eval "$(fzf --zsh)"

#######################################
# HISTORY SETTINGS
#######################################
HISTSIZE=5001
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase

setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

#######################################
# KEYBINDINGS & WIDGETS
#######################################
bindkey -e
bindkey '^[ ' autosuggest-execute
bindkey '^[Z ' autosuggest-accept
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# Custom: Ctrl+H = up one dir
cd_up() { cd ..; zle reset-prompt }
zle -N cd_up
bindkey '^H' cd_up

# Custom: Ctrl+L = interactive cd
cd_menu() {
    local dir
    dir=$(eza -1 -a --color=always --icons --group-directories-first | fzf --ansi --preview 'eza --tree --level=1 --icons --color=always {}')
    [[ -n "$dir" ]] && cd "$dir" && zle reset-prompt
}
zle -N cd_menu
bindkey '^L' cd_menu

#######################################
# ALIASES
#######################################
alias vim='nvim'
alias jump='nvim $(fzf -m --preview="bat --color=always {}")'
alias ls='eza -l --icons --level=0 --tree --sort=Name'
alias search='~/.local/bin/search.sh'
alias code='code .'
alias t='tmux new -s '
alias tt='tmux a -t'
alias fbat="fzf --preview 'bat --style=numbers --color=always --line-range :500 {}'"
alias seek='pacseek'
alias y='yazi'
alias ci='cdi'
alias ....='cd ../..'
alias ..='cd ..'
alias ~='cd ~'

#######################################
# FUNCTIONS
#######################################
edit() {
    local file="$HOME/.config/$1"
    [[ -f "$file" ]] && nvim "$file" || echo "File not found: $file"
}

cpcf() {
    local file
    file=$(fzf --query="$1" --preview 'bat --color=always {}' --preview-window 'right:60%' --bind 'ctrl-d:preview-page-down,ctrl-u:preview-page-up')
    if [ -n "$file" ]; then
        cat "$file" | wl-copy
        echo "Copied: $file"
    else
        echo "No file selected."
    fi
}

fcd() {
    local dir
    dir=$(find ${1:-.} -type d -not -path '*/\.*' 2> /dev/null | fzf +m) && cd "$dir"
}

extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.gz)  tar -xzf "$1" ;;
            *.tar.xz)  tar -xf "$1" ;;
            *.tar.bz2) tar -xjf "$1" ;;
            *.gz)      gunzip "$1" ;;
            *.bz2)     bunzip2 "$1" ;;
            *.zip)     unzip "$1" ;;
            *.Z)       uncompress "$1" ;;
            *.7z)      7z x "$1" ;;
            *)         echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

killp() {
    ps aux | fzf | awk '{print $2}' | xargs kill -9
}

j() {
    local dir
    dir=$(eza -1 --color=always --icons --group-directories-first | fzf --ansi)
    [[ -n "$dir" ]] && cd "$(echo "$dir" | awk '{print $NF}')"
}

take() {
    mkdir -p "$1" && cd "$1"
}

c() {
    cd "$1" && ls
}

music() {
    xdg-open https://music.youtube.com/
}

#######################################
# COMPLETIONS (BASH-LIKE)
#######################################
autoload -U +X bashcompinit && bashcompinit
