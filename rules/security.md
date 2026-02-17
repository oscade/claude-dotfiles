# Security - Directives Générales

> **Objectif** : Sécurité applicative (OWASP Top 10)
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

## 5. Portes d'Acceptation

| Critère | Seuil | Vérification |
|---------|-------|--------------|
| Contrôle d'accès données | Toutes les requêtes | Review architecture |
| Validation inputs | 100% des entrées utilisateur | Grep forms/endpoints sans validation |
| Secrets exposés | 0 | Grep tokens/keys dans le code source |
| `silent-failure-hunter` | Severity < HIGH | Agent |

### Checklist pré-commit

- [ ] Aucun secret/token/credential dans le code source
- [ ] Inputs utilisateur validés via schema avant tout traitement
- [ ] Contrôle d'accès vérifié sur les nouvelles données/endpoints
- [ ] Pas d'injection HTML brut
- [ ] Routes/pages protégées par des guards auth
- [ ] Recherches texte sanitizées
- [ ] `silent-failure-hunter` exécuté, aucune severity HIGH
