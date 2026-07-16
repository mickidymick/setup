# Setup

Personal bootstrap repo for a [yed](https://your-editor.org)-centric dev environment on Linux/WSL.

## Flags

All flags are opt-in and combinable; a bare `./install.sh` does the base install only.

| Flag | What it does |
| --- | --- |
| *(none)* | Base install: build + install yed to `~/.local`, PowerlineSymbols font, `.bashrc`, `kitty.conf`, and compile yed plugins + config into `~/.config/yed`. |
| `--lsp` | Also install LSP servers — `clangd`, `bash-language-server`, `pylsp`, `marksman` — via `sudo apt`. Under `--hpc`, uses user-space installs instead (no sudo). |
| `--hpc` | HPC login-node mode (e.g. Frontier/OLCF): no sudo, no apt. Skips fonts + `kitty.conf` (both are local-terminal concerns), *appends* to shell rc files instead of overwriting them, and uses user-space LSP installs. `module load` a compiler (e.g. `module load gcc`) before running. |
| `--zsh` | Also install the zsh config (`.zshrc`). bash is still set up by default — this adds zsh alongside it, it does not replace it. |
| `--claude` | Install Claude Code (no sudo, to `~/.local/bin`) if not already on PATH, then install the statusLine script to `~/.claude` and merge the `statusLine` key into `~/.claude/settings.json`. Needs `jq`. |
| `-h`, `--help` | Print usage and exit. |

Tab-completion for these is provided by the repo's `.bashrc` and offers only the flags not already on the line.

## What it installs

- **yed** itself, built from the `yed/` submodule (dev branch) into `~/.local`
- **PowerlineSymbols** font (`fonts-powerline` via apt) + `fc-cache`
- `~/.bashrc` — shell config (custom prompt, aliases including `ll` → `new_ls.sh`)
- `~/.config/kitty/kitty.conf` — terminal config
- `~/.config/yed/` — yed plugins compiled from `./.yed/**/*.c` (excluding `lsp_repos/`), plus `yedrc`, `ypm_list`, and `templates/`
- *(optional, `--lsp`)* LSP servers: `clangd`, `bash-language-server`, `pylsp`, `marksman`
- *(optional, `--claude`)* Claude Code (via `claude.ai/install.sh` if not already on PATH — no sudo, installs to `~/.local/bin`) plus `~/.claude/statusline-command.sh`, a statusLine showing context + 5hr rate-limit bars. The `statusLine` key is *merged* into `~/.claude/settings.json` (never overwriting it — that file also holds per-machine keys like `enabledPlugins`/`theme`). Needs `jq` at runtime.

## Prerequisites

- `gcc`, `make`, `git`
- `kitty` (for `kitty.conf`)
- `sudo` (for font + optional LSP installs)
- `unbuffer` (`expect` package — for `new_ls.sh`)

## Usage

```sh
git clone --recurse-submodules <this-repo>
cd setup
./install.sh                # bootstrap: build yed, install fonts + dotfiles + plugins
./install.sh --lsp          # additionally install LSP servers (sudo)
./install.sh --claude       # additionally install Claude Code + its statusLine
./install.sh --hpc --lsp    # login-node install: no sudo, user-space LSP servers
./install.sh --zsh --claude # flags combine freely
./install.sh --help         # full flag list
./update.sh                 # interactive: diff repo vs installed, push or pull per file
```

`install.sh` writes per-step logs under `/tmp/setup-<timestamp>/` and prints `[OK]` / `[FAIL]` per step. `update.sh` is for ongoing maintenance — it shows unified diffs and lets you choose direction (with `.bak-<timestamp>` backups).

If you cloned without `--recurse-submodules`, `install.sh` will run `git submodule update --init` for you.

## Layout

```
install.sh             # bootstrap: yed build, fonts, dotfiles, plugin compile
update.sh              # bidirectional dotfile sync
yed/                   # submodule: github.com/your-editor/yed (dev)
kitty.conf             # kitty terminal config
new_ls.sh              # custom columnar `ls` (aliased to `ll`)
scripts/
  check_fonts.txt      # font glyph reference (eyeball check)
.claude/
  statusline-command.sh  # Claude Code statusLine (installed by --claude)
.yed/
  init.c, plugins/     # yed plugin C sources (compiled by install.sh)
  yedrc, ypm_list      # yed config + plugin manifest
  templates/           # file templates
  lsp_repos/           # LSP-server install scripts (run via install.sh --lsp)
```

## Related dirs (not in this repo)

- `~/yed/` — yed source tree
- `~/tmp_yed/ypm-plugins/` — ypm (yed plugin manager) tooling
- `~/tmp_yed/completed_plugins/` — plugin collection (lsp, my, other)
