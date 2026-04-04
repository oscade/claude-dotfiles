# Security - Directives Générales

> **Objectif** : Sécurité applicative (OWASP Top 10 + STRIDE + Supply Chain)
> **Quand lire** : Avant tout code touchant auth, accès données, validation, secrets, ou données utilisateur
> **Agents** : silent-failure-hunter, code-reviewer
> **Résumé gates** : contrôle d'accès sur toutes les données | inputs validés | zéro secret côté client

---

## 1. Principes

### Règles Non Négociables

- Ne **jamais** logger/afficher de secrets, tokens, credentials
- Signaler **immédiatement** toute vulnérabilité identifiée
- Respecter les patterns de sécurité existants
- Ne **pas** contourner les contrôles d'accès

### Données Sensibles

- Anonymiser les exemples si données prod mentionnées
- Ne pas persister d'informations sensibles sans nécessité
- Suivre les principes du **least privilege**

---

## 2. Patterns Obligatoires

### Contrôle d'accès au niveau des données

Chaque requête de données doit être filtrée par le contexte d'accès de l'utilisateur.
Ce contrôle peut être :
- Côté serveur : RLS (Row Level Security), policies, middleware
- Côté applicatif : filtres systématiques dans les services

**Jamais** de vérification d'accès uniquement côté client.

### Validation des inputs à la frontière

Tout input utilisateur doit être validé via un schéma typé **avant** traitement.

```
// Validation structurée à l'entrée
const validated = inputSchema.parse(rawUserInput)
// Seul `validated` est utilisé ensuite
```

### Auth centralisée

- Session gérée par un provider/service dédié
- Routes protégées via des guards (middleware, composants wrapper)
- Refresh token automatique si applicable

### Sanitization des recherches texte

```
// Échapper les caractères spéciaux avant injection dans une requête
const sanitized = query.replace(/[%_\\]/g, '\\$&')
```

### Secrets management

- Variables d'environnement pour les secrets, **jamais** hardcodées
- Fichiers `.env.local` dans `.gitignore`
- Distinction clés publiques (client) vs clés privées (serveur uniquement)

---

## 3. Anti-Patterns Interdits

| Interdit | Risque OWASP | Alternative |
|----------|--------------|-------------|
| Clés serveur côté client | Broken Access Control (A01) | Clés publiques uniquement côté client |
| Inputs non validés | Injection (A03) | Schema validation avant traitement |
| Tokens dans `console.log` | Sensitive Data Exposure (A02) | Logger sans secrets |
| `innerHTML` / injection de HTML brut | XSS (A03) | Composants natifs du framework |
| Secrets commités dans le repo | Secret Exposure (A02) | `.env.local` + `.gitignore` |
| Auth vérifiée uniquement côté client | Broken Auth (A07) | Contrôle côté serveur/API |
| Tokens en localStorage | Token Theft | Session httpOnly ou secure storage |
| Concaténation SQL | SQL Injection (A03) | Parameterized queries |

---

## 4. Checklist OWASP Top 10

| # | Risque | Mitigation |
|---|--------|------------|
| A01 | Broken Access Control | Contrôle d'accès au niveau données, pas uniquement UI |
| A02 | Cryptographic Failures | HTTPS only, secrets en env vars, pas de crypto custom |
| A03 | Injection | Schema validation, parameterized queries, sanitize texte |
| A04 | Insecure Design | Séparation client/serveur, defense in depth |
| A05 | Security Misconfiguration | `.env.local`, review config déploiement |
| A06 | Vulnerable Components | Audit dépendances régulier, mises à jour |
| A07 | Auth Failures | Auth centralisée, session management, rate limiting |
| A08 | Data Integrity | Type mappers, validation entrées/sorties |
| A09 | Logging Failures | Logging structuré, pas de secrets dans les logs |
| A10 | SSRF | Pas de fetch avec URL user-controlled sans whitelist |

---

## 5. STRIDE Threat Modeling

Pour toute nouvelle feature exposant des données ou traitant des inputs externes,
évaluer les 6 catégories STRIDE :

| Catégorie | Menace | Question à poser | Mitigation type |
|-----------|--------|-------------------|-----------------|
| **S**poofing | Usurpation d'identité | Un attaquant peut-il se faire passer pour un autre utilisateur ? | Auth forte, tokens signés |
| **T**ampering | Altération de données | Les données en transit/stockage peuvent-elles être modifiées ? | Intégrité, signatures, HTTPS |
| **R**epudiation | Déni d'action | Un utilisateur peut-il nier avoir effectué une action ? | Audit logs, timestamps |
| **I**nformation Disclosure | Fuite d'information | Des données sensibles sont-elles exposées involontairement ? | Least privilege, chiffrement |
| **D**enial of Service | Déni de service | Le système peut-il être rendu indisponible ? | Rate limiting, pagination |
| **E**levation of Privilege | Élévation de privilèges | Un utilisateur peut-il accéder à des ressources non autorisées ? | RLS, RBAC, contrôle serveur |

