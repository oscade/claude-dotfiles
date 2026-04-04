# Review Agents - Directives Générales

> **Objectif** : Garantir la qualité du code via 6 agents de review parallèles
> **Quand lire** : Avant tout commit, après toute feature/tâche complétée
> **Résumé gates** : code-reviewer >= 95/100 | silent-failure-hunter 0 CRITICAL/HIGH | type-design >= 8/10 | perf-analyzer >= 93/100 | security-analyzer 0 CRITICAL/HIGH | pwa-readiness >= 8/10

---

## 1. Principes

Chaque feature ou tâche complétée doit passer par un workflow de review automatisé
AVANT de proposer un commit. Les agents s'exécutent **en parallèle** via sub-agents
pour maximiser l'efficacité.

**Exception** : Pour les refactorisations mineures ou corrections de bugs simples,
seul `code-reviewer` est obligatoire.

**Exception PWA** : `pwa-readiness` n'est requis que pour les projets déclarés PWA
(présence d'un `manifest.json` ou `service-worker`).

---

## 2. Les 6 Agents

| Agent | Rôle | Score | Déclencheur |
|-------|------|-------|-------------|
| `code-reviewer` | Review générale qualité + maintenabilité | Global /100 + Maintenabilité /10 | Chaque feature complétée |
| `silent-failure-hunter` | Erreurs silencieuses + résilience réseau | Severity (CRITICAL/HIGH/MEDIUM/LOW) | Code async, try/catch, API calls, fetch |
| `type-design-analyzer` | Conception des types et interfaces | Score /10 | Création/modification de types/interfaces |
| `perf-analyzer` | Performance runtime + bundle + Lighthouse | Score /100 (sous-scores: perf, a11y, SEO) | Code impactant chargement, rendering, requêtes |
| `security-analyzer` | OWASP Top 10 + HTTPS + secrets | Severity (CRITICAL/HIGH/MEDIUM/LOW) | Code auth, accès données, inputs, secrets |
| `pwa-readiness` | Installabilité, offline, cross-browser, manifest | Score /10 | Projets PWA uniquement |

---

## 3. Workflow Parallèle

```
APRÈS chaque feature/tâche terminée :

┌─ [code-reviewer]          → Score global /100 + maintenabilité /10
├─ [silent-failure-hunter]  → Severity issues + offline resilience
├─ [type-design-analyzer]   → Design types /10 (si nouveaux types)
├─ [perf-analyzer]          → Score Lighthouse /100 (perf, a11y, SEO)
├─ [security-analyzer]      → OWASP audit, HTTPS, secrets
└─ [pwa-readiness]          → Manifest, SW, offline, cross-browser /10 (si PWA)

Tous lancés en parallèle via sub-agents → résultats agrégés
```

---

## 4. Détail des Métriques par Agent

### 4.1 code-reviewer (OBLIGATOIRE)

| Métrique | Score | Seuil | Bloquant |
|----------|-------|-------|----------|
| Score global qualité | /100 | >= 95 | OUI |
| Maintenabilité | /10 | >= 8 | OUI |

**Critères du score global** :
- Respect des conventions du projet (naming, structure, patterns)
- Complexité cyclomatique raisonnable
- Pas de code dupliqué
- Imports propres, pas de dead code
- Commentaires pertinents sur le code complexe (ni trop, ni trop peu)
- SQL safety : pas de concaténation, parameterized queries, pas de SELECT *
- Distinction auto-fix vs ASK : les issues évidentes sont corrigées, les choix de design sont signalés à l'utilisateur pour décision

**Critères maintenabilité /10** :
- Lisibilité (noms expressifs, fonctions courtes, SRP)
- Couplage faible entre modules
- Testabilité du code produit
- Cohérence avec l'architecture existante

### 4.2 silent-failure-hunter

| Métrique | Seuil | Bloquant |
|----------|-------|----------|
| Issues CRITICAL | 0 | OUI |
| Issues HIGH | 0 | OUI |
| Issues MEDIUM | Report only | NON |

**Vérifie** :
- try/catch vides ou avec simple `console.log`
- Promises non awaited ou sans `.catch()`
- Erreurs réseau sans fallback (fetch, API calls)
- Timeouts absents sur les appels externes
- Offline resilience : fallback quand réseau indisponible
- Race conditions sur les async operations
- Erreurs silencieuses dans les event listeners

### 4.3 type-design-analyzer

| Métrique | Score | Seuil | Bloquant |
|----------|-------|-------|----------|
| Design des types | /10 | >= 8 | OUI |

**Critères** :
- Types explicites (pas de `any`, `unknown` justifié)
- Interfaces cohérentes et non-redondantes
- Unions discriminées plutôt que types optionnels multiples
- Generics utilisés à bon escient (pas de sur-abstraction)
- Mapper types alignés avec le domain model

### 4.4 perf-analyzer (fusion ancien code-simplifier + performance)

| Métrique | Score | Seuil | Bloquant |
|----------|-------|-------|----------|
| Performance globale | /100 | >= 93 | OUI |
| Sous-score Performance | /100 | >= 90 | OUI |
| Sous-score Accessibilité | /100 | >= 85 | NON (warning) |
| Sous-score SEO | /100 | >= 85 | NON (warning) |

**Critères Performance** :
- Page load < 500ms (inacceptable > 2s, ref article PWA: abandon à 3s)
- Requêtes DB par page : 1-3 max
- Payload API < 50KB
- LCP < 2.5s, FID < 100ms, CLS < 0.1
- Aucun N+1 query (0 tolérance)
- Code splitting et lazy loading sur composants lourds
- Memoization appropriée, pas de re-renders inutiles

**Critères Simplification** (intégré) :
- Complexité cyclomatique raisonnable
- Pas de sur-abstraction (3 lignes similaires > abstraction prématurée)
- Early returns plutôt que nesting profond

### 4.5 security-analyzer

| Métrique | Seuil | Bloquant |
|----------|-------|----------|
| Issues CRITICAL | 0 | OUI |
| Issues HIGH | 0 | OUI |
| Issues MEDIUM | Report only | NON |

**Vérifie (OWASP Top 10)** :
- A01 Broken Access Control : RLS/policies sur toutes les données
- A02 Cryptographic Failures : HTTPS enforced, pas de crypto custom
- A03 Injection : schema validation, parameterized queries, sanitize
- A04 Insecure Design : séparation client/serveur
- A05 Security Misconfiguration : .env.local, config deploy
- A06 Vulnerable Components : dépendances à jour
- A07 Auth Failures : auth centralisée, session management
- A08 Data Integrity : type mappers, validation I/O
- A09 Logging Failures : pas de secrets dans les logs
- A10 SSRF : pas de fetch avec URL user-controlled sans whitelist
- HTTPS : toutes les pages servies en HTTPS
- Service Worker scope : pas d'exposition de routes sensibles

**Vérifie (STRIDE)** :
- Spoofing : auth forte, tokens signés
- Tampering : intégrité des données en transit/stockage
- Repudiation : audit logs sur les actions critiques
- Information Disclosure : least privilege, pas de fuite de données
- DoS : rate limiting, pagination
- Elevation of Privilege : RLS, RBAC, contrôle serveur

**Vérifie (Supply Chain & LLM)** :
- Secrets archaeology : aucun secret dans l'historique git
- Dépendances : audit vulnérabilités, pas de packages abandonnés
- LLM trust boundaries : inputs sanitizés, outputs validés, system prompt non exposé

### 4.6 pwa-readiness (conditionnel)

| Métrique | Score | Seuil | Bloquant |
|----------|-------|-------|----------|
| PWA readiness | /10 | >= 8 | OUI (si projet PWA) |

**Critères** :
- **Manifest** : `manifest.json` valide (name, icons, start_url, display)
- **Service Worker** : enregistré, stratégie de cache définie
- **Offline** : toutes les URLs critiques retournent 200 en offline
- **Installabilité** : critères Chrome/Safari respectés
- **Cross-browser** : comportement vérifié Firefox, Chrome, Safari
- **Responsive** : meta viewport, breakpoints cohérents

**Non applicable si** : pas de `manifest.json` ni de service worker dans le projet.

---

## 5. Mapping Agents / Couches

| Couche | Agents obligatoires |
|--------|---------------------|
| API / Services | code-reviewer, silent-failure-hunter, security-analyzer |
| Types / Interfaces | code-reviewer, type-design-analyzer |
| Error handling / Async | silent-failure-hunter |
| UI Components | code-reviewer, perf-analyzer |
| Business logic | code-reviewer, type-design-analyzer, security-analyzer |
| Routes / Pages | perf-analyzer, security-analyzer |
| PWA (manifest, SW) | pwa-readiness, security-analyzer |

---

## 6. Format de Sortie Attendu

Chaque agent produit un rapport structuré :

```
═══════════════════════════════════════
AGENT: [nom-agent]
═══════════════════════════════════════
SCORE: XX/100 (ou XX/10 ou PASS/FAIL)
STATUS: ✅ PASS | ⚠️ WARNING | ❌ FAIL
───────────────────────────────────────
FINDINGS:
  [CRITICAL] Description...
  [HIGH]     Description...
  [MEDIUM]   Description...
  [LOW]      Description...
───────────────────────────────────────
DETAILS: (si issues trouvées)
  → fichier:ligne — explication
───────────────────────────────────────
```

Rapport agrégé final :

```
╔═══════════════════════════════════════╗
║         REVIEW GATE SUMMARY          ║
╠═══════════════════════════════════════╣
║ code-reviewer        XX/100  [✅|❌] ║
║   maintenabilité     XX/10   [✅|❌] ║
║ silent-failure       X issues [✅|❌] ║
║ type-design          XX/10   [✅|❌] ║
║ perf-analyzer        XX/100  [✅|❌] ║
║ security-analyzer    X issues [✅|❌] ║
║ pwa-readiness        XX/10   [✅|⬜] ║
╠═══════════════════════════════════════╣
║ VERDICT: ✅ COMMIT AUTORISÉ          ║
║          ❌ BLOQUÉ — corriger avant  ║
╚═══════════════════════════════════════╝
```

---

## 7. Verification Gate (OBLIGATOIRE)

```
NE JAMAIS déclarer une tâche terminée sans PREUVE FRAÎCHE.
"C'est fait" sans vérification exécutée = mensonge.
```

### Protocole

Avant de déclarer une tâche complète, exécuter systématiquement :

1. **Identifier** la commande de vérification appropriée (test, build, lint, type-check)
2. **Exécuter** la commande — pas de raccourci, pas de "ça devrait marcher"
3. **Lire** la sortie complète — pas de troncature, pas de résumé optimiste
4. **Vérifier** que le résultat confirme la complétion effective

### Quand appliquer

| Situation | Vérification requise |
|-----------|---------------------|
| Feature terminée | Tests passent + build OK |
| Bug fix | Test de non-régression + reproduction confirmée résolue |
| Refactoring | Tests existants passent + type-check OK |
| Délégation à subagent | Vérifier les claims du subagent indépendamment |
| Modification config | Valider que l'app démarre correctement |

### Anti-patterns

| Interdit | Alternative |
|----------|-------------|
| "J'ai vérifié mentalement" | Exécuter la commande réellement |
| Résumer un output sans le lire | Lire chaque ligne de la sortie |
| Faire confiance au subagent sans vérifier | Re-exécuter les vérifications soi-même |
| Dire "les tests devraient passer" | Lancer les tests et montrer le résultat |

---

## 8. Anti-Sycophancy (Code Review)

```
JAMAIS d'accord performatif en code review.
Vérifier techniquement AVANT d'accepter ou rejeter une suggestion.
```

### Règles

- **Interdit** : "You're absolutely right!", "Great point!", "Excellent suggestion!"
- **Obligatoire** : vérification technique avant d'implémenter une suggestion de review
- **YAGNI check** : toute suggestion de feature "professionnelle" doit passer le test "est-ce que c'est demandé ?"
- **Push back** : si une suggestion de review est incorrecte, la rejeter avec un raisonnement technique
- Si une suggestion semble correcte mais non vérifiée → vérifier dans le code avant de l'accepter

### Application

- S'applique à l'IA quand elle reçoit du feedback ou des suggestions
- S'applique aux rapports des agents de review entre eux
- Un finding d'agent doit être vérifié factuellement avant d'être corrigé

---

## 9. Portes d'Acceptation

### Checklist pré-commit

- [ ] `code-reviewer` : score >= 95/100, maintenabilité >= 8/10
- [ ] `silent-failure-hunter` : 0 CRITICAL, 0 HIGH
- [ ] `type-design-analyzer` : score >= 8/10 (si nouveaux types)
- [ ] `perf-analyzer` : score >= 93/100, sous-score perf >= 93/100
- [ ] `security-analyzer` : 0 CRITICAL, 0 HIGH
- [ ] `pwa-readiness` : score >= 8/10 (si projet PWA)
- [ ] `verification-gate` : preuve d'exécution fraîche (tests, build, type-check)

```
NE JAMAIS committer sans avoir exécuté au minimum code-reviewer.
Un score < 95/100 sur code-reviewer est BLOQUANT.
Un score < 93/100 sur perf-analyzer est BLOQUANT.
Toute issue CRITICAL ou HIGH sur silent-failure-hunter ou security-analyzer est BLOQUANTE.
```

---

*Dernière mise à jour: Avril 2026*
