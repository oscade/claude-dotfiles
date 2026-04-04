# Testing - Directives Générales

> **Objectif** : Conventions et stratégie de test par couche
> **Quand lire** : Avant d'écrire ou modifier des tests
> **Agents** : code-reviewer (>= 90)
> **Résumé gates** : toute nouvelle business logic testée | conventions respectées | E2E sur flux critiques

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

## 4. Tests E2E / Browser (Playwright)

```
Les tests unitaires vérifient la logique. Les tests E2E vérifient l'expérience.
Un test unitaire vert ne garantit PAS que l'utilisateur voit ce qu'il doit voir.
```

### Quand écrire des tests E2E

| Situation | E2E requis |
|-----------|-----------|
| Flux critique (auth, paiement, onboarding) | **Obligatoire** |
| CRUD complet d'une entité métier | **Obligatoire** |
| Formulaire multi-étapes | **Obligatoire** |
| Composant UI isolé | Non — tester via tests composants |
| Pure function / service | Non — tester via tests unitaires |

### Conventions E2E

| Aspect | Convention |
|--------|-----------|
| Framework | Playwright (sauf convention projet différente) |
| Nommage | `*.e2e.ts` |
| Emplacement | `e2e/` à la racine du projet |
| Données de test | Seed dédié ou fixtures, jamais de données prod |
| Isolation | Chaque test indépendant, cleanup after |

### Structure E2E

```typescript
test.describe('Nom du flux', () => {
  test('should [résultat utilisateur] when [action]', async ({ page }) => {
    // Navigate
    await page.goto('/route')

    // Act (interactions réelles)
    await page.getByRole('button', { name: 'Submit' }).click()

    // Assert (ce que l'utilisateur voit)
    await expect(page.getByText('Success')).toBeVisible()
  })
})
```

### Bonnes pratiques E2E

- **Sélecteurs** : `getByRole`, `getByText`, `getByLabel` — jamais de sélecteurs CSS/XPath fragiles
- **Attentes** : `toBeVisible()`, `toHaveText()` — assertions sur ce que l'utilisateur perçoit
- **Pas de sleep** : utiliser `waitForSelector`, `waitForResponse`, ou les auto-wait de Playwright
- **Screenshots** : capturer sur échec pour diagnostic (`screenshot: 'only-on-failure'`)
- **Tiered testing** : Quick (smoke, < 2min) pour chaque PR, Exhaustive (tous les flux) avant release

### Anti-patterns E2E

| Interdit | Pourquoi | Alternative |
|----------|----------|-------------|
| `page.locator('.css-class')` | Fragile, couplé à l'implémentation | `getByRole`, `getByText` |
| `page.waitForTimeout(3000)` | Flaky, lent | `waitForSelector`, auto-wait |
| Tester le style CSS | Non déterministe | Tester le comportement visible |
| Données partagées entre tests | Tests couplés, flaky | Seed/cleanup par test |
| E2E pour de la logique pure | Lent, mauvais ROI | Test unitaire |

---

## 5. Anti-Patterns Interdits

| Interdit | Pourquoi | Alternative |
|----------|----------|-------------|
| Tests dans un dossier séparé `__tests__/` | Perd la co-location (sauf si convention projet) | Même dossier que le source |
| Snapshots sur du HTML | Fragiles, peu informatifs | Assertions explicites |
| Mock de tout (y compris la logique) | Tests sans valeur | Mock uniquement les I/O |
| `test('works')` sans assertion | Faux positif | Assertions explicites |
| Tests dépendants de l'ordre | Flaky tests | Chaque test indépendant |
| Tester les détails d'implémentation | Tests fragiles | Tester le comportement |

---

## 6. Portes d'Acceptation

| Critère | Seuil | Vérification |
|---------|-------|--------------|
| Business logic testée | 100% des nouvelles fonctions | Review |
| Tests passent | Green | CI / test runner |
| E2E sur flux critiques | Smoke tests green | Playwright |
| code-reviewer | Score >= 95 | Agent |

### Checklist pré-commit

- [ ] Toute nouvelle pure function / business logic a des tests
- [ ] Tests co-localisés avec le fichier source
- [ ] Tests passent sans erreur
- [ ] Pas de `test.skip` ou `test.todo` non justifié
- [ ] Mocks limités aux I/O (API, DB, filesystem)
- [ ] Assertions explicites (pas de snapshots fragiles)
- [ ] Tests E2E sur les flux critiques (auth, CRUD, formulaires multi-étapes)
- [ ] Sélecteurs E2E accessibles (`getByRole`, `getByText`), pas de CSS/XPath
