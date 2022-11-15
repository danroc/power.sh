#!/bin/bash

# -----------------------------------------------------------------------------
# Constants

# External commands
PSH_GIT_COMMAND="env LANG=C git"

# Max number of path segments
PSH_MAX_PATH_DEPTH=4

# Symbols
PSH_SYMBOL_GIT_UNTRACKED='+'
PSH_SYMBOL_GIT_AHEAD='↑'
PSH_SYMBOL_GIT_BEHIND='↓'

PSH_SYMBOL_PATH_SEPARATOR='❯'
PSH_SYMBOL_SSH='SSH'
PSH_SYMBOL_ELLIPSIS='…'

# Color scheme
PSH_COLOR_SSH_BG=166
PSH_COLOR_SSH_FG=254

PSH_COLOR_JOBS_BG=238
PSH_COLOR_JOBS_FG=39

PSH_COLOR_REPO_CLEAN_BG=148
PSH_COLOR_REPO_CLEAN_FG=0
PSH_COLOR_REPO_DIRTY_BG=161
PSH_COLOR_REPO_DIRTY_FG=15

PSH_COLOR_USERNAME_ROOT_BG=124
PSH_COLOR_USERNAME_ROOT_FG=250
PSH_COLOR_USERNAME_BG=240
PSH_COLOR_USERNAME_FG=250

PSH_COLOR_HOSTNAME_FG=250
PSH_COLOR_HOSTNAME_BG=238

PSH_COLOR_PATH_BG=237
PSH_COLOR_PATH_FG=250
PSH_COLOR_PATH_CWD=254
PSH_COLOR_PATH_SEPARATOR=244

PSH_COLOR_HOME_BG=31
PSH_COLOR_HOME_FG=15

PSH_COLOR_READONLY_BG=124
PSH_COLOR_READONLY_FG=254
PSH_COLOR_READONLY_SEPARATOR=248

PSH_COLOR_CMD_PASSED_BG=236
PSH_COLOR_CMD_PASSED_FG=15
PSH_COLOR_CMD_FAILED_BG=161
PSH_COLOR_CMD_FAILED_FG=15

# -----------------------------------------------------------------------------
# Private functions

# --------------------------------------------------------------------------- #
# Apply foreground and background colors.                                     #
# Arguments:                                                                  #
#    $1 - String to be printed                                                #
#    $2 - Foreground color                                                    #
#    $3 - Background color                                                    #
# --------------------------------------------------------------------------- #
__psh_apply_color() {
    [[ $3 ]] && printf "\[\033[48;5;%sm\]" "$3"
    [[ $2 ]] && printf "\[\033[38;5;%sm\]" "$2"
    [[ $1 ]] && printf "%s" "$1"
}

# --------------------------------------------------------------------------- #
# Build the git segment.                                                      #
# Arguments:                                                                  #
#    None                                                                     #
# --------------------------------------------------------------------------- #
__psh_build_seg_git() {
    # Exit if Git isn't installed or current dir isn't a repo
    hash git &> /dev/null || return
    $PSH_GIT_COMMAND rev-parse &> /dev/null || return

    # Check if there are modifications on current branch
    local dirty count marks
    dirty=$($PSH_GIT_COMMAND status --porcelain 2> /dev/null)
    count=$(grep -c '^?? ' <<< "$dirty")
    marks=""
    if [[ $count -gt 0 ]]; then
        marks+=" $PSH_SYMBOL_GIT_UNTRACKED$count"
    fi

    # Count number of revisions ahead or behind origin
    local status
    status=$($PSH_GIT_COMMAND status --porcelain --branch 2> /dev/null)
    if [[ $status =~ ahead\ ([0-9]+) ]]; then
        marks+=" $PSH_SYMBOL_GIT_AHEAD${BASH_REMATCH[1]}"
    fi
    if [[ $status =~ behind\ ([0-9]+) ]]; then
        marks+=" $PSH_SYMBOL_GIT_BEHIND${BASH_REMATCH[1]}"
    fi

    local bg_color fg_color
    if [[ $dirty ]]; then
        bg_color=$PSH_COLOR_REPO_DIRTY_BG
        fg_color=$PSH_COLOR_REPO_DIRTY_FG
    else
        bg_color=$PSH_COLOR_REPO_CLEAN_BG
        fg_color=$PSH_COLOR_REPO_CLEAN_FG
    fi

    # Get current branch name or hash
    local branch
    branch=$(                                                  \
        $PSH_GIT_COMMAND symbolic-ref HEAD 2> /dev/null ||     \
        $PSH_GIT_COMMAND describe --tags --always 2> /dev/null \
    )

    __psh_apply_color " ${branch#refs/heads/}${marks} " $fg_color $bg_color
}

# --------------------------------------------------------------------------- #
# Build the jobs segment.                                                     #
# Arguments:                                                                  #
#    None                                                                     #
# --------------------------------------------------------------------------- #
__psh_build_seg_jobs() {
    local count
    count=$(jobs | wc -l | xargs)
    if [[ $count -gt 0 ]]; then
        __psh_apply_color " $count " $PSH_COLOR_JOBS_FG $PSH_COLOR_JOBS_BG
    fi
}

