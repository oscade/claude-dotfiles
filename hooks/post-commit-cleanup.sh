#!/bin/bash
# Post-commit cleanup: remove review marker after successful commit
# Triggered by PostToolUse hook on Bash tool
# No external dependencies (no jq) — uses bash builtins for zero-fork fast path

set -euo pipefail

INPUT=$(cat)

# Extract command using bash regex — zero subprocess on the fast path
if [[ ! "$INPUT" =~ \"command\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
  exit 0
fi
COMMAND="${BASH_REMATCH[1]}"

# Only act after git commit commands
if [[ ! "$COMMAND" =~ git[[:space:]]+commit ]]; then
  exit 0
fi

# Check if the commit actually succeeded (exit_code in PostToolUse JSON)
if [[ "$INPUT" =~ \"exit_code\"[[:space:]]*:[[:space:]]*([0-9]+) ]]; then
  EXIT_CODE="${BASH_REMATCH[1]}"
  if [ "$EXIT_CODE" -ne 0 ]; then
    exit 0
  fi
fi

# Clean up marker
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [ -n "$GIT_ROOT" ] && [ -f "$GIT_ROOT/.review-gate-passed" ]; then
  rm -f "$GIT_ROOT/.review-gate-passed"
  echo "🧹 Marqueur review nettoyé"
fi

exit 0
