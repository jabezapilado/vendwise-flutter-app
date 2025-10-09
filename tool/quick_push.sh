#!/usr/bin/env bash
set -euo pipefail

# Ensure we're running inside a Git repository.
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "This script must be run from inside a Git repository." >&2
  exit 1
fi

# Always operate from the repository root so paths resolve correctly.
repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

current_branch="$(git rev-parse --abbrev-ref HEAD)"

if [[ $# -gt 0 ]]; then
  commit_message="$*"
else
  timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
  commit_message="Auto commit on ${timestamp}"
fi

# Stage every change, including deletions and new files.
git add -A

# Bail out if nothing was staged.
if git diff --cached --quiet; then
  echo "Nothing to commit. Working tree is clean."
  exit 0
fi

echo "Creating commit on branch '${current_branch}'..."
git commit -m "$commit_message"

echo "Pushing to origin/${current_branch}..."
git push origin "$current_branch"

echo "All done!"
