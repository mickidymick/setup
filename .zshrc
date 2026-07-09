# ~/.zshrc — zsh analog of this repo's .bashrc.
# Install with:  ./install.sh --zsh   (bash remains the default; this is opt-in)

# --- history (mirrors .bashrc: ignoreboth + append, 1000/2000) ---
HISTFILE="$HOME/.zsh_history"
HISTSIZE=1000
SAVEHIST=2000
setopt append_history inc_append_history        # append, write as you go
setopt hist_ignore_all_dups hist_ignore_space   # HISTCONTROL=ignoreboth analog
# (zsh tracks the window size on its own; no checkwinsize needed)

setopt prompt_subst   # let ${PS1_PRE} and expansions render in the prompt

# --- prompt: green user@host:cwd on success, red on non-zero exit ---
#   %(?.A.B) -> A if $?==0 else B ; %n user, %m short host, %~ cwd, %# $/#
export PS1_PRE=''
PROMPT='${PS1_PRE}%(?.%F{green}.%F{red})%n@%m%f:%F{blue}%~%f%# '

# set the terminal title to "user@host: cwd" on xterm-like terminals
case "$TERM" in
    xterm*|rxvt*)
        _set_title() { print -Pn "\e]0;%n@%m: %~\a"; }
        precmd_functions+=(_set_title)
        ;;
esac

# --- completion system (also powers the install.sh completion below) ---
autoload -Uz compinit && compinit

# --- color ls (mirrors .bashrc) ---
if command -v dircolors >/dev/null 2>&1; then
    test -r "$HOME/.dircolors" && eval "$(dircolors -b "$HOME/.dircolors")" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
fi

# --- aliases (mirror .bashrc) ---
alias ll='~/setup/new_ls.sh'
alias fix='reset'
alias fuck='sudo $(fc -ln -1)'   # re-run last command with sudo (zsh: fc -ln -1)

# optional per-machine extras
[ -f "$HOME/.zsh_aliases" ] && source "$HOME/.zsh_aliases"

# --- yed helpers (mirror .bashrc) ---
yeddiff()  { yed -c "diff $1 $2"; }
yedflame() { yed -c "set flame-graph-bind-mouse off" -c "flame-graph $1"; }

# --- tab-completion for the setup repo's install.sh ---
# Offers only the flags not already present on the command line.
_setup_install_sh() {
    local -a opts remaining
    local o
    opts=(--lsp --hpc --zsh --help)
    remaining=()
    for o in $opts; do
        (( ${words[(I)$o]} )) || remaining+=$o
    done
    compadd -- $remaining
}
compdef _setup_install_sh install.sh

# --- PATH (mirror .bashrc) ---
PATH="$HOME/.local/bin:$PATH"
PATH="/usr/local/bin/qemu-system-riscv64:$PATH"
export PATH

# nvm (nvm.sh supports zsh; its bash_completion file is bash-only, so skip it)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
