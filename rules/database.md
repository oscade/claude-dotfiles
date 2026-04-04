# Database - Directives Générales

> **Objectif** : Performance et intégrité des accès base de données
> **Quand lire** : Avant tout code touchant un ORM, query builder, migrations, ou cache local
> **Agents** : code-reviewer, silent-failure-hunter
> **Résumé gates** : zéro N+1 | champs explicites | indexes sur WHERE/JOIN | batch writes

---

## 1. Principes

```
TOUJOURS coder "performance-ready" dès le premier commit.
La performance n'est pas une optimisation future - c'est une exigence de base.
```

---

## 2. Patterns Obligatoires

### Sélection explicite (jamais SELECT *)

Toujours spécifier les colonnes retournées, que ce soit via un ORM, un query builder,
ou du SQL brut. `SELECT *` est interdit.

### JOINs plutôt que requêtes en boucle

Pour les données relationnelles, utiliser des JOINs ou des nested selects
plutôt que des requêtes séparées.

### Pagination obligatoire sur les listes

Toute requête retournant une collection doit être paginée (`LIMIT/OFFSET`, cursor, ou keyset).

### Batch writes

Les opérations d'écriture multiples doivent utiliser des opérations batch
(`bulkInsert`, `bulkPut`, `insertMany`) plutôt que des boucles.

### Transactions pour l'atomicité

Toute séquence d'écritures interdépendantes doit être encapsulée dans une transaction.

### Migrations versionnées

Tout changement de schéma passe par une migration versionnée et réversible.
Jamais de modification de schéma manuelle en production.

### Indexes

Créer un index sur toute colonne utilisée en `WHERE`, `JOIN`, ou `ORDER BY`
sur des tables de taille significative.

---

## 3. Anti-Patterns Interdits

| Interdit | Pourquoi | Alternative |
|----------|----------|-------------|
| Boucles avec `await` de requêtes (N+1) | O(n) requêtes réseau | JOINs ou batch |
| `await` dans `.map()` séquentiel | Latence cumulée | `Promise.all()` + requête groupée |
| Multiples appels séquentiels | Latence cumulée | Une seule requête avec JOINs |
| `SELECT *` implicite | Payload non contrôlé | Colonnes explicites |
| Écritures unitaires en boucle | Perf dégradée | Batch operations |
| Schéma sans versioning | Migration impossible | Migrations versionnées |
| Table sans index sur colonnes filtrées | Full scan | Indexes ciblés |

**Exemple INTERDIT :**
```
// N+1 - Une requête par élément parent
const parents = await db.query('SELECT * FROM parents')
for (const parent of parents) {
  const children = await db.query('SELECT * FROM children WHERE parent_id = ?', parent.id)
}
```

**Exemple OBLIGATOIRE :**
```
// Une seule requête avec JOIN
const data = await db.query(`
  SELECT p.id, p.name, c.id AS child_id, c.name AS child_name
  FROM parents p
  LEFT JOIN children c ON c.parent_id = p.id
  WHERE p.org_id = ?
`, orgId)
```

---

## 4. Cache local (si applicable)

Si le projet utilise un cache local (IndexedDB, SQLite, localStorage structuré) :

- Définir un schéma versionné avec migrations
- Utiliser des opérations batch pour les écritures multiples
- Encapsuler les écritures liées dans des transactions
- Nettoyer le cache au logout/déconnexion
- Synchroniser via un mécanisme explicite (queue, sync manager)

---

## 5. Checklist Sécurité

- [ ] Pas de SQL brut avec concaténation de strings (parameterized queries uniquement)
- [ ] Contrôle d'accès au niveau des données (RLS, policies, ou filtres applicatifs)
- [ ] Indexes sur les colonnes utilisées en WHERE/JOIN/ORDER BY
- [ ] Migrations versionnées et réversibles
- [ ] Cache local nettoyé à la déconnexion

---

## 6. Portes d'Acceptation

| Critère | Seuil | Vérification |
|---------|-------|--------------|
| N+1 queries | 0 | Grep `await` dans des boucles DB |
| Champs explicites | 100% | Aucun `SELECT *` ou wildcard |
| Requêtes par page | 1-3 max | Profiling / dev tools |
| Taille payload | < 50KB | Network monitoring |
| Indexes | Sur tout WHERE/JOIN | Vérifier les migrations |

### Checklist pré-commit

- [ ] Aucune boucle contenant des `await` de requêtes DB
- [ ] JOINs pour les données relationnelles
- [ ] Indexes sur les colonnes filtrées/jointes
- [ ] Pagination sur les listes
- [ ] Pas de re-fetch de données déjà disponibles
- [ ] Batch operations pour les écritures multiples
- [ ] Cache approprié pour les données statiques/semi-statiques
