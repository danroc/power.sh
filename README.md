# power.sh

Minimalist Bash prompt.

## Installation

Just download the [`power.sh`](https://github.com/danroc/power.sh/blob/main/power.sh)
file, and source it from your `.bashrc`:

```bash
curl -fsSL https://github.com/danroc/power.sh/raw/main/power.sh -o "$HOME/.power.sh"
echo 'source "$HOME/.power.sh"' >> "$HOME/.bashrc"
```

## Customization

Colors and symbols can be customized by editing the constants prefixed with
`PSH_`. Prompt segments can be enabled or disabled by uncommenting or
commenting the corresponding lines in the `__psh_set_ps1` function.
