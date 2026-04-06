# Design System — Warm Gold

> **Identite** : Premium editorial, tons chauds, zero froideur
> **Quand lire** : Avant tout code UI, composant, page, ou choix visuel
> **Resume** : Cream + Gold + Navy | Serif headings + Sans body | Sharp radius | Uppercase badges

---

## 1. Palette

### Light mode (defaut)

| Role | Valeur | Usage |
|------|--------|-------|
| Background | `#faf8f4` | Fond principal (cream chaud) |
| Card | `#ffffff` | Cartes, popovers, modals |
| Muted | `#f5f3ef` | Sections subtiles, secondary bg |
| Foreground | `#0f0f0f` | Texte principal (near black) |
| Text secondary | `#3a3a3a` | Corps de texte, descriptions |
| Text muted | `#6b7280` | Sous-titres, metadata, placeholders |
| Primary | `#b8924a` | Accents, CTAs, liens, focus, icones |
| Primary hover | `#d4aa6a` | Hover sur primary (light gold) |
| Primary subtle | `rgba(184,146,74,0.10)` | Fond badges, tags, selections |
| Primary border | `rgba(184,146,74,0.25)` | Bordures badges, outlines actifs |
| Border | `#e2ddd5` | Bordures par defaut (warm light gray) |
| Destructive | `#dc2626` | Erreurs, P0, off_track |
| Warning | `#d97706` | At risk, alertes intermediaires |

### Teal accent (differenciation utilisateur JV)

| Role | Valeur | Usage |
|------|--------|-------|
| Teal | `#2d7a6e` | Accent secondaire, barres JV, on_track, P2, complete |
| Teal foreground | `#ffffff` | Texte sur fond teal |
| Teal light | `#4a9e90` | Hover, gradient end, variante claire |
| Teal subtle | `rgba(45,122,110,0.10)` | Fond badges, selections |
| Teal border | `rgba(45,122,110,0.25)` | Bordures badges, outlines |

> **Exception palette froide** : le teal est autorise uniquement pour la differenciation
> utilisateur (JV vs NO) et les signaux positifs (on_track, complete, P2).
> Il ne remplace PAS le gold comme accent primaire.

### Dark surfaces (headers, sidebars)

| Role | Valeur | Usage |
|------|--------|-------|
| Dark bg | `#1a1f2e` | Headers, sidebars, navbars |
| Dark foreground | `rgba(255,255,255,0.80)` | Texte sur dark |
| Dark dim | `rgba(255,255,255,0.42)` | Texte secondaire sur dark |
| Dark border | `rgba(255,255,255,0.10)` | Bordures sur dark |
| Dark accent | `#b8924a` | Gold sur dark (logo, nav active) |

### Dark mode (optionnel)

| Role | Valeur |
|------|--------|
| Background | `#1a1f2e` |
| Card | `#232a3b` |
| Foreground | `rgba(255,255,255,0.80)` |
| Primary | `#d4aa6a` |
| Muted | `#2a3148` |
| Border | `rgba(255,255,255,0.10)` |

---

## 2. Typographie

| Role | Font | Weight | Style |
|------|------|--------|-------|
| Titres (h1, h2, CardTitle) | Playfair Display (serif) | 300-500 (light preferred) | `tracking-tight` |
| Corps / UI | Geist Variable (sans-serif) | 300-400 | Normal |
| Labels / Badges | Geist Variable | 500-600 | `uppercase tracking-[0.1em] text-[10px]` |
| Mono / Donnees | System monospace | 400 | `tabular-nums` |

### Regles typographiques

- Titres de page : `font-heading text-2xl font-light tracking-tight`
- Titres de section (cards) : `font-heading text-base`
- Badges : `text-[10px] font-medium uppercase tracking-[0.1em]`
- Pas de font-bold sur les titres — `font-light` ou `font-medium` max
- Letter spacing sur labels : `tracking-wider` ou `tracking-[0.1em]`

---

## 3. Espacement & Radius

| Token | Valeur |
|-------|--------|
| Radius | `0.75rem` (12px, coins arrondis soft) |
| Radius internes | `0.5rem`-`0.625rem` (8-10px, elements internes) |
| Radius badges | `rounded` (pas `rounded-full`) |
| Radius progress bars | `rounded-[20px]` (pill) |
| Spacing cards | `gap-4` ou `gap-6` |
| Padding cards | `p-3` a `p-4` |
| Max width contenu | `max-w-6xl` centre |

---

## 4. Composants

### Header / Navbar

