# Model Routing - Optimisation Cout Sous-Agents

> **Objectif** : Minimiser le cout tokens en routant les sous-agents vers le bon modele
> **Quand lire** : Avant de lancer des sous-agents (review, explore, plan)
> **Resume** : Sonnet par defaut, Opus uniquement sur exceptions justifiees

---

## Regle Principale

```
Ne JAMAIS lancer de sous-agents en Opus sauf necessite explicite.
Le budget utilisateur est limite — Opus coute ~5x plus que Sonnet par token.
Qualite > Quantite : si Sonnet ne suffit pas pour une tache, utiliser Opus.
```

## Routing Table

| Type de sous-agent | Modele | Justification |
|--------------------|--------|---------------|
| **Explore** (recherche code, grep, read) | `model: "sonnet"` | Pas de raisonnement profond, juste du pattern matching |
| **Review agents** (code-reviewer, silent-failure-hunter, type-design, perf, security, pwa) | `model: "sonnet"` | Evaluation contre des rules definies, Sonnet suffit |
| **Plan** (architecture, design) | `model: "sonnet"` par defaut, `model: "opus"` si architecture complexe multi-domaines | Le planning beneficie parfois d'Opus pour les trade-offs |
| **Conversation principale** | Gere par Claude Code (routing auto) | Ne pas forcer le modele |

## Exceptions pour Opus sur sous-agents

- Architecture systeme complexe (nouveau service, refactoring majeur cross-cutting)
- Debugging avance (3eme strike, probleme architectural)
- Revue de securite sur du code crypto/auth custom
