# Testing - Directives Générales

> **Objectif** : Conventions et stratégie de test par couche
> **Quand lire** : Avant d'écrire ou modifier des tests
> **Agents** : code-reviewer (>= 90)
> **Résumé gates** : toute nouvelle business logic testée | conventions respectées

---

## 1. Principes

- Respecter le framework de test en place dans le projet
- Coverage : suivre les standards existants du projet
- Ne pas sur-tester pour des cas improbables
- Tests co-localisés avec le code source (même dossier)

---

## 2. Conventions

### Fichiers

| Aspect | Convention |
|--------|-----------|
| Nommage | `*.test.ts` / `*.test.tsx` (ou `*.spec.*` si convention projet) |
| Emplacement | Co-localisé dans le même dossier que le fichier testé |
| Données de test | Inline dans le test (pas de dossier fixtures séparé sauf si convention projet) |

### Structure de test

```
describe('NomDuModule', () => {
  describe('nomDeLaFonction', () => {
    it('should [comportement attendu] when [condition]', () => {
      // Arrange
      // Act
      // Assert
    })
  })
})
```

---

## 3. Quoi Tester par Couche

| Couche | Quoi tester | Priorité |
|--------|------------|----------|
| Types / Guards | Factories, type guards, discriminated unions | Haute |
| Business logic (pure functions) | Calculs, validations, transformations | Haute |
| Type mappers | Conversion data source → domaine, edge cases | Haute |
| Services | Logique d'orchestration (avec mocks I/O) | Moyenne |
| Hooks/composables | Via les composants qui les consomment | Basse |
| Composants UI | Rendu, interactions, états erreur/loading | Moyenne |
| Intégration | Flux complets critiques (auth, CRUD) | Moyenne |

### Priorité de test

```
Pure functions > Type mappers > Services > Composants > Intégration
(plus facile à tester → plus dur à tester)
```

### Pattern de test - Pure functions

```
describe('calculateTotal', () => {
  it('should sum line items correctly', () => {
    const lines = [{ quantity: 2, price: 100 }, { quantity: 1, price: 50 }]
    expect(calculateTotal(lines)).toBe(250)
  })

  it('should return 0 for empty array', () => {
    expect(calculateTotal([])).toBe(0)
  })

  it('should handle edge case: negative quantities', () => {
    // documenter le comportement attendu
  })
})
```

### Pattern de test - Avec mocks

```
// Mocker uniquement les I/O (API, DB, filesystem)
// Ne PAS mocker la logique métier
vi.mock('./apiClient', () => ({
  apiClient: { get: vi.fn(), post: vi.fn() }
}))
```

---

## 4. Anti-Patterns Interdits

| Interdit | Pourquoi | Alternative |
|----------|----------|-------------|
| Tests dans un dossier séparé `__tests__/` | Perd la co-location (sauf si convention projet) | Même dossier que le source |
| Snapshots sur du HTML | Fragiles, peu informatifs | Assertions explicites |
| Mock de tout (y compris la logique) | Tests sans valeur | Mock uniquement les I/O |
| `test('works')` sans assertion | Faux positif | Assertions explicites |
| Tests dépendants de l'ordre | Flaky tests | Chaque test indépendant |
| Tester les détails d'implémentation | Tests fragiles | Tester le comportement |

---

## 5. Portes d'Acceptation

| Critère | Seuil | Vérification |
|---------|-------|--------------|
| Business logic testée | 100% des nouvelles fonctions | Review |
| Tests passent | Green | CI / test runner |
| code-reviewer | Score >= 90 | Agent |

### Checklist pré-commit

- [ ] Toute nouvelle pure function / business logic a des tests
- [ ] Tests co-localisés avec le fichier source
- [ ] Tests passent sans erreur
- [ ] Pas de `test.skip` ou `test.todo` non justifié
- [ ] Mocks limités aux I/O (API, DB, filesystem)
- [ ] Assertions explicites (pas de snapshots fragiles)
