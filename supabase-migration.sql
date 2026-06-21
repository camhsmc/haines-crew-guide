-- ============================================================
-- Crew Guide — hh_niece_* tables + seed data
-- Project: optzbdbavpnxstpxrpbh (Cerebro / Haines Harbor)
-- Posture: "URL is the credential" — permissive RLS, first names
-- + non-sensitive info only. Dinners are NOT stored here; they are
-- read live from hh_meal_plan (rows where notes ILIKE 'NIECE WEEK%').
-- Does NOT touch any existing hh_* table.
-- ============================================================

-- ---- People (the three nieces) ----
create table if not exists public.hh_niece_people (
  id       bigint generated always as identity primary key,
  name     text not null,
  arrives  text,
  departs  text,
  dietary  text,
  note     text,
  sort     int default 0
);

-- ---- Kids ----
create table if not exists public.hh_niece_kids (
  id      bigint generated always as identity primary key,
  name    text not null,
  age     int,
  blurb   text,
  bedtime text,
  sort    int default 0
);

-- ---- Days (Mon–Sat). schedule is jsonb: [{time, what, note}] ----
create table if not exists public.hh_niece_days (
  day_date date primary key,
  label    text,
  summary  text,
  schedule jsonb default '[]'::jsonb,
  heads_up text
);

-- ---- Locations ----
create table if not exists public.hh_niece_locations (
  id      bigint generated always as identity primary key,
  name    text not null,
  address text,
  note    text
);

-- ---- Contacts (no real phone numbers seeded) ----
create table if not exists public.hh_niece_contacts (
  id    bigint generated always as identity primary key,
  name  text not null,
  role  text,
  phone text,
  note  text,
  sort  int default 0
);

-- ---- Notes back to Cam (crew can insert; Parent persona reads) ----
create table if not exists public.hh_niece_notes (
  id         bigint generated always as identity primary key,
  created_at timestamptz default now(),
  niece      text,
  body       text
);

-- ============================================================
-- RLS — permissive (URL is the credential). anon can read all;
-- anon can insert notes only.
-- ============================================================
alter table public.hh_niece_people    enable row level security;
alter table public.hh_niece_kids      enable row level security;
alter table public.hh_niece_days      enable row level security;
alter table public.hh_niece_locations enable row level security;
alter table public.hh_niece_contacts  enable row level security;
alter table public.hh_niece_notes     enable row level security;

create policy "read people"    on public.hh_niece_people    for select using (true);
create policy "read kids"      on public.hh_niece_kids      for select using (true);
create policy "read days"      on public.hh_niece_days      for select using (true);
create policy "read locations" on public.hh_niece_locations for select using (true);
create policy "read contacts"  on public.hh_niece_contacts  for select using (true);
create policy "read notes"     on public.hh_niece_notes     for select using (true);
create policy "insert notes"   on public.hh_niece_notes     for insert with check (true);

-- ============================================================
-- SEED
-- ============================================================
insert into public.hh_niece_people (name, arrives, departs, dietary, note, sort) values
  ('Rella',    'Late Sun Jun 21 (lands ~1 AM Mon)', 'Sat Jun 27, 5:45 AM flight', 'pescatarian (fish/seafood OK, no other meat)', 'Here for every dinner Mon–Fri.', 1),
  ('Laeklyn',  'Mon Jun 22, 9:18 PM',               'Sat Jun 27, 3:35 PM',        '',                                            'Catches lunch Sat, not dinner.', 2),
  ('Juliette', 'Tue Jun 23, 12:48 PM',              'Sun Jun 28, 6:00 AM',        '',                                            'Stays the longest.', 3);

insert into public.hh_niece_kids (name, age, blurb, bedtime, sort) values
  ('Theo',   11, 'Oldest, most independent. Summer school + basketball camp. Can watch the girls for a few minutes.', '~7:45 (read, prayers)', 1),
  ('Oliver',  9, 'Easygoing. Summer school. Brown belt promotion Monday night.', '~7:45 (read, prayers, lights out)', 2),
  ('Pippa',   5, 'Needs help with shoes, buckles, and bath. Loves to help when invited.', '~7:00 (bath, jammies, 2 books, prayers)', 3),
  ('Gemma',   3, 'The littlest. Swim lessons + podiatry follow-up. Needs lots of supervision.', '~7:00, needs a diaper + blanket', 4);

