#!/usr/bin/env bash
# Install clangd (C/C++ LSP) and bear (compile_commands.json generator).
# yedrc is configured to use: lsp-define-server CLANGD clangd --background-index

set -e

sudo apt -y install clangd bear
