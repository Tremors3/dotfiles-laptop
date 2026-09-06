
# ============================================================
# Zsh configuration
# ============================================================

# ------------------------------------------------------------
# History
# ------------------------------------------------------------

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY


# ------------------------------------------------------------
# General Zsh options
# ------------------------------------------------------------

# Automatically cd when entering a directory
setopt AUTO_CD

# Allow comments in interactive shell
setopt INTERACTIVE_COMMENTS

# Correct small command typos
#setopt CORRECT


# ============================================================
# Oh-My-Zsh plugins - inside '/usr/share/oh-my-zsh'
# ============================================================

export ZSH=/usr/share/oh-my-zsh

plugins=(
    git
    sudo
    fzf
)

source "$ZSH/oh-my-zsh.sh"


# ============================================================
# External plugins - inside '/usr/share/oh-my-zsh'
# ============================================================

readonly ZSH_PLUGIN_DIR=/usr/share/zsh/plugins

load_plugins() {
    local plugin
    local plugin_file

    for plugin in "$@"; do
        plugin_file="$ZSH_PLUGIN_DIR/$plugin/$plugin.zsh"

        if [[ ! -f "$plugin_file" ]]; then
            print -u2 "Warning: plugin '$plugin' not found"
            continue
        fi

        source "$plugin_file"
    done
}

ZSH_AUTOSUGGEST_STRATEGY=(history)

external_plugins=(
    zsh-autosuggestions
    zsh-syntax-highlighting
)

load_plugins "${external_plugins[@]}"


# ------------------------------------------------------------
# Aliases
# ------------------------------------------------------------

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Listing
alias c='clear'  # clear terminal
alias l='eza -lh --icons=auto'  # long list
alias ls='eza -1 --icons=auto'  # short list
alias ll='eza -lha --icons=auto --sort=name --group-directories-first'  # long list all
alias ld='eza -lhD --icons=auto'  # long list dirs
alias lt='eza --long --icons=auto --tree'  # list folder as tree
alias lt2='eza --long --icons=auto --tree --level 2'  # list folder as tree to level 2
alias lt3='eza --long --icons=auto --tree --level 3'  # list folder as tree to level 3

# Safety
alias cp='cp -i'
alias mv='mv -i'
alias rm='echo "rm is disabled, use trash or /bin/rm instead."'

# Useful commands
alias cat='bat'
alias mkdir='mkdir -p'
alias grep='grep --color=auto'
alias df='df -h'
alias du='du -h'

# Git Shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'

# Quick edit/reload zsh configuration
alias zshrc='$EDITOR ~/.zshrc'
alias reload='source ~/.zshrc'

# System
alias un='$aurhelper -Rns'  # uninstall package
alias up='$aurhelper -Syu'  # update system/package/aur
alias pl='$aurhelper -Qs'  # list installed package
alias pa='$aurhelper -Ss'  # list available package
alias pc='$aurhelper -Sc'  # remove unused cache
alias po='$aurhelper -Qtdq | $aurhelper -Rns -'  # remove unused packages, also try > $aurhelper -Qqd | $aurhelper -Rsu --print -
alias cleanup='sudo pacman -Rns $(pacman -Qtdq)'

# Trashcan aliases
alias trash='mv --backup=t -t ~/Trash'  # trash things instead of delete them
alias cd-trash='cd ~/Trash'  # go to trash
alias list-trash='ll ~/Trash'  # list trash
alias clear-trash='find ~/Trash -mindepth 1 -delete'  # clear the trash

# Set fan speed
alias fsfs='echo "level full-speed" | sudo tee /proc/acpi/ibm/fan'  # set fan speed to max
alias fsauto='echo "level auto" | sudo tee /proc/acpi/ibm/fan'  # set fan speed to auto

# Home's dotfiles alias
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

# Find and sort mirrors based on rate
alias refmirror='reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist'

# Check flagget packages
alias check_flagged='comm -1 -2 <(pacman -Qq | sort) <(curl -s https://raw.githubusercontent.com/lenucksi/aur-malware-check/master/package_list.txt | sort)'


# ------------------------------------------------------------
# Environment
# ------------------------------------------------------------

# Default editor
export EDITOR='vim'
export VISUAL="$EDITOR"


# Add .local/bin to PATH
PATH="${PATH}:.local/bin"
PATH="${PATH}:.local/custom/bin"


# Select xterm-256color as terminal for ssh sessions
[[ "$TERM" == "xterm-kitty" ]] && alias ssh="TERM=xterm-256color ssh"


# PyLucene missing python and java locations
PYTHON_BIN=$(which python3)
PREFIX_PYTHON=$(dirname $(dirname $(readlink -f $PYTHON_BIN)))
export PYTHON=${PREFIX_PYTHON}/bin/python3

