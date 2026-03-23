# Database - Directives Générales

> **Objectif** : Performance et intégrité des accès base de données
> **Quand lire** : Avant tout code touchant un ORM, query builder, migrations, ou cache local
> **Agents** : code-reviewer, silent-failure-hunter
> **Résumé gates** : zéro N+1 | champs explicites | indexes sur WHERE/JOIN | batch writes | FK explicites | guard checks avant opérations contraintes

---

## 1. Principes

```
TOUJOURS coder "performance-ready" ET "integrity-ready" dès le premier commit.
La performance et l'intégrité ne sont pas des optimisations futures - ce sont des exigences de base.
```

---

## 2. Patterns Obligatoires — Performance

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

## 3. Patterns Obligatoires — Intégrité Référentielle

### Chaque FK déclare un comportement ON DELETE explicite

Toute colonne référençant une autre table **DOIT** déclarer explicitement son
comportement de suppression. Le défaut PostgreSQL (`NO ACTION`) n'est presque
jamais le bon choix — il doit être justifié.

| Comportement | Quand l'utiliser | Exemple |
|--------------|------------------|---------|
| `ON DELETE CASCADE` | L'enfant n'a pas de sens sans le parent | `invoice_lines → invoices` |
| `ON DELETE RESTRICT` | L'enfant protège le parent contre la suppression | `invoices → clients` |
| `ON DELETE SET NULL` | La relation est optionnelle, l'enfant survit | `invoices.source_document_id → invoices` |
| `NO ACTION` | Rarement — justifier dans un commentaire SQL | Cas spéciaux uniquement |

```sql
-- OBLIGATOIRE : ON DELETE explicite sur chaque FK
client_id UUID REFERENCES clients(id) ON DELETE RESTRICT NOT NULL,
invoice_id UUID REFERENCES invoices(id) ON DELETE CASCADE NOT NULL,
source_id UUID REFERENCES invoices(id) ON DELETE SET NULL
```

### Guard check avant opération contrainte

Quand une FK utilise `RESTRICT`, le service **DOIT** vérifier les dépendances
AVANT de tenter l'opération. Ne jamais laisser une violation FK remonter brute à l'utilisateur.

```typescript
// INTERDIT — violation FK brute remontée à l'utilisateur
async delete(id: string) {
  const { error } = await supabase.from('clients').delete().eq('id', id)
  if (error) throw error  // FK violation → message incompréhensible
}

// OBLIGATOIRE — guard check + message explicite
async delete(id: string) {
  // Vérifier les dépendances AVANT la suppression
  const { count } = await supabase
    .from('invoices')
    .select('id', { count: 'exact', head: true })
    .eq('client_id', id)

  if (count && count > 0) {
    throw new AppError(
      'CLIENT_HAS_INVOICES',
      `Impossible de supprimer ce client : ${count} facture(s) associée(s)`
    )
  }

  const { error } = await supabase.from('clients').delete().eq('id', id)
  if (error) throw error
}
```

### Décision soft delete vs hard delete

Choisir UNE stratégie par projet et la documenter. Ne jamais mélanger les deux
sans justification explicite.

| Stratégie | Quand | Implications |
|-----------|-------|-------------|
| **Hard delete** (défaut) | Données sans obligation de rétention | FK CASCADE/RESTRICT obligatoire, cleanup explicite |
| **Soft delete** (`deleted_at`) | Obligation légale, audit trail, récupération | Filtre `WHERE deleted_at IS NULL` sur tous les SELECT, RLS policies adaptées |

Si soft delete : ajouter `deleted_at TIMESTAMPTZ DEFAULT NULL` et filtrer
systématiquement dans les queries et les RLS policies.

### Vérification d'intégrité dans les migrations

Chaque migration touchant des FK doit inclure un commentaire documentant
le comportement de suppression choisi et sa justification.

```sql
-- FK RESTRICT : un client avec des factures ne peut pas être supprimé
-- L'UI doit proposer l'archivage ou la suppression des factures d'abord
ALTER TABLE invoices
  ADD CONSTRAINT fk_invoices_client
  FOREIGN KEY (client_id) REFERENCES clients(id)
  ON DELETE RESTRICT;
```

### Détection d'orphelins

Après toute migration modifiant des FK, vérifier l'absence d'orphelins :

```sql
-- Pattern de détection d'orphelins
SELECT child.id FROM child_table child
LEFT JOIN parent_table parent ON parent.id = child.parent_id
WHERE parent.id IS NULL;
```

---

## 4. Anti-Patterns Interdits

### Performance

