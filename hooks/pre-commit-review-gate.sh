#!/usr/bin/env bash
# Pre-commit review gate for Claude Code
# Blocks git commit if review agents haven't passed
# Uses permissionDecision JSON output (not exit codes)
# No external dependencies (no jq)

set -euo pipefail

# Read the tool input from stdin (JSON)
INPUT=$(cat)

# Extract command using pure bash pattern matching
COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/"command"[[:space:]]*:[[:space:]]*"//;s/"$//' || true)

# Only intercept git commit commands - let everything else through
if ! echo "$COMMAND" | grep -qE 'git\s+commit\b'; then
  exit 0
fi

# Find the git root
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [ -z "$GIT_ROOT" ]; then
  exit 0
fi

MARKER="$GIT_ROOT/.review-gate-passed"

# Check for review marker
if [ ! -f "$MARKER" ]; then
  cat <<'ENDJSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "COMMIT BLOQUE - Review gate non passee. Les agents de review n'ont pas ete executes. Lancer les 6 agents de review (code-reviewer, silent-failure-hunter, type-design-analyzer, perf-analyzer, security-analyzer, pwa-readiness) AVANT de committer. Tous les seuils doivent etre atteints pour creer le marqueur .review-gate-passed."
  }
}
ENDJSON
  exit 0
fi

# Validate marker is recent (< 30 min)
NOW=$(date +%s)
MARKER_TIME=$(stat -c %Y "$MARKER" 2>/dev/null || echo 0)
MARKER_AGE=$(( NOW - MARKER_TIME ))

if [ "$MARKER_AGE" -gt 1800 ]; then
  rm -f "$MARKER"
  cat <<'ENDJSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "COMMIT BLOQUE - Marqueur review expire (> 30 min). Relancer les agents de review."
  }
}
ENDJSON
  exit 0
fi

# Review passed - allow commit
cat <<'ENDJSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "Review gate passed - tous les seuils atteints"
  }
}
ENDJSON
exit 0
