#!/usr/bin/env bash
# Install marksman (markdown LSP) as a prebuilt binary into ~/.local/bin.
#
# Deliberately NOT snap: snap mounts squashfs images, which fails outright on
# containers and VMs that don't permit it ("system does not fully support
# snapd: cannot mount squashfs image"), and it needs sudo besides. The upstream
# prebuilt binary needs neither, and ~/.local/bin is already on PATH from the
# yed step in install.sh. This mirrors what install.sh --hpc already does.

set -e

case "$(uname -m)" in
    x86_64|amd64)  arch=x64 ;;
    aarch64|arm64) arch=arm64 ;;
    *) echo "unsupported arch for marksman prebuilt: $(uname -m)" >&2; exit 1 ;;
esac

mkdir -p "$HOME/.local/bin"
curl -fsSL -o "$HOME/.local/bin/marksman" \
    "https://github.com/artempyanykh/marksman/releases/latest/download/marksman-linux-${arch}"
chmod +x "$HOME/.local/bin/marksman"

# Fail loudly if the download produced something that won't run (e.g. an HTML
# error page saved as the binary).
"$HOME/.local/bin/marksman" --version
