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
for arg in "$@"; do
    case "$arg" in
        --lsp) INSTALL_LSP=1 ;;
        -h|--help)
            echo "Usage: $0 [--lsp]"
            echo "  --lsp   also install LSP servers (clangd, bash, pylsp, marksman) via sudo"
            exit 0
            ;;
        *) echo "Unknown arg: $arg" >&2; exit 1 ;;
    esac
done

echo "Logs: $LOG_DIR"

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
say "PowerlineSymbols font"
if dpkg -s fonts-powerline >/dev/null 2>&1; then
    step "fonts-powerline (already installed)"; ok
else
    step "apt install fonts-powerline (sudo)"
    if sudo apt -y install fonts-powerline >"$LOG_DIR/fonts.log" 2>&1; then ok; else die "see $LOG_DIR/fonts.log"; fi
fi
step "fc-cache -f"
if fc-cache -f >"$LOG_DIR/fc-cache.log" 2>&1; then ok; else warn "fc-cache failed; see $LOG_DIR/fc-cache.log"; fi

# ----- 3. dotfiles -----
say "Dotfiles"
step ".bashrc -> $HM/.bashrc"
cp .bashrc "$HM/.bashrc" && ok || die
step "kitty.conf -> $HM/.config/kitty/kitty.conf"
mkdir -p "$HM/.config/kitty" && cp kitty.conf "$HM/.config/kitty/kitty.conf" && ok || die

# ----- 4. yed plugins -----
say "yed plugins (parallel compile)"
mkdir -p "$HM/.config/yed"
CC=gcc
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
if [ "$INSTALL_LSP" = "1" ]; then
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
