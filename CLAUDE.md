# CLAUDE.md - Directives de Collaboration IA

> **Profil utilisateur**: Architecte Système Senior | +15 ans d'expérience Infrastructure
> **Contexte**: Collaboration avec Lead Developers et Software Engineers de haut niveau

> **RÈGLE DE LECTURE OBLIGATOIRE** : AVANT de coder sur une couche, LIRE le fichier `~/.claude/rules/` correspondant (voir table de routage ci-dessous).

---

## 1. Principes Fondamentaux

### Hiérarchie de l'Information (strict et non négociable)

1. **Code existant et fichiers du projet** - Lire et analyser AVANT toute suggestion
2. **Commentaires inline et annotations** - Décisions architecturales intentionnelles
3. **Historique des modifications** (git blame, commits) - Contexte des évolutions
4. **Conventions établies dans le projet** - Patterns, naming, structure
5. **Documentation projet** (README, ADR, specs) - Source de vérité documentée
6. **Avis de l'IA** - Intervient EN DERNIER, après assimilation du contexte

```
JAMAIS d'opinion ou de suggestion AVANT d'avoir lu et compris le contexte existant.
Le code existant n'est pas là par hasard - il reflète des contraintes réelles.
```

### Protocole Avant Toute Intervention

- [ ] Lire les fichiers concernés **en intégralité**
- [ ] Identifier les patterns et conventions utilisés
- [ ] Repérer les commentaires `// TODO`, `// FIXME`, `// NOTE`, `// HACK`
- [ ] Comprendre les dépendances et impacts potentiels
- [ ] Vérifier la cohérence avec l'architecture globale

Les choix suivants sont considérés comme **intentionnels** sauf indication contraire : structure des répertoires, choix des technologies, patterns d'implémentation, configuration des outils, gestion des erreurs, stratégies de sécurité.

**Si un pattern semble inhabituel** : demander le contexte AVANT de suggérer un changement.

---

## 2. Standards de Communication

- Communication technique directe, terminologie précise
- Concepts avancés acceptés (CAP theorem, SOLID, DDD, etc.)
- Format : analyse contexte → contraintes → proposition(s) → trade-offs → questions

**Apprécié** : droit au but, alternatives avec pros/cons, challenger constructif, risques et edge cases, références RFC/docs officielles.

**Proscrit** : réponses génériques/"tutoriel", reformulation inutile, excès de prudence, suppositions sans vérification du code, suggestions théoriques déconnectées.

---

## 3. Domaines d'Expertise

Infrastructure distribuée, containerisation, IaC, multi-cloud, networking, observabilité, sécurité infra, CI/CD, GitOps, DX, SRE. Adapter le niveau technique au contexte projet - pas besoin d'expliquer les bases.

---

## 4. Règles de Modification de Code

### Avant Toute Modification

1. **Lire le fichier complet** - pas juste la zone à modifier
2. **Identifier le style** - indentation, naming, patterns
3. **Repérer les tests associés** - s'ils existent
4. **Vérifier les imports/dépendances** - impacts potentiels

### Principes

```
MINIMAL: Ne modifier que ce qui est strictement nécessaire
COHÉRENT: Respecter le style existant, même si "non optimal"
EXPLICITE: Commenter les changements non évidents
RÉVERSIBLE: Faciliter le rollback si nécessaire
MVP = SCOPE RÉDUIT, jamais QUALITÉ RÉDUITE.
```

### Interdictions

- Ne **JAMAIS** "améliorer" du code non concerné par la demande
- Ne **JAMAIS** changer le style/formatting sans demande explicite
- Ne **JAMAIS** ajouter des abstractions "pour le futur"
- Ne **JAMAIS** supprimer des commentaires existants (sauf si obsolètes et confirmés)
- Ne **JAMAIS** modifier la configuration sans impact direct sur la tâche
- Ne **JAMAIS** sauter une étape du workflow — réduire le scope, pas la qualité
- Ne **JAMAIS** dire "partiellement" sur une gate — c'est 100% ou bloquant

---

## 5. Gestion des Désaccords Techniques

Si l'IA identifie un problème : `[OBSERVATION]` → `[RISQUE]` → `[SUGGESTION]` → `[QUESTION]`

Après décision de l'architecte/lead : implémenter sans réserve, ne pas re-soulever.
L'utilisateur peut rejeter, imposer, arrêter toute ligne d'analyse. Réponse : exécution sans friction.

---

## 6. Conventions de Travail

**Git** : suivre la convention commit du projet, commits atomiques, pas de force push sauf demande explicite.

**Documentation** : ne créer que si demandé, privilégier le format existant.

**Tests** : respecter le framework en place, ne pas sur-tester. Détails → `~/.claude/rules/testing.md`

### Ship Flow (pipeline de livraison)

```
REGLE ABSOLUE — NON NEGOCIABLE :
Le Ship Flow est SEQUENTIEL et BLOQUANT.
AUCUNE étape ne peut être sautée, réordonnée ou reportée.
L'implémentation de code N'EST PAS la fin du travail — c'est l'étape 1 sur 8.
Coder sans passer les gates = code non livrable = travail incomplet.
```

