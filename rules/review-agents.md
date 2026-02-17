# Review Agents - Directives Générales

> **Objectif** : Garantir la qualité du code via les 5 agents PR Review Toolkit
> **Quand lire** : Avant tout commit, après toute feature/tâche complétée
> **Résumé gates** : code-reviewer >= 90 | silent-failure-hunter < HIGH | type-design >= 8/10

---

## 1. Principes

Chaque feature ou tâche complétée doit passer par un workflow de review automatisé
AVANT de proposer un commit. Les agents s'exécutent **silencieusement** après chaque bloc
de code significatif - ne pas attendre la fin de la session.

**Exception** : Pour les refactorisations mineures ou corrections de bugs simples,
seul `code-reviewer` est obligatoire.

---

## 2. Les 5 Agents

| Agent | Rôle | Déclencheur |
|-------|------|-------------|
| `code-reviewer` | Review générale (score 0-100) | Chaque feature complétée |
| `silent-failure-hunter` | Détecte erreurs silencieuses | Code avec try/catch, async/await, API calls |
| `type-design-analyzer` | Analyse conception des types | Création de nouveaux types/interfaces |
| `code-simplifier` | Suggère des simplifications | Après implémentation initiale |
| `comment-analyzer` | Vérifie qualité des commentaires | Code complexe ajouté/modifié |

---

## 3. Workflow Séquentiel Obligatoire

```
APRÈS chaque feature/tâche terminée :

1. [code-reviewer]          → Score global, issues critiques
2. [silent-failure-hunter]  → Vérifier gestion d'erreurs
3. [type-design-analyzer]   → Valider design des types (si nouveaux types)
4. [code-simplifier]        → Opportunités de simplification
5. [comment-analyzer]       → Qualité des commentaires (si code complexe)
```

---

## 4. Seuils d'Acceptation

| Agent | Seuil | Action si Non-Conforme |
|-------|-------|------------------------|
| code-reviewer | Score >= 90 (viser 90-95) | Corriger jusqu'à 90+ |
| silent-failure-hunter | Severity < HIGH | Ajouter gestion d'erreur |
| type-design-analyzer | Score moyen >= 8/10 | Refactorer les types |
| code-simplifier | Complexité raisonnable | Simplifier si suggéré |

**Standards stricts** : Un score de 72/100 ou 6/10 est inacceptable.

---

## 5. Mapping Agents / Couches

| Couche | Agents obligatoires |
|--------|---------------------|
| API / Services | code-reviewer, silent-failure-hunter |
| Types / Interfaces | code-reviewer, type-design-analyzer |
| Error handling | silent-failure-hunter |
| UI Components | code-reviewer, code-simplifier |
| Business logic | code-reviewer, type-design-analyzer |
| Code complexe | comment-analyzer |

---

## 6. Commande Manuelle

Pour une review complète à la demande :
```
/pr-review-toolkit:review-pr all
```

---

## 7. Portes d'Acceptation

### Checklist pré-commit

- [ ] `code-reviewer` exécuté, score >= 90
- [ ] `silent-failure-hunter` exécuté si code async/try-catch, severity < HIGH
- [ ] `type-design-analyzer` exécuté si nouveaux types, score >= 8/10
- [ ] `code-simplifier` exécuté, suggestions appliquées si pertinentes
- [ ] `comment-analyzer` exécuté si code complexe

```
NE JAMAIS committer sans avoir exécuté au minimum code-reviewer.
Un score < 90 est BLOQUANT - corriger avant de continuer.
```