# --------------------------------------------------------------------------- #
# Build the username segment.                                                 #
# Arguments:                                                                  #
#    None                                                                     #
# --------------------------------------------------------------------------- #
__psh_build_seg_username() {
    local bg_color fg_color
    if id -G | grep -qE '\<(544|0)\>'; then
        bg_color=$PSH_COLOR_USERNAME_ROOT_BG
        fg_color=$PSH_COLOR_USERNAME_ROOT_FG
    else
        bg_color=$PSH_COLOR_USERNAME_BG
        fg_color=$PSH_COLOR_USERNAME_FG
    fi
    __psh_apply_color ' \u ' $fg_color $bg_color
}

# --------------------------------------------------------------------------- #
# Build the hostname segment.                                                 #
# Arguments:                                                                  #
#    None                                                                     #
# --------------------------------------------------------------------------- #
__psh_build_seg_hostname() {
    __psh_apply_color ' \h ' $PSH_COLOR_HOSTNAME_FG $PSH_COLOR_HOSTNAME_BG
}

# --------------------------------------------------------------------------- #
# Build the PS segment.                                                       #
# Arguments:                                                                  #
#    $1 - Last exit code                                                      #
# --------------------------------------------------------------------------- #
__psh_build_seg_ps() {
    local bg_color fg_color
    if [[ $1 -eq 0 ]]; then
        bg_color=$PSH_COLOR_CMD_PASSED_BG
        fg_color=$PSH_COLOR_CMD_PASSED_FG
    else
        bg_color=$PSH_COLOR_CMD_FAILED_BG
        fg_color=$PSH_COLOR_CMD_FAILED_FG
    fi
    __psh_apply_color ' \$ ' $fg_color $bg_color
}

# --------------------------------------------------------------------------- #
# Build the SSH segment.                                                      #
# Arguments:                                                                  #
#    None                                                                     #
# --------------------------------------------------------------------------- #
__psh_build_seg_ssh() {
    if [[ $SSH_CLIENT ]]; then
        __psh_apply_color " $PSH_SYMBOL_SSH " $PSH_COLOR_SSH_FG $PSH_COLOR_SSH_BG
    fi
}

# --------------------------------------------------------------------------- #
# Build the path segment.                                                     #
# Arguments:                                                                  #
#    None                                                                     #
# --------------------------------------------------------------------------- #
__psh_build_seg_path() {
    local folders=$PWD
    if [[ $PWD == / ]]; then
        folders='/'
    else
        if [[ $PWD =~ ^$HOME(/|$) ]]; then
            folders="~${PWD#$HOME}"
        fi
        IFS='/' read -r -a folders <<< "${folders#'/'}"
    fi
    local limit=$(( ${#folders[*]} - PSH_MAX_PATH_DEPTH ))

    local separator
    for i in ${!folders[*]}; do
        local folder
        if [[ $i -eq 0 ]] || [[ $i -gt $limit ]]; then
            folder="${folders[$i]}"
        elif [[ $i -eq 1 ]]; then
            folder="$PSH_SYMBOL_ELLIPSIS"
        else
            continue
        fi

        local bg_color fg_color sp_color
        if [[ ! -w $PWD ]]; then
            bg_color=$PSH_COLOR_READONLY_BG
            fg_color=$PSH_COLOR_READONLY_FG
            sp_color=$PSH_COLOR_READONLY_SEPARATOR
        elif [[ $PWD == "$HOME" ]]; then
            bg_color=$PSH_COLOR_HOME_BG
            fg_color=$PSH_COLOR_HOME_FG
        else
            bg_color=$PSH_COLOR_PATH_BG
            fg_color=$PSH_COLOR_PATH_FG
            sp_color=$PSH_COLOR_PATH_SEPARATOR
            if [[ $i -eq $(( ${#folders[*]} - 1 )) ]]; then
                fg_color=$PSH_COLOR_PATH_CWD
            fi
        fi
        __psh_apply_color "$separator" $sp_color
        __psh_apply_color " $folder " $fg_color $bg_color
        separator=$PSH_SYMBOL_PATH_SEPARATOR
    done
}

# --------------------------------------------------------------------------- #
# Set the $PS1 variable.                                                      #
# Arguments:                                                                  #
#    None                                                                     #
# --------------------------------------------------------------------------- #
__psh_set_ps1() {
    local exit_code=$?

    PS1=""
    PS1+="$(__psh_build_seg_ssh)"
    # PS1+="$(__psh_build_seg_username)"
    # PS1+="$(__psh_build_seg_hostname)"
    PS1+="$(__psh_build_seg_path)"
    PS1+="$(__psh_build_seg_git)"
    PS1+="$(__psh_build_seg_jobs)"
    PS1+="$(__psh_build_seg_ps $exit_code)"
    PS1+="\[\033[0m\] " # reset colors
}

PROMPT_COMMAND=__psh_set_ps1

# -----------------------------------------------------------------------------
# Aliases

alias -- -='cd -'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias ..2='cd ../..'
alias ..3='cd ../../..'
alias ..4='cd ../../../..'
alias ..5='cd ../../../../..'

alias df='df -h'
alias du='du -h'
alias vi='vim'

alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

alias _='sudo'
alias s='sudo -s'
alias h='history'
alias j='jobs -l'
alias p='pwd -P'
alias mkdir='mkdir -p'
alias path='printf "${PATH//:/\\n}\n"'

alias d='docker'
alias g='git'

alias l='ls -lah'
alias l.='ls -d .*'
alias la='ls -lAh'
alias ll='ls -lh'
alias ls='ls --color=auto'
[[ $OSTYPE == darwin* ]] && alias ls='ls -G'

# -----------------------------------------------------------------------------
# Public functions

md() {
    mkdir -p -- "$1" && { cd -- "$1" || return 1; }
}
