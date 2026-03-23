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

### Discrimination des erreurs à la couche service

Le `throw error` brut est acceptable à la couche data (propagation immédiate).
À la couche service (face utilisateur), les erreurs doivent être **discriminées**
par code/type pour produire des messages contextualisés.

```
// INTERDIT en couche service — message incompréhensible pour l'utilisateur
if (error) throw error

// OBLIGATOIRE — discrimination par code, message actionable
if (error.code === '23503') {
  throw new Error('Impossible : des données dépendantes existent')
}
```

Voir `supabase.md` §7 pour la table des error codes Supabase/PostgreSQL.

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

| Interdit | Pourquoi | Alternative | detection_grep |
|----------|----------|-------------|----------------|
| `catch (e) {}` vide | Erreur silencieuse | Log + rethrow ou traitement | `catch` |
| `catch (e) { return null }` | Masque l'erreur à l'appelant | Throw ou Result type | `return null` |
| `console.log(error)` sans contexte | Non traçable en production | `[MODULE] message:` + error | `console.log` |
| `const { data }` sans `error` | Échec silencieux (Supabase/API) | `const { data, error }` | `const { data }` |
| Ignorer le champ erreur d'une réponse | Échec silencieux | `if (error) throw error` | — |
| `await` dans `.map()` sans error handling | Erreur non catchée | `Promise.allSettled()` ou try/catch | `await` + `.map(` |
| Catch qui log + rethrow sans transformation | Double logging | Log OU rethrow, pas les deux | — |
| `if (error) throw error` en couche service | Message brut incompréhensible | Discrimination par error code | — |

---

## 4. Checklist Sécurité

- [ ] Aucun secret/token dans les messages d'erreur
- [ ] Les erreurs exposées à l'utilisateur ne révèlent pas la structure interne
- [ ] Les stack traces ne sont pas affichées en production
- [ ] Les erreurs de validation sont formatées pour l'utilisateur (pas de dump brut)

---

## 5. Portes d'Acceptation

| Critère | Seuil | Vérification |
|---------|-------|--------------|
| Catch vides | 0 | `silent-failure-hunter` |
| Erreurs ignorées | 0 | `silent-failure-hunter` severity < HIGH |
| Logging structuré | 100% des catch | Préfixe `[MODULE]` |
| Error states UI | Tous les hooks de data | `if (error)` dans chaque composant |

### Checklist pré-commit

- [ ] `silent-failure-hunter` exécuté, aucune severity HIGH ou CRITICAL
- [ ] Tous les retours d'API ont leur erreur vérifiée (`const { data, error }`)
- [ ] Tous les `catch` ont du logging avec préfixe module
- [ ] Zéro `catch` vide ou avec simple `console.log`
- [ ] Les opérations multi-étapes ont un rollback pattern
- [ ] Les mutations UI ont un état d'erreur visible
- [ ] Les erreurs en couche service sont discriminées par code (pas de `throw error` brut face-utilisateur)