| Interdit | Pourquoi | Alternative |
|----------|----------|-------------|
| Boucles avec `await` de requêtes (N+1) | O(n) requêtes réseau | JOINs ou batch |
| `await` dans `.map()` séquentiel | Latence cumulée | `Promise.all()` + requête groupée |
| Multiples appels séquentiels | Latence cumulée | Une seule requête avec JOINs |
| `SELECT *` implicite | Payload non contrôlé | Colonnes explicites |
| Écritures unitaires en boucle | Perf dégradée | Batch operations |
| Schéma sans versioning | Migration impossible | Migrations versionnées |
| Table sans index sur colonnes filtrées | Full scan | Indexes ciblés |

### Intégrité

| Interdit | Pourquoi | Alternative |
|----------|----------|-------------|
| FK sans `ON DELETE` explicite | Comportement implicite non maîtrisé | Déclarer CASCADE/RESTRICT/SET NULL |
| `.delete()` sans guard sur FK RESTRICT | Violation FK brute à l'utilisateur | Vérifier les dépendances avant |
| Colonne `*_id` sans FK constraint | Relation implicite, pas d'intégrité DB | Déclarer la FK dans la migration |
| Mélange soft/hard delete sans convention | Comportement incohérent | Choisir une stratégie projet |
| Suppression parent sans vérifier les enfants | Orphelins ou erreur silencieuse | Guard check ou CASCADE |
| Migration FK sans commentaire justificatif | Comportement non documenté | Commenter le choix ON DELETE |

**Exemple INTERDIT — Performance :**
```
// N+1 - Une requête par élément parent
const parents = await db.query('SELECT * FROM parents')
for (const parent of parents) {
  const children = await db.query('SELECT * FROM children WHERE parent_id = ?', parent.id)
}
```

**Exemple OBLIGATOIRE — Performance :**
```
// Une seule requête avec JOIN
const data = await db.query(`
  SELECT p.id, p.name, c.id AS child_id, c.name AS child_name
  FROM parents p
  LEFT JOIN children c ON c.parent_id = p.id
  WHERE p.org_id = ?
`, orgId)
```

**Exemple INTERDIT — Intégrité :**
```
// Delete brut sans guard — violation FK incompréhensible pour l'utilisateur
const { error } = await supabase.from('clients').delete().eq('id', id)
```

**Exemple OBLIGATOIRE — Intégrité :**
```
// Guard check AVANT delete sur entité protégée par RESTRICT
const { count } = await supabase
  .from('invoices')
  .select('id', { count: 'exact', head: true })
  .eq('client_id', id)
if (count > 0) throw new AppError('CLIENT_HAS_INVOICES', `${count} facture(s) liée(s)`)
// Puis seulement le delete
```

---

## 5. Cache local (si applicable)

Si le projet utilise un cache local (IndexedDB, SQLite, localStorage structuré) :

- Définir un schéma versionné avec migrations
- Utiliser des opérations batch pour les écritures multiples
- Encapsuler les écritures liées dans des transactions
- Nettoyer le cache au logout/déconnexion
- Synchroniser via un mécanisme explicite (queue, sync manager)

---

## 6. Checklist Sécurité

- [ ] Pas de SQL brut avec concaténation de strings (parameterized queries uniquement)
- [ ] Contrôle d'accès au niveau des données (RLS, policies, ou filtres applicatifs)
- [ ] Indexes sur les colonnes utilisées en WHERE/JOIN/ORDER BY
- [ ] Migrations versionnées et réversibles
- [ ] Cache local nettoyé à la déconnexion

---

## 7. Portes d'Acceptation

| Critère | Seuil | Vérification |
|---------|-------|--------------|
| N+1 queries | 0 | Grep `await` dans des boucles DB |
| Champs explicites | 100% | Aucun `SELECT *` ou wildcard |
| Requêtes par page | 1-3 max | Profiling / dev tools |
| Taille payload | < 50KB | Network monitoring |
| Indexes | Sur tout WHERE/JOIN | Vérifier les migrations |
| FK explicites | 100% des relations | Aucune colonne `*_id` sans FK constraint |
| Guard checks | 100% des delete sur FK RESTRICT | Grep `.delete()` sans guard |
| ON DELETE déclaré | 100% des FK | Grep FK sans ON DELETE dans les migrations |

### Checklist pré-commit

- [ ] Aucune boucle contenant des `await` de requêtes DB
- [ ] JOINs pour les données relationnelles
- [ ] Indexes sur les colonnes filtrées/jointes
- [ ] Pagination sur les listes
- [ ] Pas de re-fetch de données déjà disponibles
- [ ] Batch operations pour les écritures multiples
- [ ] Cache approprié pour les données statiques/semi-statiques
- [ ] Toute FK déclare `ON DELETE` explicitement (CASCADE/RESTRICT/SET NULL)
- [ ] Tout `.delete()` sur une table référencée par FK RESTRICT a un guard check
- [ ] Migrations FK commentées avec la justification du comportement ON DELETE
- [ ] Vérification d'orphelins après migration touchant des FK

---

*Dernière mise à jour: Mars 2026*
