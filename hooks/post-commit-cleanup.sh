#!/usr/bin/env bash
# Post-commit cleanup: remove review marker after successful commit
# Triggered by PostToolUse hook on Bash tool
# No external dependencies (no jq)

set -euo pipefail

INPUT=$(cat)

# Extract command using grep/sed (no jq dependency)
COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"command"[[:space:]]*:[[:space:]]*"//;s/"$//' || true)

# Only act after git commit commands
if ! echo "$COMMAND" | grep -qE 'git\s+commit\b'; then
  exit 0
fi

# Clean up marker
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [ -n "$GIT_ROOT" ] && [ -f "$GIT_ROOT/.review-gate-passed" ]; then
  rm -f "$GIT_ROOT/.review-gate-passed"
  echo "🧹 Marqueur review nettoyé"
fi

exit 0