### Quand appliquer STRIDE

- Nouveau endpoint API ou route protégée
- Nouvelle entité avec données sensibles
- Intégration avec un service externe
- Modification du système d'auth ou des permissions

---

## 6. Secrets Archaeology

```
Les secrets commités dans l'historique git sont TOUJOURS compromis,
même après suppression. Un secret exposé = un secret à révoquer.
```

### Vérifications obligatoires

- **Avant premier push** : scanner l'historique git pour détecter des secrets
  ```
  git log --all -p | grep -iE '(api_key|secret|password|token|private_key)\s*[=:]' || true
  ```
- **Fichiers à risque** : `.env`, `*.pem`, `*.key`, `credentials.*`, `service-account*.json`
- **Si secret trouvé dans l'historique** :
  1. Révoquer immédiatement le secret côté provider
  2. Générer un nouveau secret
  3. Ne PAS tenter de réécrire l'historique git comme seule mesure

### Prévention

- Pre-commit : vérifier qu'aucun pattern de secret n'est staged
- `.gitignore` : couvrir `.env*`, `*.pem`, `*.key`, `*credentials*`

---

## 7. Supply Chain & Dépendances

### Audit des dépendances

- Vérifier les vulnérabilités connues avant ajout (`npm audit`, `pnpm audit`)
- Préférer les packages avec maintenance active (commits récents, issues traitées)
- Épingler les versions majeures (pas de `*` ou `latest`)
- Limiter le nombre de dépendances — chaque dépendance est une surface d'attaque

### Signaux d'alerte sur un package

| Signal | Risque | Action |
|--------|--------|--------|
| Pas de mise à jour depuis > 1 an | Abandon | Chercher une alternative |
| Mainteneur unique + typosquat possible | Supply chain attack | Vérifier le nom exact |
| Post-install scripts | Exécution arbitraire | Inspecter le script avant install |
| Permissions excessives demandées | Over-privilege | Évaluer la nécessité |

---

## 8. Sécurité LLM / AI

Si le projet intègre des appels à des LLM (Claude, GPT, etc.) :

### Trust Boundaries

- **Jamais** injecter du contenu utilisateur brut dans un prompt sans sanitization
- Séparer les instructions système du contenu utilisateur (system prompt vs user message)
- Ne pas exposer le system prompt à l'utilisateur
- Valider et typer les sorties du LLM avant utilisation

### Anti-patterns LLM

| Interdit | Risque | Alternative |
|----------|--------|-------------|
| Prompt construit par concaténation avec input user | Prompt injection | Template avec variables sanitizées |
| Sortie LLM utilisée comme code exécuté | Code injection | Sandbox + validation |
| System prompt dans le frontend | Leak d'instructions | Appels LLM côté serveur uniquement |
| Confiance aveugle dans la sortie LLM | Hallucination → bug | Valider contre un schéma typé |

---

## 9. Portes d'Acceptation

| Critère | Seuil | Vérification |
|---------|-------|--------------|
| Contrôle d'accès données | Toutes les requêtes | Review architecture |
| Validation inputs | 100% des entrées utilisateur | Grep forms/endpoints sans validation |
| Secrets exposés | 0 | Grep tokens/keys dans le code source |
| `silent-failure-hunter` | Severity < HIGH | Agent |
| STRIDE évalué | Sur toute nouvelle surface exposée | Review |
| Secrets dans git history | 0 | Scan avant push |
| Dépendances vulnérables | 0 critical/high | `npm audit` / `pnpm audit` |

### Checklist pré-commit

- [ ] Aucun secret/token/credential dans le code source
- [ ] Inputs utilisateur validés via schema avant tout traitement
- [ ] Contrôle d'accès vérifié sur les nouvelles données/endpoints
- [ ] Pas d'injection HTML brut
- [ ] Routes/pages protégées par des guards auth
- [ ] Recherches texte sanitizées
- [ ] `silent-failure-hunter` exécuté, aucune severity HIGH
- [ ] STRIDE évalué si nouvelle surface exposée (endpoint, entité, intégration)
- [ ] Aucun secret dans l'historique git (scan si premier push)
- [ ] `npm audit` / `pnpm audit` sans vulnérabilité critique
- [ ] Si intégration LLM : trust boundaries respectées, outputs validés
