#!/usr/bin/env bash
# install.sh — Install the workflow into any project folder.
#
# Usage (from inside your project):
#   curl -sL https://raw.githubusercontent.com/davstr1/hermetic-workflow/constitution/install.sh | bash
#
# Or targeting a specific folder:
#   curl -sL https://raw.githubusercontent.com/davstr1/hermetic-workflow/constitution/install.sh | bash -s /path/to/my-project

set -euo pipefail

TARGET="${1:-.}"
TARGET="$(cd "$TARGET" 2>/dev/null && pwd || (mkdir -p "$TARGET" && cd "$TARGET" && pwd))"

REPO="https://github.com/davstr1/hermetic-workflow"
BRANCH="constitution"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[install]${NC} $*"; }
ok()  { echo -e "${GREEN}[install]${NC} $*"; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

log "Downloading workflow from $REPO ($BRANCH)..."
curl -sL "$REPO/archive/$BRANCH.tar.gz" | tar xz -C "$TMP" --strip-components=1

log "Installing into $TARGET..."
"$TMP/init.sh" "$TARGET"

ok "Done. No template git — your project keeps its own history."
