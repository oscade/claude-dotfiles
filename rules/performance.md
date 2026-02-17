# Performance - Directives Générales

> **Objectif** : Exigences de performance non négociables pour chaque commit
> **Quand lire** : Avant tout code impactant le chargement, les requêtes, ou le bundle
> **Agents** : code-reviewer
> **Résumé gates** : page load < 500ms | queries DB 1-3/page | payload < 50KB

---

## 1. Principes

```
TOUJOURS coder "performance-ready" dès le premier commit.
La performance n'est pas une optimisation future - c'est une exigence de base.
```

- Considérer l'impact performance de chaque changement
- Big O notation quand pertinent
- Attention aux N+1 queries, memory leaks, blocking calls

---

## 2. Métriques Cibles

| Métrique | Cible | Inacceptable |
|----------|-------|--------------|
| Temps chargement page | < 500ms | > 2s |
| Requêtes DB par page | 1-3 max | > 5 |
| Taille payload API | < 50KB | > 200KB |
| LCP (Largest Contentful Paint) | < 2.5s | > 4s |
| FID (First Input Delay) | < 100ms | > 300ms |
| CLS (Cumulative Layout Shift) | < 0.1 | > 0.25 |

---

## 3. Patterns Obligatoires

### Requêtes Base de Données

| Pattern Interdit | Pattern Obligatoire |
|------------------|---------------------|
| Boucles avec requêtes (N+1) | JOINs ou requêtes batch |
| `await` dans `.map()` | `Promise.all()` avec requêtes groupées |
| Multiples appels séquentiels | Une seule requête avec JOINs |
| `SELECT *` implicite | Sélection explicite des colonnes |

Voir `database.md` pour les détails et exemples.

### Caching multi-niveaux

| Niveau | Description | TTL typique |
|--------|------------|-------------|
| Mémoire (runtime) | Data fetching cache (stale/fresh) | 1-10 min |
| Local (persistant) | IndexedDB, SQLite, localStorage | Persistant / session |
| Network (CDN/SW) | Service Worker, CDN cache | 1-24h |

Choisir le(s) niveau(x) approprié(s) selon la fréquence de changement des données.

### Bundle Optimization

- **Code splitting** : séparer le code par route/feature
- **Lazy loading** : charger les composants lourds à la demande
- **Tree shaking** : s'assurer que les imports sont tree-shakeable

```
// Lazy loading de composants lourds
const HeavyComponent = lazy(() => import('./HeavyComponent'))
```

### Rendering

- Éviter les re-renders inutiles (memoization, stable references)
- Virtualisation pour les longues listes (> 100 items)
- Debounce/throttle sur les inputs fréquents (recherche, resize)

---

## 4. Anti-Patterns Interdits

| Interdit | Impact | Alternative |
|----------|--------|-------------|
| N+1 queries | O(n) requêtes réseau | JOIN ou batch |
| `await` dans `.map()` séquentiel | Latence cumulée | `Promise.all()` |
| Re-fetch données disponibles | Requêtes inutiles | Cache |
| Import synchrone de tout | Bundle initial gonflé | Lazy + code splitting |
| Pas de pagination | Payload > 200KB | Pagination systématique |
| Écritures unitaires en boucle | I/O multiplié | Batch operations |
| Re-render arbre entier | UI janky | Memoization, granularité |

---

## 5. Checklist Performance

Avant chaque PR/commit, vérifier :

- [ ] Aucune boucle contenant des `await` de requêtes
- [ ] JOINs pour les données relationnelles
- [ ] Indexes sur les colonnes filtrées/jointes
- [ ] Pagination pour les listes potentiellement longues
- [ ] Pas de re-fetch de données déjà disponibles
- [ ] Cache approprié pour les données stables
- [ ] Composants lourds chargés en lazy
- [ ] Pas de re-renders inutiles identifiés

---

## 6. Portes d'Acceptation

| Critère | Seuil | Vérification |
|---------|-------|--------------|
| N+1 queries | 0 | Grep `await` dans boucles |
| Page load | < 500ms | Lighthouse / dev tools |
| DB queries/page | 1-3 max | Network tab |
| Payload API | < 50KB | Network tab |
| Web Vitals | LCP < 2.5s, FID < 100ms, CLS < 0.1 | Lighthouse |

### Checklist pré-commit

- [ ] Aucun N+1 détecté
- [ ] Champs explicites sur toutes les requêtes
- [ ] Pagination sur les listes
- [ ] Lazy loading pour les composants lourds
- [ ] `code-reviewer` score >= 90
