# Service Layer - Directives Générales

> **Objectif** : Architecture et conventions des services métier
> **Quand lire** : Avant de créer/modifier un service
> **Agents** : code-reviewer (>= 90), type-design-analyzer (>= 8/10)
> **Résumé gates** : pattern service cohérent | type mappers | séparation business/data

---

## 1. Principes

- **COHÉRENT** : adopter le pattern service du projet existant (objet littéral, classe, module)
- **MINIMAL** : un service par entité ou domaine métier
- Code lisible > code clever | Complexité cyclomatique raisonnable | Dépendances minimales

---

## 2. Patterns Obligatoires

### Un service par entité/domaine

Chaque entité métier a son propre service regroupant les opérations CRUD
et la logique spécifique à ce domaine.

### Pattern cohérent avec le projet

Identifier le pattern existant et le suivre strictement :
- Objet littéral exporté (`export const userService = { ... }`)
- Classe avec méthodes statiques
- Module avec fonctions nommées

Ne jamais mélanger les patterns dans un même projet.

### Type mappers à la frontière

Les types bruts de la source de données (DTO, Row, API Response) ne doivent
**jamais** sortir du service. Convertir via des mappers typés.

```
// Le service est la frontière : types externes → types domaine
async getUser(id: string): Promise<User> {
  const raw = await dataSource.get(id)
  return mapToUser(raw)  // conversion à la frontière
}
```

### Séparation business logic vs data access

| Couche | Responsabilité | Testabilité |
|--------|---------------|-------------|
| Pure functions | Calculs, validations, transformations | Sans mock, sans I/O |
| Service | Orchestration, data access, coordination | Avec mocks |

```
// Business logic pure (testable sans dépendance)
function calculateTotal(lines) { ... }
function validateTransition(from, to) { ... }

// Service (orchestration + data access)
const orderService = {
  async finalize(id) {
    const order = await this.getById(id)
    validateTransition(order.status, 'finalized')  // pure function
    const total = calculateTotal(order.lines)       // pure function
    return this.update(id, { status: 'finalized', total })
  }
}
```

### Transaction / rollback pour opérations multi-étapes

```
// 1. Sauvegarder l'état initial
// 2. Étape A (irréversible)
// 3. Étape B → si erreur, rollback étape A
// 4. Confirmer
```

---

## 3. Anti-Patterns Interdits

| Interdit | Pourquoi | Alternative |
|----------|----------|-------------|
| Mélanger les patterns service | Incohérence projet | Un seul pattern partout |
| Types data source dans les signatures publiques | Couplage | Mappers à la frontière |
| Business logic dans la couche data access | Non testable isolément | Pure functions séparées |
| Service sans propagation d'erreur | Erreur silencieuse | Throw ou Result type |
| Logique métier dans les composants UI | Réutilisabilité nulle | Extraire dans le service |
| God service (tout dans un seul) | Maintenabilité | Un service par domaine |

---

## 4. Checklist Sécurité

- [ ] Validation des inputs avant toute opération service
- [ ] Aucun secret/credential dans le code service
- [ ] Contrôle d'accès vérifié (via la couche data ou explicitement)
- [ ] Rollback pattern sur les opérations multi-étapes

---

## 5. Portes d'Acceptation

| Critère | Seuil | Vérification |
|---------|-------|--------------|
| code-reviewer | Score >= 90 | Agent |
| type-design-analyzer | Score >= 8/10 | Agent (si nouveaux types) |
| Pattern cohérent | Identique au reste du projet | Review |
| Type mappers | Frontière service | Aucun type data source exposé |
| Business logic pure | Fonctions séparées | Testables sans mock |

### Checklist pré-commit

- [ ] Pattern service identique au reste du projet
- [ ] Type mappers à chaque frontière data/domaine
- [ ] Business logic dans des pure functions séparées
- [ ] Rollback pattern sur toute opération multi-étapes
- [ ] Erreurs propagées, jamais avalées
