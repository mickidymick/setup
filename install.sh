#! /usr/bin/env bash
# Bootstraps the dev environment:
#   - builds and installs yed (submodule, dev branch) to ~/.local
#   - installs PowerlineSymbols font
#   - copies dotfiles (.bashrc, kitty.conf)
#   - compiles and installs yed plugins
#   - copies yed config (yedrc, ypm_list, templates/)
# Pass --lsp to also install LSP servers (sudo).

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

HM="$HOME"
LOG_DIR="${TMPDIR:-/tmp}/setup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$LOG_DIR"

# ----- output helpers -----
say()  { printf '\n==> %s\n' "$*"; }
step() { printf '    %-50s ' "$*"; }
ok()   { printf '[OK]\n'; }
warn() { printf '[WARN] %s\n' "$*"; }
die()  { printf '[FAIL]'; [ -n "${1:-}" ] && printf ' %s' "$1"; printf '\n'; exit 1; }

INSTALL_LSP=0
HPC=0
INSTALL_ZSH=0
for arg in "$@"; do
    case "$arg" in
        --lsp) INSTALL_LSP=1 ;;
        --hpc) HPC=1 ;;
        --zsh) INSTALL_ZSH=1 ;;
        -h|--help)
            echo "Usage: $0 [--lsp] [--hpc] [--zsh]"
            echo "  --lsp   also install LSP servers"
            echo "          (default: clangd/bash/pylsp/marksman via sudo apt;"
            echo "           with --hpc: user-space installs, no sudo)"
            echo "  --hpc   HPC login-node mode (e.g. Frontier/OLCF): no sudo, no apt."
            echo "          Skips fonts + kitty.conf, appends to (never overwrites)"
            echo "          shell rc files, and uses user-space LSP installs. Load a"
            echo "          compiler module (e.g. 'module load gcc') before running."
            echo "  --zsh   also install the zsh config (.zshrc). bash is still set up"
            echo "          by default; this just adds zsh support alongside it."
            exit 0
            ;;
        *) echo "Unknown arg: $arg" >&2; exit 1 ;;
    esac
done

echo "Logs: $LOG_DIR"
[ "$HPC" = 1 ] && say "HPC mode: no sudo/apt, skipping fonts + kitty, appending to shell rc(s)"
[ "$INSTALL_ZSH" = 1 ] && say "zsh: will also install .zshrc alongside bash"

# ----- 1. yed (submodule) -----
say "yed (submodule, dev branch)"
if [ ! -e "$DIR/yed/install.sh" ]; then
    step "init/update submodule"
    if git submodule update --init --recursive >"$LOG_DIR/submodule.log" 2>&1; then ok; else die "see $LOG_DIR/submodule.log"; fi
fi
step "build & install (prefix=\$HOME/.local)"
if ( cd "$DIR/yed" && ./install.sh -p "$HOME/.local" ) >"$LOG_DIR/yed-build.log" 2>&1; then ok; else die "see $LOG_DIR/yed-build.log"; fi

# Ensure freshly-built yed is on PATH for the rest of this script (e.g. yed --print-cflags below)
export PATH="$HOME/.local/bin:$PATH"

# ----- 2. fonts -----
# Fonts render in your LOCAL terminal, not on a remote host, so this whole
# step is skipped in HPC mode (and it needs sudo/apt, unavailable there).
if [ "$HPC" = 1 ]; then
    say "PowerlineSymbols font (skipped in HPC mode — install fonts on your local machine)"
else
    say "PowerlineSymbols font"
    if dpkg -s fonts-powerline >/dev/null 2>&1; then
        step "fonts-powerline (already installed)"; ok
    else
        step "apt install fonts-powerline (sudo)"
        if sudo apt -y install fonts-powerline >"$LOG_DIR/fonts.log" 2>&1; then ok; else die "see $LOG_DIR/fonts.log"; fi
    fi
    step "fc-cache -f"
    if fc-cache -f >"$LOG_DIR/fc-cache.log" 2>&1; then ok; else warn "fc-cache failed; see $LOG_DIR/fc-cache.log"; fi
fi

# ----- 3. dotfiles -----
say "Dotfiles"

# install_rc <src-in-repo> <dest>
#   HPC mode : install <dest>.setup and source it from <dest> via an idempotent
#              guard block, so we never clobber a login node's rc (module init).
#   normal   : overwrite <dest> with <src>.
# The guard line ('. "$HOME/....setup"') is POSIX, so it works from bash or zsh.
install_rc() {
    local src="$1" dest="$2" base
    base="$(basename "$dest")"
    if [ "$HPC" = 1 ]; then
        step "${base}.setup -> ${dest}.setup"
        cp "$src" "${dest}.setup" && ok || die
        step "source guard in $dest"
        local marker="# >>> setup repo (hpc) >>>"
        if [ -f "$dest" ] && grep -qF "$marker" "$dest"; then
            ok  # already present; nothing to append
        else
            {
                printf '\n%s\n' "$marker"
                printf '[ -f "$HOME/%s.setup" ] && . "$HOME/%s.setup"\n' "$base" "$base"
                printf '# <<< setup repo (hpc) <<<\n'
            } >> "$dest" && ok || die
        fi
    else
        step "${base} -> $dest"
        cp "$src" "$dest" && ok || die
    fi
}

