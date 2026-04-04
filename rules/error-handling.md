# Error Handling - Directives Générales

> **Objectif** : Gestion d'erreurs explicite, traçable, sans échecs silencieux
> **Quand lire** : Avant tout code async, try/catch, appels API, ou composants avec états d'erreur
> **Agents** : silent-failure-hunter (obligatoire), code-reviewer
> **Résumé gates** : silent-failure-hunter severity < HIGH | logging structuré | zéro catch vide

---

## 1. Principes

- **EXPLICITE** : toute erreur doit être propagée ou loggée avec contexte
- **JAMAIS** d'erreur silencieuse - un `catch` vide est interdit
- Chaque couche a une responsabilité claire : propager, transformer, ou afficher l'erreur

---

## 2. Patterns Obligatoires

### Throw-on-error à la couche data

```
const { data, error } = await apiCall()
if (error) throw error   // Propagation immédiate, jamais ignorer
```

### Logging structuré avec préfixe module

```
console.error('[MODULE_NAME] Description contextuelle:', error)
// Exemples : [AUTH], [SYNC], [PAYMENT], [API_CLIENT]
```

Le préfixe module permet le filtrage et la traçabilité en production.

### Error boundaries (UI)

Les composants de page doivent gérer les états d'erreur des hooks de data fetching :

```
const { data, error, isLoading } = useFetchData()
if (error) return <ErrorDisplay error={error} />
```

Encapsuler les sous-arbres React dans des Error Boundaries pour éviter les crashs en cascade.

### Rollback pattern (opérations multi-étapes)

Pour toute séquence d'opérations non-atomiques :

```
// 1. Sauvegarder l'état initial (pour rollback)
// 2. Exécuter étape A
// 3. Exécuter étape B → si erreur, rollback étape A
// 4. Confirmer le succès
```

### Retry avec max attempts

```
// Pattern : max N retries, puis escalade (dead letter, alerte, log permanent)
if (retryCount >= MAX_RETRIES) {
  await moveToFailedQueue(operation, error)
  logPermanentFailure(operation)
}
```

### Discriminated unions pour les événements async

```
type AsyncEvent =
  | { type: 'start' }
  | { type: 'success'; data: T }
  | { type: 'error'; error: Error }
  | { type: 'retry'; attempt: number }
```

---

## 3. Anti-Patterns Interdits

| Interdit | Pourquoi | Alternative |
|----------|----------|-------------|
| `catch (e) {}` vide | Erreur silencieuse | Log + rethrow ou traitement |
| `catch (e) { return null }` | Masque l'erreur à l'appelant | Throw ou Result type |
| `console.log(error)` sans contexte | Non traçable en production | `[MODULE] message:` + error |
| Ignorer le champ erreur d'une réponse | Échec silencieux | `if (error) throw error` |
| `await` dans `.map()` sans error handling | Erreur non catchée | `Promise.allSettled()` ou try/catch |
| Catch qui log + rethrow sans transformation | Double logging | Log OU rethrow, pas les deux |

---

## 4. Systematic Debugging (4 phases)

```
Mode Debug activé → suivre les 4 phases séquentiellement.
NE JAMAIS sauter une phase. NE JAMAIS deviner sans preuve.
```

### Phase 1 — Investigation (Root Cause)

1. Lire le message d'erreur **complet** (pas de troncature)
2. Reproduire le bug de manière fiable
3. Vérifier les changements récents (`git diff`, `git log --oneline -10`)
4. Rassembler les preuves : logs, stack traces, état de la DB
5. Tracer le flux de données du point d'entrée au point de crash

### Phase 2 — Analyse de patterns

1. Trouver un exemple **fonctionnel** du même pattern dans le codebase
2. Comparer les différences entre le cas fonctionnel et le cas cassé
3. Identifier les variables qui changent entre les deux cas
4. Vérifier si le bug est une régression (quand ça marchait encore ?)

### Phase 3 — Hypothèse et test

1. Formuler une hypothèse unique et testable
2. Concevoir un test qui **prouve ou infirme** l'hypothèse
3. Exécuter le test — une seule variable à la fois
4. Si infirmée → retour Phase 1 avec les nouvelles données
5. Si confirmée → Phase 4

### Phase 4 — Implémentation du fix

1. Implémenter le correctif minimal
2. Vérifier que le bug est résolu (reproduction → OK)
3. Vérifier qu'aucune régression n'est introduite (tests existants)

### Règle des 3 strikes

```
3 tentatives de fix échouées = STOP.
Ne pas insister — remettre en question l'hypothèse ou l'architecture.
```

| Strike | Action |
|--------|--------|
| 1er fix échoué | Normal — retour Phase 3, nouvelle hypothèse |
| 2ème fix échoué | Retour Phase 1 — rassembler plus de preuves |
| 3ème fix échoué | **Escalade** — le problème est probablement architectural. Présenter les 3 tentatives à l'utilisateur avec les résultats. Proposer une approche différente. |

### Scope Freeze (anti-rabbit-holing)

```
En mode Debug, le scope est GELÉ.
On corrige le bug identifié. On ne corrige RIEN d'autre.
```

- **Interdit** pendant le debug : refactorer, "améliorer" du code adjacent, corriger d'autres bugs découverts en chemin
- **Obligatoire** : noter les problèmes découverts dans un commentaire `// TODO:` ou les signaler à l'utilisateur APRÈS le fix
- Si le debug révèle un problème plus large → terminer le fix actuel d'abord, puis signaler

### Anti-patterns Debug

| Interdit | Pourquoi | Alternative |
|----------|----------|-------------|
| Deviner sans reproduire | Fix aléatoire | Reproduire d'abord |
| Changer plusieurs choses à la fois | Impossible d'isoler la cause | Une variable à la fois |
| Ignorer les logs/stack traces | L'info est déjà là | Lire tout, tracer le flux |
| Refactorer pendant le debug | Mélange les responsabilités | Fix d'abord, refactor après |
| Supprimer du code "pour voir" | Dangereux + non scientifique | Commenter temporairement si nécessaire |

---

## 5. Checklist Sécurité

- [ ] Aucun secret/token dans les messages d'erreur
- [ ] Les erreurs exposées à l'utilisateur ne révèlent pas la structure interne
- [ ] Les stack traces ne sont pas affichées en production
- [ ] Les erreurs de validation sont formatées pour l'utilisateur (pas de dump brut)

---

## 6. Portes d'Acceptation

| Critère | Seuil | Vérification |
|---------|-------|--------------|
| Catch vides | 0 | `silent-failure-hunter` |
| Erreurs ignorées | 0 | `silent-failure-hunter` severity < HIGH |
| Logging structuré | 100% des catch | Préfixe `[MODULE]` |
| Error states UI | Tous les hooks de data | `if (error)` dans chaque composant |

### Checklist pré-commit

- [ ] `silent-failure-hunter` exécuté, aucune severity HIGH ou CRITICAL
- [ ] Tous les retours d'API ont leur erreur vérifiée
- [ ] Tous les `catch` ont du logging avec préfixe module
- [ ] Zéro `catch` vide ou avec simple `console.log`
- [ ] Les opérations multi-étapes ont un rollback pattern
- [ ] Les mutations UI ont un état d'erreur visible
