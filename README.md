# power.sh

Minimalist Bash prompt.

## Installation

Just download the [`power.sh`](https://github.com/danroc/power.sh/blob/main/power.sh)
file:

```bash
curl -fsSL https://github.com/danroc/power.sh/raw/main/power.sh -o "$HOME/.power.sh"
```

And source it from your `.bashrc`:

```bash
echo 'source "$HOME/.power.sh"' >> "$HOME/.bashrc"
```

To start using it, you can re-open a terminal or:

```bash
source "$HOME/.power.sh"
```

## Customization

The following environment variables can be set to configure power.sh:

| Environment variable           | Default          |
| :----------------------------- | :--------------- |
| `PSH_ENABLE_SEGMENT_SSH`       | `true`           |
| `PSH_ENABLE_SEGMENT_USERNAME`  | `false`          |
| `PSH_ENABLE_SEGMENT_HOSTNAME`  | `false`          |
| `PSH_ENABLE_SEGMENT_RESTART`   | `true`           |
| `PSH_ENABLE_SEGMENT_PATH`      | `true`           |
| `PSH_ENABLE_SEGMENT_GIT`       | `true`           |
| `PSH_ENABLE_SEGMENT_JOBS`      | `true`           |
| `PSH_ENABLE_SEGMENT_EXIT_CODE` | `true`           |
| `PSH_GIT_COMMAND`              | `env LANG=C git` |
| `PSH_MAX_PATH_DEPTH`           | `4`              |
| `PSH_SYMBOL_GIT_UNTRACKED`     | `+`              |
| `PSH_SYMBOL_GIT_DELETED`       | `-`              |
| `PSH_SYMBOL_GIT_MODIFIED`      | `*`              |
| `PSH_SYMBOL_GIT_AHEAD`         | `↑`              |
| `PSH_SYMBOL_GIT_BEHIND`        | `↓`              |
| `PSH_SYMBOL_RESTART`           | `↺`              |
| `PSH_SYMBOL_PATH_SEPARATOR`    | `❯`              |
| `PSH_SYMBOL_SSH`               | `SSH`            |
| `PSH_SYMBOL_ELLIPSIS`          | `…`              |
| `PSH_COLOR_SSH_BG`             | `166`            |
| `PSH_COLOR_SSH_FG`             | `254`            |
| `PSH_COLOR_JOBS_BG`            | `238`            |
| `PSH_COLOR_JOBS_FG`            | `39`             |
| `PSH_COLOR_REPO_CLEAN_BG`      | `148`            |
| `PSH_COLOR_REPO_CLEAN_FG`      | `0`              |
| `PSH_COLOR_REPO_DIRTY_BG`      | `161`            |
| `PSH_COLOR_REPO_DIRTY_FG`      | `15`             |
| `PSH_COLOR_USERNAME_ROOT_BG`   | `124`            |
| `PSH_COLOR_USERNAME_ROOT_FG`   | `250`            |
| `PSH_COLOR_USERNAME_BG`        | `240`            |
| `PSH_COLOR_USERNAME_FG`        | `250`            |
| `PSH_COLOR_HOSTNAME_FG`        | `250`            |
| `PSH_COLOR_HOSTNAME_BG`        | `238`            |
| `PSH_COLOR_PATH_BG`            | `237`            |
| `PSH_COLOR_PATH_FG`            | `250`            |
| `PSH_COLOR_PATH_CWD`           | `254`            |
| `PSH_COLOR_PATH_SEPARATOR`     | `244`            |
| `PSH_COLOR_HOME_BG`            | `31`             |
| `PSH_COLOR_HOME_FG`            | `15`             |
| `PSH_COLOR_READONLY_BG`        | `124`            |
| `PSH_COLOR_READONLY_FG`        | `254`            |
| `PSH_COLOR_READONLY_SEPARATOR` | `248`            |
| `PSH_COLOR_CMD_PASSED_BG`      | `236`            |
| `PSH_COLOR_CMD_PASSED_FG`      | `15`             |
| `PSH_COLOR_CMD_FAILED_BG`      | `161`            |
| `PSH_COLOR_CMD_FAILED_FG`      | `15`             |
| `PSH_COLOR_RESTART_BG`         | `124`            |
| `PSH_COLOR_RESTART_FG`         | `250`            |
