// Builds a print-friendly HTML of the Crew Guide from the live Supabase data,
// then it's rendered to PDF with headless Chrome (see the npm-free shell step).
const SUPA = "https://optzbdbavpnxstpxrpbh.supabase.co/rest/v1";
const KEY  = "sb_publishable_OujPUygbQI0CuYbrOub5kg_ExbErjAZ";
const H = { apikey: KEY, Authorization: "Bearer " + KEY };
const get = async (p) => (await fetch(`${SUPA}/${p}`, { headers: H })).json();
const esc = (s) => (s==null?"":String(s)).replace(/[&<>]/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;"}[c]));

const [people, days, locations, contacts, lunches, reminders, dinners] = await Promise.all([
  get("hh_niece_people?select=*&order=sort"),
  get("hh_niece_days?select=*&order=day_date"),
  get("hh_niece_locations?select=*&order=id"),
  get("hh_niece_contacts?select=*&order=sort"),
  get("hh_niece_lunches?select=*&order=day_date"),
  get("hh_niece_reminders?select=*&order=sort"),
  get("hh_meal_plan?select=meal_date,recipe_title,recipe_id&meal_type=eq.dinner&notes=ilike." + encodeURIComponent("NIECE WEEK*") + "&meal_date=gte.2026-06-22&meal_date=lte.2026-06-27&order=meal_date"),
]);
const lunchBy = Object.fromEntries(lunches.map(l => [l.day_date, l]));
const dinnerBy = Object.fromEntries(dinners.map(d => [d.meal_date, d]));

const dayBlock = (day) => {
  const items = (day.schedule||[]).map(s =>
    `<tr><td class="t">${esc(s.time)}</td><td>${esc(s.what)}${s.note?`<div class="sub">${esc(s.note)}</div>`:""}</td></tr>`).join("");
  const l = lunchBy[day.day_date], d = dinnerBy[day.day_date];
  let meals = "";
  if(l){
    const side=[l.veggie,l.fruit].filter(Boolean).join(" · ");
    meals += `<div class="meal"><span class="mk">Lunch</span> ${esc(l.lunch)}${side?`<div class="sub">${esc(side)}</div>`:""}${l.rella_note?`<div class="sub">Rella: ${esc(l.rella_note)}</div>`:""}</div>`;
  }
  if(d) meals += `<div class="meal"><span class="mk">Dinner</span> ${esc(d.recipe_title)}${!d.recipe_id?` <span class="chip">no cooking</span>`:""}</div>`;
  return `<section class="day">
      <h2>${esc(day.label)} <span class="date">${esc(day.day_date)}</span></h2>
      ${day.summary?`<p class="summary">${esc(day.summary)}</p>`:""}
      ${day.heads_up?`<p class="heads">⚠ ${esc(day.heads_up)}</p>`:""}
      <h3>Schedule</h3>
      <table class="sched">${items||`<tr><td colspan=2 class="sub">No fixed schedule.</td></tr>`}</table>
      ${meals?`<h3>Meals</h3>${meals}`:""}
    </section>`;
};

const peopleRows = people.map(p =>
  `<tr><td><b>${esc(p.name)}</b></td><td>${esc(p.arrives)}</td><td>${esc(p.departs)}</td><td>${esc(p.dietary||"")}</td></tr>`).join("");
const locRows = locations.map(l => `<div class="ref-item"><b>${esc(l.name)}</b> — ${esc(l.address)}${l.note?` <span class="sub">(${esc(l.note)})</span>`:""}</div>`).join("");
const conRows = contacts.map(c => `<div class="ref-item"><b>${esc(c.name)}</b> — ${esc(c.role)}${c.phone?` · ${esc(c.phone)}`:""}</div>`).join("");
const remRows = reminders.map(r => `<li>${esc(r.body)}</li>`).join("");
const strikes = ["Getting up without asking","Too loud","Touching another kid","Negative food comments","Throwing food","Talking to Alexa during the meal"].map(s=>`<li>${s}</li>`).join("");

const html = `<!DOCTYPE html><html><head><meta charset="utf-8"><title>Crew Guide</title>
<style>
  @page { size: letter; margin: 0.6in; }
  * { box-sizing: border-box; }
  body { font-family: Georgia, "Times New Roman", serif; color:#16263d; font-size:11pt; line-height:1.4; }
  h1 { color:#1F3A5F; font-size:24pt; margin:0 0 2pt; }
  .lead { color:#B8893B; font-weight:bold; letter-spacing:1px; text-transform:uppercase; font-size:9pt; }
  .intro { margin:6pt 0 14pt; }
  h2 { color:#1F3A5F; font-size:14pt; margin:0 0 3pt; border-bottom:2px solid #B8893B; padding-bottom:2pt; }
  h2 .date { color:#6b7790; font-size:10pt; font-weight:normal; }
  h3 { color:#1F3A5F; font-size:10pt; text-transform:uppercase; letter-spacing:.5px; margin:8pt 0 3pt; }
  .summary { font-style:italic; color:#444; margin:2pt 0 4pt; }
  .heads { background:#fdf3e0; border:1px solid #f0d9a8; padding:4pt 6pt; border-radius:4pt; font-size:10pt; margin:3pt 0; }
  table.sched { width:100%; border-collapse:collapse; }
  table.sched td { vertical-align:top; padding:2.5pt 0; border-bottom:1px solid #eee; }
  td.t { width:120px; font-weight:bold; color:#1F3A5F; white-space:nowrap; padding-right:8pt; }
  .sub { color:#6b7790; font-size:9.5pt; }
  .meal { margin:3pt 0; }
  .mk { display:inline-block; min-width:48px; color:#B8893B; font-weight:bold; text-transform:uppercase; font-size:8.5pt; }
  .chip { background:#eef1f6; color:#1F3A5F; font-size:8pt; padding:1pt 5pt; border-radius:8pt; }
  .day { margin-bottom:12pt; page-break-inside:avoid; }
  .section { page-break-inside:avoid; margin-bottom:12pt; }
  .peeps td { padding:3pt 6pt 3pt 0; border-bottom:1px solid #eee; font-size:10pt; vertical-align:top; }
  .ref-item { margin:2pt 0; font-size:10pt; }
  ul { margin:3pt 0; padding-left:18pt; }
  li { margin-bottom:2pt; }
  .cols { column-count:2; column-gap:24pt; }
  .pagebreak { page-break-before:always; }
</style></head><body>
  <div class="lead">Haines Harbor</div>
  <h1>Crew Guide</h1>
  <p class="intro">Mon Jun 22 – Sat Jun 27, 2026. Thanks for helping with the kids this week. Live version: camhsmc.github.io/haines-crew-guide</p>

  <section class="section">
    <h2>The Crew</h2>
    <table class="peeps"><tr><td><b>Name</b></td><td><b>Arrives</b></td><td><b>Departs</b></td><td><b>Dietary</b></td></tr>${peopleRows}</table>
  </section>

  <section class="section">
    <h2>Every Day</h2>
    <ul>${remRows}</ul>
  </section>

  ${days.map(dayBlock).join("")}

  <div class="pagebreak"></div>
  <section class="section">
    <h2>Daily Rhythm</h2>
    <h3>Mornings</h3>
    <ul><li>Kids wake on their own → breakfast.</li><li>Boys to summer school: Theo ~8:15, Oliver ~8:50.</li><li>Sunscreen + water bottles.</li><li>Pickup: Oliver 12:00, Theo 12:15.</li><li>Girls stay home — easy play, library, backyard.</li></ul>
    <h3>Evenings</h3>
    <ul><li>Dinner between 5:30 and 6:30.</li></ul>
  </section>

  <section class="section">
    <h2>Mealtime Strike System</h2>
    <p class="sub">Each kid starts every meal at 0 strikes (resets each meal). A strike for:</p>
    <ul class="cols">${strikes}</ul>
    <p><b>3 strikes</b> = no dessert.&nbsp;&nbsp;<b>4 strikes</b> = excused + an extra chore tomorrow.</p>
  </section>

  <section class="section">
    <h2>Chores &amp; Time Off</h2>
    <ul><li>This week's chore to help with: help each child clean and vacuum their room.</li>
      <li>Take an evening out together if you want — movies, ice cream, downtown Hudson.</li></ul>
  </section>

  <section class="section">
    <h2>Locations</h2>${locRows}
  </section>
  <section class="section">
    <h2>Contacts</h2>${conRows}
  </section>
</body></html>`;

await import("node:fs").then(fs => fs.writeFileSync("/Users/camhaines/haines-crew-guide/crew-guide-print.html", html));
console.log("wrote crew-guide-print.html");
