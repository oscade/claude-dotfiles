# Supabase - Directives Générales

> **Objectif** : Patterns spécifiques Supabase (PostgreSQL managé + Auth + Storage + RLS)
> **Quand lire** : Avant tout code touchant Supabase (client, migrations, RLS, storage, auth)
> **Agents** : code-reviewer, silent-failure-hunter, security-analyzer
> **Résumé gates** : RLS sur toutes les tables | types auto-générés | client singleton typé | guard checks sur FK RESTRICT | schema explicite

---

## 1. Principes

```
Supabase = PostgreSQL. Les règles de database.md s'appliquent intégralement.
Ce fichier couvre les spécificités Supabase au-dessus de PostgreSQL.
```

- **RLS est non négociable** — chaque table expose des données, chaque table a des policies
- **Types auto-générés** — jamais de types manuels dupliquant le schéma
- **Client singleton typé** — un seul point d'entrée, un seul fichier
- **Migrations > Table Editor** — le Table Editor ne garantit pas les FK ni les contraintes

---

## 2. Client Supabase

### Singleton typé

Le client Supabase est créé UNE fois dans un module dédié (`lib/supabase.ts` ou équivalent),
typé avec les types auto-générés.

```typescript
import { createClient } from '@supabase/supabase-js'
import type { Database } from '@/types/database'

export const supabase = createClient<Database>(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
)
```

### Sélection du client selon le contexte (si SSR)

| Contexte | Client | RLS |
|----------|--------|-----|
| Client Components | `createBrowserClient()` | Enforced via auth cookie |
| Server Components / Actions / Route Handlers | `createServerClient()` | Enforced via server auth |
| Opérations admin (migrations, seed, scripts) | Service role client | Bypasse RLS — justification obligatoire |

**Le service role client ne doit JAMAIS être utilisé dans du code applicatif**
sauf cas justifié avec commentaire expliquant pourquoi le bypass RLS est nécessaire.

### Auth : `getUser()` et JAMAIS `getSession()` (CWE-287)

`getSession()` lit le JWT depuis le cookie **sans le revalider côté serveur**.
Le JWT peut être expiré, révoqué, ou forgé. Seul `getUser()` fait un appel
à Supabase Auth pour vérifier la validité du token.

```typescript
// INTERDIT — JWT lu depuis le cookie, non vérifié serveur-side
const { data: { session } } = await supabase.auth.getSession()
const userId = session?.user?.id  // peut être forgé

// OBLIGATOIRE — validation serveur du JWT
const { data: { user }, error } = await supabase.auth.getUser()
if (error || !user) throw new Error('Non authentifié')
const userId = user.id  // vérifié par Supabase Auth
```

`detection_grep: "getSession"` — tout appel à `getSession()` dans du code
applicatif est suspect et doit être justifié ou remplacé par `getUser()`.

**Exception** : `getSession()` est acceptable dans un middleware Next.js pour
le refresh token, car `getUser()` y est trop lent (appel réseau sur chaque requête).

---

## 3. Types et Schéma

### Types auto-générés obligatoires

Générer les types après chaque migration :

```bash
npx supabase gen types typescript --local > types/database.ts
```

Utiliser les types générés, jamais de types manuels dupliquant le schéma :

```typescript
// OBLIGATOIRE — type dérivé du schéma
type Client = Database['public']['Tables']['clients']['Row']
type ClientInsert = Database['public']['Tables']['clients']['Insert']

// INTERDIT — type manuel dupliquant le schéma
interface Client { id: string; name: string; /* ... */ }
```

### Schéma explicite dans le SQL

Toujours préfixer les références de tables et fonctions avec le schéma :

```sql
-- OBLIGATOIRE
SELECT * FROM public.clients WHERE public.clients.id = $1;

-- INTERDIT — résolution implicite via search_path
SELECT * FROM clients WHERE id = $1;
```

---

## 4. RLS (Row Level Security)

### Chaque table DOIT avoir RLS activé

```sql
ALTER TABLE public.my_table ENABLE ROW LEVEL SECURITY;
```

Une table sans RLS expose **toutes ses lignes** à tout utilisateur authentifié.

### Policies obligatoires par opération

Chaque table doit avoir des policies couvrant les 4 opérations :

| Opération | Policy requise |
|-----------|---------------|
| SELECT | Filtrer par contexte utilisateur |
| INSERT | Vérifier que l'utilisateur a le droit de créer dans ce contexte |
| UPDATE | Vérifier ownership ou membership |
| DELETE | Vérifier ownership ou membership |

### Patterns de policy courants

