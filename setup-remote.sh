#!/usr/bin/env bash
# setup-remote.sh — One-liner to bootstrap hermetic workflow into any project.
#
# Usage (run from your project directory):
#   curl -fsSL https://raw.githubusercontent.com/davstr1/hermetic-workflow/main/setup-remote.sh | bash
#
# Or with a specific target:
#   curl -fsSL https://raw.githubusercontent.com/davstr1/hermetic-workflow/main/setup-remote.sh | bash -s /path/to/project

set -euo pipefail

TARGET="${1:-$(pwd)}"
TMP_DIR=$(mktemp -d)

trap 'rm -rf "$TMP_DIR"' EXIT

echo "[setup] Downloading hermetic workflow..."
# Download as tarball — no git clone, no history, no remote
curl -fsSL "https://api.github.com/repos/davstr1/hermetic-workflow/tarball/main" \
  -H "Authorization: Bearer $(gh auth token 2>/dev/null || echo '')" \
  | tar -xz -C "$TMP_DIR" --strip-components=1

echo "[setup] Running init.sh into: $TARGET"
bash "$TMP_DIR/init.sh" "$TARGET"

echo "[setup] Done. No hermetic-workflow git remote was added to your project."