insert into public.hh_niece_days (day_date, label, summary, heads_up, schedule) values
  ('2026-06-22', 'Monday', 'Rella''s first full day; Laeklyn arrives tonight', null,
    '[{"time":"8:15 AM","what":"Drop Theo at summer school","note":"Hudson Middle School, 1300 Carmichael Rd (8:30–12:15)"},
      {"time":"8:50 AM","what":"Drop Oliver at summer school","note":"E.P. Rock Elementary, 340 13th St S (9:00–12:00)"},
      {"time":"12:00 / 12:15","what":"Pick up the boys","note":"Oliver 12:00, Theo 12:15"},
      {"time":"2:15–3:30 PM","what":"Basketball Camp","note":"Hudson High School, 1501 Vine St (confirm which kid)"},
      {"time":"6:15–7:15 PM","what":"Oliver''s Brown Belt Promotion (Kyuki-Do)","note":"Come cheer!"},
      {"time":"9:18 PM","what":"Laeklyn arrives","note":""}]'::jsonb),

  ('2026-06-23', 'Tuesday', 'Juliette arrives at lunch; picnic for dinner (no cooking)',
    'The library craft (ends 11:30) and Gemma''s podiatry (11:30) overlap — leave the library a few minutes early.',
    '[{"time":"8:15 / 8:50 AM","what":"Boys to summer school","note":"Pickup 12:00 / 12:15"},
      {"time":"10:30–11:30 AM","what":"Knuffle Bunny Stories & Craft","note":"Hudson Area Public Library, 700 First St (fun for Pippa & Gemma)"},
      {"time":"11:30 AM–12:30 PM","what":"Gemma podiatry follow-up","note":"Clinic address TBD — tight with the library, leave a few minutes early"},
      {"time":"12:48 PM","what":"Juliette arrives","note":""},
      {"time":"6:00 PM","what":"Neighborhood Picnic","note":"This is dinner"}]'::jsonb),

  ('2026-06-24', 'Wednesday', 'A calmer day; build-your-own bowls for dinner', null,
    '[{"time":"8:15 / 8:50 AM","what":"Boys to summer school","note":"Pickup 12:00 / 12:15"},
      {"time":"2:15–3:30 PM","what":"Basketball Camp","note":"Hudson High School, 1501 Vine St"}]'::jsonb),

  ('2026-06-25', 'Thursday', 'Quieter day at home', null,
    '[{"time":"8:15 / 8:50 AM","what":"Boys to summer school","note":"Pickup 12:00 / 12:15"},
      {"time":"Afternoon","what":"Open / free play","note":"Pool, park, or library"}]'::jsonb),

  ('2026-06-26', 'Friday', 'Last day of summer school; Pizza Friday', null,
    '[{"time":"8:15 / 8:50 AM","what":"Boys to summer school","note":"LAST day"},
      {"time":"9:35–10:05 AM","what":"Gemma swim lessons","note":"Hudson YMCA, 2211 Vine St (suit, towel, goggles)"},
      {"time":"1:30–2:00 PM","what":"Family Bingo","note":"Hudson Area Public Library"},
      {"time":"2:15–3:30 PM","what":"Basketball Camp","note":"Hudson High School"}]'::jsonb),

  ('2026-06-27', 'Saturday', 'Rella flies home early; Laeklyn leaves mid-afternoon; Juliette stays',
    'Three departures today — Rella''s 5:45 AM flight and Laeklyn at 3:35 PM. Juliette stays.',
    '[{"time":"5:45 AM","what":"Rella''s flight home","note":""},
      {"time":"Late morning","what":"Easy family morning","note":"No summer school"},
      {"time":"3:35 PM","what":"Laeklyn departs","note":"Catches lunch"}]'::jsonb);

insert into public.hh_niece_locations (name, address, note) values
  ('Hudson Middle School',       '1300 Carmichael Rd', 'Theo summer school (8:30–12:15)'),
  ('E.P. Rock Elementary',       '340 13th St S',      'Oliver summer school (9:00–12:00)'),
  ('Hudson High School',         '1501 Vine St',       'Basketball camp (2:15–3:30)'),
  ('Hudson YMCA',                '2211 Vine St',       'Gemma swim (Fri 9:35)'),
  ('Hudson Area Public Library', '700 First St',       'Stories (Tue), Family Bingo (Fri)');

-- Contacts: names/roles only — no real numbers seeded (URL is public).
insert into public.hh_niece_contacts (name, role, phone, note, sort) values
  ('Cam (Dad)', 'Home all week — call or text first', '', 'Here the whole week.', 1),
  ('Kara (Mom)', 'Away, but reachable', '', '', 2),
  ('Emergencies', '911', '911', '', 3);
