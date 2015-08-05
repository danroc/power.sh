#!/usr/bin/env bash

__powerbash() {
    # external commands
    readonly GIT_CMD="env LANG=C git"

    # max number of folders in path
    readonly MAX_PATH_DEPTH=4

    # symbols
    readonly SYMBOL_GIT_UNTRACKED='+'
    readonly SYMBOL_GIT_AHEAD='↑'
    readonly SYMBOL_GIT_BEHIND='↓'
    readonly SYMBOL_GIT_BRANCH=''

    readonly SYMBOL_PATH_SEPARATOR='❯'
    readonly SYMBOL_SSH='SSH'
    readonly SYMBOL_ELLIPSIS='…'

    # colors
    readonly COLOR_SSH_BG=166
    readonly COLOR_SSH_FG=254

    readonly COLOR_JOBS_BG=238
    readonly COLOR_JOBS_FG=39

    readonly COLOR_REPO_CLEAN_BG=148
    readonly COLOR_REPO_CLEAN_FG=0
    readonly COLOR_REPO_DIRTY_BG=161
    readonly COLOR_REPO_DIRTY_FG=15

    readonly COLOR_USERNAME_ROOT_BG=124
    readonly COLOR_USERNAME_ROOT_FG=250
    readonly COLOR_USERNAME_BG=240
    readonly COLOR_USERNAME_FG=250

    readonly COLOR_HOSTNAME_FG=250
    readonly COLOR_HOSTNAME_BG=238

    readonly COLOR_PATH_BG=237
    readonly COLOR_PATH_FG=250
    readonly COLOR_PATH_SEPARATOR=244

    readonly COLOR_HOME_BG=31
    readonly COLOR_HOME_FG=15

    readonly COLOR_READONLY_BG=124
    readonly COLOR_READONLY_FG=254
    readonly COLOR_READONLY_SEPARATOR=248

    readonly COLOR_CMD_PASSED_BG=236
    readonly COLOR_CMD_PASSED_FG=15
    readonly COLOR_CMD_FAILED_BG=161
    readonly COLOR_CMD_FAILED_FG=15

    # ------------------------------------------------------------------------ #
    # Applies foreground/background colors.                                    #
    # Arguments:                                                               #
    #    $1 - String to be printed                                             #
    #    $2 - Foreground color                                                 #
    #    $3 - Background color                                                 #
    # ------------------------------------------------------------------------ #
    apply_color() {
        if [[ -n "$3" ]]; then
            printf "\[\033[48;5;$3m\]"
        fi
        if [[ -n "$2" ]]; then
            printf "\[\033[38;5;$2m\]"
        fi
        if [[ -n "$1" ]]; then
            printf "$1"
        fi
    }

    # ------------------------------------------------------------------------ #
    # Splits the $PWD variable into an array.                                  #
    # Arguments:                                                               #
    #    None                                                                  #
    # ------------------------------------------------------------------------ #
    split_pwd() {
        if [[ "$PWD" == "/" ]]; then
            echo '/'
        else
            local working="$PWD"
            [[ "$PWD" =~ ^"$HOME"(/|$) ]] && working="~${working#$HOME}"
            local IFS='/'
            echo $working
        fi
    }

    # ------------------------------------------------------------------------ #
    # Builds the git segment.                                                  #
    # Arguments:                                                               #
    #    None                                                                  #
    # ------------------------------------------------------------------------ #
    build_seg_git() {
        # exit if git isn't installed or the folder isn't a valid git folder
        hash git 2>/dev/null || return
        $GIT_CMD rev-parse --is-inside-work-tree > /dev/null 2>&1 || return

        # get current branch name or hash
        local branch="$($GIT_CMD symbolic-ref --short HEAD || $GIT_CMD describe --tags --always)"
        [[ -n "$branch" ]] || return

        local repo_status="$($GIT_CMD status --porcelain --branch)"

        # keep these lines aligned to easily spot typos
        local  has_modified="$(echo "$repo_status" | grep '^.. ' | grep '[MADRCU]')"
        local  behind_count="$(echo "$repo_status" | grep '^## ' | grep -o '\[behind [[:digit:]]\+\]$' | grep -o '[[:digit:]]\+')"
        local   ahead_count="$(echo "$repo_status" | grep '^## ' | grep -o  '\[ahead [[:digit:]]\+\]$' | grep -o '[[:digit:]]\+')"
        local untrack_count="$(echo "$repo_status" | grep '^?? ' | wc -l                               | grep -o '[[:digit:]]\+')"

        local marks=""
        [[ "$untrack_count" -gt 0 ]] && marks+=" ${SYMBOL_GIT_UNTRACKED}${untrack_count}"
        [[ -n "$ahead_count" ]] && marks+=" ${SYMBOL_GIT_AHEAD}${ahead_count}"
        [[ -n "$behind_count" ]] && marks+=" ${SYMBOL_GIT_BEHIND}${behind_count}"

        if [[ -n "$has_modified" ]]; then
            local bg_color="$COLOR_REPO_DIRTY_BG"
            local fg_color="$COLOR_REPO_DIRTY_FG"
        else
            local bg_color="$COLOR_REPO_CLEAN_BG"
            local fg_color="$COLOR_REPO_CLEAN_FG"
        fi
        apply_color " ${SYMBOL_GIT_BRANCH}${branch}${marks} " "$fg_color" "$bg_color"
    }

    # ------------------------------------------------------------------------ #
    # Builds the jobs segment.                                                 #
    # Arguments:                                                               #
    #    None                                                                  #
    # ------------------------------------------------------------------------ #
    build_seg_jobs() {
        local count="$(jobs | wc -l | grep -o '[[:digit:]]\+')"
        [[ "$count" -gt 0 ]] && apply_color " $count " "$COLOR_JOBS_FG" "$COLOR_JOBS_BG"
    }

    # ------------------------------------------------------------------------ #
    # Builds the username segment.                                             #
    # Arguments:                                                               #
    #    None                                                                  #
    # ------------------------------------------------------------------------ #
    build_seg_username() {
        if id -G | grep -qE '\<(544|0)\>' ; then
            local bg_color="$COLOR_USERNAME_ROOT_BG"
            local fg_color="$COLOR_USERNAME_ROOT_FG"
        else
            local bg_color="$COLOR_USERNAME_BG"
            local fg_color="$COLOR_USERNAME_FG"
        fi
        apply_color ' \\u ' "$fg_color" "$bg_color"
    }

    # ------------------------------------------------------------------------ #
    # Builds the hostname segment.                                             #
    # Arguments:                                                               #
    #    None                                                                  #
    # ------------------------------------------------------------------------ #
    build_seg_hostname() {
        apply_color ' \\h ' "$COLOR_HOSTNAME_FG" "$COLOR_HOSTNAME_BG"
    }

    # ------------------------------------------------------------------------ #
    # Builds the PS segment.                                                   #
    # Arguments:                                                               #
    #    $1 - Last exit code                                                   #
    # ------------------------------------------------------------------------ #
    build_seg_ps() {
        if [[ "$1" -eq 0 ]]; then
            local bg_color="$COLOR_CMD_PASSED_BG"
            local fg_color="$COLOR_CMD_PASSED_FG"
        else
            local bg_color="$COLOR_CMD_FAILED_BG"
            local fg_color="$COLOR_CMD_FAILED_FG"
        fi
        [[ "$1" -ne 0 ]] && local code="($1) "
        apply_color " ${code}\\$ " "$fg_color" "$bg_color"
    }

    # ------------------------------------------------------------------------ #
    # Builds the SSH segment.                                                  #
    # Arguments:                                                               #
    #    None                                                                  #
    # ------------------------------------------------------------------------ #
    build_seg_ssh() {
        [[ -n "$SSH_CLIENT" ]] && apply_color " $SYMBOL_SSH " "$COLOR_SSH_FG" "$COLOR_SSH_BG"
    }

    # ------------------------------------------------------------------------ #
    # Builds the path segment.                                                 #
    # Arguments:                                                               #
    #    None                                                                  #
    # ------------------------------------------------------------------------ #
    build_seg_path() {
        if [[ ! -w "$PWD" ]]; then
            local bg_color="$COLOR_READONLY_BG"
            local fg_color="$COLOR_READONLY_FG"
            local sp_color="$COLOR_READONLY_SEPARATOR"
        elif [[ "$PWD" == "$HOME" ]]; then
            local bg_color="$COLOR_HOME_BG"
            local fg_color="$COLOR_HOME_FG"
            local sp_color=""
        else
            local bg_color="$COLOR_PATH_BG"
            local fg_color="$COLOR_PATH_FG"
            local sp_color="$COLOR_PATH_SEPARATOR"
        fi

        local folders=($(split_pwd))
        local limit="$(( ${#folders[*]} - $MAX_PATH_DEPTH ))"

        local separator=""
        for i in ${!folders[*]}; do
            if [[ "$i" -eq 0 ]] || [[ "$i" -gt "$limit" ]]; then
                folder="${folders[$i]}"
            elif [[ "$i" -eq 1 ]]; then
                folder="$SYMBOL_ELLIPSIS"
            else
                continue
            fi
            apply_color "$separator" "$sp_color"
            apply_color " $folder " "$fg_color" "$bg_color"
            separator="$SYMBOL_PATH_SEPARATOR"
        done
    }

    # ------------------------------------------------------------------------ #
    # Sets the $PS1 variable.                                                  #
    # Arguments:                                                               #
    #    None                                                                  #
    # ------------------------------------------------------------------------ #
    set_ps1() {
        local exit_code="$?"

        PS1=""
        PS1+="$(build_seg_ssh)"
        PS1+="$(build_seg_username)"
        PS1+="$(build_seg_hostname)"
        PS1+="$(build_seg_path)"
        PS1+="$(build_seg_git)"
        PS1+="$(build_seg_jobs)"
        PS1+="$(build_seg_ps "$exit_code")"
        PS1+="\[\033[0m\] " # reset colors
    }

    PROMPT_COMMAND=set_ps1
}

__powerbash
unset __powerbash