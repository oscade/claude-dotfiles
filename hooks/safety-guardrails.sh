#!/usr/bin/env bash
# Safety guardrails - Intercepte les commandes destructives AVANT exécution
# Bloque: rm -rf, DROP TABLE/DATABASE, git push --force, git reset --hard,
#         git clean -f, git checkout -- ., truncate, delete sans where
# Laisse passer tout le reste sans friction

set -euo pipefail

INPUT=$(cat)

# Extract command using pure bash pattern matching
COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/"command"[[:space:]]*:[[:space:]]*"//;s/"$//' || true)

# Skip if no command extracted
if [ -z "$COMMAND" ]; then
  exit 0
fi

# Skip git commit interception (handled by pre-commit-review-gate.sh)
if echo "$COMMAND" | grep -qE 'git\s+commit\b'; then
  exit 0
fi

# --- Destructive filesystem commands ---
if echo "$COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|--force\s+--recursive|-[a-zA-Z]*f[a-zA-Z]*r)\b'; then
  cat <<'ENDJSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "SAFETY GUARDRAIL - Commande destructive detectee: rm -rf. Confirmer explicitement avec l'utilisateur avant d'executer cette commande. Expliquer ce qui sera supprime."
  }
}
ENDJSON
  exit 0
fi

# --- Destructive git commands ---
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*--force|git\s+push\s+-f\b'; then
  cat <<'ENDJSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "SAFETY GUARDRAIL - git push --force detecte. Force push peut ecraser le travail distant. Confirmer explicitement avec l'utilisateur."
  }
}
ENDJSON
  exit 0
fi

if echo "$COMMAND" | grep -qE 'git\s+reset\s+--hard'; then
  cat <<'ENDJSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "SAFETY GUARDRAIL - git reset --hard detecte. Cette commande detruit les modifications locales de maniere irreversible. Confirmer explicitement avec l'utilisateur."
  }
}
ENDJSON
  exit 0
fi

if echo "$COMMAND" | grep -qE 'git\s+clean\s+(-[a-zA-Z]*f)'; then
  cat <<'ENDJSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "SAFETY GUARDRAIL - git clean -f detecte. Supprime les fichiers non-tracked de maniere irreversible. Confirmer explicitement avec l'utilisateur."
  }
}
ENDJSON
  exit 0
fi

if echo "$COMMAND" | grep -qE 'git\s+checkout\s+--\s+\.'; then
  cat <<'ENDJSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "SAFETY GUARDRAIL - git checkout -- . detecte. Ecrase toutes les modifications locales. Confirmer explicitement avec l'utilisateur."
  }
}
ENDJSON
  exit 0
fi

if echo "$COMMAND" | grep -qE 'git\s+branch\s+(-[a-zA-Z]*D)'; then
  cat <<'ENDJSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "SAFETY GUARDRAIL - git branch -D detecte. Suppression forcee de branche. Confirmer explicitement avec l'utilisateur."
  }
}
ENDJSON
  exit 0
fi

# --- Destructive SQL commands ---
if echo "$COMMAND" | grep -qiE 'DROP\s+(TABLE|DATABASE|SCHEMA|INDEX)\b'; then
  cat <<'ENDJSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "SAFETY GUARDRAIL - DROP TABLE/DATABASE detecte. Operation irreversible sur la base de donnees. Confirmer explicitement avec l'utilisateur."
  }
}
ENDJSON
  exit 0
fi

if echo "$COMMAND" | grep -qiE 'TRUNCATE\s+TABLE\b'; then
  cat <<'ENDJSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "SAFETY GUARDRAIL - TRUNCATE TABLE detecte. Supprime toutes les donnees de la table. Confirmer explicitement avec l'utilisateur."
  }
}
ENDJSON
  exit 0
fi

if echo "$COMMAND" | grep -qiE 'DELETE\s+FROM\s+\w+\s*;?\s*$'; then
  cat <<'ENDJSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "SAFETY GUARDRAIL - DELETE FROM sans clause WHERE detecte. Supprime toutes les lignes de la table. Ajouter un WHERE ou confirmer explicitement."
  }
}
ENDJSON
  exit 0
fi

# No dangerous command detected - allow
exit 0
