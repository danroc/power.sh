#!/bin/bash

# External commands
GIT_COMMAND="env LANG=C git"

# Max number of path segments
MAX_PATH_DEPTH=4

# Symbols
SYMBOL_GIT_UNTRACKED='+'
SYMBOL_GIT_AHEAD='↑'
SYMBOL_GIT_BEHIND='↓'

SYMBOL_PATH_SEPARATOR='❯'
SYMBOL_SSH='SSH'
SYMBOL_ELLIPSIS='…'

# Color scheme
COLOR_SSH_BG=166
COLOR_SSH_FG=254

COLOR_JOBS_BG=238
COLOR_JOBS_FG=39

COLOR_REPO_CLEAN_BG=148
COLOR_REPO_CLEAN_FG=0
COLOR_REPO_DIRTY_BG=161
COLOR_REPO_DIRTY_FG=15

COLOR_USERNAME_ROOT_BG=124
COLOR_USERNAME_ROOT_FG=250
COLOR_USERNAME_BG=240
COLOR_USERNAME_FG=250

COLOR_HOSTNAME_FG=250
COLOR_HOSTNAME_BG=238

COLOR_PATH_BG=237
COLOR_PATH_FG=250
COLOR_PATH_CWD=254
COLOR_PATH_SEPARATOR=244

COLOR_HOME_BG=31
COLOR_HOME_FG=15

COLOR_READONLY_BG=124
COLOR_READONLY_FG=254
COLOR_READONLY_SEPARATOR=248

COLOR_CMD_PASSED_BG=236
COLOR_CMD_PASSED_FG=15
COLOR_CMD_FAILED_BG=161
COLOR_CMD_FAILED_FG=15

# --------------------------------------------------------------------------- #
# Apply foreground and background colors.                                     #
# Arguments:                                                                  #
#    $1 - String to be printed                                                #
#    $2 - Foreground color                                                    #
#    $3 - Background color                                                    #
# --------------------------------------------------------------------------- #
apply_color() {
    [[ $3 ]] && printf "\[\033[48;5;%sm\]" "$3"
    [[ $2 ]] && printf "\[\033[38;5;%sm\]" "$2"
    [[ $1 ]] && printf "%s" "$1"
}

# --------------------------------------------------------------------------- #
# Build the git segment.                                                      #
# Arguments:                                                                  #
#    None                                                                     #
# --------------------------------------------------------------------------- #
build_seg_git() {
    # Exit if Git isn't installed or current dir isn't a repo
    hash git &> /dev/null || return
    $GIT_COMMAND rev-parse &> /dev/null || return

    # Check if there are modifications on current branch
    local dirty count marks
    dirty=$($GIT_COMMAND status --porcelain 2> /dev/null)
    count=$(grep -c '^?? ' <<< "$dirty")
    marks=""
    if [[ $count -gt 0 ]]; then
        marks+=" $SYMBOL_GIT_UNTRACKED$count"
    fi

    # Count number of revisions ahead or behind origin
    local status
    status=$($GIT_COMMAND status --porcelain --branch 2> /dev/null)
    if [[ $status =~ ahead\ ([0-9]+) ]]; then
        marks+=" $SYMBOL_GIT_AHEAD${BASH_REMATCH[1]}"
    fi
    if [[ $status =~ behind\ ([0-9]+) ]]; then
        marks+=" $SYMBOL_GIT_BEHIND${BASH_REMATCH[1]}"
    fi

    local bg_color fg_color
    if [[ $dirty ]]; then
        bg_color=$COLOR_REPO_DIRTY_BG
        fg_color=$COLOR_REPO_DIRTY_FG
    else
        bg_color=$COLOR_REPO_CLEAN_BG
        fg_color=$COLOR_REPO_CLEAN_FG
    fi

    # Get current branch name or hash
    local branch
    branch=$($GIT_COMMAND symbolic-ref HEAD 2> /dev/null || \
             $GIT_COMMAND describe --tags --always 2> /dev/null)

    apply_color " ${branch#refs/heads/}${marks} " $fg_color $bg_color
}

# --------------------------------------------------------------------------- #
# Build the jobs segment.                                                     #
# Arguments:                                                                  #
#    None                                                                     #
# --------------------------------------------------------------------------- #
build_seg_jobs() {
    local count
    count=$(jobs | wc -l | xargs)
    if [[ $count -gt 0 ]]; then
        apply_color " $count " $COLOR_JOBS_FG $COLOR_JOBS_BG
    fi
}

