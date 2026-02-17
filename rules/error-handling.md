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
- [ ] Tous les retours d'API ont leur erreur vérifiée
- [ ] Tous les `catch` ont du logging avec préfixe module
- [ ] Zéro `catch` vide ou avec simple `console.log`
- [ ] Les opérations multi-étapes ont un rollback pattern
- [ ] Les mutations UI ont un état d'erreur visible