```sql
-- Pattern ownership direct (mono-utilisateur)
CREATE POLICY "users_own_data" ON public.companies
  FOR ALL USING (user_id = auth.uid());

-- Pattern membership (multi-tenant)
CREATE POLICY "team_access" ON public.invoices
  FOR ALL USING (
    company_id IN (SELECT id FROM public.companies WHERE user_id = auth.uid())
  );
```

### RLS helpers factorisés (si multi-tenant)

Factoriser la logique d'accès dans des fonctions réutilisables plutôt que
de dupliquer le JOIN dans chaque policy :

```sql
CREATE OR REPLACE FUNCTION public.user_owns_company(target_company_id UUID)
RETURNS BOOLEAN LANGUAGE sql SECURITY DEFINER SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.companies
    WHERE id = target_company_id AND user_id = (SELECT auth.uid())
  );
$$;

-- Utilisation dans les policies
CREATE POLICY "access" ON public.invoices
  FOR ALL USING (public.user_owns_company(company_id));
```

### Interaction RLS + CASCADE

`ON DELETE CASCADE` est exécuté par PostgreSQL au niveau DB — il **bypasse les RLS policies**
des tables enfants. Ce n'est pas un bug, c'est le comportement attendu.

En revanche :
- Les `BEFORE DELETE` triggers sur les tables enfants sont toujours exécutés
- Un trigger qui `RAISE EXCEPTION` bloque le CASCADE et donc le DELETE parent
- **Tester les suppressions avec RLS activé**, pas uniquement en tant que `postgres`

---

## 5. Migrations

### Workflow

```bash
# 1. Modifier le schéma local (SQL ou Table Editor local)
# 2. Générer le diff
npx supabase db diff --schema public -f nom_descriptif_migration

# 3. Vérifier le fichier généré dans supabase/migrations/
# 4. Appliquer
npx supabase db reset

# 5. Régénérer les types
npx supabase gen types typescript --local > types/database.ts
```

### Règles dans les migrations

- Chaque FK déclare `ON DELETE` explicitement (voir `database.md` §3)
- Commentaire justifiant le choix CASCADE/RESTRICT/SET NULL
- `search_path = ''` sur toute fonction définie
- `SECURITY DEFINER` uniquement si justifié (bypasse RLS du caller)
- `WITH (security_invoker = true)` sur toute view

### Table Editor ≠ source de vérité

Le Table Editor Supabase (UI) ne génère pas toujours les FK constraints correctement.
**Toujours vérifier le SQL généré** et préférer écrire les migrations manuellement
pour les relations complexes.

---

## 6. Storage

### Suppression de fichiers non automatique

Supprimer une ligne qui référence un fichier dans `storage.objects` ne supprime
**PAS** le fichier automatiquement. Le cleanup doit être explicite :

```typescript
// OBLIGATOIRE — cleanup storage AVANT ou APRÈS suppression de la ligne
await supabase.storage.from('bucket').remove([filePath])
```

Options de cleanup :
- **Application** : supprimer le fichier dans le service, avant le DELETE SQL
- **Trigger PostgreSQL** : `AFTER DELETE` sur la table, appel à `storage.delete()`
- **Edge Function** : webhook déclenché par un database webhook

---

## 7. Gestion des erreurs Supabase

### Toujours destructurer data + error

```typescript
// INTERDIT — error ignorée, échec silencieux
const { data } = await supabase.from('clients').select('id, name')

// OBLIGATOIRE — error destructurée et vérifiée
const { data, error } = await supabase.from('clients').select('id, name')
if (error) throw error
```

`detection_grep: "const { data }"` — toute destructuration sans `error` est suspecte.

### Discrimination des error codes Supabase

Ne pas traiter toutes les erreurs Supabase de façon identique. Les codes PostgreSQL
et PostgREST ont des significations distinctes qui appellent des réponses différentes :

| Code | Signification | Réponse appropriée |
|------|--------------|-------------------|
| `PGRST116` | Row not found (`.single()` sans résultat) | 404 — entité non trouvée |
| `23503` | FK violation (RESTRICT bloqué) | 409 — dépendances existantes, message utilisateur |
| `23505` | Unique constraint violation | 409 — doublon, message utilisateur |
| `42501` | RLS violation (insufficient privilege) | 403 — debug les policies, ne pas exposer |
| `42P01` | Table inexistante | 500 — bug code ou migration manquante |
| `PGRST301` | JWT expiré | Refresh token ou redirect login |

