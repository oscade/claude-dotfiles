#!/bin/bash
# Pre-commit review gate for Claude Code
# Blocks git commit if review agents haven't passed
# Triggered by PreToolUse hook on Bash tool
# No external dependencies (no jq) — uses bash builtins for zero-fork fast path

set -euo pipefail

# Read the tool input from stdin (JSON)
INPUT=$(cat)

# Extract command using bash regex — zero subprocess on the fast path
if [[ ! "$INPUT" =~ \"command\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
  exit 0
fi
COMMAND="${BASH_REMATCH[1]}"

# Only intercept git commit commands
if [[ ! "$COMMAND" =~ git[[:space:]]+commit ]]; then
  exit 0
fi

# Find the git root of the current working directory
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [ -z "$GIT_ROOT" ]; then
  exit 0
fi

MARKER="$GIT_ROOT/.review-gate-passed"

# Check for review marker
if [ ! -f "$MARKER" ]; then
  echo ""
  echo "╔═══════════════════════════════════════════════╗"
  echo "║  ❌ COMMIT BLOQUÉ — Review gate non passée   ║"
  echo "╠═══════════════════════════════════════════════╣"
  echo "║ Les agents de review n'ont pas été exécutés.  ║"
  echo "║ Lancer la review AVANT de committer :         ║"
  echo "║                                               ║"
  echo "║   → Exécuter les 6 agents de review           ║"
  echo "║   → Tous les seuils doivent être atteints     ║"
  echo "║   → Le fichier .review-gate-passed sera créé  ║"
  echo "╚═══════════════════════════════════════════════╝"
  exit 2
fi

# Validate marker is recent (< 30 min) to prevent stale markers
NOW=$(date +%s)
# GNU stat -c, fallback to BSD stat -f for macOS portability
MARKER_TIME=$(stat -c %Y "$MARKER" 2>/dev/null || stat -f %m "$MARKER" 2>/dev/null || echo 0)
MARKER_AGE=$(( NOW - MARKER_TIME ))

if [ "$MARKER_AGE" -gt 1800 ]; then
  rm -f "$MARKER"
  echo ""
  echo "╔═══════════════════════════════════════════════╗"
  echo "║  ⚠️  Marqueur review expiré (> 30 min)       ║"
  echo "║  Relancer les agents de review.               ║"
  echo "╚═══════════════════════════════════════════════╝"
  exit 2
fi

echo "✅ Review gate passed — commit autorisé"
exit 0
