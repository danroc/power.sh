# power.sh

Minimalist Bash prompt.

## Installation

Just download the [`power.sh`](https://github.com/danroc/power.sh/blob/main/power.sh)
file from GitHub and source it from your `.bashrc` file:

```bash
curl -fsSL https://raw.githubusercontent.com/danroc/power.sh/master/power.sh -o "$HOME/.power.sh"
echo 'source "$HOME/.power.sh"' >> "$HOME/.bashrc"
```

## Customization

Colors and symbols can be customized by editing the constants prefixed with
`PSH_`. Prompt segments can be enabled or disabled by uncommenting or
commenting the corresponding lines in the `__psh_set_ps1` function.
