#!/usr/bin/env bash

__powerbash() {
    # External commands
    GIT_CMD="env LANG=C git"

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

    # ------------------------------------------------------------------------ #
    # Applies foreground/background colors.                                    #
    # Arguments:                                                               #
    #    $1 - String to be printed                                             #
    #    $2 - Foreground color                                                 #
    #    $3 - Background color                                                 #
    # ------------------------------------------------------------------------ #
    apply_color() {
        [[ $3 ]] && printf "\[\033[48;5;$3m\]"
        [[ $2 ]] && printf "\[\033[38;5;$2m\]"
        [[ $1 ]] && printf "$1"
    }

    # ------------------------------------------------------------------------ #
    # Builds the git segment.                                                  #
    # Arguments:                                                               #
    #    None                                                                  #
    # ------------------------------------------------------------------------ #
    build_seg_git() {
        # exit if git isn't installed or the folder isn't a valid git folder
        hash git &> /dev/null || return
        $GIT_CMD rev-parse --is-inside-work-tree &> /dev/null || return

        # get current branch name or hash
        local branch="$($GIT_CMD symbolic-ref HEAD || $GIT_CMD describe --tags --always)"
        [[ $branch ]] || return

        # check if there are modifications on current branch
        local has_modified="$($GIT_CMD status --porcelain 2> /dev/null)"
        local untrack_count=$(grep '^?? ' <<< "$has_modified" | wc -l | awk '{print $1}')

        # count number of revisions ahead or behind origin
        local repo_status="$($GIT_CMD status --porcelain 2> /dev/null)"
        local marks=""
        [[ $untrack_count -gt 0 ]] && marks+=" ${SYMBOL_GIT_UNTRACKED}${untrack_count}"
        [[ $repo_status =~  ahead\ ([0-9]+) ]] && marks+=" ${SYMBOL_GIT_AHEAD}${BASH_REMATCH[1]}"
        [[ $repo_status =~ behind\ ([0-9]+) ]] && marks+=" ${SYMBOL_GIT_BEHIND}${BASH_REMATCH[1]}"

        local bg_color fg_color
        if [[ $has_modified ]]; then
            bg_color=$COLOR_REPO_DIRTY_BG
            fg_color=$COLOR_REPO_DIRTY_FG
        else
            bg_color=$COLOR_REPO_CLEAN_BG
            fg_color=$COLOR_REPO_CLEAN_FG
        fi
        apply_color " ${branch#refs/heads/}${marks} " $fg_color $bg_color
    }

    # ------------------------------------------------------------------------ #
    # Builds the jobs segment.                                                 #
    # Arguments:                                                               #
    #    None                                                                  #
    # ------------------------------------------------------------------------ #
    build_seg_jobs() {
        local count="$(jobs | wc -l | awk '{print $1}')"
        [[ $count -gt 0 ]] && apply_color " $count " $COLOR_JOBS_FG $COLOR_JOBS_BG
    }

    # ------------------------------------------------------------------------ #
    # Builds the username segment.                                             #
    # Arguments:                                                               #
    #    None                                                                  #
    # ------------------------------------------------------------------------ #
    build_seg_username() {
        local bg_color fg_color
        if id -G | grep -qE '\<(544|0)\>' ; then
            bg_color=$COLOR_USERNAME_ROOT_BG
            fg_color=$COLOR_USERNAME_ROOT_FG
        else
            bg_color=$COLOR_USERNAME_BG
            fg_color=$COLOR_USERNAME_FG
        fi
        apply_color ' \\u ' $fg_color $bg_color
    }

    # ------------------------------------------------------------------------ #
    # Builds the hostname segment.                                             #
    # Arguments:                                                               #
    #    None                                                                  #
    # ------------------------------------------------------------------------ #
    build_seg_hostname() {
        apply_color ' \\h ' $COLOR_HOSTNAME_FG $COLOR_HOSTNAME_BG
    }

    # ------------------------------------------------------------------------ #
    # Builds the PS segment.                                                   #
    # Arguments:                                                               #
    #    $1 - Last exit code                                                   #
    # ------------------------------------------------------------------------ #
    build_seg_ps() {
        local bg_color fg_color
        if [[ $1 -eq 0 ]]; then
            bg_color=$COLOR_CMD_PASSED_BG
            fg_color=$COLOR_CMD_PASSED_FG
        else
            bg_color=$COLOR_CMD_FAILED_BG
            fg_color=$COLOR_CMD_FAILED_FG
        fi
        apply_color ' \\$ ' $fg_color $bg_color
    }

    # ------------------------------------------------------------------------ #
    # Builds the SSH segment.                                                  #
    # Arguments:                                                               #
    #    None                                                                  #
    # ------------------------------------------------------------------------ #
    build_seg_ssh() {
        [[ $SSH_CLIENT ]] && apply_color " $SYMBOL_SSH " $COLOR_SSH_FG $COLOR_SSH_BG
    }

    # ------------------------------------------------------------------------ #
    # Builds the path segment.                                                 #
    # Arguments:                                                               #
    #    None                                                                  #
    # ------------------------------------------------------------------------ #
    build_seg_path() {
        local folders="$PWD"
        if [[ $PWD == "/" ]]; then
            folders='/'
        else
            [[ $PWD =~ ^$HOME(/|$) ]] && folders="~${PWD#$HOME}"
            IFS='/' read -a folders <<< "${folders#'/'}"
        fi
        local limit=$(( ${#folders[*]} - $MAX_PATH_DEPTH ))

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
            elif [[ $PWD == $HOME ]]; then
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
            separator="$SYMBOL_PATH_SEPARATOR"
        done
    }

    # ------------------------------------------------------------------------ #
    # Sets the $PS1 variable.                                                  #
    # Arguments:                                                               #
    #    None                                                                  #
    # ------------------------------------------------------------------------ #
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
}

__powerbash
unset __powerbash
