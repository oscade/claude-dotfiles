# Browser Verification - Directives Generales

> **Objectif** : Verification fonctionnelle et visuelle via Playwright MCP avant validation feature
> **Quand lire** : Apres implementation d'une feature UI complete, avant review gate
> **Prerequis** : Serveurs MCP `playwright` et `playwright-vision` configures dans `.mcp.json`
> **Resume gates** : 0 erreur bloquante DOM | validation visuelle OK sur pages impactees

---

## 1. Principes

```
TOUTE feature touchant l'UI doit etre verifiee dans le navigateur.
Un build qui passe ne garantit PAS que l'utilisateur voit ce qu'il doit voir.
```

- La verification navigateur est une etape du workflow, pas un bonus
- DOM d'abord (rapide, deterministe), screenshot si necessaire (visuel)
- Une erreur bloquante trouvee = fix avant review gate

---

## 2. Deux Serveurs MCP — Strategie Mixte

| Serveur | Mode | Cout tokens | Usage |
|---------|------|-------------|-------|
| `playwright` | Snapshot DOM (arbre accessibilite) | ~200-500/action | 80% des verifications |
| `playwright-vision` | Screenshots | ~1500-2500/action | Validation visuelle |

### Quand utiliser `playwright` (DOM snapshot)

- Verifier qu'un element existe ou est absent
- Lire le texte affiche (titres, labels, messages d'erreur, toasts)
- Verifier la navigation (URL, presence de composants)
- Verifier les etats (loading, error, empty, success)
- Remplir des formulaires et verifier la soumission
- Verifier les attributs (disabled, aria-*, data-*)

### Quand utiliser `playwright-vision` (Screenshot)

- Validation du layout general d'une page (alignement, spacing)
- Verification des couleurs, badges, indicateurs visuels
- Design review apres changements UI significatifs
- Responsive check (si viewport change)
- Premiere visite d'une page jamais verifiee

---

## 3. Protocole de Verification par Feature

### Etape 1 — Smoke test DOM (OBLIGATOIRE)

Apres chaque feature UI implementee :

1. Naviguer vers la page impactee
2. Verifier les elements critiques via DOM snapshot
3. Executer le flux utilisateur principal (cliquer, remplir, soumettre)
4. Verifier le resultat (redirection, message succes, donnees affichees)

```
Resultat attendu : TOUS les elements critiques presents, aucune erreur visible.
Si erreur → FIX avant de continuer. Ne pas passer a la review gate.
```

### Etape 2 — Validation visuelle (CONDITIONNELLE)

Declencher `playwright-vision` screenshot SI :

| Condition | Screenshot requis |
|-----------|-------------------|
| Nouveau composant UI ou page | OUI |
| Changement de layout/structure | OUI |
| Modification CSS/design tokens | OUI |
| Fix logique sans impact visuel | NON |
| Ajout de champ dans un formulaire | NON (DOM suffit) |
| Correction de texte/label | NON (DOM suffit) |

### Etape 3 — Rapport

Apres verification, documenter dans la conversation :

```
[BROWSER-CHECK] Page: /route
  DOM: ✅ elements critiques presents, flux OK
  Visual: ✅ layout coherent (ou ⬜ non requis)
  Erreurs: aucune (ou liste des erreurs trouvees)
```

---

## 4. Plan de Verification — Generation par Projet

A la premiere session sur un projet existant ou nouveau, generer un **plan de verification**
specifique au projet. Ce plan est un artefact projet, pas une rule generique.

### Comment generer le plan

1. **Analyser le routeur** : lister toutes les pages/routes de l'application
2. **Identifier les flux critiques** : auth, CRUD principal, formulaires multi-etapes, paiement, onboarding
3. **Classifier chaque flux** :
   - Type de verification (DOM seul, DOM + screenshot)
   - Elements critiques a verifier par page
   - Scenarios utilisateur (happy path + cas d'erreur)
4. **Produire le plan** au format table :

```
| Flux | Pages | Type verif | Elements critiques |
|------|-------|------------|-------------------|
| [nom du flux] | [routes] | DOM / DOM+Screenshot | [ce qu'on verifie] |
```

### Ou stocker le plan

- Fichier : `docs/browser-verification-plan.md` dans le projet (si demande)
- Sinon : dans la memoire projet (memory/) pour reference inter-sessions

### Quand regenerer le plan

- Ajout d'une nouvelle page/route
- Changement significatif dans un flux existant
- Nouveau domaine metier ajoute

---

## 5. Classification des Erreurs

| Severite | Definition | Action |
|----------|------------|--------|
| **BLOQUANT** | Element critique absent, crash JS, formulaire non soumettable, navigation cassee | Fix IMMEDIAT, pas de review gate |
| **DEGRADED** | Element present mais mal affiche, texte tronque, espacement incorrect | Fix avant commit si possible, sinon noter comme issue |
| **COSMETIC** | Leger ecart visuel, pixel-perfect non respecte | Noter, ne bloque pas |

```
REGLE : Toute erreur BLOQUANT trouvee en browser-check EMPECHE la review gate.
Corriger d'abord, re-verifier, puis passer aux agents de review.
```

---

## 6. Integration dans le Ship Flow

Le browser-check s'insere entre l'implementation et la review gate :

```
1. Implementation feature
2. Build + type-check (tsc -b) ← existant
3. ★ Browser verification (DOM + screenshot si requis) ← NOUVEAU
4. Review gate (6 agents) ← existant
5. Commit + push ← existant
```

Si le browser-check trouve des erreurs bloquantes :
- Retour a l'etape 1 (fix)
- Re-executer le browser-check
- Puis seulement passer a la review gate

---

## 7. Anti-Patterns

| Interdit | Pourquoi | Alternative |
|----------|----------|-------------|
| Screenshot systematique sur chaque action | Cout tokens explose | DOM snapshot par defaut |
| Skipper le browser-check "parce que c'est un petit fix" | Un petit fix peut casser le rendu | Au minimum DOM smoke test |
| Valider visuellement sans naviguer le flux complet | Flux partiel = faux positif | Tester le flux de bout en bout |
| Browser-check sur du code non-UI (service, lib) | Inutile, cout pour rien | Uniquement sur features UI |
| Plan de verification hardcode dans cette rule | Specifique au projet | Generer par projet (§4) |

---

## 8. Portes d'Acceptation

| Critere | Seuil | Verification |
|---------|-------|--------------|
| Erreurs BLOQUANT | 0 | Browser-check DOM |
| Flux critique navigable | 100% | Smoke test bout en bout |
| Screenshot valide | Si requis (§3 etape 2) | playwright-vision |
| Rapport documente | Chaque feature UI | [BROWSER-CHECK] dans la conversation |

### Checklist pre-review-gate (complement)

- [ ] Browser-check DOM execute sur les pages impactees
- [ ] Flux utilisateur principal teste de bout en bout
- [ ] Aucune erreur BLOQUANT
- [ ] Screenshot si changement visuel significatif
- [ ] Rapport [BROWSER-CHECK] documente