JAVA_BIN=$(which java)
JAVA_HOME=$(dirname $(dirname $(readlink -f $JAVA_BIN)))
export LD_LIBRARY_PATH=${JAVA_HOME}/lib/server:$LD_LIBRARY_PATH


# ------------------------------------------------------------
# SSH Keys
# ------------------------------------------------------------

export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"


# ------------------------------------------------------------
# Package Utilities
# ------------------------------------------------------------

# Detect AUR helper

if (( $+commands[yay] )); then
    aurhelper="yay"
elif (( $+commands[paru] )); then
    aurhelper="paru"
else
    aurhelper=""
fi


# Install packages from official repositories and AUR

in() {
    local -a arch=()
    local -a aur=()

    for pkg in "$@"; do
        if pacman -Si "$pkg" &>/dev/null; then
            arch+=("$pkg")
        else
            aur+=("$pkg")
        fi
    done

    if (( ${#arch[@]} )); then
        sudo pacman -S "${arch[@]}"
    fi

    if (( ${#aur[@]} )); then
        if [[ -z "$aurhelper" ]]; then
            print -u2 "No AUR helper found (yay/paru)"
            return 1
        fi

        "$aurhelper" -S "${aur[@]}"
    fi
}


# ------------------------------------------------------------
# Command Not Found
# ------------------------------------------------------------

# In case a command is not found, try to find the package that has it
command_not_found_handler() {
    local purple='\e[1;35m' bright='\e[0;1m' green='\e[1;32m' reset='\e[0m'
    
    local entries
    local pkg

    printf 'zsh: command not found: %s\n' "$1"

    entries=( ${(f)"$(pacman -F --machinereadable -- "/usr/bin/$1" 2>/dev/null)"} )

    if (( ${#entries[@]} )); then
        printf '%s may be found in the following packages:\n' "$1"

        for entry in "${entries[@]}"; do
            local fields=( ${(0)entry} )

            if [[ "$pkg" != "${fields[2]}" ]]; then
                printf "  ${purple}%s/${bright}%s ${green}%s${reset}\n" \
                    "${fields[1]}" \
                    "${fields[2]}" \
                    "${fields[3]}"
            fi

            printf '      /%s\n' "${fields[4]}"

            pkg="${fields[2]}"
        done
    fi

    return 127
}


# ------------------------------------------------------------
# Prompt - Utilities
# ------------------------------------------------------------

# Prompt expansion
# https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html

setopt PROMPT_SUBST


# Display all available terminal colors
# spectrum_ls
# colors() {
#     for i in {0..255}; do
#         print -Pn "%K{$i}  %k%F{$i}${(l:3::0:)i}%f " \
#             ${${(M)$((i % 6)):#3}:+$'\n'}
#     done
# }


# Git prompt
#GIT_PROMPT_LOCATION="$HOME/.local/bin/git-prompt.sh"

# Download git-prompt.sh if needed
# curl -o "$GIT_PROMPT_LOCATION" \
#     https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh

#if [[ -f "$GIT_PROMPT_LOCATION" ]]; then
#    source "$GIT_PROMPT_LOCATION"
#fi

# if (( ${+functions[__git_ps1]} )); then
#     PROMPT+="${NEWLINE}├─>$(__git_ps1 ' (%s)')"
# fi


precmd() {
    unset git_prompt_info

    if git rev-parse --is-inside-work-tree &>/dev/null; then
        local branch
        branch=$(git branch --show-current)

        [[ -z "$branch" ]] &&
            branch="HEAD:$(git rev-parse --short HEAD)"

        git_prompt_info="${branch}"

        if [[ -n "$(git status --porcelain)" ]]; then
            git_prompt_info+=" ●"
        fi
    fi
}


# ------------------------------------------------------------
# Prompt
# ------------------------------------------------------------

# Useful Characters
# ╭ — U+256D (Top-Left Arc)
# ╰ — U+256F (Bottom-Left Arc)
# ├ — U+251C (Box Drawings Light Vertical and Right)
# ─ — U+2500 (Box Drawings Light Horizontal)

# Colors
BEGIN_ORANGE='%F{208}'
BEGIN_COOLBLUE='%F{24}'
END_COLOR='%f'

# New Line
NEWLINE=$'\n'

# Prompt
PROMPT="${NEWLINE}"
PROMPT+="╭─${BEGIN_ORANGE}[%m]${END_COLOR}"
PROMPT+="─${BEGIN_COOLBLUE}[%n]${END_COLOR}"
PROMPT+='${git_prompt_info:+─(${git_prompt_info})}'
PROMPT+=" %d"
PROMPT+="${NEWLINE}"
PROMPT+="╰─> "