```typescript
// INTERDIT — traitement uniforme, message incompréhensible
if (error) throw error

// OBLIGATOIRE — discrimination et message contextualisé
if (error) {
  switch (error.code) {
    case 'PGRST116':
      throw new Error('Enregistrement non trouvé')
    case '23503':
      throw new Error('Impossible : des données dépendantes existent')
    case '23505':
      throw new Error('Un enregistrement identique existe déjà')
    case '42501':
      console.error('[RLS] Policy violation:', error.message)
      throw new Error('Accès refusé')
    default:
      console.error('[SUPABASE] Erreur non gérée:', error.code, error.message)
      throw error
  }
}
```

**Note** : la discrimination est obligatoire dans les services qui font face à l'utilisateur.
Pour les scripts internes ou les migrations, `if (error) throw error` reste acceptable.

### Guard check avant FK RESTRICT

Les erreurs `23503` doivent être **prévenues**, pas juste traduites.
Voir guard check pattern dans `database.md` §3.

### Erreurs RLS — liste vide ≠ erreur

Une policy manquante ou incorrecte retourne une **liste vide** (pas une erreur),
ce qui rend le debug difficile. Si une query retourne 0 résultats de façon inattendue,
vérifier les RLS policies en priorité.

`detection_grep: "USING(true)"` — policy trop permissive, risque cross-tenant.

---

## 8. Anti-Patterns Interdits

| Interdit | Pourquoi | Alternative |
|----------|----------|-------------|
| Table sans RLS | Toutes les lignes exposées | `ENABLE ROW LEVEL SECURITY` |
| `USING(true)` dans une policy | Données exposées cross-tenant | Policy basée sur auth context |
| Types manuels dupliquant le schéma | Drift types/DB | `supabase gen types` |
| Service role client dans du code applicatif | Bypass RLS total | Client anon + RLS |
| `SECURITY DEFINER` sans `search_path = ''` | Résolution de schéma non sécurisée | Ajouter `SET search_path = ''` |
| View sans `security_invoker = true` | Bypass RLS du caller | Ajouter l'option |
| Suppression de ligne sans cleanup storage | Fichiers orphelins dans le bucket | Cleanup explicite |
| `.delete()` brut sur FK RESTRICT | Violation FK incompréhensible | Guard check (voir `database.md`) |
| `getSession()` pour vérifier l'auth | JWT non revalidé, forgeable (CWE-287) | `getUser()` avec vérification serveur |
| `const { data }` sans `error` | Échec silencieux | Toujours destructurer `{ data, error }` |
| `if (error) throw error` sans discrimination | Message incompréhensible pour l'utilisateur | Switch sur `error.code` (PGRST116, 23503, etc.) |
| Migration via Table Editor sans vérification | FK/contraintes manquantes | Vérifier le SQL ou écrire manuellement |

---

## 9. Checklist Sécurité

- [ ] RLS activé sur toutes les tables
- [ ] Policies couvrant SELECT, INSERT, UPDATE, DELETE
- [ ] Pas de `USING(true)` dans les policies
- [ ] `search_path = ''` sur toute fonction `SECURITY DEFINER`
- [ ] `security_invoker = true` sur toute view
- [ ] Service role client jamais dans du code applicatif (sauf justification)
- [ ] Clé `SUPABASE_SERVICE_ROLE_KEY` jamais préfixée `NEXT_PUBLIC_`
- [ ] `getUser()` pour la vérification auth, jamais `getSession()` en code applicatif
- [ ] Types générés depuis le schéma, pas manuels

---

## 10. Portes d'Acceptation

| Critère | Seuil | Vérification |
|---------|-------|--------------|
| RLS activé | 100% des tables | Grep `ENABLE ROW LEVEL SECURITY` dans les migrations |
| Policies complètes | SELECT+INSERT+UPDATE+DELETE | Audit policies par table |
| Types auto-générés | 100% | Aucun `interface` dupliquant un Row type |
| FK explicites | ON DELETE sur 100% des FK | Grep FK sans ON DELETE |
| Guard checks | 100% des delete sur FK RESTRICT | Grep `.delete()` sans guard |
| Storage cleanup | 100% des suppressions référençant storage | Grep delete sans cleanup |

### Checklist pré-commit

- [ ] RLS activé + policies complètes sur toute nouvelle table
- [ ] Types régénérés après chaque migration (`supabase gen types`)
- [ ] FK avec `ON DELETE` explicite et commenté dans la migration
- [ ] Guard check avant tout `.delete()` sur une table avec FK RESTRICT
- [ ] Error codes Supabase discriminés dans les services face-utilisateur
- [ ] `getUser()` utilisé (pas `getSession()`) pour la vérification auth
- [ ] Pas de `const { data }` sans `error` dans les appels Supabase
- [ ] Pas de service role client dans du code applicatif
- [ ] Storage cleanup explicite si la table référence des fichiers
- [ ] Test des opérations de suppression avec RLS activé

---

*Dernière mise à jour: Mars 2026*
