# Crew Guide — Project Bible

Personalized, mobile-first reference guide for Cam's three nieces (Rella, Laeklyn, Juliette)
who are helping with his four kids the week of **Mon Jun 22 → Sat Jun 27, 2026** while Kara is
away. Each niece picks who she is once; the app then greets her by name, opens to a date-scoped
"Today" view, and shows the week, the kids, the daily rhythm, and a quick reference. Cam is home
all week (works days), so this is a reference, not a "you're on your own" handbook.

## Tech stack & conventions

- **Single `index.html`** — vanilla JS/HTML/CSS. No frameworks, no build step.
- **Data:** Supabase project `optzbdbavpnxstpxrpbh` (shared Cerebro / Haines Harbor project).
  Anon (publishable) key embedded client-side; reads via PostgREST `fetch`.
- **Auth posture:** URL is the credential (same as Haines Gringotts). Permissive RLS on
  `hh_niece_*`. First names + non-sensitive info only — no phone numbers, no door codes seeded.
- **localStorage:** used ONLY for the persona choice (`crew_persona`).
- **Design tokens:** navy `#1F3A5F`, sand `#F4ECD8`, gold `#B8893B`, deep-navy text `#16263d`.
  Mobile-first, big tap targets, sticky bottom tab bar.
- **Hosting:** public GitHub repo `haines-crew-guide` → GitHub Pages (free Pages needs a public
  repo). Share link is the `*.github.io` URL.

## Supabase schema (all new tables prefixed `hh_niece_`)

Created via migration `hh_niece_crew_guide_tables`. **Existing `hh_*` tables are never touched.**

| Table | Columns | Notes |
|---|---|---|
| `hh_niece_people` | id, name, arrives, departs, dietary, note, sort | the 3 nieces |
| `hh_niece_kids` | id, name, age, blurb, bedtime, sort | the 4 kids |
| `hh_niece_days` | day_date (PK), label, summary, schedule (jsonb `[{time,what,note}]`), heads_up | 6 days Mon–Sat |
| `hh_niece_locations` | id, name, address, note | 5 locations |
| `hh_niece_contacts` | id, name, role, phone, note, sort | phone left blank on purpose |
| `hh_niece_notes` | id, created_at, niece, body | crew → Cam channel; anon insert allowed |

RLS: anon `select` on every table; anon `insert` on `hh_niece_notes` only.

### Dinners are NOT stored here — they read live from `hh_meal_plan`

The single source of truth for dinners is the existing `hh_meal_plan` table. The app queries:

```
hh_meal_plan?meal_type=eq.dinner&notes=ilike.NIECE WEEK*&meal_date=gte.2026-06-22&meal_date=lte.2026-06-27
```

and shows `recipe_title` + a cleaned version of `notes`. **Two critical rules learned from the
data:**

1. **Never inner-join on / require `recipe_id`.** Tue (Neighborhood Picnic) and Fri (Papa Johns)
   have `recipe_id = NULL` but are real dinners. Keying off `recipe_id` would make them vanish.
   The app keys off `recipe_title`/`notes`; a NULL `recipe_id` just renders a "No cooking" chip.
2. **`recipe_title` is already denormalized onto `hh_meal_plan`** — no join to `hh_recipes` needed.

### Dinner-note cleaning (`cleanDinnerNote`)

- Strips the `NIECE WEEK Day N —` prefix.
- Removes the stale Wednesday sentence `Cam at YM/YW ... Kara assembles. Easy.` — Cam is home all
  week and Kara is away, so that line in the source row is wrong. It's suppressed in the display
  layer only; the source `hh_meal_plan` row is left untouched.

## Screens

- **Header (Home):** persona greeting by name + her arrival/departure. "Switch" button resets persona.
- **Today:** date-scoped (auto-detects Central date; `?date=YYYY-MM-DD` override for testing).
  Pescatarian banner (Rella only) → day heads-up → schedule timeline → live dinner card.
- **Week:** six expandable Mon–Sat cards (today auto-expanded + highlighted).
- **Kids:** Theo / Oliver / Pippa / Gemma — age, blurb, bedtime.
- **Reference:** daily rhythm, mealtime strike system, locations, contacts, and the
  "Leave a note for Cam" form. Parent-preview persona reads the submitted notes instead of the form.

## Persona behavior

- First open → "Who are you?" overlay: Rella / Laeklyn / Juliette / Parent preview. Stored in
  localStorage; validated on load (falls back to picker if the saved value is unknown).
- **Pescatarian flagging is data-driven:** if the active person's `dietary` matches `/pescatarian/i`
  (currently Rella only), Home/Today show a banner and every dinner card shows a 🐟 flag. Others
  never see it.
- **Parent preview** reads `hh_niece_notes`; would be where any real phone numbers live if added.

## Definition of Done — status ✅

- [x] Loads on a phone; persona persists; Today auto-detects the date (`?date=` override works).
- [x] Rella's persona shows pescatarian flags; Laeklyn/Juliette don't.
- [x] Every dinner card is live from `hh_meal_plan` (incl. the NULL-`recipe_id` Tue/Fri nights).
- [x] Wednesday shows no "Cam out" heads-up; the stale dinner note line is suppressed.
- [x] Tables created + seeded; anon read + note insert verified through RLS.
- [ ] Deployed to public GitHub Pages (share link) — final step.
- [ ] One-line Cerebro note logged.

## Open items (non-blocking — Cam to fill)

- Gemma's podiatry clinic address (Tue) — seeded as "TBD".
- "Confirm which kid" for basketball camp (Mon/Wed/Fri).
- Real phone numbers for Cam/Kara — intentionally NOT seeded (public URL). Add behind Parent
  preview only if wanted.
- Optional: fix the Wednesday note at the source in `hh_meal_plan` (id 96) so it's correct
  everywhere, not just cleaned in-app.

## Session log

### 2026-06-20 — Initial build
- Validated the source prompt against live `hh_meal_plan` data; caught two data-instruction bugs
  (the `hh_recipes` join was wrong/unnecessary; NULL `recipe_id` on Tue/Fri would have hidden two
  dinners). Confirmed all 6 niece-week dinner rows exist with `NIECE WEEK` notes.
- Dropped the prompt's "Cam out Wednesday evening" premise per Cam — he's home all week.
- Created + seeded the six `hh_niece_*` tables; verified anon read + note insert through RLS.
- Built `index.html` (persona flow, Today/Week/Kids/Reference, live dinners, pescatarian flags,
  leave-a-note). Verified the note-cleaning logic against the real Wednesday/Thursday/Monday notes.
- Next: deploy to public GitHub Pages, then log the Cerebro note.
