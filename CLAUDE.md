# Crew Guide — Project Bible

Personalized, mobile-first reference guide for Cam's three nieces (Rella, Laeklyn, Juliet)
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
| `hh_niece_lunches` | day_date (PK), lunch, veggie, fruit, rella_note, rella_ok | Mon–Fri kid lunches; `rella_note` shows for Rella only (✅ if `rella_ok`, ⚠️ if not) |
| `hh_niece_reminders` | id, body, sort | standing "Every Day" reminders; drives the Today card |
| `hh_niece_config` | key (PK), value | holds `pin_hash` for edit mode; anon READ only, writes need service_role |
| `hh_niece_notes` | id, created_at, niece, body | crew → Cam channel; anon insert allowed |

## Edit mode (Parent persona + PIN)

The Parent persona gets a 4th bottom-tab, **Edit**. Tapping it asks for a PIN; on match it unlocks
in-app editing of the simple fields: **People, Lunches, Locations, Contacts, Daily reminders**.
Day schedules (timeline items) and dinners (`hh_meal_plan`) are intentionally NOT editable here.

- **Writes** use the anon key against the editable tables (RLS has `update`/`insert`/`delete`
  policies). Locations/Contacts/Reminders support add + delete; People/Lunches are edit-only.
- **The PIN gates the UI only — it is not hard security.** With the public anon key, the data
  tables are technically writable by anyone who reads the page source. Accepted posture for
  first-names-and-schedule data (Cam chose the PIN gate over a full login).
- **PIN storage:** SHA-256 hash in `hh_niece_config.pin_hash`. anon can read the hash (to verify
  an entered PIN) but cannot write it — the PIN is only settable with the service_role key, so it
  can't be changed through the app. Unlock state is in-memory (re-prompts each session / persona
  switch); never stored in localStorage.

### Setting / changing the edit PIN (run in a terminal, PIN never leaves your machine)

```bash
SVC=$(awk '/optzbdbavpnxstpxrpbh \(Cerebro/{f=1} f&&/service_role key:/{print $NF; exit}' ~/.secrets.md)
read -s -p "New Crew Guide edit PIN: " PIN; echo
HASH=$(node -e 'process.stdout.write(require("crypto").createHash("sha256").update(process.argv[1]).digest("hex"))' "$PIN")
curl -s -o /dev/null -w "%{http_code}\n" -X POST \
  "https://optzbdbavpnxstpxrpbh.supabase.co/rest/v1/hh_niece_config" \
  -H "apikey: $SVC" -H "Authorization: Bearer $SVC" -H "Content-Type: application/json" \
  -H "Prefer: resolution=merge-duplicates,return=minimal" \
  -d "{\"key\":\"pin_hash\",\"value\":\"$HASH\"}"
```

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

### Dinner cards show the dish name only

Cam handles all the cooking, so dinner cards show just `recipe_title` (plus a "No cooking" chip
for the NULL-`recipe_id` nights and a small pescatarian note for Rella). The `hh_meal_plan.notes`
field — recipe steps, the stale Wednesday "Kara assembles" line, the Papa Johns "tradition"
framing — is intentionally NOT displayed. The source `hh_meal_plan` rows are left untouched.

## Screens

- **Header (Home):** persona greeting by name + her arrival/departure. "Switch" button resets persona.
- **Today:** date-scoped (auto-detects Central date; `?date=YYYY-MM-DD` override for testing).
  Pescatarian banner (Rella only) → day heads-up → schedule timeline → live dinner card.
