# API Layer - Directives Générales

> **Objectif** : Standardiser les interactions avec les APIs (REST, GraphQL, RPC)
> **Quand lire** : Avant tout code touchant un client API, des appels réseau, ou des hooks de data fetching
> **Agents** : code-reviewer, silent-failure-hunter
> **Résumé gates** : champs explicites | payload < 50KB | erreurs propagées | pagination

---

## 1. Principes

- **MINIMAL** : ne demander que les champs nécessaires à l'appelant
- **PERFORMANCE** : zéro over-fetching, pagination obligatoire sur les listes
- Le client API doit être typé, singleton, et centralisé dans un module dédié

---

## 2. Patterns Obligatoires

### Client typé singleton

Centraliser la configuration du client API dans un seul module. Ne jamais instancier
de client dans un composant ou un service métier.

```
// Un seul point d'entrée, typé, configuré une fois
export const apiClient = createTypedClient(config)
```

### Sélection explicite des champs

Toujours spécifier les champs retournés. Jamais de `SELECT *` ou de requête
sans projection, que ce soit en REST (query params), GraphQL (query), ou ORM.

### Destructure systématique de la réponse

Toujours séparer les données de l'erreur/status. Ne jamais ignorer le champ erreur.

```
const { data, error } = await apiClient.get('/resource')
if (error) throw error   // throw-on-error, jamais ignorer
```

### Pagination sur toute liste

Toute requête retournant une collection doit être paginée.
Fournir `offset/limit` ou `cursor` selon le pattern du projet.

### Types domaine à la frontière

Les types bruts de l'API (DTO, Row, Response) ne doivent jamais traverser la couche service.
Convertir via des mappers typés à la frontière.

```
// API retourne ApiUserResponse → mapper vers User (type domaine)
return apiResponse.map(mapToUser)
```

---

## 3. Anti-Patterns Interdits

| Interdit | Pourquoi | Alternative |
|----------|----------|-------------|
| Requête sans projection de champs | Payload non contrôlé, over-fetching | Champs explicites |
| Ignorer l'erreur de la réponse | Erreur silencieuse | Propager ou throw |
| Créer plusieurs instances du client | Config dupliquée, connexions multiples | Singleton centralisé |
| Retourner les types API bruts | Couplage API/domaine | Mappers à la frontière |
| Listes sans pagination | Payload > 50KB, temps de réponse | Pagination systématique |
| Logique métier dans l'appel API | Responsabilité mal placée | Déléguer au service layer |

---

## 4. Checklist Sécurité

- [ ] Aucune donnée sensible dans les query params (préférer le body ou les headers)
- [ ] Inputs validés (schema validation) AVANT l'appel API
- [ ] Pas d'injection dans les filtres texte (sanitization)
- [ ] Tokens/secrets jamais exposés côté client
- [ ] Rate limiting considéré pour les appels fréquents

---

## 5. Portes d'Acceptation

| Critère | Seuil | Vérification |
|---------|-------|--------------|
| Champs explicites | 100% des requêtes | Aucun wildcard / select-all |
| Payload réponse | < 50KB | Dev tools / monitoring |
| Error handling | Erreur toujours propagée | `silent-failure-hunter` severity < HIGH |
| Type mapping | Types domaine uniquement | Aucun type API dans les retours publics |

### Checklist pré-commit

- [ ] Toutes les requêtes spécifient les champs nécessaires
- [ ] Chaque réponse API est destructurée (data + error)
- [ ] Les erreurs sont propagées, jamais ignorées
- [ ] Pagination sur toute collection
- [ ] Types domaine (pas DTO/Row) dans les signatures publiques
