#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

git -C "$repo_root" config core.hooksPath hooks
chmod +x "$repo_root/hooks/post-commit" "$repo_root/hooks/post-merge"

echo "Installed agent-skills git hooks."
