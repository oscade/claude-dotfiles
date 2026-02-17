# State Management - Directives Générales

> **Objectif** : Séparation stricte des responsabilités d'état
> **Quand lire** : Avant tout code touchant le state management (stores, cache, data fetching)
> **Agents** : code-reviewer, type-design-analyzer
> **Résumé gates** : zéro server state dans le client store | invalidation correcte | cache keys cohérentes

---

## 1. Principes

L'état doit être réparti en couches distinctes avec des responsabilités strictes :

| Couche | Responsabilité | Exemples d'outils |
|--------|---------------|-------------------|
| Server state | Données distantes, cache, sync, refetch | TanStack Query, SWR, Apollo |
| Client state | UI state, préférences, navigation | Zustand, Redux, Jotai, Context |
| Persistent state | Cache offline, données locales | IndexedDB, SQLite, localStorage |

**Règle fondamentale** : une donnée ne vit que dans UNE couche. Jamais de duplication.

---

## 2. Patterns Obligatoires

### Server state → outil de data fetching dédié

Les données provenant d'une API distante sont gérées exclusivement par un outil
de server state (cache, stale detection, refetch, retry intégrés).

```
// Cache key déterministe basée sur les paramètres
queryKey: [entity, ...identifiers, ...filters]

// Guard obligatoire si paramètres optionnels
enabled: !!requiredParam
```

### Mutation avec invalidation

Toute mutation qui modifie des données distantes doit invalider les caches concernés.

```
// Après succès : invalider les queries liées
onSuccess: () => {
  invalidate([entity, parentId])
  invalidate([entity, 'detail', itemId])
}
```

### Client state → store minimal

Le store client ne contient que l'état UI pur :
- Utilisateur authentifié / session
- Sélection active (quel item est sélectionné)
- Préférences UI (thème, sidebar, langue)
- Flags de navigation

### Persistent state → cache explicite

Si le projet nécessite du offline-first ou du cache local :
- Schéma versionné
- Sync explicite avec le serveur
- Nettoyage au logout

---

## 3. Anti-Patterns Interdits

| Interdit | Pourquoi | Alternative |
|----------|----------|-------------|
| Server state dans le client store | Duplication, désynchronisation | Outil de data fetching |
| `useState` / `useEffect` pour fetch | Pas de cache/retry/refetch | Hook de data fetching |
| Mutation sans invalidation | Cache stale, UI désynchronisée | `onSuccess: invalidate` |
| Query sans guard `enabled` | Requête avec params `undefined` | `enabled: !!param` |
| Cache keys non déterministes | Cache incohérent | Clés basées sur les params |
| Store client comme cache API | Responsabilité mal placée | Server state dédié |
| Duplication de données entre couches | Source de vérité floue | Une seule couche par donnée |

---

## 4. Checklist Sécurité

- [ ] Les tokens auth ne sont pas dans un store client accessible au JS (préférer httpOnly)
- [ ] Les données sensibles ne sont pas persistées en localStorage/IndexedDB sans chiffrement
- [ ] Le cache local est nettoyé à la déconnexion
- [ ] Les stores persistés ne contiennent que le strict nécessaire

---

## 5. Portes d'Acceptation

| Critère | Seuil | Vérification |
|---------|-------|--------------|
| Server state dans client store | 0 | Grep stores pour données distantes |
| Invalidation après mutation | 100% | Toute mutation invalide les caches |
| Cache keys cohérentes | Convention `[entity, ...params]` | Review |
| Guards sur queries conditionnelles | 100% | `enabled:` sur toute query optionnelle |

### Checklist pré-commit

- [ ] Aucune donnée serveur dans le client store
- [ ] Toute mutation invalide les cache keys appropriées
- [ ] Toute query avec paramètres optionnels a un guard
- [ ] Les cache keys suivent la convention `[entity, ...identifiers]`
- [ ] Le store persisté utilise un filtre pour limiter ce qui est sauvegardé
