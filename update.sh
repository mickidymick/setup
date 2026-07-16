#! /usr/bin/env bash
# Bidirectional sync for managed dotfiles.
# For each managed file, shows the diff between repo and installed copy and lets
# you choose: push repo->installed, sync installed->repo, or skip.
# Backups (.bak-<timestamp>) are written before any overwrite.

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HM="$HOME"

say()  { printf '\n==> %s\n' "$*"; }
note() { printf '    %s\n' "$*"; }

# Pairs of <repo-relative-path>:<installed-absolute-path>
files=(
    ".bashrc:$HM/.bashrc"
    "kitty.conf:$HM/.config/kitty/kitty.conf"
    ".yed/yedrc:$HM/.config/yed/yedrc"
    ".yed/ypm_list:$HM/.config/yed/ypm_list"
    ".claude/statusline-command.sh:$HM/.claude/statusline-command.sh"
)

backup() {
    local path="$1"
    local bak="${path}.bak-$(date +%Y%m%d-%H%M%S)"
    cp "$path" "$bak"
    echo "  backup: $bak"
}

for entry in "${files[@]}"; do
    repo_rel="${entry%%:*}"
    installed="${entry#*:}"
    repo="$DIR/$repo_rel"

    if [ ! -e "$repo" ]; then
        say "[$repo_rel] missing in repo; skipping"
        continue
    fi
    if [ ! -e "$installed" ]; then
        say "[$repo_rel] not installed at $installed; skipping"
        continue
    fi

    if diff -q "$repo" "$installed" >/dev/null 2>&1; then
        say "[$repo_rel] in sync"
        continue
    fi

    say "[$repo_rel] DIFFERS"
    diff -u "$repo" "$installed" || true
    note ""
    note "(p) push:  repo -> installed   ($repo_rel -> $installed)"
    note "(s) sync:  installed -> repo   ($installed -> $repo_rel)"
    note "(k) keep:  do nothing"
    read -rp "    Choose [p/s/k]: " choice

    case "$choice" in
        p|P)
            backup "$installed"
            cp "$repo" "$installed"
            note "pushed."
            ;;
        s|S)
            backup "$repo"
            cp "$installed" "$repo"
            note "synced."
            ;;
        k|K|"")
            note "kept."
            ;;
        *)
            note "unknown choice; kept."
            ;;
    esac
done

say "Done. If you pulled new yed plugin sources, re-run install.sh to recompile."