- **Week:** six expandable Mon–Sat cards (today auto-expanded + highlighted).
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
- Deployed to public GitHub Pages (https://camhsmc.github.io/haines-crew-guide/) and logged the
  Cerebro note.

### 2026-06-20 — Round 2 tweaks (Cam feedback)
- Dinner cards now show the dish name only (dropped recipe/instruction display + `cleanDinnerNote`).
- Persona picker shows just the three names + Parent preview (removed the per-name detail lines).
- Renamed Juliette → **Juliet** (one T) across `hh_niece_*` data and the app.
- Cam takes Gemma to the Tuesday podiatry appointment — updated the Tuesday timeline and removed
  the library/podiatry overlap heads-up (no longer the crew's concern).
- Removed the Papa Johns "standing family tradition" framing (it lived in `hh_meal_plan.notes`,
  which the app no longer surfaces anyway).

### 2026-06-20 — Round 3 (Cam feedback)
- Removed the **Kids** tab entirely — the nieces know the kids, and Cam does bedtime mainly.
  Bottom bar is now Today / Week / Reference. The `hh_niece_kids` table is retained (unused) in
  case it's wanted later; the app no longer fetches or renders it.

### 2026-06-20 — Round 4 (Cam feedback)
- Added the **Lunch menu** (Mon–Fri) — new `hh_niece_lunches` table; a Lunch card now shows on
  Today and each Week day, between the schedule and the dinner card. Rella sees the per-day note
  (✅ pescatarian-friendly, or ⚠️ swap — e.g. Fri fish sticks for chicken).
- Trimmed Reference → Evenings to a single line: "Dinner between 5:30 and 6:30." Dropped per-kid
  bedtime detail (Cam does bedtime).
- Cut filler copy app-wide per Cam: no reassurance/atmosphere lines. Dinner pescatarian flag is
  now just "🐟 Pescatarian". Keep all copy factual.

### 2026-06-20 — Round 5 (Cam feedback)
- Restructured each day into two labeled sections — **Schedule** (the timeline) and **Meals**
  (Lunch + Dinner as rows under one heading). Replaced the standalone lunch/dinner cards, which
  looked too much like the collapsed day cards. Used in both Today and the Week accordion body
  (`scheduleSection()` / `mealsSection()` in `index.html`).
- Deleted the Wed/Thu day summaries ("A calmer/quieter day at home") — set `summary = null`; the
  UI now omits the summary line when it's empty.

### 2026-06-20 — Round 6 (Cam feedback)
- Added standing daily reminders (`dailyReminders()`): **Quiet Hour 1:00–2:00 PM**, take Gemma to
  the bathroom when she wakes up, and again right before Quiet Hour. Shown as an "Every Day" card
  on Today and folded into the Reference daily rhythm (new Afternoon block + a morning line).

### 2026-06-20 — Round 7 (Cam feedback)
- Added **Edit mode** (Parent persona + PIN) — see the "Edit mode" section above. Cam can now edit
  People, Lunches, Locations, Contacts, and Daily reminders directly in the app.
- Moved the daily reminders out of hardcoded HTML into the new `hh_niece_reminders` table (so they
  became editable) and removed the duplicated reminder lines from the Reference rhythm.
- Verified anon CRUD through the new RLS (PATCH/POST/DELETE → 204/201) and that `hh_niece_config`
  rejects anon writes (401). PIN hash store/read plumbing verified end-to-end.
- **Cam still needs to set the edit PIN** with the terminal command above before edit mode unlocks.

### 2026-06-22 — Round 8 (Cam feedback)
- **Today screen day stepper**: `‹ ›` to move between days + "Jump to today". Added `state.viewDate`
  (the viewed date) separate from `state.today` (actual date); `dayNav()` / `stepDay()` / `goToday()`.
- **Monday reworked** (Rella's flight cancelled): she now arrives 12:45 PM; stripped Monday's lunch
  and everything before 12:45; added Pick up Rella → Costco run (with shopping list) → Oliver
  practices his forms before the 6:15 promotion.
- **Every day**: bedtime routine 7:00–8:30 PM on the schedule; explicit "Pick up boys from summer
  school" item on each school day; added beds / girls' hair / morning-afternoon-evening checklists
  to the Every Day reminders.
- **Reference**: new "Chores & Time Off" card (clean+vacuum each child's room this week; an evening
  out together is fine).
- **Printable PDF**: `generate-pdf.mjs` fetches the live data and writes `crew-guide-print.html`;
  rendered to `Crew-Guide.pdf` with headless Chrome (`--print-to-pdf`). Re-run both to refresh after
  data changes. Brand-matched (navy/sand/gold), ~6 pages, also copied to ~/Downloads.