# --------------------------------------------------------------------------- #
# Build the username segment.                                                 #
# Arguments:                                                                  #
#    None                                                                     #
# --------------------------------------------------------------------------- #
build_seg_username() {
    local bg_color fg_color
    if id -G | grep -qE '\<(544|0)\>'; then
        bg_color=$COLOR_USERNAME_ROOT_BG
        fg_color=$COLOR_USERNAME_ROOT_FG
    else
        bg_color=$COLOR_USERNAME_BG
        fg_color=$COLOR_USERNAME_FG
    fi
    apply_color ' \u ' $fg_color $bg_color
}

# --------------------------------------------------------------------------- #
# Build the hostname segment.                                                 #
# Arguments:                                                                  #
#    None                                                                     #
# --------------------------------------------------------------------------- #
build_seg_hostname() {
    apply_color ' \h ' $COLOR_HOSTNAME_FG $COLOR_HOSTNAME_BG
}

# --------------------------------------------------------------------------- #
# Build the PS segment.                                                       #
# Arguments:                                                                  #
#    $1 - Last exit code                                                      #
# --------------------------------------------------------------------------- #
build_seg_ps() {
    local bg_color fg_color
    if [[ $1 -eq 0 ]]; then
        bg_color=$COLOR_CMD_PASSED_BG
        fg_color=$COLOR_CMD_PASSED_FG
    else
        bg_color=$COLOR_CMD_FAILED_BG
        fg_color=$COLOR_CMD_FAILED_FG
    fi
    apply_color ' \$ ' $fg_color $bg_color
}

# --------------------------------------------------------------------------- #
# Build the SSH segment.                                                      #
# Arguments:                                                                  #
#    None                                                                     #
# --------------------------------------------------------------------------- #
build_seg_ssh() {
    if [[ $SSH_CLIENT ]]; then
        apply_color " $SYMBOL_SSH " $COLOR_SSH_FG $COLOR_SSH_BG
    fi
}

# --------------------------------------------------------------------------- #
# Build the path segment.                                                     #
# Arguments:                                                                  #
#    None                                                                     #
# --------------------------------------------------------------------------- #
build_seg_path() {
    local folders=$PWD
    if [[ $PWD == / ]]; then
        folders='/'
    else
        if [[ $PWD =~ ^$HOME(/|$) ]]; then
            folders="~${PWD#$HOME}"
        fi
        IFS='/' read -r -a folders <<< "${folders#'/'}"
    fi
    local limit=$(( ${#folders[*]} - MAX_PATH_DEPTH ))

    local separator
    for i in ${!folders[*]}; do
        local folder
        if [[ $i -eq 0 ]] || [[ $i -gt $limit ]]; then
            folder="${folders[$i]}"
        elif [[ $i -eq 1 ]]; then
            folder="$SYMBOL_ELLIPSIS"
        else
            continue
        fi

        local bg_color fg_color sp_color
        if [[ ! -w $PWD ]]; then
            bg_color=$COLOR_READONLY_BG
            fg_color=$COLOR_READONLY_FG
            sp_color=$COLOR_READONLY_SEPARATOR
        elif [[ $PWD == "$HOME" ]]; then
            bg_color=$COLOR_HOME_BG
            fg_color=$COLOR_HOME_FG
        else
            bg_color=$COLOR_PATH_BG
            fg_color=$COLOR_PATH_FG
            sp_color=$COLOR_PATH_SEPARATOR
            if [[ $i -eq $(( ${#folders[*]} - 1 )) ]]; then
                fg_color=$COLOR_PATH_CWD
            fi
        fi
        apply_color "$separator" $sp_color
        apply_color " $folder " $fg_color $bg_color
        separator=$SYMBOL_PATH_SEPARATOR
    done
}

# --------------------------------------------------------------------------- #
# Set the $PS1 variable.                                                      #
# Arguments:                                                                  #
#    None                                                                     #
# --------------------------------------------------------------------------- #
set_ps1() {
    local exit_code=$?

    PS1=""
    PS1+="$(build_seg_ssh)"
    # PS1+="$(build_seg_username)"
    # PS1+="$(build_seg_hostname)"
    PS1+="$(build_seg_path)"
    PS1+="$(build_seg_git)"
    PS1+="$(build_seg_jobs)"
    PS1+="$(build_seg_ps $exit_code)"
    PS1+="\[\033[0m\] " # reset colors
}

PROMPT_COMMAND=set_ps1

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

md() { mkdir -p -- "$1" && { cd -- "$1" || return 1; } }
