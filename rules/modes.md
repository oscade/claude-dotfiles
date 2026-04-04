# Modes de Fonctionnement - Directives Generales

> **Objectif** : Definir les artefacts et formats obligatoires par mode operationnel
> **Quand lire** : Quand un mode specifique est active (architecture, planning)
> **Resume gates** : artefacts presentes AVANT implementation | plans valides par l'utilisateur

---

## 1. Mode Architecture — Artefacts Structures

Active pour toute decision architecturale significative (nouveau service, nouvelle entite, refactoring majeur).

**Artefacts obligatoires avant implementation :**

| Artefact | Contenu | Format |
|----------|---------|--------|
| **Diagramme de composants** | Modules, dependances, flux de donnees | ASCII art ou Mermaid |
| **Data flow** | Entree → traitement → stockage → sortie | Diagramme fleche |
| **State machines** (si applicable) | Etats, transitions, guards | Table ou diagramme |
| **Error paths** | Chaque point de defaillance et sa gestion | Table : point → erreur → handling |
| **Test matrix** | Quoi tester, comment, priorite | Table par couche |

**Regles :**

- Chaque artefact est presente a l'utilisateur AVANT implementation
- Les diagrammes ASCII sont preferes (lisibles partout, versionnables)
- L'artefact error paths est obligatoire — pas d'architecture sans plan de gestion d'erreurs
- Sauvegarder dans `docs/architecture/` si demande

---

## 2. Mode Planning — Plans Structures

Active pour toute feature non triviale (> 1 fichier ou > 30min estime).

**Format obligatoire du plan :**

```
# Plan: [Nom de la feature]
## Spec approuvee: [lien ou resume]
## Taches

### Tache 1 — [Description courte]
- Fichier(s): chemin(s) exact(s)
- Modification: code complet, pas de placeholder
- Verification: commande a executer pour valider

### Tache 2 — [Description courte]
...
```

**Regles :**

- Chaque tache = 1 changement atomique verifiable
- **Zero placeholder** : chaque tache contient le code reel ou la description exacte
- Fichiers cibles identifies avec chemins complets
- Chaque tache a sa commande de verification
- Le plan est valide par l'utilisateur AVANT execution
- Sauvegarder le plan dans `docs/plans/` si demande

---

## 3. Autres Modes

| Mode | Description |
|------|-------------|
| **Execution** (defaut) | Faire ce qui est demande, efficacement, sans sur-analyse |
| **Revue** | Analyse critique, ameliorations, evaluation securite/performance |
| **Debug** | Protocole 4 phases → `~/.claude/rules/error-handling.md` section 4 |
