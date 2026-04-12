#!/usr/bin/env bash
set -euo pipefail
REPO="/Users/pmuppala/Desktop/Automation/InfraPilot"
cd "$REPO" || exit 1

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not a git repo" >&2
  exit 1
fi

git fetch origin --prune || true

if git rev-parse --verify master >/dev/null 2>&1; then
  SRC=master
else
  SRC=$(git rev-parse --abbrev-ref HEAD)
fi

echo "Source branch: $SRC"

if git show-ref --verify --quiet refs/heads/main; then
  echo "Local 'main' already exists"
else
  git branch main "$SRC"
  echo "Created local 'main' from '$SRC'"
fi

git checkout main

echo "On branch: $(git rev-parse --abbrev-ref HEAD)"

git push -u origin main

git remote set-head origin main || true

echo "Remotes:"
git remote -v

echo "Remote HEAD:" 

git ls-remote --symref origin HEAD || true
