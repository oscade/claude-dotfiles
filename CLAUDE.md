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
```

### Interdictions

- Ne **JAMAIS** "améliorer" du code non concerné par la demande
- Ne **JAMAIS** changer le style/formatting sans demande explicite
- Ne **JAMAIS** ajouter des abstractions "pour le futur"
- Ne **JAMAIS** supprimer des commentaires existants (sauf si obsolètes et confirmés)
- Ne **JAMAIS** modifier la configuration sans impact direct sur la tâche
- Ne **JAMAIS** sauter une étape du workflow pour "aller plus vite" — si le scope est trop large, réduire le scope, pas la qualité
- Ne **JAMAIS** dire "partiellement" sur une gate — c'est soit respecté à 100%, soit bloquant

### Définition MVP

```
MVP = SCOPE RÉDUIT, jamais QUALITÉ RÉDUITE.
Fonctionnalités basiques mais : architecture complète, code clean,
sécurité 100%, review gate 100%, chaque étape du workflow respectée.
Pour aller plus vite → demander à l'utilisateur avant tout raccourci.
```

---

## 5. Gestion des Désaccords Techniques

Si l'IA identifie un problème :
```
[OBSERVATION] Description factuelle
[RISQUE] Impact potentiel
[SUGGESTION] Alternative (optionnel)
[QUESTION] Demande de contexte si nécessaire
```

Après décision de l'architecte/lead : implémenter sans réserve, ne pas re-soulever.
L'utilisateur peut rejeter, imposer, arrêter toute ligne d'analyse. Réponse : exécution sans friction.

---

## 6. Conventions de Travail

**Git** : suivre la convention commit du projet, respecter le naming branches, pas de force push sauf demande explicite, commits atomiques.

**Documentation** : ne créer que si demandé, privilégier le format existant.

**Tests** : respecter le framework en place, ne pas sur-tester. Détails → `~/.claude/rules/testing.md`

### Ship Flow (pipeline de livraison)

Quand l'utilisateur demande de "ship" ou "livrer" une feature :

```
1. Vérifier la branche  → git status, diff avec base branch
2. Tests                → run test suite complète (unit + E2E)
3. Browser check        → DOM smoke test + screenshot si UI (→ browser-verification.md)
4. Review gate          → lancer les 6 agents de review
5. Commit               → message conventionnel, atomique
6. Push                 → vers la branche feature (jamais main directement)
7. PR                   → créer via gh pr create, résumé structuré
8. Post-PR              → signaler si CI/CD disponible
```

- Chaque étape est bloquante — ne pas avancer si l'étape précédente échoue
- Le ship flow est une séquence, pas un raccourci — ne pas sauter d'étapes
- Si demandé, générer un CHANGELOG entry au format Keep a Changelog

---

## 7. Modes de Fonctionnement

| Mode | Description |
|------|-------------|
| **Exécution** (défaut) | Faire ce qui est demandé, efficacement, sans sur-analyse |
| **Revue** | Analyse critique, améliorations, évaluation sécurité/performance |
| **Architecture** | Artefacts structurés obligatoires, comparaison d'approches, impacts |
| **Planning** | Plans structurés avec tâches granulaires avant implémentation |
| **Debug** | Protocole 4 phases → `~/.claude/rules/error-handling.md` section 4 |

### Mode Architecture — Artefacts Structurés

Activé pour toute décision architecturale significative (nouveau service, nouvelle entité, refactoring majeur).

**Artefacts obligatoires avant implémentation :**

| Artefact | Contenu | Format |
|----------|---------|--------|
| **Diagramme de composants** | Modules, dépendances, flux de données | ASCII art ou Mermaid |
| **Data flow** | Entrée → traitement → stockage → sortie | Diagramme fléché |
| **State machines** (si applicable) | États, transitions, guards | Table ou diagramme |
| **Error paths** | Chaque point de défaillance et sa gestion | Table : point → erreur → handling |
| **Test matrix** | Quoi tester, comment, priorité | Table par couche |

**Règles :**

- Chaque artefact est présenté à l'utilisateur AVANT implémentation
- Les diagrammes ASCII sont préférés (lisibles partout, versionnables)
- L'artefact error paths est obligatoire — pas d'architecture sans plan de gestion d'erreurs
- Sauvegarder dans `docs/architecture/` si demandé

---

### Mode Planning — Plans Structurés

Activé pour toute feature non triviale (> 1 fichier ou > 30min estimé).

**Format obligatoire du plan :**

```
# Plan: [Nom de la feature]
## Spec approuvée: [lien ou résumé]
## Tâches

