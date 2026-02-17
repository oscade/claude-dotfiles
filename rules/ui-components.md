# UI Components - Directives Générales

> **Objectif** : Organisation, patterns et accessibilité des composants
> **Quand lire** : Avant de créer/modifier des composants UI
> **Agents** : code-reviewer, code-simplifier
> **Résumé gates** : labels sur tous les inputs | structure cohérente | accessibilité

---

## 1. Principes

- **COHÉRENT** : respecter l'organisation existante du projet
- **MINIMAL** : ne pas créer d'abstractions pour un seul usage
- Accessibilité (a11y) est un requis, pas un bonus

---

## 2. Organisation des Composants

Identifier et respecter la structure existante du projet. Pattern typique :

```
components/
├── ui/          # Primitives réutilisables (Input, Button, Modal, Dialog)
├── common/      # Layout, navigation, guards (AppLayout, ProtectedRoute)
└── [features]/  # Composants spécifiques à un domaine métier
```

### Règle de placement

| Type | Dossier | Critère |
|------|---------|---------|
| Primitives UI | `ui/` (ou équivalent) | Réutilisable partout, zéro logique métier |
| Layout/Navigation | `common/` (ou équivalent) | Structure app, auth guards |
| Feature-specific | `features/xxx/` | Logique métier, consomme un service/hook feature |

---

## 3. Patterns Obligatoires

### Forms : schema validation + live feedback

Les formulaires doivent utiliser :
1. Une bibliothèque de gestion de form (form state, validation, touched tracking)
2. Un schéma de validation typé (runtime + compile time)
3. Le mode `onChange` ou équivalent pour feedback visuel immédiat

```
// Pattern générique
const form = useForm({
  schema: validationSchema,     // schéma typé
  mode: 'onChange',             // validation live
  defaultValues: initialData
})
```

### Visual validation feedback

| État du champ | Indicateur visuel |
|---------------|-------------------|
| Default | Style neutre |
| Erreur (touched + invalide) | Bordure rouge + message d'erreur |
| Valide (touched + valide) | Bordure verte + indicateur succès |

### Composants form : forwardRef compatible

Les composants d'input doivent être compatibles avec le ref forwarding
pour s'intégrer avec les bibliothèques de form (`register`, `ref`).

### Design tokens cohérents

Utiliser les tokens du design system du projet (couleurs, spacing, typography).
Ne pas inventer de nouvelles valeurs ad-hoc.

| Rôle | Exemples de tokens |
|------|-------------------|
| Primaire | Actions, focus, liens |
| Succès | Confirmations, statuts positifs |
| Warning | Alertes, statuts intermédiaires |
| Erreur | Validations, statuts négatifs |
| Neutre | Backgrounds, texte, bordures |

---

## 4. Anti-Patterns Interdits

| Interdit | Pourquoi | Alternative |
|----------|----------|-------------|
| CSS custom quand un design system existe | Incohérence | Tokens du design system |
| Composant feature dans `ui/` | Couplage métier dans les primitives | `features/xxx/` |
| State serveur dans le composant | Pas de cache/refetch | Hook de data fetching |
| Form sans schema validation | Validation non typée, incomplète | Schema + form library |
| Input sans label/aria-label | Accessibilité | Label associé obligatoire |
| Composants god (500+ lignes) | Maintenabilité | Découper en sous-composants |

---

## 5. Checklist Accessibilité (a11y)

- [ ] Tout `<input>` a un `<label>` associé (via `htmlFor`/`for`) ou `aria-label`
- [ ] Les modals/dialogs ont `aria-modal`, focus trap, fermeture Escape
- [ ] Les boutons d'action ont un texte descriptif (pas juste une icône)
- [ ] Contraste suffisant (respecter les tokens du design system)
- [ ] Navigation clavier fonctionnelle (tabIndex, focus visible)
- [ ] Les images significatives ont un `alt` descriptif
- [ ] Les zones de contenu dynamique ont `aria-live` si nécessaire

---

## 6. Portes d'Acceptation

| Critère | Seuil | Vérification |
|---------|-------|--------------|
| Labels sur inputs | 100% | Review / grep inputs sans label |
| Design system | Tokens existants uniquement | Pas de valeurs ad-hoc |
| code-simplifier | Complexité raisonnable | Agent |
| code-reviewer | Score >= 90 | Agent |

### Checklist pré-commit

- [ ] Composant placé dans le bon dossier selon la convention projet
- [ ] Forms avec schema validation + mode live
- [ ] Design tokens du projet respectés
- [ ] Labels/aria sur tous les inputs
- [ ] Pas de CSS custom quand un design system existe
- [ ] `code-simplifier` exécuté pour les composants complexes
