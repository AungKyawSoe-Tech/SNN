#!/usr/bin/env bash
# Helper to fetch NEORV32 into rtl/neorv32 if not present.
set -euo pipefail

TARGET_DIR="$(git rev-parse --show-toplevel)/rtl/neorv32"
REPO_URL="https://github.com/stnolting/neorv32.git"

if [[ -d "$TARGET_DIR" ]]; then
  echo "NEORV32 already present at $TARGET_DIR"
  exit 0
fi

echo "Cloning NEORV32 into $TARGET_DIR"
git clone --depth 1 "$REPO_URL" "$TARGET_DIR"