- Background : `--dark-bg` (#1a1f2e)
- Logo : carre gold (`bg-primary`) + wordmark serif light
- Nav items : `text-dark-foreground/60`, actif = `bg-primary/15 text-primary`
- Hover : `hover:text-dark-foreground hover:bg-white/5`

### Cards

- Background : `bg-card` (blanc) sur `bg-background` (cream)
- Border : `border-border` (#e2ddd5)
- Pas de shadow par defaut, `hover:shadow-md` si interactif
- Titre card : serif `font-heading text-base`

### Badges

- Style par defaut : gold primary bg + white text
- Outline : `border-border text-foreground`
- Toujours : `uppercase tracking-[0.1em] text-[10px] rounded`
- Pas de `rounded-full` — coins sharp

### Boutons

- Primary : `bg-primary text-white`, hover `bg-primary-hover`
- Outline : `border-border`, hover `border-primary/40`
- Ghost sur dark : `text-dark-foreground/60 hover:bg-white/5`

### Formulaires

- Inputs : `border-border` (#e2ddd5), focus `ring-primary`
- Checkboxes : `border-primary/50`, checked `bg-primary text-white`
- Labels : `text-sm font-medium`

### Status / Couleurs semantiques

| Statut | Couleur | Usage |
|--------|---------|-------|
| Succes / On track / Complete | `teal` (#2d7a6e) | Progress 100%, on_track dots, completed steps |
| En cours / Actif | `primary` (#b8924a gold) | Progress bars en cours, active steps, CTA |
| Warning / At risk | `amber-600` / `amber-700` | Alertes, KRs a risque |
| Erreur / Off track / P0 | `destructive` (#dc2626) | Erreurs, deadlines, off_track |
| Neutre / Planned | `muted` / `muted-foreground` | Elements inactifs, backlog |

**Regle** : pas de violet, pas de bleu vif, pas de gris froid (gray/slate). Teal autorise uniquement pour differenciation utilisateur et signaux positifs.

---

## 5. Regles de design

### A faire

- Headers et sidebars en dark navy avec accents gold
- Cards blanches sur fond cream avec bordures chaudes
- Badges gold wash (fond subtle + bordure gold) en uppercase
- Separateurs : ligne fine 1px warm gray
- Boutons primaires : gold solid (#b8924a) texte blanc
- Icones : muted-foreground par defaut, primary si actif

### A eviter

- **Jamais** de violet, bleu, ou gris froid
- **Jamais** de `rounded-full` sur les badges (sharp corners)
- **Jamais** de `font-bold` sur les titres (utiliser `font-light`)
- **Jamais** de shadows lourdes — `shadow-md` max au hover
- **Jamais** de couleurs hors palette (pas de hardcoded hex dans les composants)
- **Jamais** de fond sombre sur le contenu principal (dark = header/sidebar only)

---

## 6. Implementation shadcn/ui

### Tokens CSS (index.css :root)

```css
--background: #faf8f4;
--foreground: #0f0f0f;
--card: #ffffff;
--card-foreground: #0f0f0f;
--primary: #b8924a;
--primary-foreground: #ffffff;
--secondary: #f5f3ef;
--secondary-foreground: #1a1f2e;
--muted: #f5f3ef;
--muted-foreground: #6b7280;
--accent: #b8924a;
--accent-foreground: #ffffff;
--border: #e2ddd5;
--input: #e2ddd5;
--ring: #b8924a;
--destructive: #dc2626;
--radius: 0.75rem;
--teal: #2d7a6e;
--teal-foreground: #ffffff;
--teal-light: #4a9e90;
```

### Fonts (imports)

```css
@import "@fontsource-variable/geist";
@import "@fontsource-variable/playfair-display";
```

### Theme inline (Tailwind v4)

```css
@theme inline {
  --font-heading: 'Playfair Display Variable', Georgia, serif;
  --font-sans: 'Geist Variable', system-ui, sans-serif;
}
```

---

## 7. PDF / Contextes sans CSS vars

Pour react-pdf ou tout contexte qui ne supporte pas les CSS variables :

| Role | Hex |
|------|-----|
| Texte principal | `#0f0f0f` |
| Texte body | `#3a3a3a` |
| Texte muted | `#6b7280` |
| Accent / Score | `#b8924a` |
| Titre / Header | `#1a1f2e` |
| Border / Separator | `#e2ddd5` |
| Erreur | `#dc2626` |
| Warning | `#d97706` |
| Background | `#faf8f4` |
| Teal (on_track, complete) | `#2d7a6e` |
| Teal light | `#4a9e90` |

---

## 8. Animations

| Animation | Duree | Easing | Usage |
|-----------|-------|--------|-------|
| `fadeIn` | 200ms | ease-out | Transition de page, apparition contenu |
| `progressFill` | 0.8s | ease-out | Remplissage progress bars au mount |
| `pulseOnce` | 0.3s | ease-out | Pulse KR quand 100% atteint |

### Regles d'animation

- Toutes les transitions interactives : `150ms ease-out`
- Hover cards : `translateY(-2px)` + `shadow-md`
- **Jamais** d'animation sur elements qui re-render frequemment (listes, sliders)
- CSS keyframes natifs uniquement — pas de Framer Motion
- `animate={false}` prop sur ProgressBar pour contextes a re-render frequent

---

*Warm Gold + Teal Design System — v2.0*