install_rc .bashrc "$HM/.bashrc"
[ "$INSTALL_ZSH" = 1 ] && install_rc .zshrc "$HM/.zshrc"

if [ "$HPC" = 1 ]; then
    step "kitty.conf (skipped in HPC mode — local terminal config)"; ok
else
    step "kitty.conf -> $HM/.config/kitty/kitty.conf"
    mkdir -p "$HM/.config/kitty" && cp kitty.conf "$HM/.config/kitty/kitty.conf" && ok || die
fi

# ----- 4. yed plugins -----
say "yed plugins (parallel compile)"
mkdir -p "$HM/.config/yed"
CC="${CC:-gcc}"   # override with e.g. CC=cc on systems without gcc on PATH
C_FLAGS="-O3 $(yed --print-cflags) $(yed --print-ldflags)"
YED_DIR="${DIR}/.yed"
HOME_YED_DIR="${HM}/.config/yed"

pids=()
files=()
logs=()
for f in $(find "${YED_DIR}" -path "${YED_DIR}/lsp_repos" -prune -o -name "*.c" -print); do
    rel="${f/${YED_DIR}/.yed}"
    PLUG_DIR=$(dirname "${f/${YED_DIR}/${HOME_YED_DIR}}")
    PLUG_FULL_PATH="${PLUG_DIR}/$(basename "$f" .c).so"
    log="$LOG_DIR/plugin-$(basename "$f" .c).log"
    mkdir -p "${PLUG_DIR}"
    ${CC} "${f}" ${C_FLAGS} -o "${PLUG_FULL_PATH}" >"$log" 2>&1 &
    pids+=($!)
    files+=("${rel}")
    logs+=("$log")
done

plugin_status=0
for i in "${!pids[@]}"; do
    step "${files[$i]}"
    if wait "${pids[$i]}"; then
        ok
    else
        printf '[FAIL] see %s\n' "${logs[$i]}" >&2
        plugin_status=1
    fi
done
[ $plugin_status -eq 0 ] || die "one or more plugins failed to compile"

# ----- 5. yed config -----
say "yed config"
step "yedrc"
cp "${YED_DIR}/yedrc" "${HOME_YED_DIR}" && ok || die
step "ypm_list"
cp "${YED_DIR}/ypm_list" "${HOME_YED_DIR}" && ok || die
step "templates/"
cp -r "${YED_DIR}/templates" "${HOME_YED_DIR}" && ok || die

# ----- 6. LSP servers (optional) -----
if [ "$INSTALL_LSP" = "1" ] && [ "$HPC" = 1 ]; then
    # HPC: no sudo/apt/snap. Use user-space installs; warn (don't die) on the
    # pieces that need tools you must `module load` yourself (compiler/node).
    say "LSP servers (HPC, user-space — no sudo)"

    step "pylsp (pip install --user)"
    if python3 -m pip install --user jedi python-lsp-server >"$LOG_DIR/lsp-pylsp.log" 2>&1; then
        ok
    else
        warn "pylsp failed; 'module load' a python first? see $LOG_DIR/lsp-pylsp.log"
    fi

    step "clangd (check availability)"
    if command -v clangd >/dev/null 2>&1; then
        ok
    else
        warn "clangd not on PATH — try 'module load llvm' (or clang/rocm); no user install here"
    fi

    step "marksman (prebuilt binary -> ~/.local/bin)"
    mkdir -p "$HM/.local/bin"
    if command -v curl >/dev/null 2>&1; then
        if curl -fsSL -o "$HM/.local/bin/marksman" \
            https://github.com/artempyanykh/marksman/releases/latest/download/marksman-linux-x64 \
            >"$LOG_DIR/lsp-marksman.log" 2>&1 && chmod +x "$HM/.local/bin/marksman"; then ok
        else warn "marksman download failed; see $LOG_DIR/lsp-marksman.log"; fi
    else
        warn "curl not found; skipped marksman"
    fi

    step "bash-language-server (npm -g, needs node)"
    if command -v npm >/dev/null 2>&1; then
        if npm install -g bash-language-server >"$LOG_DIR/lsp-bashls.log" 2>&1; then ok
        else warn "npm install failed (needs writable global prefix); see $LOG_DIR/lsp-bashls.log"; fi
    else
        warn "npm not on PATH — 'module load node' (or nodejs) first; skipped"
    fi
elif [ "$INSTALL_LSP" = "1" ]; then
    say "LSP servers (sudo)"
    lsp_status=0
    for build in "${YED_DIR}"/lsp_repos/*/build.sh; do
        name=$(basename "$(dirname "$build")")
        log="$LOG_DIR/lsp-${name}.log"
        step "$name"
        if bash "$build" >"$log" 2>&1; then ok; else printf '[FAIL] see %s\n' "$log" >&2; lsp_status=1; fi
    done
    [ $lsp_status -eq 0 ] || die "one or more LSP servers failed to install"
fi

say "All done. Logs: $LOG_DIR"