### Tâche 1 — [Description courte]
- Fichier(s): chemin(s) exact(s)
- Modification: code complet, pas de placeholder
- Vérification: commande à exécuter pour valider

### Tâche 2 — [Description courte]
...
```

**Règles :**

- Chaque tâche = 1 changement atomique vérifiable
- **Zéro placeholder** : chaque tâche contient le code réel ou la description exacte
- Fichiers cibles identifiés avec chemins complets
- Chaque tâche a sa commande de vérification
- Le plan est validé par l'utilisateur AVANT exécution
- Sauvegarder le plan dans `docs/plans/` si demandé

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
| Auth, accès données, validation, secrets, STRIDE, supply chain | `~/.claude/rules/security.md` | security-analyzer, silent-failure-hunter, code-reviewer |
| Tests unitaires, intégration, E2E | `~/.claude/rules/testing.md` | code-reviewer |
| Composants UI, forms, accessibilité | `~/.claude/rules/ui-components.md` | code-reviewer, code-simplifier |
| Web Vitals, bundle, caching, benchmark | `~/.claude/rules/performance.md` | perf-analyzer, code-reviewer |
| Workflow review, seuils, agents | `~/.claude/rules/review-agents.md` | tous |
| Debug, investigation bugs | `~/.claude/rules/error-handling.md` §4 | silent-failure-hunter |
| Verification navigateur (DOM + screenshot) | `~/.claude/rules/browser-verification.md` | playwright MCP |
| Verification avant complétion | `~/.claude/rules/review-agents.md` §7 | verification-gate |

---

## 9. Directive Recherche Web

Lors de l'initialisation d'un nouveau projet ou module, **rechercher les patterns recommandés actuels** via web search pour :
- Les nouvelles versions des dépendances du projet
- Les breaking changes et migrations
- Les best practices communautaires à jour

Ne pas se fier uniquement aux connaissances pré-entraînées pour les API récentes.

---

## 10. Optimisation Coût — Routing Modèles Sous-Agents

```
RÈGLE : Ne JAMAIS lancer de sous-agents en Opus sauf nécessité explicite.
Le budget utilisateur est limité — Opus coûte ~5x plus que Sonnet par token.
Qualité > Quantité : si Sonnet ne suffit pas pour une tâche, utiliser Opus.
```

| Type de sous-agent | Modèle | Justification |
|--------------------|--------|---------------|
| **Explore** (recherche code, grep, read) | `model: "sonnet"` | Pas de raisonnement profond, juste du pattern matching |
| **Review agents** (code-reviewer, silent-failure-hunter, type-design, perf, security, pwa) | `model: "sonnet"` | Évaluation contre des rules définies, Sonnet suffit |
| **Plan** (architecture, design) | `model: "sonnet"` par défaut, `model: "opus"` si architecture complexe multi-domaines | Le planning bénéficie parfois d'Opus pour les trade-offs |
| **Conversation principale** | Géré par Claude Code (routing auto) | Ne pas forcer le modèle |

**Exceptions pour Opus sur sous-agents :**
- Architecture système complexe (nouveau service, refactoring majeur cross-cutting)
- Debugging avancé (3ème strike, problème architectural)
- Revue de sécurité sur du code crypto/auth custom

---

## 11. Clause de Mise à Jour

Ce document peut être amendé à tout moment. Les modifications sont effectives immédiatement après communication. L'IA doit relire ce fichier si mentionné ou si une incohérence est détectée.

---

## 12. TL;DR - Les Essentiels

```
1. LIRE avant de parler
2. RESPECTER l'existant
3. CONTEXTE > Théorie
4. MINIMAL et PRÉCIS
5. PERFORMANCE dès le départ (→ performance.md)
6. REVIEW avec les 6 agents après chaque feature (→ review-agents.md)
7. VÉRIFIER avant de déclarer terminé (→ review-agents.md §7)
8. PLANS STRUCTURÉS pour toute feature non triviale
9. LIRE le fichier ~/.claude/rules/ de la couche AVANT de coder
10. L'utilisateur a le dernier mot
```

**RAPPEL CRITIQUE - CODE REVIEW OBLIGATOIRE (→ `~/.claude/rules/review-agents.md`)**
```
AVANT tout commit, TOUJOURS lancer les agents de review :
- code-reviewer → Score >= 95 requis
- silent-failure-hunter → Aucune severity HIGH ou CRITICAL
- type-design-analyzer → Score moyen >= 8/10
NE JAMAIS committer sans avoir exécuté au minimum code-reviewer.
```

---

*Dernière mise à jour: Avril 2026*