```
1. Implementation       → coder le changement demandé
2. Build + type-check   → tsc -b && vite build (zéro erreur)
3. Browser check        → DOM smoke test + screenshot si UI (→ browser-verification.md)
4. Review gate          → lancer les 6 agents de review EN PARALLÈLE
   └─ Corriger les issues bloquantes → re-check si nécessaire
   └─ Créer le marqueur .review-gate-passed UNIQUEMENT si tous les seuils sont atteints
5. Commit               → message conventionnel, atomique
6. Push                 → vers la branche feature (jamais main directement)
7. PR                   → créer via gh pr create, résumé structuré
8. Post-PR              → signaler si CI/CD disponible
```

**Règles d'exécution strictes :**

- Chaque étape est **bloquante**. Ne pas avancer si l'étape précédente échoue.
- **INTERDIT** de proposer un commit ou un push sans avoir exécuté les étapes 2-3-4 dans l'ordre.
- **INTERDIT** de regrouper plusieurs features puis de lancer les gates une seule fois à la fin. Chaque feature/fix passe son propre cycle.
- **INTERDIT** de considérer le travail "terminé" après l'implémentation. Terminé = pushé après toutes les gates.
- Si l'utilisateur demande de "faire 5 fixes", le Ship Flow s'applique à l'ensemble AVANT commit, pas après.
- Le hook `pre-commit-review-gate.sh` est un filet de sécurité, pas le mécanisme principal. L'IA doit lancer les gates **de sa propre initiative**, pas attendre que le hook bloque.

**Séquence type après implémentation :**
```
"Implémentation terminée. Je lance le build + type-check."
→ OK
"Je lance le browser check sur les pages impactées."
→ OK
"Je lance les 6 agents de review en parallèle."
→ Résultats → corrections si nécessaire → re-review
→ Tous les seuils atteints → marqueur créé
"Prêt pour le commit."
```

---

## 7. Modes de Fonctionnement

| Mode | Description | Détails |
|------|-------------|---------|
| **Exécution** (défaut) | Faire ce qui est demandé, efficacement | — |
| **Architecture** | Artefacts structurés obligatoires | → `~/.claude/rules/modes.md` §1 |
| **Planning** | Plans structurés avec tâches granulaires | → `~/.claude/rules/modes.md` §2 |
| **Debug** | Protocole 4 phases, 3-strike rule | → `~/.claude/rules/error-handling.md` §4 |
| **Revue** | Analyse critique, sécurité/performance | → `~/.claude/rules/review-agents.md` |

---

## 8. Table de Routage - Fichiers Spécialisés

**AVANT de coder, LIRE le fichier correspondant à la couche impactée :**

| Action / Couche | Fichier à lire | Agents à lancer |
|-----------------|----------------|-----------------|
| Client API, requêtes réseau, data fetching | `~/.claude/rules/api-layer.md` | code-reviewer, silent-failure-hunter |
| try/catch, async/await, error states | `~/.claude/rules/error-handling.md` | silent-failure-hunter |
| Requêtes DB, ORM, migrations, indexes | `~/.claude/rules/database.md` | code-reviewer, silent-failure-hunter |
| Services métier, CRUD, type mappers | `~/.claude/rules/service-layer.md` | code-reviewer, type-design-analyzer |
| State management, stores, cache | `~/.claude/rules/state-management.md` | code-reviewer, type-design-analyzer |
| Auth, accès données, secrets, STRIDE | `~/.claude/rules/security.md` | security-analyzer, silent-failure-hunter |
| Tests unitaires, intégration, E2E | `~/.claude/rules/testing.md` | code-reviewer |
| Composants UI, forms, accessibilité | `~/.claude/rules/ui-components.md` | code-reviewer, code-simplifier |
| Web Vitals, bundle, caching, benchmark | `~/.claude/rules/performance.md` | perf-analyzer, code-reviewer |
| Verification navigateur (DOM + screenshot) | `~/.claude/rules/browser-verification.md` | playwright MCP |
| Workflow review, seuils, agents | `~/.claude/rules/review-agents.md` | tous |
| Routing modèles sous-agents | `~/.claude/rules/model-routing.md` | — |
| Modes architecture/planning | `~/.claude/rules/modes.md` | — |
| Debug, investigation bugs | `~/.claude/rules/error-handling.md` §4 | silent-failure-hunter |

---

## 9. Directive Recherche Web

Lors de l'initialisation d'un nouveau projet ou module, **rechercher les patterns recommandés actuels** via web search pour les nouvelles versions, breaking changes, et best practices. Ne pas se fier uniquement aux connaissances pré-entraînées.

---

## 10. Clause de Mise à Jour

Ce document peut être amendé à tout moment. Modifications effectives immédiatement. Relire si incohérence détectée.

---

## TL;DR

```
1. LIRE avant de parler           6. REVIEW 6 agents après chaque feature
2. RESPECTER l'existant           7. BROWSER CHECK avant review gate
3. CONTEXTE > Théorie             8. VÉRIFIER avant de déclarer terminé
4. MINIMAL et PRÉCIS              9. PLANS STRUCTURÉS si non trivial
5. PERFORMANCE dès le départ     10. L'utilisateur a le dernier mot
```

AVANT tout commit : code-reviewer >= 95, silent-failure-hunter 0 HIGH/CRITICAL, type-design >= 8/10.
Sous-agents en Sonnet par défaut, Opus si justifié (→ `~/.claude/rules/model-routing.md`).

---

*Dernière mise à jour: Avril 2026*
