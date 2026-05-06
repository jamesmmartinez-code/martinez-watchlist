# World State — Realm of Eldoria

Canonical facts about the world. This is the source of truth for *what exists*
and *what has happened*. Update this file whenever the world changes.

## World Canon

### Geography
- **Briarwood Village** (origin, friendly hub). 7 named NPCs, 6 buildings,
  cobble path network, well, pond, windmill, market stalls, lanterns, banners,
  campfires. Mountain ring (36 inner + 28 outer peaks with snow caps).
- **Whisperwood Forest** — wilderness north/west of Briarwood. Currently hosts
  3 goblin camps (each: 4 Goblin Scouts + 1 Goblin Brute + glowing campfire)
  and 4 wandering Dire Wolves. The Goblin Warlord (boss) lairs deep within.
- **Crystal Caves** — dungeon, NW Whisperwood entrance. STATUS: planned, not
  yet placed in world. Planned inhabitants: skeletons, crystal elementals.

### Time
- Day/night cycle: 6 real-minute full rotation (sped up from default).
- `World.time_of_day` is the canonical clock. NPC schedules consume it.

## Active Hooks

(Future runs pick from this list. A hook is a one-liner that makes the next
run easier — what's the *next* thing that compounds?)

- ✅ **Resolved 2026-05-05 (run 22 — Builder):** Bandit camp spawn pattern
  shipped. `WorldBuilder._build_enemies` now reads
  `World.faction_pressure("bandits")` and derives camp population from a
  new `_bandit_camp_size(pressure)` helper (INVERTED thresholds:
  `<0.20→0`, `<0.40→1`, `<0.55→2`, `<0.70→3`, `≥0.70→4` — high pressure =
  more bandits, opposite of goblin/wolf). One camp at `Vector3(2, 0, -55)`
  south of the path-network terminus, with a `_make_bandit_camp` prop
  (cold ash + leaning plank — no warm light, bandits stay hidden). Bandit
  enemies use `warrior.glb` (KIND_MODELS) with `KIND_TINT_OVERRIDE = true`
  and a dark-leather `Color(0.30, 0.22, 0.18)` tint for the hooded
  silhouette. The four pre-existing readers of `faction_pressure`
  (cooldown band, chase-speed band, NPC dialogue tier 3 — wait, NPC tier
  is keyed off faction id, not "bandits" specifically; only Roan's
  `bandits_emergent` warm_world_flag tier reads it) all light up the
  moment a bandit spawns. New player toast: "Hooded figures stalk the
  south road." fires when `bandit_count > 0`.
- ✅ **Resolved 2026-05-06 (run 23 — Builder):** Roan's bandit-clear
  quest shipped as `bandit_road_for_roan` in `World.QUEST_CATALOG`.
  Kind=kill, target=bandit, needed=4. Reward 80 xp + 75 gold.
  Consequence: `bandits` `pressure_delta: -0.20` (double the wolf-quest
  delta — bandits are the inverse-pressure faction meant to be cleared
  FAST), `world_flag: roan_bandit_road_clear`, `npc_flag: ["Stablemaster
  Roan", "road_warden"]`. Gated by NEW schema field
  `prerequisite_npc_flag: ["Stablemaster Roan", "first_bounty_done"]` —
  unlocks AFTER Roan's wolf bounty. `_quest_for_role` was upgraded in the
  same edit to honor prereq + auto-skip-on-completion (consequence's
  world_flag already set), so a single role can issue a SEQUENCE of
  quests in narrative order. First role to use it: Roan
  (`wolf_fang_for_roan` → `bandit_road_for_roan`).
- ✅ **Resolved 2026-05-06 (run 23 — Builder):** Bandit Captain mini-boss
  shipped. New `bandit_captain` enemy kind in `Enemy.KIND_MODELS` /
  `KIND_TINT_OVERRIDE` / `KIND_TO_FACTION` (warrior.glb at 1.40× scale,
  bruise-purple tint, joins `bandits` faction so kills count toward the
  `target: "bandit"` quest). Spawn gated by
  `WorldBuilder._bandit_captain_should_spawn(pressure)` at pressure ≥
  0.70 (same threshold that maxes regular bandit_count to 4 — full
  camp). Stat profile: 130 hp / 15 dmg / 120 xp / 50 gold (between
  Goblin Brute 90 hp and Goblin Warlord ~600 hp). Drops from new
  `Items.bandit_captain` table tilted toward steel_blade/chainmail/
  ember_axe + `crystal_shard` 12 (qty 2-4 — bridge to Edda's forge for
  road-tame players who haven't run the Crystal Caves yet) + crit_amulet
  + shadow_dagger. Total weight 100. Captain joins `boss_silhouettes`
  group for future polish-run scale-cap exemption. Two-beat toast
  cascade: "Hooded figures stalk the south road." then "🗡️ A Captain
  leads the south-road camp." Achievement `road_warden` (priority 45,
  title "Road-Warden") fires on quest completion via the existing
  unlock pipeline.
- **Top-priority next (run 24+):** Lore Keeper writes Roan's
  `road_warden` warm_lines. The new `npc_flag` set by
  `bandit_road_for_roan` has no warm_lines yet — Lore Keeper authors 4
  lines for `road_warden` (same shape as the existing `first_bounty_done`
  warm_lines). Tier-2 resolver picks the FIRST flag in npc_flags so
  authoring order matters (LIFO append on `road_warden` to outrank
  `first_bounty_done`). Pure data, zero new code.
- **Top-priority next (run 24+):** `captain_seal` material + Maeve
  sequenced quest. Add a 0-weight `captain_seal` slot now in the
  `bandit_captain` table; a future run lifts it to ~10 by pulling from
  `cloth` (lowest-weight floor) and wires a Maeve fetch quest "bring me
  the captain's seal" as her SECOND quest using the run-23
  `prerequisite_npc_flag` schema. SECOND consumer of `prerequisite_npc_flag`
  proves the schema scales beyond Roan; composes Roan's south-road verb
  into Maeve's narrative.
- **Top-priority next (run 24+):** Bandit Captain name-beat. Captain is
  currently the generic "Bandit Captain." Lore Keeper run can name them
  via per-spawn name dict in `WorldBuilder._build_enemies`, mirroring
  the "Pippin"-the-horse pattern. Pure data.
- **Top-priority next (run 24+):** Maeve cross-NPC mention of bandit
  clear. Maeve's open `warm_world_flag` slot can now read
  `roan_bandit_road_clear` as a fourth cross-NPC flag-recognition tier
  (joining `mara_bounty_paid`, `lyra_potion_brew`, `bram_nights_quiet`).
  Pure data add in `WorldBuilder.NPCS`.
- **Hook for Lore Keeper:** the leaning plank in `_make_bandit_camp` is
  un-painted `MAT_DARK_WOOD`. A Lore Keeper run can paint a "TOLL" rune
  decal once the rune-texture pipeline lands, turning the foreshadowing
  prop into a readable warning sign. Composes with Roan's tier-3 line
  about "paid a 'toll' to a hooded fellow at the crossroads."
- **Top-priority next (run 22+):** First bandit-themed quest. Roan's dialogue
  promises bandits emerging — the natural quest is "Roan asks the player
  to clear the south road" (kind: kill, item: bandit, needed: 4-5).
  Consequence consumes the inverted-pressure direction: `pressure_delta:
  -0.15` on `bandits` faction (player REDUCES bandit boldness by clearing
  the camp). Compounds the existing wolf-quest authoring template — same
  schema, opposite faction direction, no new code.
- **Top-priority next (run 22+):** Maeve cross-NPC mention of Bram's bounty.
  Maeve's WorldBuilder entry has an OPEN `warm_world_flag` slot
  (Lyra's existing tier uses `lyra_potion_brew`; Maeve never set one). Wire
  `warm_world_flag: "bram_nights_quiet"` + 4 lines like "even Bram says the
  Lantern's bards finished a set last night — quite a thing." Pure data,
  zero new schema. Compounds the FOURTH cross-NPC flag-recognition pattern
  after Mara/Lyra/Roan world flags. Pairs nicely with the run-15 painterly
  crest art if the Lore Keeper lands a "Quiet Songhouse" name beat.
- **Top-priority next (run 20+):** Heartwood Mead consumable. The run-19
  Bram quest references "the deep barrel" but the toast/reward is gold-
  only; a `heartwood_mead` consumable in Items.gd (heal 60 + brief mp
  regen) shipped as a one-shot quest reward (set on `complete_quest_if_done`)
  closes the loop on the bards-and-mead motif. Pure data + one Items.gd
  entry. Polisher territory.
- **Top-priority next (run 20+):** Faction-state bandit boldness. Backlog
  item — bandits scale with road defense (i.e. when wolves+goblins are
  quiet, bandits get bold). Requires NEW `bandits` faction in
  World.factions, NEW bandit GLB or warrior.glb-tinted reuse (Enemy.gd
  already has `kind:"bandit"` plumbed but unmapped), NEW road-spawn pattern
  in WorldBuilder. Larger system change — assign to a fresh Builder run.
- Crystal Caves entrance is undefined → place it once dungeon is ready.
- Skeleton + Crystal Elemental drop tables exist in Items.gd; spawn paths do
  not. Anyone adding the dungeon should reuse those tables, not redefine them.
- ✅ **Resolved 2026-05-04:** Faction pressure scalar exists
  (`World.factions[id].pressure`) — three quests already mutate it.
- ✅ **Resolved 2026-05-04 (integrator):** Reactive dialogue wired.
  NPC.gd now reads `World.npc_has_flag(npc_name, warmed_flag)` and prefers
  a `warmed_dialogue_variants` (4 entries, same time-of-day buckets) when
  the flag is set. Maeve (`first_quest_done`), Lyra (`trusts_player`),
  Mara (`good_customer`) each ship 4 warmed variants in WorldBuilder.NPCS.
  Every other NPC has empty `warm_*` fields and behaves unchanged.
- ✅ **Resolved 2026-05-04 (run 3 follow-up):** World-flag warmed dialogue
  tier added to NPC.gd as a SECOND lower-priority warmed layer
  (`warmed_world_flag` / `warmed_world_dialogue_variants`). Lyra now has 4
  extra lines that fire on `lyra_potion_brew`. Composes with the integrator's
  `warmed_flag` tier — NPC-flag warm beats world-flag warm beats time-of-day.
  Consumes `World.world_flags` which had no other readers until now.
- ✅ **Resolved 2026-05-04 (run 4):** Faction-pressure dialogue tier wired
  as NPC.gd Tier 3 (between world-flag warm and time-of-day variants).
  Maeve carries 4 lines fired by `whisperwood_goblins` pressure < 0.9; the
  tier reaches her on the "ears-before-cleansing" path (Mara's bounty drops
  pressure to 0.85 before Maeve's `first_quest_done` flag locks in tier 1).
  `World.faction_pressure(id)` now has its first reader after 2 runs of being
  written-only. Authoring trap captured in SYSTEM_REGISTRY.md: never pair a
  faction reducer with the same quest that issues the NPC's warm_flag.
- ✅ **Resolved 2026-05-04 (run 5):** Goblin spawn density reads
  `World.faction_pressure("whisperwood_goblins")` in `WorldBuilder._build_enemies()`.
  Per-camp population now derives from a `_goblin_camp_size(pressure)` helper
  with thresholds at 0.9 / 0.7 / 0.4 / 0.15 — co-fired with NPC.gd's tier-3
  dialogue so dialogue *speaks* the faction state and spawning *enacts* it.
  At fresh-save pressure 1.0 the camp population is identical to pre-run-5
  (4 scouts + 1 brute per camp); at 0.85 (Mara's bounty alone) goblins drop
  by 1 per camp; at 0.65 (Mara + Maeve) by 2 per camp; brute disappears
  below 0.4. The empty camp prop (campfire, huts) persists as a memorial.
  `World.faction_pressure()` now has TWO consumers (NPC.gd dialogue tier 3,
  WorldBuilder spawn density) — the consequence-resolver loop is closed on
  both narrative and pacing axes.
- ✅ **Resolved 2026-05-04 (run 6):** Wolf spawn density reads
  `World.faction_pressure("dire_wolves")` in `WorldBuilder._build_enemies()`.
  `_wolf_pack_size(pressure)` mirror of the goblin helper with thresholds at
  0.5 / 0.3 / 0.15 — wolves drop from 4 → 3 the moment `pelt_for_lyra` ships
  (-0.1 takes pressure 0.5 → 0.4, < 0.5 trips the first threshold). Empty
  forest patches where a wolf used to roam serve as the same "they used to
  be here" memorial as the empty goblin camps. `World.faction_pressure()`
  now has THREE consumers (NPC.gd dialogue tier 3, goblin spawn density,
  wolf spawn density) — pattern proven generalizable to every faction.
- ✅ **Resolved 2026-05-04 (run 7):** Adaptive `Enemy.gd.attack_cooldown`
  is now a THIRD reader of `World.faction_pressure(faction_id)`. Each enemy
  resolves its cooldown at spawn via a `KIND_TO_FACTION` map + lerp across
  `[1.45, 1.05]` keyed on the kind's faction pressure. At fresh-save pressure
  1.0 a goblin keeps the kid-tuned 1.45s recovery window; at pressure 0.0
  the few survivors hit at 1.05s — Owen's mastery rung. Goblins, wolves,
  skeletons, crystal_elementals, crystal_guardians all wired; bandits
  (no faction yet) keep baseline. Same fail-soft contract as spawn density:
  unmapped kind / missing world / older `World.gd` → baseline, never crash.
  `World.faction_pressure()` now has FOUR consumers (NPC.gd dialogue tier 3,
  goblin spawn density, wolf spawn density, enemy attack cooldown) — the
  same scalar drives narrative + density + pacing. Mastery threshold for
  Rule 1 ("compound, don't sprawl") demonstrated: ONE primitive can fan out
  to multiple readers without sprawl. Visible "agitated" ⚡ prefix on the
  floating name fires when cooldown < 1.30 so kids can read pacing change
  per-enemy, not just per-density.
- ✅ **Resolved 2026-05-04 (run 8):** Roan (Stablemaster) carries 4
  `dire_wolves` faction-tier lines (`warm_faction_id:"dire_wolves"`,
  `warm_faction_below:0.5`). First NPC whose ONLY warming channel is the
  faction scalar — smoke-tests Tier 3 of the NPC.gd dialogue stack on an
  NPC with no `warm_flag` and no `warm_world_flag`. Threshold 0.5 mirrors
  the run-6 wolf-spawn first cliff, so Roan begins speaking the moment
  any wolf-reducing quest ships (today: `pelt_for_lyra`). Roan's lines
  now compose with run-6 spawn density (3 wolves remaining) and run-7
  adaptive cooldown (visible ⚡ prefix on agitated survivors), closing
  the FOURTH leg of the `dire_wolves` compound (dialogue + density +
  cooldown + visual marker). `World.faction_pressure("dire_wolves")` now
  has FIVE consumers (Roan dialogue, Maeve via `whisperwood_goblins`
  doesn't count for wolves, but spawn density + adaptive cooldown +
  Maeve-on-goblins-pattern reuse + future bandit/skeleton schema all
  validate the run-7 mastery threshold). Pattern proven: ANY NPC can
  speak ANY faction's state via data-only edits.
- ✅ **Resolved 2026-05-04 (run 9):** JSON dialogue trees made live.
  New `DialogueDB.gd` static helper reads `data/dialogue/<npc_slug>.json`
  and applies a 9-step predicate priority (low_health_player → boss_slain →
  boss_alive → high_renown → stranger → festival → after_first_quest_complete
  → mood bucket → default). Maeve and Edda are opted in via
  `"use_json_dialogue": true` in `WorldBuilder.NPCS`. The mood-keyed JSONs
  shipped from `auto/lore` on 2026-05-04 (and flagged dormant by the
  integrator) are now the FIRST tier of NPC.gd's dialogue resolution —
  above all 4 existing tiers (warm_flag / warm_world_flag /
  warm_faction_id / mood bucket). Misses fall through cleanly so opt-in is
  purely additive. Four predicates (`boss_alive`, `high_renown`, `stranger`,
  festival keys) are fail-soft on World fields not yet shipped (`player_renown`,
  `npc_seen`, `current_festival`, `seen_warlord`); they LIGHT UP the day
  those fields land — no DialogueDB / JSON edit required, and Maeve & Edda
  already author lines for them. Closes the integrator-noted gap from
  2026-05-04: lore-keeper output is no longer canon-only.
- 🔥 **Top-priority next:** ship JSON dialogue trees for the other 5 NPCs
  (**Mara the Merchant**, **Herbalist Lyra**, **Innkeeper Bram**,
  **Stablemaster Roan**, **Trainer Hala**). Pure data work — drop a
  `data/dialogue/<slug>.json` file with the schema documented in
  SYSTEM_REGISTRY.md "JSON Dialogue Tree Schema" + flip
  `"use_json_dialogue": true` in `WorldBuilder.NPCS`. Each NPC gets the
  same 9-tier predicate space without a single GDScript edit. Highest-leverage
  next move because the SYSTEM is already shipped and tested on 2 NPCs.
- ✅ **Resolved 2026-05-05 (run 17 — Builder):** `wolf_fang_for_roan`
  quest shipped. SECOND `dire_wolves` reducer (`-0.1`) — pressure now
  tracks `0.5 → 0.4 (Lyra's pelts) → 0.3 (Roan's fangs)` on the canonical
  reduction path. Trips the run-6 second wolf-spawn cliff (3 → 2 wolves)
  AND drops adaptive cooldown (run 7) and chase speed (run 8) another
  step on the same scalar. New material `wolf_fang` (Items.gd) added to
  the wolf DROP_TABLE at weight 18 (pelt 48 → 38), so a single 5-kill
  wolf grind produces ~1.9 fangs AND ~2.0 pelts in parallel —
  `wolf_fang_for_roan` and `pelt_for_lyra` can be progressed together
  without re-grinding. Standalone (no Lyra) the bounty hits the FIRST
  cliff (4 → 3) — also visible. Composes with the Roan-arc started in
  run 8 and the Roan `warm_flag` tier shipped in this same run.
- ✅ **Resolved 2026-05-05 (run 17 — Builder):** Roan `warm_flag`
  tier wired in `WorldBuilder.NPCS`. Quest consequence sets
  `first_bounty_done` on Roan's `npc_flags`; four `warm_lines` author the
  personal-warmth tier. Roan promoted from faction-only NPC (run 8) to
  faction + warm_flag NPC — same dialogue depth as Maeve (`first_quest_done`),
  Mara (`good_customer`), Lyra (`trusts_player`). NPC.gd Tier 2 (warm_flag)
  fires above Tier 4 (faction-pressure), so warm_lines surface the
  moment the quest turns in. `line` field updated to the bounty pitch
  ("Wolves nip my mares again. Bring me 5 wolf fangs and the road's
  safer.") matching the Mara/Lyra offer-line convention.
- ✅ **Resolved 2026-05-05 (run 18 — Builder):** `wolf_form_with_hala`
  quest shipped — THIRD `dire_wolves` reducer (`-0.1`). Closes the
  authoring gap left by the previous run: Hala's WorldBuilder pitch
  line, `warm_flag: wolf_form_taught`, and four `warm_lines` were
  ALREADY shipped, AND `Achievements.wolf_tamer` predicate was wired
  referencing `wolf_form_taught` on Hala — but `World.QUEST_CATALOG`
  had no `role: trainer` entry, so the engine could never deliver the
  pitched quest and the achievement could never trip. Single edit in
  World.gd adds the entry with values matching SYSTEM_REGISTRY.md
  run-18 documentation (90 xp / 35 g / `hala_wolf_form_done`
  world_flag). Wolf pressure now tracks 0.5 → 0.4 (Lyra) → 0.3 (Roan)
  → 0.2 (Hala), trips the run-6 SECOND cliff (3 → 2 wolves) on the
  full path. The two surviving wolves are ~21% faster (run-8 chase
  lerp) and ~28% slower-attacking (run-7 cooldown lerp) — older,
  wiser, hungrier. With Lyra+Roan+Hala done, `Achievements.wolf_tamer`
  finally resolves TRUE — Owen unlocks "the Wolf-Tamer" title at
  priority 35, auto-equipping above "Wolf-Friend" (30). Hala's
  authored `warm_flag` tier 2 lines (run 18 prior) light up on the
  very next training visit. Closes the FIRST quest where dialogue,
  warm-flag tier, achievement predicate, and reward economy were
  all pre-authored across multiple files BEFORE the keystone quest
  entry — a useful pattern for downstream "data-first" runs (write
  the registry / dialogue / achievement first, drop the World.gd
  entry last).
- ✅ **Resolved 2026-05-04 (run 8):** Adaptive `Enemy.gd.chase_speed` is
  now a FOURTH reader of `World.faction_pressure(faction_id)`. Multiplicative
  band — each enemy kind's WorldBuilder-assigned chase_speed lerps up to
  `+CHASE_SPEED_AGITATION_GAIN` (=0.17, +17%) at pressure 0.0. Goblin Scout
  4.6 → 5.38, Brute 1.0 → 1.17 (tank role preserved), Wolf 1.05 → 1.23,
  Skeleton 4.4 → 5.15, Crystal Elemental 3.2 → 3.74, Crystal Guardian 3.4
  → 3.98. Bandits unmapped → baseline. Same fail-soft contract as run 7;
  reuses the same `KIND_TO_FACTION` map (single source of truth). NO new
  visual cue — run 7's `⚡` agitated-name prefix already fires below
  pressure ~0.625 and now subsumes BOTH adaptive outputs (cooldown AND
  chase lerp on the same scalar — they trip together). `World.faction_pressure()`
  now has FIVE consumers (NPC dialogue tier 3, goblin spawn density, wolf
  spawn density, enemy attack cooldown, **enemy chase speed**) — same
  scalar drives narrative + density + 2-axis pacing. Mastery threshold
  for Rule 1 ("compound, don't sprawl") restated: ONE primitive can fan
  out to 5+ readers without sprawl, provided each reader uses the SAME
  fail-soft contract and the SAME kind→faction map.
- 🔥 **Top-priority next:** Roan (Stablemaster) → `dire_wolves` faction tier.
  Smoke-tests the 4-tier dialogue system on an NPC with no warm_flag at
  all. Schema is in place, only WorldBuilder edits required. After runs
  6 + 7, Roan's faction-tier lines now have TWO partners: wolf spawn
  density already speaks the state AND the surviving wolves visibly
  agitate (⚡ prefix) — dialogue completes the FOURTH leg of the
  `dire_wolves` compound (dialogue + density + cooldown + visual marker).
- ✅ **Resolved 2026-05-05 (run 17 — Builder):** *(duplicate hook)*
  Folded into the run-17 wolf-bounty entry above. The Roan-arc on
  `dire_wolves` is now complete on all four legs: dialogue (tier 4
  faction + tier 2 warm_flag), spawn density (run 6), adaptive cooldown
  (run 7), adaptive chase (run 8) — every consumer of
  `World.faction_pressure("dire_wolves")` is wired to a Roan-issued
  reduction event.
- ✅ **Resolved 2026-05-05 (run 10): Boss world-flag wire + 3rd JSON opt-in.**
  Two world flags now flip on Goblin Warlord lifecycle events:
  - `seen_warlord` — set in `Boss._physics_process` immediately after the
    intro sting plays (player came within 30m). Reads as "the village has
    heard the Warlord's banners go up." Permanent for the session.
  - `warlord_dead` — set in `Boss._die` alongside the existing reward /
    quest-hook calls. Reads as "the Warlord has fallen." Permanent — never
    cleared on player respawn (a slain boss stays slain).

  Both flags are written via a new `World.set_world_flag(name, value=true)`
  helper (single-line callsites) which also runs `_check_achievements()` so
  any future "Met the Warlord" / "Warlord Slain" achievement unlocks on the
  same tick the flag flips. `apply_consequence`'s flag step continues to
  work unchanged — `set_world_flag` is the no-faction / no-toast / no-npc
  sister for emergent runtime events that aren't quest consequences.

  **Innkeeper Bram opted into JSON dialogue** (`use_json_dialogue: true` on
  his WorldBuilder.NPCS entry). He becomes the THIRD JSON-resolver NPC
  alongside Maeve and Edda. With the boss-flag wire above, all three now
  speak DISTINCT boss_alive and boss_slain lines on the same world tick:
  - Boss alive: Maeve "Do not fight him angry. Anger is what made him." /
    Edda "The Warlord rides a blade I'd recognize anywhere. I forged it
    before I knew better." / Bram "Some folk who walked into the
    Whisperwood I still set a place for at supper. Habit."
  - Boss slain: Maeve "*long pause* — *Ai-velin*, traveler. The Whisperwood
    will sleep tonight." / Edda "*long silence* — You unmade my mistake.
    *one hard hammer-strike*" / Bram "*sets the mug down very carefully*
    — Some debts get paid in iron, friend."

  Six dormant authored lines became reachable in the player flow. No new
  state shape introduced; `world_flags` had been written by quest
  consequences and now also by boss lifecycle events.

  **DialogueDB consumer count for `world_flags`:** the JSON loader had been
  the SOLE downstream reader of `seen_warlord` / `warlord_dead` flags
  before this run — fail-soft, so DialogueDB silently fell through to
  mood/default tier when the flags were never set. Run 10 makes the flags
  actually flip, completing the 3-leg compound (Boss.gd writes →
  `world_flags` carries → DialogueDB reads → JSON line surfaces).

- 🔥 **Top-priority next:** Author Mara / Lyra / Roan / Hala JSON trees and
  drop them into `data/dialogue/`. Pure data PR — `WorldBuilder.NPCS` adds
  one `"use_json_dialogue": true` per NPC and DialogueDB picks up the rest.
  Mara is highest-leverage (her `low_health_player` reads as "she comps a
  potion" — mechanically distinct from Bram's "no coin tonight, stew first").
  Roan and Hala have no JSONs authored yet; the lore agent ships first,
  Builder/WorldBuilder lights up the opt-in switch second.
- 🔥 **Adjacent next:** Wire a `World.player_renown` int (or reuse
  `unlocked_achievements.size()`) so Maeve and Edda's already-authored
  `high_renown` JSON lines fire. DialogueDB reads `world.player_renown >=
  renown_threshold` (default 100) and the JSONs are pre-authored. Single
  field write + one quest hook.
- ✅ **Resolved 2026-05-05 (run 20 — Builder):** `World.npc_seen` Dictionary
  + `mark_npc_seen(name)` writer + `is_stranger(name)` reader, all
  session-scoped on the World autoload. Wired into `World.show_dialogue`
  as a POST-condition (after `dialogue_panel.visible = true`) so
  DialogueDB.choose_line — which runs BEFORE show_dialogue inside
  NPC.gd::_on_interact — sees the OLD `npc_seen` state on the FIRST
  hello and the NEW state from the SECOND onward. Lights up DialogueDB's
  pre-existing 5th-tier `stranger` predicate for every NPC opted into
  JSON dialogue: all 7 villagers (Maeve, Edda, Mara, Lyra, Bram, Roan,
  Hala) carry an authored `stranger` key written by the Lore Keeper on
  2026-05-04. Seven dormant lines become reachable in the player flow
  in a single field+method add. No NPC.gd or DialogueDB.gd edits
  required (DialogueDB had a fail-soft `"npc_seen" in world_node` guard
  in place from run 9; the predicate had been waiting for the field
  to land). `World.npc_seen` joins `World.player_renown` (run 11) as
  the SECOND DialogueDB-only consumer field — both shipped with no
  in-game UI surface, both purely route authored dialogue tiers to
  authored predicates. Pattern proven: world-state fields whose ONLY
  consumer is DialogueDB don't need their own HUD/UX and still carry
  meaningful in-game weight. `stranger` predicate priority sits ABOVE
  the time-of-day mood bucket so the FIRST hello to any never-met NPC
  is guaranteed to surface the authored stranger line, not a generic
  morning/midday greeting.
- Player housing has no anchor point. A flat plot east of Briarwood (positive
  X, near +12,0,+4) is reserved for it.
- Lyra shop unlock: when `World.has_world_flag("lyra_potion_brew")`, list
  `hp_potion_g` (greater) at her shop. Today no shop UI exists — pair with
  Smith Edda's forge UI (backlog #4).

## NPC Memory

(Tracks who has spoken to whom, who has been thanked, who has been ignored.
Populated as runs ship reactive dialogue. Run 16 added a per-visit ledger
that complements the flag-derived columns below — see
`World.npc_memory[name]`.)

| NPC                  | Role     | Player relationship | Flag-warmed lines | Visit-warmed (run 16) | Memory flags consumed |
|----------------------|----------|---------------------|-------------------|------------------------|------------------------|
| Elder Maeve          | quest    | warms after first quest; senses goblin retreat; recognizes regulars | ✅ 4 (npc-flag, integrator) + ✅ 4 (faction, run 4) | ✅ 4 @ visits ≥ 3 | `first_quest_done`; `whisperwood_goblins` < 0.9 |
| Smith Edda           | smithy   | reforge sink (run 12) | ❌ (forge dialogue not warmed) | ❌ (forge button covers cadence) | — |
| Mara the Merchant    | shop     | warms after ear bounty | ✅ 4 (npc-flag, integrator) | ❌ | `good_customer` (ears_for_mara) |
| Herbalist Lyra       | alchemy  | warms after pelts; senses brewing | ✅ 4 (npc-flag) + ✅ 4 (world-flag, run 3 follow-up) | ❌ | `trusts_player`, `lyra_potion_brew` |
| Innkeeper Bram       | inn      | "regular at the bar" cadence after 3 visits | ❌ (no quest yet) | ✅ 4 @ visits ≥ 3 | — |
| Stablemaster Roan    | stable   | warms after fang bounty; warms when wolves quiet | ✅ 4 (npc-flag, run 17) + ✅ 4 (faction, run 8) | ❌ | `first_bounty_done` (wolf_fang_for_roan); `dire_wolves` < 0.5 |
| Trainer Hala         | trainer  | recognizes returning student after 3 sessions | ❌ (no quest yet) | ✅ 4 @ visits ≥ 3 | — |

Live data:
* `World.npc_flags[npc_name] -> Array[String]` — flag-derived memory.
  Read with `World.npc_has_flag(npc, flag)`. Mutated by quest consequences
  only.
* `World.npc_memory[npc_name] -> {visits, first_day, last_day, first_tod,
  last_tod}` — visit-derived memory (run 16 — Builder). Read with
  `World.npc_visits(name)`, `World.npc_first_visit_day(name)`,
  `World.npc_last_visit_day(name)`, `World.npc_days_since_last_visit(name)`.
  Mutated by `World.record_npc_visit(name)`, called from NPC.gd's
  `_on_interact` BEFORE tier resolution so the triggering visit counts.
* `World.world_day` — integer counter; increments when `time_of_day` wraps
  past midnight. Pure derivation from `time_of_day`, no separate timer.
* `World.npc_seen[npc_name] -> bool` — per-NPC "have we ever met?" ledger
  (run 20 — Builder). Read with `World.is_stranger(name)`. Mutated by
  `World.mark_npc_seen(name)` only, called from `World.show_dialogue`
  AFTER `dialogue_panel.visible = true` so DialogueDB.choose_line (which
  runs BEFORE show_dialogue, inside NPC.gd::_on_interact) sees the OLD
  state on the FIRST hello and the NEW state on every subsequent hello.
  First reader is DialogueDB's pre-existing 5th-tier `stranger` predicate
  (run 9, fail-soft on missing field — now active). All 7 villagers carry
  authored `stranger` JSON keys (Lore Keeper, 2026-05-04), reachable in
  the player flow as of this run.

The dialogue tier order (highest → lowest priority) is:
1. JSON-tree (DialogueDB, opt-in via `use_json_dialogue`) — internal
   predicate sub-priority: low_health_player → boss_slain → boss_alive →
   high_renown → **stranger (run 20 — wired via `World.npc_seen`)** →
   festival keys → after_first_quest_complete → mood bucket → default.
2. NPC-flag warmed (`warmed_flag` + `warmed_dialogue_variants`)
3. World-flag warmed (`warmed_world_flag` + `warmed_world_dialogue_variants`)
4. Faction-pressure warmed (`warmed_faction_id` + `warmed_faction_below` + variants)
5. **Visit-memory warmed (`warmed_memory_visits_min` + variants — run 16)**
6. Time-of-day default (`dialogue_variants`, 4 buckets)

Memory sits BELOW faction by deliberate authoring choice: a villager
reacts to the SHAPE of the world (faction) before the cadence of their
relationship with the player. Flip if play-testing disagrees.

## Faction State

(Live scalars in `World.factions`. Bandits row added run 21 — Builder.)

| Faction          | Disposition | Pressure | Notes                          |
|------------------|-------------|----------|--------------------------------|
| Briarwood        | friendly    | 0.0      | safe hub                       |
| Whisperwood Goblins | hostile  | 1.0      | mutable; cleansing & ear bounty reduce; **Maeve speaks at <0.9 (run-4 dialogue tier 3); spawns drop at <0.9/<0.7/<0.4/<0.15 (run-5 spawn density); attack cooldown lerps 1.45→1.05 (run-7 adaptive pacing); chase_speed lerps +17% (run-8 adaptive pacing)** |
| Dire Wolves      | hostile     | 0.5      | mutable; **FOUR reducers**: `pelt_for_lyra` (-0.1) + `wolf_fang_for_roan` (-0.1, run 17) + `wolf_form_with_hala` (-0.1, run 18) + `wolf_heart_for_bram` (-0.1, run 19); **Roan speaks at <0.5 (run-8 faction tier) + <warm_flag `first_bounty_done` (run-17 personal tier); Hala speaks at <warm_flag `wolf_form_taught` (run-18 personal tier); Bram speaks at <warm_flag `nights_quiet` (run-19 personal tier)**; spawns drop at <0.5/<0.3/<0.15 (run-6 spawn density — all three cliffs now player-reachable in a single save AND the run-6 third cliff trips on Bram completion: 4 reducers stack to pressure 0.1, packs of 1); attack cooldown lerps 1.45→1.05 (run-7); chase_speed lerps +17% (run-8 adaptive pacing); FIRST `all_npc_flags` achievement consumer wired (run-18 `wolf_tamer`) — Bram is purely additive (curve, not predicate) so Wolf-Tamer title still attainable on the Lyra+Roan+Hala arc |
| Crystal Caves    | hostile     | 0.0      | placeholder; dungeon not placed; **skeleton/crystal_elemental/crystal_guardian cooldown wired (run-7) AND chase wired (run-8) — both fire the moment the dungeon ships** |
| Bandits          | hostile     | 0.0      | **NEW (run 21 — Builder)**: INVERTED-pressure faction (high = bandits bold). Single writer is `World.update_bandit_pressure()`, called from Step 5a of `apply_consequence`. Derivation: `clamp(1.0 - 0.5*(goblin + wolf) - 0.20, 0, 1)`. Sets `bandits_emergent` world flag at threshold 0.40. **Roan speaks the emergence at <warm_world_flag `bandits_emergent` (run-21 cross-NPC tier — first world-flag-from-derivation tier ever)**; Enemy.gd cooldown band + chase band wired via `KIND_TO_FACTION["bandit"] = "bandits"` and fire the moment a bandit-kind enemy spawns; drop_table["bandit"] in Items.gd ready (total weight 100). NEXT: spawn pattern + warrior.glb wiring. |
Live data in `World.factions`. Read with `World.faction_pressure(id)`. Mutated
by `World.apply_consequence({...})` (Steps 1, 5a — Step 1 for direct quest
writes, Step 5a for the derived `bandits` rewrite each consequence).

## World Flags (Active)

`World.world_flags` is a dict keyed on flag name. Set by quest consequences,
read by dialogue / spawning / future runs.

| Flag                  | Set by quest          | Default | Used by (downstream) |
|-----------------------|-----------------------|---------|----------------------|
| `whisperwood_safer`   | whisperwood_cleansing | unset   | future: roving patrol density |
| `lyra_potion_brew`    | pelt_for_lyra         | unset   | future: Lyra unlocks rarer potions in shop |
| `mara_bounty_paid`    | ears_for_mara         | unset   | future: Mara raises buy prices on goblin loot |
| `roan_bounty_paid`    | wolf_fang_for_roan    | unset   | future: Maeve cross-NPC mention; Edda fang-stitched greaves recipe (run 17) |
| `hala_wolf_form_done` | wolf_form_with_hala   | unset   | run 18: `wolf_tamer` achievement reads the npc_flag side; future: Hala teaches an advanced wolf-defense technique unlocking a counter-stance buff |
| `bram_nights_quiet`   | wolf_heart_for_bram   | unset   | **run 19**: Bram warm_flag tier reads the npc_flag side; future: Maeve cross-NPC mention via `warm_world_flag` + 4 lines, Bram's nightly bards play a Celtic lute track only when this flag is set |
| `bandits_emergent`    | **DERIVED** (run 21)  | unset   | **run 21 — Builder**: NOT set by a quest — set/cleared by `World.update_bandit_pressure()` whenever bandit pressure crosses ±0.40. **Roan warm_world_flag tier** is the first reader. Authoring contract: NEVER add this flag to a `consequence.world_flag` — it would be overwritten on next pressure mutation. Future: Maeve adds `warm_world_flag: "bandits_emergent"` for cross-NPC pattern; bandit road-spawn pattern reads the flag as a gate; "Wolf-Tamer turned Bandit-Hunter" achievement chain. |

Read with `World.has_world_flag(name)`. Convention: flag names are
`snake_case`, present-tense fact ("safer", "paid", "brew"), never imperative.

## Player Impact Ledger

(Cumulative consequences of player actions. Empty until reactive systems exist.)

- Goblins killed (lifetime): tracked per-save in Player.kills_by_kind, not yet
  surfaced to NPCs. (Adjacent compound: a kills-derived faction-pressure decay
  could route per-kill impact into the dialogue tier 3 channel.)
- Goblins spawned (per world load): now scales from baseline 15 (3 camps × 5)
  down to 3 (3 × 1) as `whisperwood_goblins` pressure drops. Ledger of *what
  the world LOOKS like to the player on save reload* now reflects their work.
- Wolves spawned (per world load): scales from baseline 4 down to 1 as
  `dire_wolves` pressure drops. Position list is stable — wolves vanish
  from the END of `wolf_spots` first, so re-loading the same save shows
  the SAME wolves missing from the SAME forest patches. (Run 6.) FOUR
  reducers now drive this: `pelt_for_lyra` (-0.1, run 6) + `wolf_fang_for_roan`
  (-0.1, run 17) + `wolf_form_with_hala` (-0.1, run 18) + `wolf_heart_for_bram`
  (-0.1, run 19). Running all four takes pressure 0.5 → 0.1, trips ALL
  THREE cliffs, and the Whisperwood ends with a single surviving wolf —
  the apex/scarred alpha that wouldn't be hunted. At pressure 0.1 that
  last wolf has cooldown ~1.07s and chase_speed +15%: a boss-feeling
  fight without a boss-spawn, pure compound on existing scalars.
- Quests completed: surfaced as toast AND (run 4) as faction-pressure shifts
  that NPCs now narrate. `apply_consequence()` is no longer write-only on the
  faction key.
- Surviving enemy aggression (per world load): each remaining goblin / wolf /
  skeleton / crystal_elemental / crystal_guardian resolves attack_cooldown
  against its faction pressure at spawn (run 7). Visible ⚡ prefix on the
  floating name when cooldown < 1.30 — the third *visible* axis on the
  consequence loop after dialogue (run 4) and spawn density (runs 5–6).
- Surviving enemy chase pacing (per world load): each remaining enemy of a
  mapped kind also resolves chase_speed against its faction pressure at
  spawn (run 8). Multiplicative `+17%` ceiling at pressure 0.0; baseline
  preserved at pressure 1.0. The same `⚡` prefix subsumes both pacing
  outputs — kids see ONE marker meaning "this one is faster recovery AND
  faster chase," not two separate marks. Output #4 on the same scalar.
- Roads defended: not modeled.
- Buildings damaged: not modeled.

## Recent Run Summary

See CHANGES.md for the human-readable run log.

## Lore Artifacts

(Append-only ledger of canonical written lore. The Lore Keeper agent owns
this section. Files live under `eldoria-godot/lore/`, `eldoria-godot/data/`.)

### NPC backstories (`lore/npcs/`)

| NPC          | File                              | Dialogue tree                                  | Status |
|--------------|-----------------------------------|------------------------------------------------|--------|
| Smith Edda   | `lore/npcs/smith_edda.md`         | `data/dialogue/smith_edda.json` (16 keys)      | drafted; awaiting Builder wiring |

### Old Faerie glossary (cumulative)

Canonical words, in the order they entered canon. Future writers should
reuse these before inventing new ones.

- **`thirre`** *(world.md)* — memory of stone; a place where time pools.
- **`ai-velin`** *(world.md)* — the long path; the river of stars / a mortal life.
- **`kerrithen`** *(world.md)* — to lay down so the land may hold it.
- **`haethe`** *(npcs/smith_edda.md)* — the song iron remembers; a properly-tempered blade's hum.
- **`unnen`** *(npcs/smith_edda.md)* — the work of two hands; the highest praise of the smith tradition.

### Cross-references seeded this run

- Smith Edda's mother **Halsa** (deceased; Longnight death) is now seedable
  for codex narration about iron and the *haethe*.
- The **Goblin Warlord's saber** is canonized as Edda's badly-forged early
  work. Builder may, when ready, wire `boss_slain` to drop it as a unique
  quest-turn-in to Edda. Her dialogue tree's `boss_slain` line is pre-tuned.
- **Longnight Vigil** is now the most loaded day in Edda's year (Halsa's
  death-night; Bram's stew). Future seasonal dialogue can lean here.
- Bram quietly knows Edda forged the Warlord's saber. He has never said.
  This is a relationship hook for Bram's eventual backstory file.

---

## Lore Run — 2026-05-04 (Elder Maeve)

### NPC backstories (`lore/npcs/`) — added this run

| NPC          | File                              | Dialogue tree                                  | Status |
|--------------|-----------------------------------|------------------------------------------------|--------|
| Elder Maeve  | `lore/npcs/elder_maeve.md`        | `data/dialogue/elder_maeve.json` (16 keys)     | drafted; awaiting Builder wiring |

### Old Faerie glossary — additions

Two new canonical words enter the language. They sit alongside *thirre*,
*ai-velin*, *kerrithen* (`world.md`) and *haethe*, *unnen*
(`smith_edda.md`). Future writers should reuse these before inventing new
ones.

- **`vael-tor`** *(elder_maeve.md)* — the gathered hearth; the collective
  warmth a village turns toward a death. Older 'we'-form: *vael-tor-i*.
  Maeve speaks the *we*-form on Longnight Vigil.
- **`thressa-mai`** *(elder_maeve.md)* — the unanswered letter; a debt of
  words owed to one who has gone without farewell.

### Cross-references seeded this run

- **Maeve was Edda's midwife.** She named Edda. She has not crossed the
  forge threshold since the spring after Halsa's death, when she brought
  Halsa's cradle. This is the canonical bridge between the two existing
  NPC files. (`elder_maeve.md` ↔ `smith_edda.md`)
- **Maeve's brother Cailen** was lost on the High Steppe. A Steppe-rider
  returned a horseshoe and a pressed sprig of heather; the horseshoe
  hangs above Maeve's hearth. This makes the Stone Crown reusable for
  future quests/codex.
- **Maeve's daughter Aelis** went south to the Iron Crown's smoke-cities
  eleven years ago and stopped writing. Maeve sends a sealed letter every
  Lambmoon by **Mara the Merchant**. **Mara is keeping one returned
  letter** (water-stained, addressed in a hand not Aelis's) — a slow-burn
  quest seed she has not yet decided what to do with. Mara is canonically
  expected to give it eventually to Edda for keeping. (Three-way bridge:
  Maeve ↔ Mara ↔ Edda.)
- **Roan rode the High Steppe twice** for Maeve, hunting word of Cailen.
  Maeve paid him in a hand-carved cradle he keeps in the stable loft,
  unused, against the day Maeve needs it back. (Maeve ↔ Roan bridge.)
- **Lyra is Maeve's chosen successor.** Maeve is teaching her the
  Longnight Vigil ritual one candle at a time. Neither has said the word
  *Elder* aloud. (Maeve ↔ Lyra bridge — strong hook for Lyra's eventual
  backstory file.)
- **Bram brings Maeve a Longnight Vigil stew** that Maeve sets out for
  the Hollow King; the cat eats it. Bram knows. This expands the Vigil
  tradition first seeded in `smith_edda.md` — Bram's Vigil-stew round
  goes Edda → Maeve, and is now a canonical village ritual, not a one-NPC
  detail. (Bram ↔ {Edda, Maeve} bridge.)
- **The Stag-Court once offered Maeve a seat at the Antler Crown** for
  the price of one mortal year remembered backwards. She declined. She
  believes the offer is still open. *This thread is sealed-room canon:*
  it must NEVER be spoken in a Maeve dialogue line, only ever surfaced as
  a codex fragment after the player has reached the Crystal Caves (a
  *thirre*). Future writers please respect the withholding — it is the
  point of the character.
- **Maeve's hawthorn walking stick** is canonized as a censusing artifact
  carrying 111 ringed knots — one per Briarwood-born child since she
  became Elder. Knot 37 is Halsa, knot 62 is Edda. A future codex entry
  *"Maeve's Knot-Stick"* is hooked.
- **Honeysong Eve and Longnight Vigil** are now both anchored to Maeve
  as their ritual-holder. The Calendar entries in `world.md` should
  henceforth be read as *Maeve's calendar* in any future flavor pass.

### Withholding ledger (do-not-surface canon)

These canonical facts are *intentionally* never to be spoken by the NPC
in dialogue. They live in the .md as story fuel and may surface only via
codex entries, third-party narration, or other NPCs' lines.

- Maeve's Stag-Court offer (Antler Crown). Codex-only, post-Crystal-Caves.
- Aelis (Maeve's daughter). Mentioned only via Mara's unopened letter
  arc, never directly by Maeve.
- Cailen (Maeve's brother). Maeve has not spoken his name since
  *kerritha-ing* his pressed heather; her dialogue tree must not put it
  in her mouth.

### Hooks queued for future runs

- **`Cailen's Horseshoe` quest** (Maeve → Stone Crown rider passing
  through, or burial at Foxthaw on the High Road). Reward: a knot carved
  into Maeve's stick *for the player.* No other in-game reward needed.
- **Mara's unopened-letter turn-in** (a Maeve-and-Lyra-only scene; do
  not surface in casual repeat-talk).
- **Maeve's Knot-Stick** as a discoverable codex object.
- **Bram backstory** is now strongly seeded — his Vigil-stew round and
  his quiet knowing about both Edda's saber and Maeve's letter make him
  the village's *quiet keeper*. Priority candidate for the next NPC
  backstory.

---

## Lore Run — 2026-05-04 (Innkeeper Bram)

### NPC backstories (`lore/npcs/`) — added this run

| NPC            | File                              | Dialogue tree                                  | Status |
|----------------|-----------------------------------|------------------------------------------------|--------|
| Innkeeper Bram | `lore/npcs/innkeeper_bram.md`     | `data/dialogue/innkeeper_bram.json` (16 keys)  | drafted; awaiting Builder wiring |

### Old Faerie glossary — additions

Three new canonical words enter the language. They sit alongside *thirre*,
*ai-velin*, *kerrithen* (`world.md`); *haethe*, *unnen* (`smith_edda.md`);
and *vael-tor*, *thressa-mai* (`elder_maeve.md`). Future writers should
reuse these before inventing new ones.

- **`vethar`** *(innkeeper_bram.md)* — the candle in the window; a small
  light kept burning for someone whose road has not ended. Erris-keyed.
  Bram has lit one in the front window of the Long Lantern every night
  for nine years.
- **`haisten`** *(innkeeper_bram.md)* — the song with no last verse; a
  story whose teller stopped before the end — by death, by distance, by
  grief, or by *kerrithen*. Bards know the word. Innkeepers learn it.
- **`breos`** *(innkeeper_bram.md)* — what the bowl remembers; a place
  many lives have passed through and been fed. The Long Lantern is
  *breos*. So is the road.

### Cross-references seeded this run

- **The Long Lantern** is now the canonical name of Briarwood's inn.
  Environment may carve a hand-painted wood-and-iron sign with a small
  lantern motif over the front door. The lit candle in the front window
  is a per-night flicker prop (Motion §12 — never static).
- **Caedr**, Bram's missing road-singer husband, is now seedable as a
  bardic codex narrator (same convention as Halsa-as-narrator in
  `smith_edda.md` hooks): present-tense voice, no body, no death
  confirmed. Walked into the Whisperwood on a Honeysong Eve eight in-
  world years ago following a song-debt to the Antler Crown — present-
  tense per herbalist canon ("not, the herbalists insist, *gone*").
  Lyra is the herbalist who tells Bram this in those exact words. Both
  of them are lying to each other. Both of them are right.
- **Bram's Vigil-stew round Edda → Maeve.** The Maeve canon's stew-drop
  detail is now bilateral: Maeve sets the bowl out for the Hollow King
  and the cat eats it; Bram knows; he brings it anyway. The round is a
  *village ritual,* not a one-NPC kindness. (Bram ↔ {Edda, Maeve} bridge
  closed.)
- **Bram is the second in-village witness to Mara's water-stained
  returned letter** (`elder_maeve.md`, Withholding Ledger). He saw it
  fall from Mara's coat pocket two springs ago, saw the unbroken seal,
  saw her face, and refilled her cup without comment. He has not spoken
  of it and will not. Future writers MUST NOT have Bram surface this in
  dialogue — he is its keeper, not its caller. (Bram ↔ Mara bridge —
  *kerrithen*-typed, same shape as Bram ↔ Edda's saber.)
- **Bram knows about Smith Edda's saber.** His `boss_slain` line is
  pre-tuned to *non-confirm* on the same in-game day Edda's fires. The
  most he will ever say is *"Some debts get paid in iron, friend."*
  Builder may co-fire both for the village's quietest two-person scene.
- **Roan's road-name for Bram is "Bron."** Roan was Bram's horse-boy on
  a single shared route nine years ago, before either came to this
  valley. Reserved for Roan's future warmed dialogue variants — no
  other NPC may use the name. (Bram ↔ Roan bridge.)
- **Lyra leaves dreamleaf at Bram's back door every Longnight Vigil.**
  Bram does not sleep on Longnight; he gives the dreamleaf to the
  eldest traveler in the common room. Both know. Neither says.
  Reserved as a candidate consequence for a future Lyra-Bram quest with
  a `bram_holds_vigil` flag. (Bram ↔ Lyra bridge.)
- **Hala and Bram argue, gently, about whether a blade is a tool or an
  oath.** They have argued the same argument for nine years and neither
  has moved an inch. Reserved as a future warmed-dialogue hook on Hala's
  side; Bram's side is in the `lore_notes` of his dialogue file.
  (Bram ↔ Hala bridge.)
- **Triptych staging on Longnight Vigil.** Edda, Maeve, and Bram now all
  ship a `longnight_vigil` mood-key. Bram's line opens with *"Edda's
  forge first. Always Edda's forge first."* — the *first* is the
  textual cue that the round continues to Maeve. If Builder ever
  co-fires all three lines on the same Longnight tick, the village's
  quietest scene plays itself across three thresholds with no
  scripting beyond mood-key resolution.

### Withholding ledger (do-not-surface canon)

- **Caedr's name in Bram's mouth, unprompted.** Bram never names Caedr
  aloud unless the player has reached a sufficiently warm relationship
  *and* asks specifically. He will say *vethar*; he will not say
  *Caedr*. Codex-only beyond that gate.
- **The contents of Mara's letter.** Bram saw it. He did not read it.
  Even if he had, he would not say. Future writers must respect the
  withholding — same shape as Maeve's Stag-Court offer. The letter is
  Mara's to give, not Bram's to surface.
- **The last verse of Caedr's song.** `bram_last_verse_offered` is
  reserved as *intentionally unresolvable.* Closing it would violate
  THEME.md §7. Future writers MUST consult §7 before touching this loop.

### Hooks queued for future runs

- **Honeysong Eve quest** (Bram → fetch one `paper_lantern` for "someone
  whose road has not ended"). Reward: `bram_road_knife` (sentimental
  flavor item — the only blade Bram still owns from his bard days,
  dulled, +1 luck flavor not stat). Quest text never names Caedr.
- **The Last Verse side-quest.** A traveling NPC sings a tune the
  player can carry to Bram. Bram refuses to use it. Quest *completes*
  but Bram never confirms. World flag `bram_last_verse_offered` records
  the offer; nothing reads from it. (Intentional.)
- **Caedr as bardic codex narrator** for codex pages on Erris, the
  road, the Antler Court, and the shape of an unfinished tune. Use
  same convention as Halsa-as-narrator: present-tense, no body.
- **`bram_holds_vigil`** as a Lyra-readable Bram flag, set by a future
  Lyra-Bram Longnight-eve quest exchanging the dreamleaf bundle.
- **`bram_letter_acknowledged`** as a one-line Bram reactive on the day
  Mara finally turns her letter in (canonically expected: to Edda for
  keeping). Short, dry, no Aelis name.
- **The Long Lantern interior** as an Environment build target — common
  room with hearth, copper coin balanced on the lintel above the front
  door (Erris offering, swept and replaced), front-window candle
  flickering nightly, three small leather notebooks on a back shelf
  (Bram's verse-attempts — Environment may model them as world-readable
  examinables tied to a future codex page).

---

## Lore Run — 2026-05-05 (Herbalist Lyra)

### Artifact shipped

- `eldoria-godot/lore/npcs/herbalist_lyra.md` — Lyra's full backstory:
  birth as the 89th knot on Maeve's stick; mother **Wennet** (the
  village's previous herbalist) dead of lung-fever in Sunpetal Lyra was
  eight; village raising at Bram's inn, Maeve's hearth, Edda's mortar,
  Roan's slow horse, Hala's gentle defensive forms; the four Whisperwood
  years apprenticed to **Aenwyn**, who taught her *mossaen*, the
  seventeen unlisted herbs and the four wrongly-listed ones, that the
  Crystal Caves are a *thirre*, that the Whisperwood goblins are
  faerie-descended, and that the Stag-Court hears every herb-name
  spoken at midnight inside the deeper Whisperwood; Aenwyn's parting
  gift of the green-dyed coat at the eastern Foxthaw of the fourth
  year; Lyra's wound — **Tess Brookhollow** dying in her lap two
  springs ago of a marsh-fever broken too late by fen-foxglove from the
  southern marsh-edges; Lyra's secret — she still hears the *listening*
  in Foxthaw fox-fire, has answered once at twenty-three, wrote down
  one Old Faerie word in the back of her herb-book and has not in six
  years looked it up; what she wants — to not be the last reader of
  the Whisperwood in Briarwood; her relationships to all six other
  NPCs, including the bilateral closure of Bram's "not gone" line and
  the canonical pairing of Edda's *unnen* cleavers with Lyra's
  *wennen* marshmint as the village's most exact small mutual gift.

- `eldoria-godot/data/dialogue/herbalist_lyra.json` — Lyra's
  mood-keyed surface, tree shape mirroring `smith_edda.json`,
  `elder_maeve.json`, and `innkeeper_bram.json` exactly so NPC.gd
  reads all four through a single code path. Two seasonal slots:
  `greenshield_first_pick` (Lyra's annual heart's-ease + dogwort
  delivery to Maeve) and `tess_remembrance` (Sunpetal 7 — the
  shortest line in her tree, herb-shed door closed; the brevity is
  the grief and Builder MUST NOT extend it).

### Old Faerie words seeded this run

Three new words enter canon, joining *thirre*, *ai-velin*, *kerrithen*
(`world.md`), *haethe*, *unnen* (`smith_edda.md`), *vael-tor*,
*thressa-mai* (`elder_maeve.md`), and *vethar*, *haisten*, *breos*
(`innkeeper_bram.md`):

- **`mossaen`** *(herbalist_lyra.md)* — the listening you do with both
  hands in the dirt. Not magic; attention. The herbalist's first
  practice and her last one. The mountain clans are said to use the
  same word in Stone-Tongue for the listening a stoneworker does to a
  granite face before the first chisel-stroke. Aenwyn taught it.
- **`thalen-ai`** *(herbalist_lyra.md)* — the herb that grows where
  it is needed. The herbalist's working faith — that the right plant
  comes up in the right place at the right time, if the land trusts
  the gatherer. Lyra has reluctantly found it mostly true.
- **`wennen`** *(herbalist_lyra.md)* — to leave something growing for
  someone else to find. Not a gift; a faith. The word is one letter
  from Lyra's mother **Wennet's** name. **Lyra has not consciously
  noticed.** Maeve has. Bram has and assumes Lyra knows. The
  unconscious naming is canon and surfacing it kills it — see
  Withholding ledger below.

### Cross-references seeded this run

- **Lyra is the 89th knot** on Maeve's hawthorn walking-stick. (Edda
  is 62nd. Halsa is 37th. Lyra does not know this and Maeve will not
  say.) Maeve carved it with her thumb still slightly bandaged from
  the cutting because Wennet had asked her to.
- **Maeve washes the dead's hair the way they wore it living.** The
  pattern is now canonical across three deaths: **Halsa** (`smith_edda.md`),
  **Wennet** (`herbalist_lyra.md`), **Tess Brookhollow**
  (`herbalist_lyra.md`). Future writers may use this as a Maeve-rite
  on any future canonical Briarwood death without re-explaining.
- **The Vigil round on Longnight is a quartet, not a triptych.** The
  full ordered round is now Edda's forge → Maeve's hearth → Bram's
  back door → Lyra at the well, with Lyra carrying the dreamleaf
  bundle and naming the whole sequence in her `longnight_vigil` line.
  If Builder co-fires all four lines on the same Longnight tick, the
  village's quietest scene plays itself across four thresholds with
  no scripting beyond mood-key resolution. Lyra's *vael-tor-i* call
  mirrors Maeve's older we-form — the apprentice has begun to sound
  like the teacher.
- **Edda's *unnen* + Lyra's *wennen* are now the canonical
  village-pair example of both words.** The cleavers Edda sends Lyra
  every Foxthaw are *unnen* (Edda has not called them that aloud).
  The marshmint Lyra leaves at the forge door every spring is
  *wennen* (Lyra calls it that only in her head). Cleaner than either
  NPC's individual canon. Codex pages teaching the words may quote
  this pair.
- **Bram's "not gone" line is now bilateral.** Bram canon already
  named Lyra as the herbalist who said it; Lyra canon now names the
  moment — the Honeysong after Caedr walked into the Whisperwood,
  said as a kindness more than a truth, not repeated since. Both of
  them are lying to each other. Both of them are right.
- **The `pelt_for_lyra` salve recipient is canonized as Roan.**
  Lyra has decided alone that the salve will be made and that Roan
  will receive it without ceremony in a small clay jar at his stable
  door. Lyra never names him. Future writers wiring the turn-in MUST
  NOT have Lyra say who the salve is for. The withholding is the
  kindness. A `roan_received_salve` flag is reserved for Roan's
  future warmed dialogue.
- **Roan's slowest horse** is now canon-touched in three NPC files
  (Maeve, Edda, Lyra). The slowest is the one Lyra rode the night of
  the fen-foxglove. By Lyra's preference, it is never named —
  naming a horse a person has ridden hard in grief is, in the older
  tongue, *kerrithen*-shaped. Roan's other horses, when his backstory
  ships, may be named freely. Not this one.
- **The Whisperwood goblins are faerie-descended** is now canonized
  inside the village's knowledge — Aenwyn told Lyra directly. Lyra is
  the only NPC in the village who knows. She has not told anyone. She
  would tell Maeve if asked. She has not been asked. (The hint in
  `world.md` → The Tongues — *"the Whisperwood goblins were once
  something else before the Sundering"* — now has an in-village
  knower.)
- **The Crystal Caves as *thirre*** is now canonized inside the
  village's knowledge — Aenwyn taught Lyra. Lyra knows certain plants
  only grow at the gentle edges of *thirre*-places. Strong codex
  hook for Priority-5 (a *Whisperwood Herbal* page narrated by
  Aenwyn).
- **Lyra ↔ Maeve bridge:** chosen successor; Vigil-rite teaching one
  candle at a time; the unanswered third question about the forest
  reserved for the day Maeve dies; the *wennen*/Wennet resonance
  that only Maeve has noticed and only a late Maeve dialogue moment
  may surface.
- **Lyra ↔ Edda bridge:** *unnen* cleavers / *wennen* marshmint
  mutual gift; Edda taught Lyra to grind a mortar evenly when Lyra
  was nine and Edda was nineteen and three months earlier
  motherless; Lyra remembers, Edda has forgotten, Lyra will not
  remind her.
- **Lyra ↔ Bram bridge:** dreamleaf at his back door every Longnight;
  the "not gone" line said once after Caedr's Whisperwood walk; the
  back hearth Bram banked too high the night Tess died, never used
  to bank a fire that high since.
- **Lyra ↔ Mara bridge:** southern-honey jar every spring (empty at
  Reapmoon, full again at Greenshield, left at the meadow-edge for
  the Hollow King's ants on Sunpetal 7); Lyra suspects Mara is
  carrying something she cannot put down (the unopened letter).
  Lyra is willing to wait.
- **Lyra ↔ Roan bridge:** he saddled the slow horse the night of
  the fen-foxglove; he brought her the folded cloak the morning
  after; she patches his hands when the horses bite; he is the
  only person besides Maeve who knows by Lyra's face when she is
  hearing the older tongue; she will give him the salve without
  ceremony.
- **Lyra ↔ Hala bridge:** they walk to the meadow at every planting
  moon; Hala digs, Lyra names; Hala has tried twice to teach Lyra a
  defensive form and Lyra has gently declined; they are the
  village's two slowest walkers, and they walk together because the
  pace matches.

### Withholding ledger (do-not-surface canon)

- **Lyra's *listening*** — the older tongue she still hears when
  Foxthaw fox-fire kindles. NEVER spoken to anyone. Codex-only via
  the Aenwyn-narrator track.
- **The unread word at the back of her herb-book.** Reserved for a
  late-game codex unlock (gated on Crystal Caves *thirre* + sufficient
  *mossaen* exposure). The codex page may NAME the word. The codex
  page MUST NOT translate it. Translation belongs to the Stag-Court.
- **Lyra's suspicion that the unread word is the Stag-Court's
  offer-word** — not surfaced until Maeve's third question is asked
  aloud and answered. Future writers MUST NOT close this loop without
  Maeve having earned it.
- **The salve recipient on the `pelt_for_lyra` turn-in is Roan.**
  Lyra never names him in the line. Future writers MUST NOT have
  Lyra surface this. The withholding is the kindness.
- **Tess Brookhollow's name** — appears nowhere in Lyra's spoken
  lines except inside the `tess_remembrance` slot itself, which is
  intentionally the shortest line in her tree: *"Not today,
  traveler. — Tomorrow."* Builder MUST NOT extend it. The brevity
  is the grief.
- **The *wennen* / Wennet resonance** — Lyra has not consciously
  noticed. Maeve has. Bram has and assumes Lyra knows. Reserved for
  a single late MAEVE dialogue moment after Maeve has answered
  Lyra's third asking. NOT Lyra's. NOT Edda's. NOT Bram's. Maeve's
  only.

### Hooks queued for future runs

- **Greenshield first-pick visit** — `seasonal_event:
  greenshield_first_pick` flag reservable for Builder. Stacks safely
  with Maeve's morning line; Maeve's tone softens.
- **Tess anniversary** — `seasonal_event: tess_remembrance` flag,
  Sunpetal 7. Herb-shed door closed; one short line; no fallback.
  No quest, no mechanic, no XP, no item. Honor it.
- **Fen-foxglove side-quest (gentle)** — a future Sunpetal child-fever
  event in the village (NOT Tess again — a new child, named) where
  Lyra has the fen-foxglove growing this time. Reward: nothing in
  the bag. The reward is the child surviving. World flag
  `briarwood_keeps_a_child` set. Lyra acknowledges with the
  *thalen-ai* line — *"the land trusted us this season."* THEME §7
  test for the agent who picks this up.
- **The unread word codex unlock** — late-game, gated on Crystal
  Caves *thirre* + *mossaen* exposure. Names the word; does not
  translate it.
- **Aenwyn as bardic / herbalist codex narrator** — same convention
  as Halsa-as-narrator (`smith_edda.md`) and Caedr-as-narrator
  (`innkeeper_bram.md`): present-tense voice, no body, no death
  confirmed. Natural narrator for the *Whisperwood Herbal* codex
  (Priority-5).
- **Lyra inherits the Vigil — the day Maeve dies.** `world_flag:
  lyra_inherits_vigil` reserved post-Crystal-Caves, gated on Maeve's
  third-question loop being closed. If not closed, the hawthorn
  knot-stick goes to Edda first; Edda refuses it and gives it to
  Lyra anyway. Quieter scene.
- **Roan's salve** — `npc_flag: ["Stablemaster Roan",
  "received_salve"]` set on `pelt_for_lyra` turn-in. Roan's future
  warmed dialogue may carry one line that does not name Lyra and
  does not name the salve.
- **The *wennen* / Wennet resonance** — reserved for a single late
  Maeve dialogue moment after the third-question loop closes.
- **Quartet staging on Longnight Vigil.** Edda, Maeve, Bram, AND Lyra
  now all ship a `longnight_vigil` mood-key. If Builder co-fires all
  four on the same Longnight tick, the village's quietest scene
  plays itself in order — Edda doesn't look up, Bram brings the stew,
  Maeve sets it for the Hollow King, Lyra carries the dreamleaf to
  the well. No additional scripting required beyond mood-key
  resolution.

## Renown — first-class scalar (run 11)

`World.player_renown: int` is now a first-class field. It is a strict
function of `unlocked_achievements`: each achievement awards renown equal
to its `title_priority` (10 / 30 / 40 / 50 / 100). The Warden of Eldoria
unlock alone trips the default `high_renown` threshold (100) and lights
up four authored JSON lines (Maeve, Edda, Bram, Lyra) in the same
session. HUD RenownLabel sits below GoldLabel, scale-pulses 0.45s on every
gain (THEME §12). `gain_renown(amount, source)` is the only public
mutator; it clamps min 0, toasts positive deltas, and re-evaluates
achievements at the end. `_recompute_renown_from_achievements()` is the
idempotent rebuild path for any future save/load work — no drift between
sessions because the integer is derived, not stored independently.

Lyra's `data/dialogue/herbalist_lyra.json` was simultaneously opted into
the JSON-tree resolver in run 11 (`use_json_dialogue:true` flip in
WorldBuilder.gd NPCS). She is now the fourth opted-in NPC and the FIRST
to have her `high_renown` line ("Mara mentioned a name on her last
circuit. So did Roan…") become reachable on the renown side.
---

## Run history — Lore (2026-05-05, run 9)

### Mara the Merchant — backstory shipped (`lore/npcs/mara_merchant.md`)

Fifth of seven canonical NPC backstories. First non-Briarwood-born
character in the file set. Anchors the southbound side of the village's
`mhairen` ledger and the courier vector that connects the Iron Crown,
Cinder Reach, and the High Steppe to the Briarwood player-loop.

#### New facts entering canon

- **Mara is from Cinder Reach**, a courier-town three weeks south of
  the Briarwood signpost on the road to the Iron Crown's smoke-cities.
  Cinder Reach is now a named-but-offstage trade origin reservable for
  southern goods (salt, southern honey, bonded wax, spice-tin contents,
  courier-grade oilskin).
- **Yew-and-Lantern** is Mara's family courier-house, three generations
  deep (grandmother **Reseda**, mother **Yula**, Mara). The
  red-kid-leather routes-book in Mara's satchel is the canonical
  artifact; last entry is 28 years out of date in Mara's own hand.
- **Nessa**, Mara's older sister, rode the High Steppe a third time on
  a Honeysong and did not return. A water-stained returned letter came
  back two springs later in a stranger's hand, addressed to a stranger,
  re-sealed in a wax not the family's. Mara has carried that letter
  unopened for thirty-one years. *(The first letter.)*
- **The High Steppe vector now takes three Briarwood-adjacent
  characters:** Cailen (Maeve's brother), Nessa (Mara's sister), and
  the two rides Roan made hunting word of Cailen. The Stone Crown is
  reaffirmed as a vector of loss for the village. Mara has not, in
  twelve years, confessed the parallel to Maeve. Maeve has not asked.
  Both of them know.
- **Mara's water-stained returned Aelis-letter is canonically the
  *second* such letter she has held.** The first is Nessa's,
  thirty-one years unopened. Both ride in her satchel on opposite
  sides of the spice-tin. *They must not touch.*
- **Mara came to Briarwood twelve years ago** because the Iron Crown's
  couriers had stopped being honest. Greenshield evening, walked the
  cart past the signpost, smelled woodsmoke and pond-mint, did not
  walk back out. The cart sleeps in **Roan's stable loft** — axle-mended
  twice, oiled by Roan every Reapmoon unasked, paid-loft-rent for nine
  years.
- **Mara invokes Erris of the Two Roads** — copper coin on the awning-
  post (never blown off, even in the Wolfwake gales), under-breath
  thanks at every closed sale, lantern-to-lantern idiom. She does NOT
  invoke the Hollow King. The first letter came back in his season.
- **Mara is the southbound half of the southern-honey jar ritual.**
  Lyra leaves the empty jar at Reapmoon's last day; Mara fills it from
  southern apiaries on her southbound route; Mara walks the full jar
  back on the first Sunpetal morning to the meadow-edge stone for the
  Hollow King's ants on Sunpetal 7. Both `mara_jar_returned`
  (Sunpetal 1) and `lyra_jar_emptied` (Reapmoon last day) are now
  reservable seasonal world-flag pulses.
- **Mara stocks Trainer Hala's hand-bound practice cudgels** — a row
  of six against the back wall of the stall, restocked twice a year.
  Neither is sure who is selling them to whom. New bridge; first
  Hala-side detail entering canon ahead of Hala's own backstory file.

#### Bridges added or deepened

- **Mara ↔ Maeve bridge:** Lambmoon letter southbound; water-stained
  letter northbound; Foxthaw tea at Maeve's hearth (the kind two old
  women drink when one is keeping a thing for the other); the
  twelve-year postponement of one long quiet conversation about roads
  and silences.
- **Mara ↔ Edda bridge:** Mara buys Edda's *seconds* in honest coin
  at full price, never haggles. Mara has decided — though not yet
  acted — that **Edda is the canonical eventual keeper of the
  water-stained letter.** Edda's tongs are the destination.
- **Mara ↔ Bram bridge:** Bram is the second in-village witness to
  the second letter. He saw it fall, saw the unbroken seal, saw her
  face, refilled her cup. He fills her tankard a finger lower than
  the rest of his guests because she always pays the same and he
  wants her to feel looked-after, not measured. She knows. Both of
  them are *kerrithen-*shaped about it, the same shape Bram and Edda
  share.
- **Mara ↔ Lyra bridge:** the southern-honey jar ritual is now fully
  canonized as a year-loop. Lyra opens satchels the way Reseda did
  (pinch from the bottom, never the top). Lyra is the only person
  Mara suspects might one day be ready to receive the routes-book.
  Mara has not yet asked. Lyra knows she has not asked.
- **Mara ↔ Roan bridge:** the courier-cart in Roan's loft, axle-mended
  twice, oiled every Reapmoon unasked, paid-rent for nine years and
  unloaded for none. A canonical *kerrithen* pairing — Roan keeps
  the cart the way Maeve kept Halsa's cradle. Morning head-tips
  across the cobble path.
- **Mara ↔ Hala bridge (new):** the cudgel row of six. Mara stocks
  them, neither knows who sells them to whom, both seem to need the
  row to exist. First seed of a withholding the Hala backstory file
  may carry forward. Reservable flag: `cudgel_row_acknowledged`.

### Withholding ledger (do-not-surface canon)

- **Nessa's name in Mara's mouth** — never spoken aloud to any
  living person. Future writers MUST NOT have Mara say *Nessa* in
  dialogue, in quest text, or in turn-in lines. The name may
  surface in a Reseda-as-narrator codex page and nowhere else.
- **The first letter (Nessa's)** — stays in the satchel forever.
  NOT a turn-in, NOT a quest reward, NOT a discoverable codex
  object. The withholding is the character.
- **The second letter (Aelis's) turn-in** — to Edda for keeping,
  one canonical day, witnessed only by Maeve and Lyra, with Bram's
  pre-tuned reactive in the background. The letter is NEVER opened
  in-game. Edda receives it, sets it on the highest forge shelf
  next to her mother's tongs, and does not open it either. The
  withholding is the kindness.
- **What is in either letter** — Bram saw the seal of the second;
  he did not read it. No one in Briarwood knows. No one in
  Briarwood will. The contents are intentionally unwritable.
- **The *pendrel* coin's intended recipient** — Mara does not know.
  The text MUST NOT decide for her. Even the warmest-tier dialogue
  unlock must leave the recipient open. *"For someone who has not
  yet asked"* is the canonical formulation.
- **The Mara/Maeve High-Steppe parallel** — Mara has not in twelve
  years told Maeve about Nessa. Maeve has not asked. Both know.
  Future writers MUST NOT have either of them surface this in
  dialogue. The parallel may be eligible for a Reseda or
  Caedr-style narrator codex page, but only after the Aelis
  letter turn-in has shipped.

### Hooks queued for future runs

- **Mara `mara_merchant.json` dialogue tree** — priority-3 next
  for the Lore agent. Tree-shape mirrors `smith_edda.json` and
  `innkeeper_bram.json`. Seasonal slot: `sunpetal_first_morning`
  (the honey-jar walk; line must not name Lyra or the Hollow King).
  Village-wide `longnight_vigil` line closes the **Vigil quintet**
  — Edda doesn't look up, Bram brings the stew, Maeve sets it for
  the Hollow King, Lyra carries the dreamleaf to the well, Mara
  holds the candle from the stall. The Mara line cues *"Bram's got
  the stew round"* as the textual relay that the round continues.
- **Mara-issued `lost_courier_pouch` quest** (kind: fetch). Reduces
  a future `whisperwood_bandits` faction pressure (when bandits
  ship); reward: `yew_and_lantern_brass_token` flavor item;
  consequence flag: `first_pouch_returned`. Use sparingly — Mara is
  not yet ready to ask anyone to ride for her.
- **The water-stained letter turn-in scene** — Maeve-and-Lyra-only
  witnesses; Bram's `bram_letter_acknowledged` reactive in the
  background; Mara says *"a thing kept too long, and a place to
  set it down"* and Edda receives it without speaking. The letter
  goes on the highest forge shelf next to Halsa's tongs. Future
  writers MUST consult `elder_maeve.md` Withholding Ledger,
  `innkeeper_bram.md` cross-canon, AND `mara_merchant.md`
  Withholding Ledger before touching this loop. The first letter
  (Nessa's) does NOT turn in — that is the point.
- **The *Yew-and-Lantern* routes-book as a discoverable codex
  object.** Red kid-leather, last entry 28 years out of date in
  Mara's hand. Codex page may surface Reseda, Yula, the twenty
  stables, the four scribe-houses; MUST NOT surface Nessa.
- **Reseda-as-narrator codex track** — same convention as
  Halsa-as-narrator (`smith_edda.md`) and Caedr-as-narrator
  (`innkeeper_bram.md`): present-tense voice, no body, no death
  confirmed. Natural narrator for codex pages on Erris, the
  long-road, courier-craft, and (post-Aelis-turn-in only) the
  High-Steppe-loss parallel.
- **Honeysong Eve pond pairing with Bram** — both set paper
  lanterns from opposite banks; do not cross; do not speak; nod
  once. Never name Nessa or Caedr in the scene.
- **The *pendrel* coin-row** as a stall environmental detail —
  bronze fox-and-mark coin + column of coppers beside it,
  quietly lit by stall lantern. Polisher-flag: do not animate
  the column knocking over.
- **Seasonal honey-jar prop placements** at the meadow-edge stone:
  empty during Reapmoon, full during Sunpetal week one. Same
  cadence as Maeve's hawthorn knot-stick prop.
- **Cinder Reach** as a named-but-offstage trade origin. Mara's
  stall inventory may flavor any southern good as
  Cinder-Reach-shipped.
- **`mara_jar_returned`** (Sunpetal 1) and **`lyra_jar_emptied`**
  (Reapmoon last day) as reservable seasonal world-flag pulses.
- **Quintet staging on Longnight Vigil.** With Mara's line, all
  five Briarwood NPCs with backstory files now ship a
  `longnight_vigil` mood-key. The full ring (Edda → Bram → Maeve →
  Lyra → Mara) plays itself across five thresholds with no
  scripting beyond mood-key resolution. Builder hook: co-fire on
  same Longnight tick.

### New Old Faerie words

- ***pendrel*** *(PEN-druhl)* — "the third coin in the till that
  does not belong to the day's count." Set aside for someone who
  has not yet asked. The merchant's *kerrithen.*
- ***mhairen*** *(MAR-en)* — "what the satchel carries that is not
  for sale." Things a courier holds in trust.

Total Old Faerie lexicon now 10 words: *thirre, ai-velin, kerrithen*
(world.md); *haethe, unnen* (smith_edda.md); *vethar, haisten,
breos* (innkeeper_bram.md); *pendrel, mhairen* (mara_merchant.md).
Lyra's file did not seed new words; it composed against the
existing eight. Future NPC files (Roan, Hala) should aim for 1–2
new words each, keeping the lexicon growing at roughly the cadence
established here.


---

## 2026-05-05 — Briarwood NPCs become mobile (Builder run 11)

The seven Briarwood villagers now move between role-specific anchors
across the day. Midday default still matches every existing
WorldBuilder spawn pos, so prior dialogue lines that say "I'm at the
forge" / "by the well" / "at the inn" still tell the truth at midday.
The other three buckets describe new lived-in beats.

| NPC                  | Morning                                | Midday (default)              | Evening                              | Night                                |
|----------------------|----------------------------------------|-------------------------------|--------------------------------------|--------------------------------------|
| Elder Maeve          | At the well, blessing the day          | At her hut (6, 3)             | At the hearth, telling stories       | At her hut door, watching the road   |
| Smith Edda           | Fanning coals at the forge             | Forge, peak hammer            | Forge, finishing strikes             | Quenching trough, banking the fire   |
| Mara the Merchant    | Setting up the market stall            | Stall (selling)               | Counting coin near her hut           | At the inn (drinks with Bram)        |
| Herbalist Lyra       | Foraging at the treeline (-7.5, -7.5)  | Hut (-3, -5), grinding herbs  | Hut, brewing                         | Hut, sleeping                        |
| Innkeeper Bram       | Sweeping the inn doorstep              | Inn, polishing mugs           | Inn, peak service                    | Inn, banking the hearth fire         |
| Stablemaster Roan    | Brushing horse outside the stable      | Stable (-10, -2)              | Leading the team in                  | Stable, lantern lit                  |
| Trainer Hala         | Field forms                            | Field, peak training          | Lantern-side practice                | Field watch                          |

### High-leverage observables (the moments that make the village feel real)
- **Mara joins Bram at the inn at night.** Without schedules she was
  stuck at her stall with no customers — now she walks ~12m east to
  the inn at 21:00 and Bram's inn-night line ("Bards lie about half
  their songs.") plays to an audience.
- **Lyra walks to the treeline at dawn.** Her morning dialogue
  variant — *"Four wolf pelts for a healing salve — wolves are bolder
  at dawn, mind."* — is now spoken AT the treeline where wolves spawn.
  Spatial truth matches dialogue truth.
- **Maeve sits at the hearth in the evening.** The hearth is at
  (0, -2), 6m southwest of her hut. Her evening line previously said
  "Tea by the hearth?" while she stood 6m from the hearth. Now she's
  there.
- **Edda's micro-shifts.** Never strays more than 1m from the forge —
  she's the smithy. Motion sells dedication rather than relocating her.

### Compounds with parallel-builder's run-11 player_renown
- All four JSON-opted NPCs (Maeve, Edda, Bram, Lyra) now have:
  - JSON-tree dialogue resolution (existing)
  - `high_renown` predicate that fires (parallel-builder run-11)
  - Spatial position truth (THIS run)
- Lyra's `high_renown` line is reachable AT the treeline at dawn or AT
  her hut at midday — wherever the player crosses her path with
  `unlocked_achievements.size() >= 4`. The line "Mara mentioned a name
  on her last circuit" plays in two distinct settings depending on
  when the player meets her.

### Quartet on Longnight Vigil (queued)
Edda, Maeve, Bram, AND Lyra all ship a `longnight_vigil` mood-key in
their JSON trees (run-10 lore). With schedules in place, a future
festival hook can route all four to the well at vigil time — the
village's quietest scene plays itself with the quartet visibly
converged. No additional scripting beyond a one-shot `schedule_anchors`
swap during the vigil window.

### What schedules do NOT do (yet)
- No walk-anim swap. NPCs play their idle anim while moving. Polisher
  hook documented for next run.
- No path-aware avoidance. Schedule walker is straight-line lerp;
  anchor positions chosen to avoid current fences.
- No festival overrides. Schedule is uniform across all in-game days.
---

## Run: Lore Keeper — 2026-05-05 — Stablemaster Roan backstory

**Artifact shipped:** `eldoria-godot/lore/npcs/stablemaster_roan.md`
(~470 lines). Roan was the sixth-of-seven Briarwood NPC without a
backstory; he is now canonized.

### What is now canon (load-bearing)

- **Roan was born in Briar's Run**, a one-stable hamlet on the lower
  lip of the High Steppe — eight families, four riders, four
  craftspeople. Parents **Tael (saddler)** and **Eithne (colt-gentler)**
  died of the same chest fever the winter Roan was eleven, two days
  apart, and lie in a single Steppe-rite Long Mound at the
  *thirre*-stone above Briar's Run. He rode a courier-string out of
  Briar's Run for nine years before walking into Briarwood twelve
  years ago. The previous Briarwood stablemaster was **Daire**, who
  had died unattended the Foxthaw before. Roan opened the empty
  stable, oiled the doorpost, and lit the gate-lantern that has not
  moved since. The lantern shutter holds a copper coin for **Erris of
  the Two Roads** — Roan's unspoken patron, renewed every Sunpetal.
- **Roan was Cailen of Briarwood's friend at nine.** Cailen stayed
  three weeks at Roan's parents' courier-house on his way to the
  Stone Crown, taught Roan a Steppe halter-braid, and lent Roan a
  small fox-carved Steppe whetstone Roan still keeps in his left
  coat pocket every day. Twelve years ago Roan recognized Cailen's
  horseshoe above Maeve's hearth and asked Maeve quietly if he could
  ride for word of him. He rode the High Steppe twice — both empty —
  and brought back, on the second ride, a single Steppe-iron nail
  hammered now into the lintel above the stable door. The nail is
  **withheld** as a quest object (see below). Roan has decided he will
  not ride a third time *for Maeve.* The third *maelorn,* if it
  comes, is to take Cailen's whetstone home to the Long Mound, and
  it is off-page.
- **The cradle in Roan's loft.** Hawthorn, ringed-knot at each corner
  (same carving cadence as Maeve's stick), brought to Roan by Maeve
  the third summer he was in Briarwood after his second empty ride.
  It is *ostren* — a kept stall — and is for Maeve, not Roan. Above
  it Roan has hung an **oilskin curtain** that breaks the loft
  window's light on the Foxthaw evenings the **Stag-Court's** fox-fire
  kindles. He believes he is breaking the evening light. He is not.
  This is the canonical Roan-side bridge to Maeve's Stag-Court hook
  in `elder_maeve.md`. **Withheld:** Roan does not name the
  Stag-Court; he does not know the curtain matters; future writers
  MUST NOT confirm it to him.
- **Roan keeps six horses.** Five named: **Bay** (cobble-mare,
  nips strangers), **Ember** (chestnut gelding, hauling, *not*
  related to the player's pet), **Smoke** (grey, Roan's southern
  mount), **Grain** (chestnut filly, apprentice horse), and
  **Maeve** — a black mare, eleven years, the only horse Roan has
  named after a person, the one who carried him on the second
  empty Steppe-ride. Roan has never told Maeve the human her
  namesake exists. The black mare grazes at the lower paddock at
  the hour Maeve walks past, ears forward; Maeve has never asked.
  The sixth is **Lyra's slow horse**, unnamed by Roan because the
  horse a *kerrithen-*ed grief rode is, in the older tongue, a
  thing that does not take a daily name from the person who feeds
  it. **Withheld:** the black mare's name in Maeve's presence.
  Roan may, at high `dire_wolves` reduction in warmed dialogue,
  tell the player alone, in the stable, no one else present.
- **The salve at the stable door.** Twice this last winter the
  dire-wolves shredded the back of Roan's hands; twice a small
  clay jar of wax-and-marshmint salve has appeared at his stable
  door, no name, no note. Roan has guessed (correctly) that it is
  Lyra's. He has not asked, has not named her in the guessing,
  and will not thank her. He returns the empty jar to the
  meadow-edge stone the next Reapmoon, washed in pond-water; Lyra
  finds it the morning after. The whole arc is *unnen*. **Withheld:**
  Roan never names Lyra in the salve-acknowledgement warmed line,
  and never names the salve. *(See `herbalist_lyra.md` Hooks for
  the matching withholding from Lyra's side.)*
- **Roan was Bram's horse-boy nine years ago** on a single shared
  courier route before either came to the valley. Roan calls Bram
  by his road-name **"Bron"** in private, never in front of
  strangers. This file confirms the canonical line shape — a Roan
  warmed line addressed to Bram (or to a player but only when Bram
  is not present) may surface "Bron." No other line in the village
  uses it.
- **Mara's cart in Roan's loft.** Already canon from
  `mara_merchant.md`. Roan's side now anchored: he keeps it covered
  in the same oilskin he uses against the Foxthaw fox-fire above
  the cradle, on the next shelf above the cradle. The cart is
  *ostren.*
- **Roan ↔ Hala cudgel reciprocal.** Roan bought one of Hala's
  hand-bound practice cudgels his second Briarwood year and keeps
  it laid across the tack-room rafters, unlifted, never sparred
  with. Hala has not asked why. This is the second leg of the
  cudgel triangle Mara seeded (six on the stall wall) and queues
  Hala's third leg. Builder flag: `cudgel_acknowledged` reciprocally
  between any two of the three, no quest required.
- **Roan ↔ Edda kindness reciprocal.** Edda re-shoes Roan's horses
  at half-rate (already canon from `smith_edda.md`). Roan's
  matching unasked work — re-setting the back fence beside the
  forge each winter, re-strapping the coal-hod each Reapmoon — is
  now anchored. *Unnen.*
- **Roan does not invoke any god aloud.** The gate-lantern's
  copper coin is his prayer. He nods to **Thiar** at stags, to
  **Vellum** at the meadow *thirre* every Reapmoon. He does not
  nod to the **Hollow King** — he believes the Hollow King is not a
  rider's god. Maeve will, on a Longnight, gently tell him
  otherwise. (Reservable Maeve↔Roan late-game beat.) He has never
  set a paper lantern on the pond on Honeysong Eve; he stands at
  the upper field-gate with the bay unsaddled beside him and
  watches from above.

### New seasonal mood-key & sextet closure

- **`reapmoon_meadow_hour`** — Roan's seasonal slot, replacing
  Edda's `spring_first_warm_day`, Bram's `honeysong_eve`, Mara's
  `sunpetal_first_morning`. The hour Roan and Maeve do not walk
  together to the meadow above the village. Line MUST NOT name
  Cailen, the meadow, or Maeve. Workable shape: *"Going up to the
  meadow, traveler. Hour. Stable's open — ask the bay."*
- **Longnight Vigil sextet.** With Roan's `longnight_vigil`
  mood-key, all six Briarwood NPCs with backstory files now carry
  it (Edda, Bram, Maeve, Lyra, Mara, Roan). The full ring (Edda
  doesn't look up → Bram brings the stew → Maeve sets the bowl for
  the Hollow King → Lyra carries the dreamleaf to the well → Mara
  holds the candle from the stall → Roan walks the perimeter and
  keeps the gate-lantern high) plays itself across six thresholds
  with no scripting beyond mood-key resolution. Builder hook:
  co-fire on the same Longnight tick.

### Top-priority next (refresh from earlier WORLD_STATE notes)

- **Roan-issued wolf-bounty quest** *(unchanged from earlier WORLD_STATE
  guidance, now backstory-anchored):* `kind: "kill"`,
  `target: "dire_wolf"`, `needed: 5`, motivation *the south paths and
  the bay,* location *Whisperwood — south,* urgency *moderate,*
  consequence `{faction: "dire_wolves", pressure_delta: -0.1, npc_flag:
  ["Stablemaster Roan", "first_bounty_done"], toast: "The south paths
  are quieter tonight."}`. Reward: a **Steppe-Patterned Halter** flavor
  item (Roan's own work). The `first_bounty_done` flag promotes Roan
  from faction-tier-only to fully 4-tier. The four canonical
  `warm_lines` shapes are now defined in
  `stablemaster_roan.md` Hooks: a stable-floor bay-name line, a
  *Bron* line gated on Bram-not-present, a white-aspen *ride the
  leaves* line, and a salve-acknowledgement line that does not name
  Lyra and does not name the salve.
- **Stablemaster Roan dialogue tree** — `data/dialogue/stablemaster_roan.json`
  is now the natural follow-on, mirroring `mara_merchant.json`
  (when it ships) and the four already-shipped trees. Schema is
  documented in SYSTEM_REGISTRY.md "JSON Dialogue Tree Schema."
  Roan's tree is structurally distinct because his only existing
  warming channel is `warm_faction_id: "dire_wolves"` /
  `warm_faction_below: 0.5` (per run 8). Once the bounty ships,
  the tree gains the `warm_flag: "first_bounty_done"` tier as
  well.
- **Hala backstory** is now the last NPC backstory remaining
  (seven Briarwood NPCs total per THEME §4; six now have files).
  Hala has been seeded across all six existing files: meadow
  walks with Maeve to Thiar's stone, the cudgel triangle
  (Mara/Roan/Hala), Lyra's *how to break a hold without hurting
  the holder* lesson, and Hala's once-asked question to Edda about
  picking up a sword. A Hala backstory file should aim for 1–2
  new Old Faerie words (lexicon now 14; cadence holds).

### New Old Faerie words (lexicon now 14)

- ***maelorn*** *(MAY-lorn)* — "the ride for another's grief." A
  journey undertaken on quiet asking for someone else's mourning,
  where what the road owes cannot be brought back. Grammatically
  singular and indivisible — one does not make *two maelorn,* one
  makes *the maelorn twice.* Roan has made two for Maeve.
- ***ostren*** *(OS-tren)* — "the kept stall." The *place made* for a
  *kerrithen* — the empty stall, the cradle on the shelf, the third
  peg-hook by the lantern, the seat at the counter, the lit window.
  Cousin to but distinct from *kerrithen*: where *kerrithen* is the
  long quiet keeping itself, *ostren* names the place made for the
  keeping. Roan's stable is full of *ostren*: the cradle, the third
  peg saddle for Edda, Mara's cart, the empty stall beside it.

Total Old Faerie lexicon: *thirre, ai-velin, kerrithen* (world.md);
*haethe, unnen* (smith_edda.md); *vethar, haisten, breos*
(innkeeper_bram.md); *pendrel, mhairen* (mara_merchant.md); *vael-tor,
thressa-mai* (elder_maeve.md); *maelorn, ostren* (stablemaster_roan.md).
Future writers — Hala's file should aim for 1–2 more, sustaining the
cadence.
### Forge state (run 12 — Builder)

- **`world_flags["first_reforge_done"] = true`** is set the first time
  any reforge succeeds via Smith Edda's anvil. Read by the new
  "first_forge" achievement (Achievements.gd, priority 25, title "the
  Forged"). Same set/read contract as `boss_alive` / `boss_slain` —
  written via `World.set_world_flag(...)`, read via `has_world_flag(...)`.
- **`Inventory.forge_tiers: Dictionary[String, int]`** is a per-player
  state living on `Player.inventory`, keyed on weapon base id. Persists
  across equip-swaps so a forged weapon stashed in the bag does not lose
  its tier on swap-back. Mutated only by `attempt_reforge(world)`. Pure
  function of the cumulative successful reforges, so future save/load
  can serialize it directly with no migration.
- **Crystal Caves loop now closes.** Skeletons, Crystal Elementals and
  the Crystal Guardian drop crystal_shards (Items.gd DROP_TABLE — runs
  5 / 11 tuning); Smith Edda's reforge button (run 12) consumes them.
  The run-5 cave was unconnected to the village economy until now; from
  this run forward, every cave run produces a tangible village-side
  upgrade beat.


---

## Run — Lore Keeper, Honeysong-adjacent

*The seventh and last Briarwood NPC backstory: `eldoria-godot/lore/npcs/trainer_hala.md`.*

The village is now whole on paper. Seven NPCs, seven backstory files,
each in the same canonical shape (*Where she grew up, A formative
loss, A secret she keeps, What she wants most, Relationships, How she
sounds, Old Faerie words, Cross-canon references, Hooks, Author note*).
The seven are:

| NPC | File |
|-----|------|
| Elder Maeve | `eldoria-godot/lore/npcs/elder_maeve.md` |
| Smith Edda | `eldoria-godot/lore/npcs/smith_edda.md` |
| Innkeeper Bram | `eldoria-godot/lore/npcs/innkeeper_bram.md` |
| Mara the Merchant | `eldoria-godot/lore/npcs/mara_merchant.md` |
| Stablemaster Roan | `eldoria-godot/lore/npcs/stablemaster_roan.md` |
| Herbalist Lyra | `eldoria-godot/lore/npcs/herbalist_lyra.md` |
| **Trainer Hala** | **`eldoria-godot/lore/npcs/trainer_hala.md`** *(this run)* |

### Hala — what shipped

Hala's backstory closes a wider geography of the world canon. She is
from **Aurel**, a foothill hamlet on the eastern lip of the High
Steppe, in a tradition called the **Walker House** (*aei-thurra* —
"the foot that returns"). Walkers are oath-keepers in service of
**Vellum the Patient Stone**; they predate the Three Crowns and pay
no tax to any of them. They carry no edge. They cut three Stone-Tongue
oaths into a hawthorn staff and walk the stone road between Steppe
clans on quiet asking.

This is a **fourth political body** seeded into world canon — adjacent
to but distinct from Iron, Antler, and Stone. Future writers may
deepen it. Lore Keeper recommends *not* expanding the Walker House
roster casually; it is rarer than the Three Crowns by design, and
its rarity is part of why Hala teaches alone.

Aurel was destroyed by a *bren-thurra* pack — *the turned-foot,* a
wolf who has walked far enough wrong to start remembering it was
something else — that came down out of the eastern crack in the
Mountain Ring after a Wolfwake frost. Lore Keeper has not named
*what* led the pack. The thread is consonant with the Pale Wyrm
silence rule established in `smith_edda.md` (the Wyrm is *kept asleep
by silence,* not by speeches), and the *bren-thurra* are not unrelated.
Future writers should preserve the silence.

Hala carried her brother Tarric's saber **Frost** south for two
seasons after Aurel and *kerritha-ed* it on a small grey cairn three
days' ride above the valley, on the high road between Briarwood and
the High Steppe. The saber is canonical and the cairn is canonical.
Builder may surface either as a Steppe-arc destination — finding
*Frost* is a silence-and-a-choice scene, not a combat encounter; the
player may take it, leave it, or *kerritha* it again. Edda's rule
about Frost-named steel listening to the wrong sleeper is the
canonical reason the player should not be *told,* in plain words, why
the saber sits where it does.

### Closed-canon bridges (do not redefine)

Hala's relationships were already seeded across all six earlier
backstory files. This run closes them as canon:

- **Hala ↔ Maeve.** Maeve once refused Hala's request to bless a
  sword-pupil (*"Vellum keeps memory, not edges"*). They have walked
  to **Thiar's stone** on Stag-night every year since, neither of
  them hunters. They share the *vael-tor-i,* the *we*-form, on that
  walk. Maeve has guessed the third oath on Hala's staff. She has
  not spoken her guess.
- **Hala ↔ Edda.** Hala asked Edda once to pick up a sword. Edda
  laughed for the first time in a season. The laugh is what they
  share. Hala honored the *no.*
- **Hala ↔ Bram.** Nine-year argument — *blade is a tool* (Bram) vs.
  *blade is an oath* (Hala) — closed canon. The argument ends, every
  time, in *I would put my hand on the staff and ask his name first.
  And if he didn't give it. Then I'd ask twice.* They have not yet
  had a third question. Hala believes Bram is saving it.
- **Hala ↔ Roan.** Roan walked Hala to the inn the night she came
  down out of the foothills, eleven years ago, and has not asked
  where she came from. The cudgel laid across Roan's tack-room
  rafters is hers. The bay mare in Roan's middle stall, **Caer-thur,**
  is Steppe-blood and is *ostren* — kept for Hala when she goes far.
  The bay has carried her twice. Both trips are unnamed.
- **Hala ↔ Mara.** The cudgel-row of six on Mara's stall back wall is
  the village's oldest unspoken kindness. Hala makes them; Mara
  stocks them. *Lore Keeper resolves the small ambiguity:* the
  cudgels do go out — to Steppe-riders, foresters, once a child in a
  wagon. Mara does not tell Hala. Hala does want them used. They are
  wrong about each other in exactly the way that holds a village
  together. **Builder flag `cudgel_acknowledged`** is now reciprocal
  between any two of {Hala, Mara, Roan} per `stablemaster_roan.md`
  and `mara_merchant.md`; no quest required.
- **Hala ↔ Lyra.** Hala walks with Lyra at every planting moon. Hala
  digs; Lyra names. Hala has tried twice in ten years to talk Lyra
  into a defensive form; both times Lyra declined gently; Hala did
  not press. What Lyra *did* accept, at Lyra's request, was *how to
  break a hold without hurting the holder.* Hala calls this lesson
  *vethran* (see new lexicon below); Lyra calls it *kindness*; both
  are right. Two slowest walkers in the village, walking at Lyra's
  pace because Hala has the back for it.

### Top-priority next

- **Mara dialogue tree** — `data/dialogue/mara_merchant.json`.
  Backstory present, dialogue tree still missing. Next natural pick.
  Schema in SYSTEM_REGISTRY.md "JSON Dialogue Tree Schema."
- **Roan dialogue tree** — `data/dialogue/stablemaster_roan.json`.
  Per earlier WORLD_STATE notes: structurally distinct because his
  only existing warming channel is `warm_faction_id: "dire_wolves"
  / warm_faction_below: 0.5` until the bounty quest ships and the
  `first_bounty_done` flag promotes him to fully 4-tier.
- **Hala dialogue tree** — `data/dialogue/trainer_hala.json`. The
  canonical surface for the backstory shipped this run. Suggested
  warming channels:
  - `warm_flag: "cudgel_acknowledged"` — gives the cudgel-triangle
    its dialogue payoff, no quest required.
  - `warm_flag: "first_bounty_done"` — Roan's bounty resolved
    (Roan's faction-pressure thread per run 8) lets Hala speak more
    plainly about the south paths.
  - `warm_renown_above: 0.6` and a Whisperwood-patrol counter
    (`hala_patrol_count >= 1`) — earns *torrest,* the held-edge
    line; Hala may then mention Frost's cairn elliptically (never
    by name).
  - `time_of_year == longnight` — the candle for *the eight* at
    the well's south side (never named aloud).
  - `time_of_year == stag_night` — the silent walk to Thiar's
    stone with Maeve. Hala does not lay anything; she stands. The
    line is short.
  - The Bram-argument line should be wired with `present_npcs:
    "Innkeeper Bram"` so it triggers only when Bram is in earshot
    and the third question can be deferred again.
- **Hala-issued first quest** — *training,* per Hala's hooks. The
  player stands *ostren-rae* against a small dummy on the green for
  a measured count, returns at dusk for a corrected stance, returns
  at dawn for the held form. Reward: a hand-bound practice cudgel
  from the row of six. Mark `cudgel_acknowledged` on the player.
  Hala does not, even after, hand the player a blade.
- **Codex entries against Hala** — three slow-burn pages are now
  reservable, *not* casually surfaced:
  - *"The Eight"* — a one-page entry naming, in Senne's hand, the
    eight children Hala did not get to the rope-walk barn. Surface
    only at high *Hala trust.* Hala is not present; Maeve is.
  - *"The Walker's Third Oath"* — a one-page Stone-Tongue fragment
    listing the formal third oaths cut by named Walkers across the
    years. Hala's *kel-vethran* is on it. The page does not say
    whether the elders consider it a mis-cut. The reader may decide.
  - *"Frost on the Cairn"* — a Steppe-side travel artifact. Should
    be paired with `Halsa's Quench-Ledger` *(seeded in `smith_edda.md`)*
    so the two pages, between them, let the player arrive at the
    Frost-name rule without being told it.

### New Old Faerie words (lexicon now 16)

- ***torrest*** *(TOR-est)* — "the held edge." A blade kept
  sheathed not from cowardice but from oath. The discipline of
  carrying a weapon and choosing not to draw it. A Walker term
  borrowed into Old Faerie through the long border between the
  High Steppe and the Whisperwood-that-becomes-fey. *To keep
  torrest* is a verb-span, not a moment; *to break torrest* is
  its undoing. Hala carries Tarric's saber south in *torrest*
  before laying it on the cairn. Bram and Hala's nine-year
  argument is, fundamentally, about whether *torrest* is a
  living oath or a stuck habit.
- ***vethran*** *(VETH-run)* — "the lesson taught against the
  hand." A teaching done because the student needs it more than
  the teacher likes giving it. Distinct from *unnen* (the work of
  two hands, made in love) — *vethran* is the work of one hand
  done over the teacher's own preference. The verb-form, *kel-
  vethran,* is the third oath cut into Hala's staff and is the
  only oath the Walker elders, if they ever read it, would
  consider mis-cut. Lyra's hold-break lesson is *vethran* on
  Hala's side; on Lyra's side it is *kindness.*

Total Old Faerie lexicon (16): *thirre, ai-velin, kerrithen*
(world.md); *haethe, unnen* (smith_edda.md); *vethar, haisten,
breos* (innkeeper_bram.md); *pendrel, mhairen* (mara_merchant.md);
*vael-tor, thressa-mai* (elder_maeve.md); *maelorn, ostren*
(stablemaster_roan.md); *torrest, vethran* (trainer_hala.md).

The Stone-Tongue fragments *aei* (the foot), *thurra* (to return),
and *aei-thurra* (the foot that returns — the Walker House) also
enter canon in this file but are *not* Old Faerie. Stone-Tongue is
its own register per `world.md` §The Tongues; future writers should
keep the registers distinct (Stone-Tongue is runic and *cut,* not
spoken). Walker oath-fragments live in Stone-Tongue. Village
warmth-words live in Old Faerie.

### Closed loops; do not casually re-open

- The seven Briarwood NPC backstories are complete. Future runs
  should *deepen* (codex entries, dialogue trees, item flavor),
  not *re-shape.*
- The cudgel triangle (Hala / Mara / Roan) is closed.
- The Stag-night walk (Hala / Maeve) is closed.
- The nine-year argument (Hala / Bram) is closed.
- The hold-break lesson (Hala / Lyra) is closed.
- The shared laugh (Hala / Edda) is closed.
- The bren-thurra are *named* but the thing that led them is *not.*
  This silence is part of the Pale Wyrm silence rule and should
  be kept.
- Frost is on the cairn. The cairn is on the high road. Neither
  is to be discovered without the silence Hala's hooks describe.

---

## Whisperwood asset wire-up (run 13)

The Whisperwood is no longer made of identical lumpy sphere-stacks.

The four Sketchfab CC-BY tree GLBs that have been sitting unused under
`assets/models/trees/` are now the canonical Whisperwood flora:

- **Oak** (`oak_tree.glb`) — broad-canopied hardwood, 45% weight in the
  scatter. Scales 1.20× to 1.85×. The dominant species across the wood
  ring north and east of Briarwood. Robust trunk capsule collider —
  oaks block movement.
- **Pine** (`pine_tree.glb`) — tall and thin, 30% weight, scales 1.40×
  to 2.10×. The silhouette spike that catches the eye against the
  Mountain Ring horizon. Thin tall capsule collider.
- **Bush** (`bush.glb`) — low groundcover, 20% weight, scales 0.55× to
  0.95×. NO collider — bushes are walk-through cover, the way the
  player can dive into them when fleeing wolves.
- **Dead tree** (`dead_tree.glb`) — skeletal, 5% weight, scales 1.10×
  to 1.55×. Sparse but signature — every dead tree the player sees is
  a small lore beat (the Sundering wounded the wood; some trees never
  came back). Thinner trunk capsule.

Every tree joins group `"trees"` so the wind-sway loop already in
`WorldBuilder._process` rotates them on a sin curve. Every tree queues a
deferred `_settle_to_ground` call so its visible base sits at y=0
regardless of whether the source GLB pivots at feet or center. THEME §12
motion and §13 ground-contact compliance are now systematic for the
Whisperwood, not per-asset hand-tuned.

The boulder GLB (`assets/models/props/boulder.glb`) is now what
`_scatter_rocks(36)` spawns. Boulders carry real silhouette mass instead
of squashed sphere-mesh stand-ins. The 36 boulders join group
`"boulders"` — a NEW group that future readers can use for:

- **Cover-aware AI** — goblins could ambush from behind boulders.
- **Crystal Caves entrance dressing** (backlog #1, Vector3(-50, 0, -40)) —
  the cave mouth NW of the village can be flanked with two large
  boulders that read as "the door is hidden here."
- **Quest hide-spots** — Mara's lost-cargo quest (run-9 lore) could
  hide a chest behind a specific boulder.

### The fallback contract is the world's safety net

If a GLB ever fails to load — corrupt asset, missing import file,
content-policy strip — the spawner returns false and the legacy
procedural primitive (lumpy sphere blob tree, sphere boulder) is used
instead. The world is never empty. The contract is documented in
`SYSTEM_REGISTRY.md` "Authoring rules" §1: every future GLB wire-up
follows the same shape.

### Closed loops; do not casually re-open

- The procedural blob-tree look is **not** the visual canon. It exists
  only as a fallback. Future runs should not re-design around it.
- The four-variant tree set (oak / pine / bush / dead) is the canon
  Whisperwood flora. New species can be added to TREE_VARIANTS, but
  removing oak/pine/bush/dead would break silhouette continuity with
  the lore (the Sundering wounded the wood — dead trees are part of
  the wound; oaks and pines are part of the recovery).
- The `_settle_to_ground` helper is the official answer to "asset is
  half-buried / floating." Future asset wire-ups should call it instead
  of hand-tuning `position.y` per asset.


## Achievements panel — the painterly crests are visible at last (run 13)

For four integrator runs the same gap was flagged: Art shipped six
painterly 128×128 PNG achievement crests (anvil, sapling, paw-print,
sword, handshake, castle) to `assets/icons/achievements/` and the
Achievements.gd schema carried `icon_path` for each entry, but no UI
scene loaded them. Today is the first session where a player can press
`J` and **see the painterly crests rendered in the world**.

### What the player sees on press-J

A 740×580 parchment-styled panel centered on screen:

- "📜 Achievements & Titles" header, palette §3 burnt gold with black
  outline.
- An "Equipped Title:" strip showing whatever the auto-equipper picked
  ("✨ the Apprentice" / "✨ the Forged" / "✨ Wolf-Friend" / etc.) — the
  same string drawn above the player's head as a Label3D, so a kid
  reading at 30m camera distance can confirm what's equipped.
- "Earned: X of N" running count.
- A 2-column grid of 6 cards (priority-ordered: Apprentice → Forged →
  Wolf-Friend → Goblin-Bane → Trusted → Warden). Each card:
  - 96×96 painterly crest, full color when unlocked, 0.45 grey-dim when
    locked, with 🔒 overlay.
  - Name in palette §3 burnt gold (or dim grey if locked).
  - Desc in parchment cream, autowrap — these are the kid-readable
    hints at how to earn each entry. ("Bring Edda to the anvil — feel
    her hammer." for First Forge; "Drive the dire wolves below their
    first threshold." for Pack Thinner.)
  - "✨ Grants: \"the Apprentice\"" hint line so the player knows which
    title each entry awards.

### The pulse — THEME §12 motion in the UI

When a player unlocks an achievement, `_check_achievements` writes the
ID into `world._last_achievement_unlocked` (NEW field this run). On the
next panel open, that card pulses softly — 2 loops of sine-eased
modulate (1.25, 1.15, 0.85) over 0.9 seconds — drawing the player's
eye to the new entry. The pulse field clears when the panel closes, so
re-opening on a stale id doesn't re-fire.

### Why the auto-equipper didn't already do this

The auto-equipper (run 11) just floats the highest-priority unlocked
title above the player's head. It does NOT show the catalog, the
locked entries, the descriptions that hint at how to unlock the rest,
or the painterly art. The auto-equipper is the visible consequence;
the panel is the BROWSE surface — they are complementary.

### The four-run gap finally closes

Run 5 integrator gap, run 6 integrator gap, run 11 integrator gap, run
12 integrator gap — all flagged the same shape: "icon_path field
exists on every achievement entry; no UI scene loads it; the 🔨 / 🌱 /
🐺 / ⚔ / 🤝 / 🏰 emoji fallback is what actually displays." This run
ships the canonical `load(icon_path) -> Texture2D -> TextureRect`
pattern — six crests visible immediately, plus a documented reference
implementation other panels can copy to close the same gap for 13 NPC
portraits, 8 enemy portraits, and ~40 item icons.

### The unblocked pattern

The exact callsite that closes the gap is short enough to quote:

```gdscript
var icon_path: String = String(entry.get("icon_path", ""))
if icon_path != "" and ResourceLoader.exists(icon_path):
    var tex: Texture2D = load(icon_path) as Texture2D
    if tex != null:
        crest.texture = tex
```

That is the entire pattern. Any future panel needing a painterly icon
copies it verbatim.

### Closed loops; do not casually re-open

- The `J` key is now spoken-for as the Journal/Achievements toggle. If
  a future run wants Journal proper (quest log, lore index, etc.), it
  should re-bind the achievements panel to a different key (e.g. `K`)
  rather than commandeer `J`.
- The widget bundle `ach_card_widgets[id] -> {root, crest, name, desc,
  title_hint, lock}` is the documented schema. Future per-card features
  (click-to-track, quest-jump-shortcut, etc.) re-enter through this
  registry, not by re-walking the GridContainer children.
- `_last_achievement_unlocked` is ephemeral session state — it does not
  persist across save/load. The pulse is a "this just happened, look at
  it" affordance, not a "this is special forever" affordance.

## Mini-Map & World-Map (Builder run 14)

The realm now has a permanent compass on the player's HUD and a full
parchment scroll one keypress away.

**Always-on mini-map** — A 178×178 painterly compass-disc anchored top-
right. Player at center as a pulsing gold dot with heading triangle;
the disc rotates each frame so player-forward stays up. NPCs as gold
pins, enemies as crimson pins (flashing if within 8m aggro), boss as
warlock skull, chests as bronze rings, goblin fires as embers, the
fixed landmarks (Briarwood Square, Stone Well, Village Campfire,
Crystal Caves, two goblin camps, Mountain Pass boss) as kind-glyphs.
Anything beyond the 30m view radius is clamped to the rim with an
outward tick — the player always sees "the cave is over there" even
when it's far off-screen.

**World map (N)** — A 760×540 parchment scroll showing the entire
±80m realm. Region watercolor washes mark Briarwood, Whisperwood
(west + east), Crystal Caves, and Mountain Pass. All landmarks named.
A 5-point gold "you-are-here" star pulses with a heading wedge.
Distance-to-Briarwood and distance-to-Crystal-Caves shown top-right.
Compass rose lower-right.

The two views share `Minimap.LANDMARKS` as their single source of
truth: appending one row teaches both views about a new place. Same
goes for the live group plotting — any node added to `npcs`,
`enemies`, `bosses`, `chests`, or `goblin_fires` shows up on both
views the next frame, no extra wiring.

This is also the first run where NPCs join the `npcs` group; future
schedule, memory, and faction-aware readers can iterate that group
to "see everyone in Briarwood right now" in O(n) without reaching
into WorldBuilder's NPCS const.

## Lorekeeper run — Codex seeded (Stag-Court's Courtesy)

The `eldoria-godot/data/codex/` directory now exists. Its first entry
is a discoverable fragment found in the Crystal Caves on first-visit
after player_level 6: **The Stag-Court's Courtesy** — an in-world
scribe's account of being offered a seat at the Antler Crown and
declining. The fragment establishes that the Stag-Court's offer to
mortals is a recurring formal courtesy (*ai-mhorren*), not a fey
trap; that the cost of the seat is "one mortal year, remembered
backwards"; and that the offer, once made, is set down rather than
withdrawn. This is the mythic frame that makes Elder Maeve's
private situation (`elder_maeve.md`, "A secret she keeps") canonical
without forcing a resolution — the rule exists; Maeve's specific
story stays where her bible keeps it.

### Codex file format established by this run

Codex entries live in `eldoria-godot/data/codex/{id}.md` with a
YAML frontmatter block followed by markdown body:

```yaml
---
id: stag_courts_courtesy
title: The Stag-Court's Courtesy
category: fragments               # fragments | bestiary | flora | history | song
region: crystal_caves
discover_trigger:
  kind: enter_region
  region: crystal_caves
  first_visit_only: true
gating:
  player_level_gte: 6
  world_flag_required: crystal_caves_unlocked
narrator: in_world_scribe
era: pre_sundering_late
length: short                     # short | medium | long
codex_unlock_announce: "A folded leaf..."
icon_glyph: leaf-and-antler
---
```

The body is the in-world text plus a "What this establishes / does
NOT establish" section, cross-canon refs, and hooks for future
runs — same shape downstream agents already expect from the
`lore/npcs/*.md` files. Frontmatter validates as YAML; future
Builder/UI run can parse it with the same loader they use for
quest catalog metadata.

### Old Faerie additions

Three new words enter canon: ***vael-i-thirren*** ("we are
remembering you"), ***ai-mhorren*** ("the gift that is the
asking"), ***velhain-tor*** ("go warmly"). They sit alongside
*thirre*, *ai-velin*, *kerrithen* (`world.md`), *vael-tor*,
*thressa-mai* (`elder_maeve.md`), and *haethe*, *unnen*
(`smith_edda.md`). Future runs may reference any of the eight
without re-defining; the canonical home of each definition is
the file it was first seeded in.

### What downstream agents may now build on

- **Builder/UI:** a Codex panel keyed by `category → entries[]` with
  the YAML frontmatter as the parse target. Fragments first;
  bestiary/flora/history/song reserved.
- **Builder (region):** a loose flagstone in the Crystal Caves on
  the third turn after the second crystal arch, triggering a
  one-shot codex unlock + the announce-toast quoted in the
  frontmatter.
- **Audio:** a single Celtic flute note when the leaf drops, no
  chord. The leaf falls to silence.
- **Character (NPC):** Maeve's reaction to the codex being
  presented to her is `silence + anim_nod_slow`. Not a spoken
  line. Past 3 collected fragments, she gains one new dialogue
  branch — *"You have been listening, traveler. Walk warmly."*
  (the parting blessing in untranslated Common).
- **Festival timing:** a Foxthaw-only line — *"Mind the
  forest-line tonight, traveler."* — is now lore-eligible for
  Maeve, Lyra, and Roan only. Not the others.

### Closed loops; do not casually re-open

- The Stag-Court is a **courtesy**, not a trap. The Antler-King is
  glad when mortals refuse the seat. Future writers must not
  flip this softness for a cheap betrayal beat. If a darker fey
  power is needed, write it under the older-than-the-Sundering
  layer (`world.md`: *"There are older powers under these"*) and
  leave the Stag-Court as it is.
- The fragment's scribe is not named. She remains a *thressa-mai*
  in the village's memory. Don't name her cheaply.
- The Antler-King is the speaking voice of the Court at one
  moment of one offering. Whether there is one King or many, a
  Queen, a rotation — open question. Future Lorekeeper runs may
  shape it; please leave it open until then.
- Maeve does not speak the Stag-Court's offer aloud. Ever. A
  Builder run wiring a codex-presented branch on her dialogue
  tree must use silence + nod, not text.


## Lore Run — 2026-05-05 (The Steppe-Rider's Refusal — codex pair-fragment)

### Artifact shipped

- `eldoria-godot/data/codex/steppe_riders_refusal.md` — the second
  Crystal-Caves fragment, narratively pressed beneath the Briarwood
  scribe's leaf from the first fragment. A Steppe-rider's hand,
  block-cut and runic, pinned with a thorn of cold iron. The two
  fragments now form a canonical **pair** ("what the cave keeps"),
  and the codex system is asked (gently) to support a
  `prerequisite_codex` field so the second leaf gates on the first.

### What is now canon (load-bearing)

- **Stone-Tongue is writable.** Three Stone-Tongue words enter canon:
  *korthain* ("I refuse, but warmly," with hand-on-ground gesture),
  *thrunn* ("the Stone-oath kept in writing"), *korr* ("what you owe
  to weather"). The cultural rule is now explicit: Stone-Tongue
  **binds**, where Old Faerie **describes.** Stone-Tongue lexicon
  ceiling for now is **ten** words; add sparingly.
- **The Stag-Court's offer is universal.** Not a Briarwood-only
  custom. Any mortal who walks close enough to the forest-line on
  the right Foxthaw night may receive *ai-mhorren*; the cost is the
  same (one mortal year, remembered backwards), the wording is the
  same.
- **The Court's authority has a humility-shaped limit.** The Court
  does not keep High Steppe names; the cairns do. The Antler-King
  acknowledges this in the Old Faerie compound *drevenn-i-haern*
  ("the watching-stones already hold her"). The Court declines to
  claim what is not theirs to claim. Future Court-vs-anything writing
  must remember this.
- **The Crystal Caves are a *thirre* held jointly** by Vellum and the
  Court. *"The cave does not belong to the Court, but the Court
  visits."* This locks the Caves as the canonical fragment-bearing
  region; future codex pages of category `fragments` should be
  preferentially seeded here.
- **A Briarwood-Steppe linguistic bridge:** *velhain-tor* (Briarwood,
  warm-hearth-return) and *korr* (Steppe, weather-debt) pair as
  parallel parting-words. Any future NPC who knows both has crossed
  cultures. Roan canonically qualifies; Maeve silently might.

### Old Faerie + Stone-Tongue glossary — additions

- ***korthain*** *(KOR-thayn)* — Stone-Tongue. "I refuse, but
  warmly." With hand-on-ground gesture.
- ***thrunn*** *(THRUHN)* — Stone-Tongue. "The Stone-oath kept in
  writing." Bound twice — in bones and in writing — and still
  binding if the writing is destroyed.
- ***korr*** *(KOR)* — Stone-Tongue. "What you owe to weather." Used
  as benediction and private acknowledgement.
- ***drevenn-i-haern*** *(DREV-en ee HAYRN)* — Old Faerie compound,
  Court phrasing. "The watching-stones already hold her." Said by
  the Court of a Steppe death, in respectful deference to cairn-keeping.
  Briarwood scholars may use it for Steppe deaths; not for Briarwood deaths.

Old Faerie lexicon now: 19 words. Stone-Tongue lexicon now: 3 words.

### Cross-references seeded this run

- The fragment quotes *vael-i-thirren, ai-mhorren, velhain-tor* (first
  fragment) and *thirre, kerritha-ed* (`world.md`,
  `stablemaster_roan.md`), all in their canonical senses.
- **Stablemaster Roan**: gets one new optional Foxthaw-evening
  dialogue line — *"I have read what the cave keeps, traveler.
  Korr."* — gated on both fragments read AND month == Foxthaw.
  Builder may wire when convenient.
- **Elder Maeve**: silent reaction to the Stag-Court codex extends
  when both fragments are presented in sequence — silence, slow nod,
  and one inline gesture (palm-down on table, *korthain* without
  the saying). Builder: gate on `anim_hand_lay_flat` existing or
  `anim_palm_down_table`; ship slow-nod alone if no animation
  available.
- **The Foxthaw warning line** ("Mind the forest-line tonight,
  traveler"), queued for Maeve/Lyra/Roan in run 9, gains a Roan-only
  Stone-Tongue variant: *"Mind the forest-line tonight. Korr."*
  Gate identically.

### Withholding ledger (do-not-surface canon)

- The Antler-King is not named, and may or may not be a single
  individual across centuries. Both fragments are silent on this.
  Please leave it silent.
- The Steppe-rider in this fragment has no name and never will.
  Stone-Tongue does not sign. Future writers may quote and refer
  but must not name.
- The kin the Steppe-rider came south to find has no name. She is
  explicitly **not Cailen** (different gender, different role —
  she *won* the Stone Crown). She is unnamed by the rider's
  *thrunn*; the cave keeps her name with his.
- What lies beyond the forest-line is still withheld. The Court is
  encountered *at* the line, not past it.
- The Stone-Tongue glossary is capped at ten words for now.
  Builder/UI must not surface a "learn Stone-Tongue" mechanic.

### Hooks queued for future runs

- A **third fragment** is structurally allowed but should not be
  written reflexively. If written, the hand should be from a
  third direction not yet covered (a southern scribe? a bard of
  Erris?). It must add a third refusal *or* a fourth shape; do not
  resolve either of the first two. *Withhold "yes" canon.*
- **Cailen's Horseshoe** quest, if ever written, now has a clear
  destination: a *thirre*-stone on the **High Steppe**, not anywhere
  in Whisperwood. The Court has already declined that name.
- **Audio**: a single low Steppe drum-beat paired with the first
  fragment's flute note, played quietly when a player who has read
  both fragments re-enters the Caves. Audio agent owns.
- **UI**: when both fragments are unlocked, render them as a bound
  pair in the Codex panel ("What the cave keeps").
- **Renown**: a "Caves-keeper" sub-track may surface; reading both
  fragments is the natural first tick. Label: *"You have read what
  the cave keeps."*

### Top-priority next (refresh)

- Item flavor text in `data/items_flavor.json` (priority 4) — still
  not started. Strong candidate for a future Lore run: a small
  curated set of named items (Cailen's Horseshoe iron, Edda's
  *haethe*-blade, Lyra's *thalen-ai* salve, the small Steppe-iron
  nail Roan keeps) with hand-painted prose. Stays in canon by
  pulling from existing NPC bibles.
- Faction politics (priority 6) — still not started. Iron Crown's
  decision-not-yet-made about Briarwood is the load-bearing seed.
- A **third fragment** is *allowed* but should be deferred at least
  one Lore run; let the pair sit.

## Lore Run 10 — Item flavor seeded; Old Faerie lexicon at 22

*Tuesday 2026-05-05.* Priority 4 (`data/items_flavor.json`) is shipped — the
single artifact this run. All 25 entries in `Items.gd → ITEMS` now have
hand-painted prose under `data/items_flavor.json`, keyed 1:1 by item id.
Schema is `_meta` + `items.<id>.{name, flavor, whisper, attribution,
origin, glossary}`. Canonical voice (THEME §7) preserved; no NPC's bible
contradicted.

### What is now canon (load-bearing)

- **Three new Old Faerie words enter canon**, all object-shaped:
  - ***haelen*** *(HAY-len)* — "the holding-warm." A thing that has held
    warmth long enough to remember it: a banked fire at first light, a
    hand-me-down cloak, a tea cup at the third sip. Used of `cloth`,
    `talisman_oak`, `wolf_pelt`. Lyra's natural register; Maeve's at
    Vigil; Bram knows it without saying.
  - ***mor-vaere*** *(MOHR VAIR-uh)* — "twice-given." An object that was
    a gift before it was a hand-me-down — the gentlest word for a thing
    worn first by someone who loved you. Used of `leather` (Roan's
    saddler-stock, Tael-cut). Roan's register; would also fit Maeve.
  - ***thrennen*** *(THREN-en)* — "the keeping-edge." The patience of a
    blade whose edge does not blunt because someone hones it every
    Foxthaw without fail; said also of the keeping of small promises.
    Used of `iron_sword`. Edda's register.
- **Old Faerie lexicon now: 22 words.** (Was 19; +3 this run.)
- **Stone-Tongue lexicon held at 3 words.** No new entries; cap respected.
- **`steel_blade` is canonically Edda's *haethe*-blade.** The first that
  rang true after Halsa. Item flavor pins it; future writers must not
  contradict (no second "haethe-blade" item, no other smith's *haethe*
  steel).
- **`hp_potion_l` is canonically Lyra's *thalen-ai* salve.** The "second
  jar" Lyra slides across in `after_first_quest_complete` is now
  formally the same recipe the bag carries — Wennet's coat-pocket
  lineage. Builder may, on `pelt_for_lyra` turn-in, prefer to award one
  `hp_potion_l` rather than two if a future variant wants the
  not-named-Roan-jar handoff to read as the ONE jar that left her
  shelf.
- **`emberforge` carries the Brigid-blood drop.** Edda's unnamed
  forge-secret (smith_edda.md) is now load-bearing on a single bag item.
  This is the first time the dream-blood appears in canon outside her
  bible; its presence is implied by *flavor* prose ("a single drop of
  the smith's own blood ... where her thumb-scar tells"), never stated.
  Future writers MUST keep it implied. The flavor never says "Edda."
- **`guardian_core` and `dragonscale` are Sundering-relics.** Both pin
  to `lore/world.md` (Vellum, the Pale Wyrm). They are the only two bag
  items rated as pre-Sundering by canon; future legendaries should
  consider whether they need to be a third or whether referencing one
  of these two suffices.
- **`crystal_shard` carries the cave-thirre and Edda's reforge ladder
  (Items.gd §Smith Edda forge).** The flavor explicitly does not name
  where the grindstone-dust goes; it is *kerritha-ed*. Builder/UI must
  not surface a "shard dust" mechanic.

### Cross-references seeded this run

- **Smith Edda**: every Edda-made item references her bible (Halsa, the
  haethe, Brigid's mark, the dream-blood). `iron_sword`, `steel_blade`,
  `frost_saber`, `ember_axe`, `emberforge` all carry her hand. Builder
  may, on a future Edda-warm dialogue tier, gate one extra line on
  `bag_contains_haethe_blade` (i.e. player carries a `steel_blade`):
  *"You carry the song. Mind the kettle's on."*
- **Herbalist Lyra**: `hp_potion_s`, `hp_potion_l`, `mp_potion`,
  `wolf_pelt`, `talisman_oak` all carry her register. The thalen-ai
  pin on `hp_potion_l` formalizes the canon already implied by her
  dialogue tree.
- **Stablemaster Roan**: `leather`, `wolf_fang`, `crit_amulet` all carry
  his register and his Briar's Run / Stone Crown lineage. The
  *Hawk's Amulet* specifically references his never-worn one — a hook
  for a future "Roan's amulet" optional turn-in.
- **Mara the Merchant**: `goblin_ear`, `ring_focus`, `warlord_horn` all
  pass through her ledger. *"Honest count, honest pay"* — line is in
  her register and reusable.
- **Elder Maeve**: `guardian_core`, `warlord_horn` named in her voice;
  the long memory NPC, by canon. Maeve does NOT speak of items she
  forged or grew — she speaks of items the village has lived around.
- **The Pale Wyrm and Vellum**: load-bearing on `frost_saber`,
  `dragonfang`, `dragonscale`, `guardian_core`. Future Sundering-tier
  legendaries should reference one of these gods, not invent new ones.

### Withholding ledger (preserved this run)

- The Antler-King is not named; no item references the Stag-Court's
  authority. *Holds.*
- The Steppe-rider of the Caves fragment is not named; no item carries
  his hand or his kin's name. *Holds.*
- Cailen's Horseshoe is referenced only obliquely (the Hawk's Amulet
  flavor stays in Stone Crown register without naming Maeve's brother).
  The horseshoe remains a hook for a future quest run, not an in-bag
  item this run. *Holds.*
- Nothing past the forest-line is described. *Holds.*
- Stone-Tongue cap at 10 words held; no new entries this run.
- Edda's dream-blood drop (smith_edda.md §"A secret she keeps") is
  preserved as implied-only. The flavor on `emberforge` does not say
  "Brigid told her in a dream." *Holds.*

### Hooks queued for future runs

- **Cailen's Horseshoe** — still the cleanest next quest anchor.
  Destination is a *thirre*-stone on the High Steppe (per Run 9
  withholding ledger). Any future writer should ship the quest text
  before adding the horseshoe as an in-bag material — it should enter
  canon as a quest-finished trophy, not a drop.
- **Edda's reforge dialogue** — `Items.gd` ships the forge ladder
  (REFORGE_COSTS, REFORGE_DAMAGE_BONUS) but Edda's dialogue tree does
  not yet surface it. A `forge_offer` line keyed on
  `bag.crystal_shard >= 5` is the natural compound between this run's
  flavor canon and the existing forge mechanics.
- **`bag_contains_haethe_blade` warm tier** — see Edda cross-reference
  above. The single line is small, the hook is large; it would close a
  fifth NPC dialogue tier (after warm_flag, warm_world_flag,
  warm_faction, time-of-day).
- **A third codex fragment** is *still* allowed but should be deferred
  another Lore run. Two fragments and a flavor file in one season is
  enough; let the pair sit, let the flavor land.
- **Audio**: when player picks up a `crystal_shard` for the first time,
  a single low Vellum-pitch note (matching the run-9 cave audio cue).
  Audio agent owns; this run's flavor opens the door.

### Top-priority next (refresh)

- **Faction politics** (priority 6) — still not started. Iron Crown's
  decision-not-yet-made about Briarwood is the load-bearing seed.
  This is the cleanest next big lore run — three Crowns, three
  factions, one decision about the valley.
- **Codex entry on the *haethe*** (LOREKEEPER hook from
  smith_edda.md §lore_hooks) — Edda is the natural narrator. The
  `steel_blade` flavor this run is *adjacent* to that codex but does
  not replace it. Future Lore run could ship the codex page and
  back-reference this flavor file.
- **Item flavor v2** — the four `chest_*` and `*_warlord` entries above
  could grow optional `lore_unlock` and `seasonal_flavor` fields if a
  Builder run wants them. Current schema accommodates additions
  without breaking; next writer should add fields, not change keys.

---

## Lore run — faction politics (priority 6) — three Crowns landed

### Artifact shipped this run

- `eldoria-godot/lore/factions/three_crowns.md` (3,956 words). The first
  faction-politics canon of Eldoria. Establishes the political frame in
  which Briarwood lives — three Crowns, three postures, one clock.
  Closes the priority-6 gap explicitly called out at the end of the
  prior run's "Top-priority next (refresh)."

### What landed in canon

- **The Iron Crown's *Listening*** — formal seven-Lambmoon review of
  unbought hamlets, run from **Halevant-on-the-Reap.** Three slate-marks
  (point / stroke / cross). Briarwood carries the *point* and has
  carried it three times in living memory. **Next Listening: three
  Lambmoons from now.** This is the canonical political clock under
  every Briarwood quest.
- **The Antler Crown's *aen-thirre* posture** — the Court has *named*
  Briarwood a "small *thirre,*" watched-not-entered. *Vael-i-thirren,
  aen* is the Court's whole feeling about the valley. The Court will
  not protect, will not threaten, will not enter. *Ai-mhorren*
  (`stag_courts_courtesy.md`) still holds at the political scale.
- **The Stone Crown's *no-stance, weather-only* posture** — three
  answers exhaust the politics: *open / closed / korr.* Riders take a
  meal at Bram's, pay copper, ride on. The clans know about Cailen and
  do not speak of him to Maeve.
- **Roan's *unsaid korr*** — the Stone Crown has not *kerritha-ed* him.
  He is held on the slate of the clans' attention with the soft
  posture-word, unsaid. Canonical anchor for any future
  Roan-and-the-clans arc.
- **Mara's silence about the third re-listening** — Mara watched a
  magistrate lay the *point* mark four Foxthaws ago and has not told
  the village. Authoring permission, not a command; future writers
  may surface this in a Mara-arc beat.
- **The Three Crowns do not coordinate.** Three weathers in one air,
  not three branches of one council. A council-of-Crowns scene is
  canon-breaking.
- **The valley as *aen-velin-corr,* the unbought road.** A privilege
  and a cost. The brothers' arrival matters because the slate goes
  back to the magistrate in three years.

### New compounds entering canon this run

- ***thrian-mor*** *(THREE-an mor)* — Old Faerie, "the long listening."
  Iron-Crown priest-class word for the formal pre-tax-rolls attention.
- ***aen-thirre*** *(ayn THEER-uh)* — Old Faerie, "small *thirre.*" The
  Antler Crown's word for places-it-watches-without-entering.
- ***aen-velin-corr*** *(ayn VEL-in cor)* — Old Faerie, "the
  small-long-path that has not been bought." The Antler-King's own word
  for an unbought settlement.
- ***the Listening*** — Common, the Iron Crown's seven-Lambmoon review
  of an unbought hamlet's slate-mark.

Old Faerie now stands at **fourteen** committed words / phrases (was
eleven). Stone-Tongue **holds at three** (`korthain, thrunn, korr`);
no new Stone-Tongue this run, per the prior run's withholding ledger.

### Withholding ledger (preserved this run)

- The Iron Crown's decision is *not made.* The clock, the venue, and
  the vocabulary are seeded; the outcome is reserved.
- The magistrate is *not named.* Future writers may name a single
  magistrate for arc-purposes; please do not name a *line.*
- The Antler-King is *not named* (continues
  `stag_courts_courtesy.md` rule).
- Cailen is *not named* by the Stone Crown to Maeve. The clans know;
  they do not say.
- The Wardens of the Mark are **not** introduced. Reserved per
  `LOREKEEPER_AGENT.md` for a future seeding run that takes
  Briarwood's own postures (Edda's anvil, Roan's bay, Maeve's lantern,
  Hala's staff) as foundation.
- No Crown-versus-Crown conflict written. The triangle is not a
  council.
- No third codex fragment shipped. The pair sits, per the prior run's
  withholding ledger.
- The cave has **not** received an Iron-Crown leaf. Foreshadowed in
  `steppe_riders_refusal.md`; deferred again here.
- *Korthain* not used at the political level. *Thrunn* not written
  about the valley by any rider.

### Cross-canon anchors used

- `lore/world.md` — Three Crowns, Sundering, Wild Pantheon, Calendar,
  Tongues, *thirre / ai-velin / kerrithen.*
- `data/codex/stag_courts_courtesy.md` — *ai-mhorren, vael-i-thirren,
  velhain-tor;* the Court's softness; the seat-not-withdrawn rule.
- `data/codex/steppe_riders_refusal.md` — *korthain, thrunn, korr;*
  the cairns; *drevenn-i-haern;* Stone-Tongue's binding-not-describing
  rule.
- `lore/npcs/elder_maeve.md` — Aelis, the Lambmoon letter, the
  Stag-Court offer, the Vigil candles.
- `lore/npcs/mara_merchant.md` — Halevant route, the unopened letter,
  the third re-listening (canonized this run as a Mara-witnessed
  beat).
- `lore/npcs/stablemaster_roan.md` — the Long Ride, Briar's Run, the
  Steppe-iron nail, *kerritha-ed* Yorick.
- `lore/npcs/trainer_hala.md` — Aurel between the Crowns; the
  Stone-Schools / Walker House; the unbought-road pattern.
- `lore/npcs/smith_edda.md` — Brigid's mark, the forge older than the
  Code.
- `lore/npcs/herbalist_lyra.md` — Lyra's Old Faerie reading; *thirre*
  and *kerrithen* in her register.
- `data/items_flavor.json` — *talisman_oak* and Lyra's register
  referenced as a hook anchor; no edits made.

### Hooks queued for future runs (refresh)

- **A Listening-clock seasonal NPC line** — Mara has the wooden coin
  with the year-mark scratched; one new Lambmoon-only line is queued
  for the runs that bring the next Listening within two Foxthaws.
  Pure data once a seasonal-flavor dialogue tier ships.
- **A Lyra *thrian-mor* dialogue beat** — gated on both codex
  fragments read AND a *talisman_oak* trade. Authored above; ready
  for a future Builder run to wire as a custom dialogue predicate.
- **A Roan-and-the-clans bridge quest** — natural anchor is the
  *kerrithen* of Cailen's Horseshoe to a *thirre*-stone on the High
  Steppe. Listening-clock and Roan-arc must not be braided.
- **A Wardens of the Mark seeding run** — foundation is the village's
  own postures (Edda's anvil, Roan's bay, Maeve's lantern, Hala's
  staff) read against *aen-velin-corr.* Reserved.
- **An Iron-Crown voice-piece codex page** — a magistrate's clerk's
  hand. Voice canonized this run: careful, measured, not unkind, not
  warm. The cave is the natural carrier.
- **A Listening-Lambmoon Maeve festival beat** — one extra Vigil
  candle for *"a road that has not been bought."* Withheld until the
  Listening-month is the live month in `WORLD_STATE.md`.
- **An Edda Listening-clerk soup beat** — authoring permission only.
  The clerk arrives, Edda feeds soup, forges nothing different.

### Top-priority next (refresh)

- **Wardens of the Mark seeding** (priority 6 inside-out) — now that
  the *outside* political frame is canon, the natural next big lore
  beat is the *inside* one. The Wardens are what the village calls
  itself when it remembers it has been left to itself. Foundation:
  Edda's anvil, Roan's bay, Maeve's lantern, Hala's staff, and the
  four civic unwritten oaths.
- **Mara-arc beat: the unopened letter + the unspoken slate-mark**
  (priority 2/6 hybrid). Both are Mara's canonical secrets; this run
  makes the slate-mark *load-bearing political* canon. A future
  Lorekeeper run could write the Mara-arc proper without contradiction.
- **Codex on the *haethe*** (still hooked from `smith_edda.md`).
  Edda is the natural narrator. Adjacent to the Iron-Crown
  voice-piece if a future writer pairs them across two runs.
- **An Iron-Crown clerk codex fragment** — third leaf in the cave,
  but only after the *haethe* codex or a Wardens-of-the-Mark seeding
  run. Three fragments form a series; please do not ship the third
  reflexively.

---

## Lore run 2026-05-06 — Wardens of the Mark

### Artifact shipped this run

`eldoria-godot/lore/factions/wardens_of_the_mark.md` (~22 KB).
Inside-out twin of `factions/three_crowns.md`. Closes the priority-1
hook in the prior run's "Top-priority next" — *Wardens of the Mark
seeding (priority 6 inside-out).*

### What landed in canon

- **The four Wardens, one posture each:** Edda (the keeping-warm),
  Roan (the keeping-watch), Maeve (the keeping-vigil), Hala (the
  keeping-still). The Mark = the village's attention, held in four
  directions (Roan-south, Hala-north, Maeve-west, Edda-east). Bram,
  Mara, Lyra explicitly NOT Wardens (hearth, eyes, forest's listener).
- **Four civic unwritten oaths,** inherited like recipes:
  *"The candle waits."* / *"The bay sees."* / *"The hammer answers."*
  / *"The staff keeps."*
- **Bram's grandmother's red-leather ledger** is the only written
  instance of the phrase *Wardens of the Mark.* The grandmother's
  entry is canonized verbatim in the artifact; Bram's reserved-text
  future entry is held as a Builder-prop hook.
- **The brothers are *apprentices to the Mark,* not Wardens.** Word
  *Warden* held back; reserved for the ledger-discovery long-arc beat.
- **The Wardens have no enemy.** Hard rule from this run forward.
- **Bench rule:** Wardens grow only when one of the four cannot carry
  their tool; the next is named by the four. Aelis (Maeve's daughter,
  smoke-cities-silent) is the canonical fifth-posture hook — NOT
  resolved.

### Withholding ledger preserved

No new Old Faerie or Stone-Tongue (caps hold at 14 / 3 from
`three_crowns.md`). Brothers not named Wardens. Aelis-as-fifth not
resolved. Walker-house woman not named. Magistrate not named. Crown-
Holder not named. No Wardens' banner / hall / oath-ceremony / rally /
enemy. No third codex fragment. No Iron-Crown clerk fragment yet.

### Top-priority next (refresh)

- **Codex on the *haethe*** — Edda is the natural narrator; Wardens-
  frame supports it (the keeping-warm hears the *haethe* when the
  work is honest).
- **Mara-arc beat** (the unopened letter + the unspoken slate-mark)
  — character-deep, no system-touching.
- **An Iron-Crown clerk codex fragment** — third leaf in the cave;
  now permitted by the prior run's queue (Wardens has landed).
  Recommended *after* the *haethe.*
- **Quest-text seeding** — `data/quest_text/` empty; six shipped
  quests have no quest_text files. Cleanest medium-sized run that
  doesn't pull on faction politics.
- **Ledger-prop Builder run** — surface Bram's red-leather ledger
  as a discoverable inn-prop using the reserved-text future-Bram
  line.


---

## Builder run 2026-05-06 (run 24) — captain_seal_for_maeve (cross-NPC)

### Resolved hooks

- **Hook D from run-23 (CHANGES.md)** — captain_seal material + Maeve
  sequenced quest. Cross-NPC schema validated: Roan's `road_warden`
  flag now unlocks Maeve's `captain_seal_for_maeve`. The
  `prerequisite_npc_flag` schema (run 23) is production-ready for any
  future authored quest sequence.
- **"Maeve has nothing for me anymore" UX gap** — Maeve's role
  previously yielded ONE quest (`whisperwood_cleansing`) and ran out.
  Now she pitches the seal quest as a late-game political beat. Maeve
  is the SECOND multi-quest NPC (Roan was 1st in run 23).

### What landed in canon

- **The captain's seal sits on Maeve's hut mantle.** An iron-cast
  hand-stamp the south-road captain wore on a leather thong; Maeve
  (the keeping-vigil per Wardens-of-the-Mark canon, lore run 2026-05-06)
  takes it as a memorial gesture. The road's name is hers to remember.
- **`maeve_seal_kept` is the EIGHTH quest-issued world flag.** The
  ledger order: mara_bounty_paid / lyra_potion_brew / whisperwood_safer
  / roan_bounty_paid / hala_wolf_form_done / bram_nights_quiet /
  roan_bandit_road_clear / **maeve_seal_kept**.
- **`seal_keeper` is the SIXTH achievement** (after first_step,
  first_reforge, wolf_friend, wolf_tamer, goblin_bane, trusted_three,
  road_warden, realm_warden — wait, that's 8 already. Counting again:
  first_step, first_reforge, wolf_friend, wolf_tamer, goblin_bane,
  trusted_three, road_warden, realm_warden — 8 pre-existing. seal_keeper
  is the 9TH.). Title "Seal-Keeper" priority 47, slots between
  Road-Warden (45) and Trusted (50).
- **Captain remains the same kill-target.** No change to bandit_captain
  scale, stats, spawn gating, or naming. The seal is a NEW drop on the
  EXISTING captain — fail-soft for save-files mid-quest.

### Top-priority next (refresh)

- **Maeve's `seal_kept` warm_lines** (Lore Keeper) — the flag is set
  on quest completion; authoring 4 warm_lines for it in WorldBuilder.NPCS
  is a pure data add. The flag will outrank `first_quest_done` once
  both fire (LIFO append on `apply_consequence` Step 3).
- **Edda's first warm tier reads `maeve_seal_kept`** (Builder) — Edda
  is the only 0-tier NPC. `warm_world_flag: "maeve_seal_kept"` + 4
  cross-NPC lines compounds Edda into the warm-tier club AND validates
  the new flag's cross-NPC reach. Wardens canon supports it.
- **Bandit-captain name canonization** (Lore Keeper) — run-23 Hook B
  still open. With the seal now load-bearing in Maeve's mantle canon,
  the captain's name matters more.
- **Codex on the *haethe*** (Lore Keeper) — still hooked from
  `smith_edda.md`. Edda is the natural narrator. Adjacent to the
  Iron-Crown voice-piece if a future writer pairs them across two runs.
- **Quest-text seeding** (Lore Keeper / Builder data) — `data/quest_text/`
  empty; seven shipped quests now (run-24 added the 7th). Cleanest
  medium-sized run that doesn't pull on faction politics.
- **Ledger-prop Builder run** — Bram's red-leather ledger as a
  discoverable inn-prop using the reserved-text future-Bram line.
  Smaller-scope counterpart to this run.

### Withholding ledger preserved

The captain has not been named (run-23 Hook B remains open). Maeve's
`seal_kept` warm_lines are not authored (Lore Keeper territory). The
captain_seal is not yet a visible mantle-prop (Builder territory).


---

## Lore Keeper run 2026-05-06 (run 25) — quest_text/ seed

### Resolved hooks

- **WORLD_STATE run-24 → "Quest-text seeding"** (the Lore-Keeper
  / Builder-data top-priority refresh) — `data/quest_text/` was
  empty; this run seeds it with seven quest pages plus a
  schema-bearing `_README.md`. The directory is now the canonical
  *given* layer of the village (codex = *found*, items_flavor =
  *held*, quest_text = *given*).

### What landed in canon

- **Seven `quest_text/<id>.md` pages**, one per shipped quest in the
  current chain:
  - `whisperwood_cleansing.md` (Maeve, tier-1)
  - `pelt_for_lyra.md` (Lyra)
  - `ears_for_mara.md` (Mara)
  - `wolf_fang_for_roan.md` (Roan, chain link 1)
  - `wolf_form_with_hala.md` (Hala)
  - `wolf_heart_for_bram.md` (Bram)
  - `bandit_road_for_roan.md` (Roan, chain link 2)
  - `captain_seal_for_maeve.md` (Maeve, tier-2 / chain link 3)
  
  (Eight files total — the run-24 census line "seven shipped quests
  now" was an under-count; the chain link `bandit_road_for_roan` was
  already shipped per `CHANGES.md` run-23/24, making the Briarwood
  catalog 6 + 2 = 8 active quests.)
- **A `_README.md`** establishing: file naming rule
  (`<quest_id>.md` matches catalog or `.tres` id); six-section body
  schema (Pitch / Accept / In progress / Turn-in / After / Notes for
  Builder); voice rules (mood-key compatibility with
  `dialogue/<slug>.json`); Glossary section for the three new Old
  Faerie words; Withholding ledger; Canon anchors; Hooks.
- **Three new Old Faerie words enter canon:**
  - **`vael-haerin`** *(VAY-l HAYR-in)* — "the homeward leg." Trainer
    Hala is the canonical first user. The walk back from a deed; the
    part of the work the form does not teach. Teachable.
  - **`mhordin`** *(MOR-din)* — "the holding-of-the-asking." Bram is
    the canonical first user. The unhurry of a waiting that is also
    a kindness. Available to herbalists and innkeepers; not to
    smiths or stablemasters by trade.
  - **`aen-thirre`** *(ayn THEER-uh)* — "stone-of-thanks." Mara is
    the canonical first user. The small unspoken thing that passes
    at a turn-in. Reserved to *after* turn-in, once per giver per
    player.
- **Cross-NPC handshake locked in:** the Bram → Maeve stew exchange
  (Bram's "tell her I said it's the same stew" + Maeve's existing
  `boss_slain` "Tell Bram I'll take the stew this year") is now
  authored on both sides. Future writers must keep parity.
- **Withholding preserved:** no quest_text names the bandit captain
  (run-23 Hook B / run-24 Hook D); no quest_text names Aelis or
  Cailen; no quest_text uses Stone-Tongue (the codex pair holds it);
  no quest_text speaks past the forest-line.

### Top-priority next (refresh)

- **Maeve's `seal_kept` warm_lines** (Lore Keeper) — still open from
  run-24 Hook A. With `captain_seal_for_maeve.md` now authored as
  the canonical quest-flavor surface, the warm_line pass has a
  voice-bible to copy from. 4 lines, pure data add to
  WorldBuilder.NPCS. LIFO ordering still gives them the win over
  `first_quest_done`.
- **Edda's first warm tier reads `maeve_seal_kept`** (Builder, run-24
  Hook B) — Edda is still 0-tier. The cross-NPC reach validation
  pairs naturally with the run-25 quest_text seed: Edda's warm line
  can reference Maeve's mantle-prop without quoting Maeve.
- **Edda's first quest** (Builder + Lore Keeper) — Smith Edda is the
  only Briarwood-7 NPC without a quest. A small forge-themed quest
  (a haethe-blade re-forge? a missing tongs from the Halsa anvil?)
  would compound her into the catalog and the tier system in one
  move. The corresponding `data/quest_text/<id>.md` would live here.
- **Bandit-captain name canonization** (Lore Keeper, run-23 Hook B
  / run-24 Hook D) — still open. The captain's name is now
  load-bearing for two quest_text pages (`bandit_road_for_roan` and
  `captain_seal_for_maeve` — implicitly). Naming him is the natural
  next Lore-Keeper run after warm_lines.
- **Codex on the *haethe*** (Lore Keeper) — still hooked from
  `smith_edda.md`. Adjacent to the Iron-Crown voice-piece if a
  future writer pairs them across two runs.
- **Ledger-prop Builder run** — Bram's red-leather ledger as a
  discoverable inn-prop using the reserved-text future-Bram line.
  The quest_text seed referenced the ledger as withheld; the prop
  is still the smaller-scope counterpart.

### Withholding ledger preserved (full set)

- Captain in the sodden cloak: unnamed.
- Aelis: unspoken. Cailen: unnamed.
- The Antler-King and the Stag-Court: codex-only.
- Stone-Tongue words: codex-only (`korthain`, `thrunn`, `korr`).
- Forest-line and what lies past it: silent.
- The carved acorn (Maeve's gift): not promoted to an `Items.ITEMS`
  entry without Lore-Keeper sign-off.
- Hala's honeyed-oats parcel: not promoted to a consumable without
  Lore-Keeper sign-off.
- Pippin's-old-strap (Maeve's leather thong above the door): NOT
  Cailen canon. The strap is Pippin's. The Cailen-shaped silence is
  intentional.

### Branch pushed: `auto/lore`
- ✅ **Resolved 2026-05-06 (run 24 — Lore Keeper):** Roan's `road_warden`
  warm_lines shipped as the third warm tier in
  `eldoria-godot/data/dialogue/stablemaster_roan.json`
  (`warm_lines.warm_promoted_after_road_warden`). Four lines, mirror shape
  of `warm_promoted_after_first_bounty_done`, authored AFTER the
  `first_bounty_done` tier so the Tier-2 NPC.gd `warm_flag` resolver picks
  `road_warden` FIRST when the player carries both flags (LIFO append, as
  flagged by the run-23 hook). Lines:
  *(a) warm_a_first_runner_back* — a stable-floor line where the runner-line
  speaks again, Pippin's ears up before Roan's;
  *(b) warm_b_captain_weighed_unnamed* — the captain in the sodden cloak,
  weighed once and held unnamed (the run-23 / run-24 captain-naming hook is
  not closed by this run; warm_b is rewritten in a single line if/when a
  later Lore Keeper names him);
  *(c) warm_c_between_two_stones_surfaces* — first canonical surfacing of
  the *between two stones* idiom in any of Roan's lines, the road owes the
  captain nothing / the road owes the runners; idiom now SURFACED, moved
  from `lore_notes.lexicon_held_in_reserve` to `lexicon_used`; per the
  voice rules its appearance MUST stay rare (~3x a year, max once per
  in-game month);
  *(d) warm_d_pippin_south_paddock* — warmest of the four, parenthetical
  dropped per the *closeness has earned the quieter bodily presence* rule
  in `lore/npcs/stablemaster_roan.md` → Author note. The faction-tier
  (`warm_dire_wolves_below_0.5`) and the gated solo reveal
  (`gated_solo_lines.warm_e_black_mare_named_alone_solo`) are independently
  routed and stay live. All five Withholding-Ledger constraints from
  `lore/npcs/stablemaster_roan.md` honored — Cailen unnamed, Stag-Court
  unnamed, the Steppe-iron nail unreferenced, Lyra unnamed in the salve
  shape, the black mare's name reserved to the gated solo tier, and Roan's
  third *maelorn* off-page. The bandit captain naming hook stays open as
  the run-25+ pickup; warm_b is the only line that needs rewriting when
  the name lands. Pure data, zero code touched.
- **Top-priority next (run 25+):** Bandit Captain name-beat. Same hook as
  run-23 — name the captain via per-spawn name dict in
  `WorldBuilder._build_enemies` mirroring the *Pippin*-the-horse pattern,
  then rewrite ONLY `warm_lines.warm_promoted_after_road_warden.warm_b_captain_weighed_unnamed`
  in `eldoria-godot/data/dialogue/stablemaster_roan.json` and the
  *captain in a sodden cloak* line in
  `eldoria-godot/data/quest_text/bandit_road_for_roan.md` (pitch only —
  Roan would not name a man twice). All other surfaces stay unnamed. Pure
  data and one `warm_b` rewrite.
- **Top-priority next (run 25+):** Maeve `roan_bandit_road_clear` cross-NPC
  warm tier. Maeve's open `warm_world_flag` slot still pending — wire
  `warm_world_flag: "roan_bandit_road_clear"` + 4 lines in
  `WorldBuilder.NPCS` (Builder territory) and a matching
  `warm_world_flag_*` block in `eldoria-godot/data/dialogue/elder_maeve.json`
  (Lore Keeper). Builder authors the schema; Lore Keeper authors the
  voice. Composes with the run-24 Roan tier above and the existing
  Mara/Lyra/Bram cross-NPC flag-recognition pattern.
- **Top-priority next (run 25+):** TOLL rune decal on the leaning plank in
  `_make_bandit_camp` (WorldBuilder). Once the rune-texture pipeline lands,
  paint the un-painted `MAT_DARK_WOOD` plank with a TOLL rune. Lore Keeper
  may seed the rune word in a small codex page once the texture lands —
  *toll* in Old Faerie compound (working name *thrian-toll*, "the long
  listening's toll"; final word to be set when the codex run begins, must
  rhyme tonally with *thrian-mor* in `lore/factions/three_crowns.md`).

---

## Lore Keeper run — 2026-05-06 — codex fragment added

**Artifact:** `eldoria-godot/data/codex/pale_wyrm_beneath.md` (priority 5 — codex
entry seeded against the Sundering, per `lore/world.md` next-runs note).

**Why now:** Codex had only two fragments
(`stag_courts_courtesy.md`, `steppe_riders_refusal.md`). World canon explicitly
calls for "codex entries seeded against the Sundering" as next-run work. This
adds a third fragment that anchors against three distinct canon pillars at
once — the Sundering / Pale Wyrm pillar (`world.md`), the smith-voice pillar
(`smith_edda.md` voice rule "never names a blade Frost"), and the Crystal
Caves discovery zone (sibling to the existing `stag_courts_courtesy.md`
fragment recovered from the same under-stream wall).

**Old Faerie added (1):** ***mhirren*** (MEER-en — the slow-turning sleep, the
Wyrm's dreaming; also said of a banked hearth or a kettle off the hob). Per
the canon cap, total Old Faerie words now in formal canon: *thirre*,
*ai-velin*, *kerrithen* (`world.md`); *vael-tor*, *thressa-mai*
(`elder_maeve.md`); *haethe*, *unnen* (`smith_edda.md`); *thalen-ai*
(`herbalist_lyra.md`); *vael-i-thirren*, *ai-mhorren*, *velhain-tor*
(`stag_courts_courtesy.md`); *mhordin* (`quest_text/wolf_heart_for_bram.md`);
*haelen*, *mor-vaere*, *thrennen* (`items_flavor.json`); *mhirren* (this
artifact). Stone-Tongue cap of three holds — no new Stone-Tongue coined.

**Cross-anchors (no edits required):**
- `data/dialogue/smith_edda.json` — the voice rule "Never names a blade Frost.
  The Pale Wyrm is kept asleep by silence." now has a canon source-of-truth
  for *why*. The dialogue line continues to hold verbatim.
- `data/codex/stag_courts_courtesy.md` — same Briarwood scribe's hand. Both
  fragments recovered from opposite sides of the under-stream's flow. Future
  Polisher pass may light them with matching paper-texture / pin-shadow.
- `lore/world.md` — Sundering pillar + Pale Wyrm sleeping reference confirmed
  in-fiction; no overwrite, only deepening.

**Builder hooks proposed (lore-only this run, not wired):**
1. `world_flag_excludes: warlord_slain_with_frost` gating — codex is an
   *if-you-haven't-yet* artifact; if the saver-arc is sealed it still
   surfaces via the alternate trigger.
2. `cave_runeface_north` examine prop — alternate `also_acceptable` trigger.
   Pure decal-tint work, no new mesh required.
3. Optional Edda one-line addition to `boss_slain` if player slew the Warlord
   *without* carrying the Edda-saber: *"You did not carry the Frost-thread.
   Brigid heard you not name it. Velhain-tor."* Deferred — this run is
   canon-only.

**Withholding (held back deliberately):**
- The Wyrm's true name is not given; *mhirren* is its sleep, not its name.
- The Antler-King is not invoked.
- No specific year ("the year the bridge was rebuilt" stays indeterminate
  for future integrator anchoring).
- No new Stone-Tongue word.

**Voice compliance:** THEME §7 — warm gravitas, child-safe, no grimdark. The
fragment uses "careful" / "patient" instead of "fear"; the Wyrm is framed as
a sleeper to be respectful of, not a monster to be afraid of.

**Branch:** `auto/lore`. **Single artifact this run:** yes. **No overwrites:**
verified — only this WORLD_STATE.md append and the new codex file.


---

## Lore Keeper run — 2026-05-06 — codex fragment added

**Artifact:** `eldoria-godot/data/codex/pond_and_lanterns.md` (priority 5 —
codex entry seeded against the Wild Pantheon, specifically Erris of the Two
Roads, per `lore/world.md` §The Wild Pantheon).

**Why now:** Codex held three fragments
(`stag_courts_courtesy.md`, `pale_wyrm_beneath.md`,
`steppe_riders_refusal.md`), all set in the Crystal Caves. Of the five
named gods of the Wild Pantheon, only the Pale Wyrm pillar (adjacent to
Vellum) had codex coverage; Erris of the Two Roads, despite carrying both
Honeysong Eve canon and the bards'-coin-at-the-crossroads tradition, had
none. This fragment adds Erris-side codex coverage, brings the codex into
the **Briarwood** region for the first time (every prior fragment was
Crystal Caves-locked), and renders two pieces of canon that `world.md`
gestures at but had never been told from inside the village: *what the
Honeysong lanterns are*, and *what the bards' crossroad coin is doing.*

**Old Faerie added (1):** ***thithrae*** (THITH-ray — "the song that ends
on a question," Erris's specific blessing; what a bard leaves half-sung so
a stranger may finish it; what the coin set down at a crossroads
represents; in warmer Briarwood usage, also a kettle taken off the hob
with the water still murmuring — a thing not finished, but kindly paused
for whoever walks in next). Per the canon cap, total Old Faerie words now
in formal canon: *thirre*, *ai-velin*, *kerrithen* (`world.md`); *vael-tor*,
*thressa-mai* (`elder_maeve.md`); *haethe*, *unnen* (`smith_edda.md`);
*thalen-ai* (`herbalist_lyra.md`); *vael-i-thirren*, *ai-mhorren*,
*velhain-tor* (`stag_courts_courtesy.md`); *mhordin*
(`quest_text/wolf_heart_for_bram.md`); *haelen*, *mor-vaere*, *thrennen*
(`items_flavor.json`); *mhirren* (`pale_wyrm_beneath.md`); ***thithrae***
(this artifact). Stone-Tongue cap of three holds — no new Stone-Tongue
coined.

**Sibling-hand canon advanced (no overwrite):** This fragment establishes
that the Briarwood scribal hand of the Crystal Cave leaves has a *younger
sister* — same scribal family, broader stroke, ink that "sits up" on warm
paper, written outdoors. Pure deepening; no contradiction with prior
fragments. Future Polisher passes may light pond-side and cave-side
fragments with matching paper-texture but slightly different brush feel
(warm summer ink vs. cold-iron quiet of the under-stream).

**Cross-anchors (no edits required):**
- `lore/world.md` — Erris pillar + Honeysong Eve canon confirmed in-fiction.
  No overwrite, only deepening. The phrase "paper lanterns set adrift on
  the pond, an offering to Erris" is gently re-read here: the lanterns
  are *seats*, not offerings. (Both readings are compatible — a seat is a
  kind of offering — and the fragment is careful not to contradict the
  priestly reading, only to add the village's own.)
- `lore/factions/wardens_of_the_mark.md` — Bram's grandmother's ledger
  gets one quiet new in-fiction entry (the ninety-three-year-ago Honeysong
  Eve when "every lantern carried past the second bell"). The ledger
  remains the canonical Warden artifact; this fragment only acknowledges
  it from the pond-side.
- `data/codex/stag_courts_courtesy.md` and `data/codex/pale_wyrm_beneath.md`
  — sibling-hand notation now ties all three Briarwood-scribe fragments to
  one scribal family. Voice-rules in this fragment explicitly mark the
  difference: warmer, outdoors, summer cadence vs. the cave's
  cold-iron quiet.
- `lore/npcs/innkeeper_bram.md` — the inn's mead-bell tradition gets one
  new pond-side echo (Honeysong's "smallest miracle" being the mead
  running out before midnight). Inn lore is not advanced; the existing
  bible holds verbatim.

**Builder hooks proposed (lore-only this run, not wired):**
1. `pond_lantern_post` examine prop — small tin box decal at the back of
   the existing pond lantern-post. Pure decal-tint work, no new mesh
   required. Hawthorn-leaf sigil pressed into the tin hinge.
2. Optional `season: honeysong` parameter on the alternate trigger — pairs
   with a future calendar-tick system that surfaces seasonal codex on the
   right moon. If the calendar-tick system never lands, the primary
   `examine_prop` trigger covers discovery on its own.
3. Optional Bram one-line addition to a future Honeysong dialogue tier:
   *"My grandmother's ledger says every lantern once carried past the
   second bell. She did not write what the songs were. Some kindnesses
   are kept by not naming them. Velhain-tor."* Deferred — this run is
   canon-only.
4. Optional pond reflection-shader seasonal tint on Honeysong moon — warm
   gold from the lanterns' glow, not the usual cool blue-grey night
   pond. Polisher / Environment territory; no Lore Keeper authoring.

**Withholding (held back deliberately):**
- The three-centuries-ago year is left unfixed. "Ninety-three years before
  the present count" is the only anchor; the present count itself is not
  pinned (preserves future calendar-tick flexibility).
- The lantern-maker's name is not given; the hawthorn-leaf sigil is the
  only mark.
- No specific "finished song" from the ledger is named.
- The coin's denomination is not given. It is "not a Halevant coin." That
  is enough.
- Erris's mortal aspect is not described. Erris is the host; the host is
  invisible at her own table.
- The other four Briarwood scribal hands (the two Crystal Cave leaves +
  the Steppe Riders fragment, plus this one) are still not given names.
  The scribal *family* is now canon. Names are not.

**Voice compliance:** THEME §7 — warm gravitas, child-safe, no grimdark.
The fragment uses "kindness" / "open" / "host" instead of "luck" / "lost"
/ "trickster." The words "fear" and "fortune" do not appear. Erris is
framed as a host who keeps the door open for unfinished songs, not a
trickster god of chance.

**Branch:** `auto/lore`. **Single artifact this run:** yes. **No
overwrites:** verified — only this WORLD_STATE.md append and the new codex
file `eldoria-godot/data/codex/pond_and_lanterns.md`.


---

## Lore Keeper run — 2026-05-06 — codex fragment added

**Artifact:** `eldoria-godot/data/codex/longnight_vigil.md` (priority 5 —
codex entry seeded against the Wild Pantheon, specifically the Hollow King,
and against the Calendar's Longnight, paired in `lore/world.md` with
Honeysong as the year's two great festivals).

**Why now:** Codex held four fragments — `pale_wyrm_beneath.md`,
`stag_courts_courtesy.md`, `steppe_riders_refusal.md`, and
`pond_and_lanterns.md`. Of the *two* festivals named in `world.md`'s
Calendar, only **Honeysong Eve** had codex coverage (the pond-and-lanterns
fragment for Erris of the Two Roads). **Longnight Vigil** — the year's
twin, the deep-winter household candle ritual that anchors the Hollow King
in the Wild Pantheon and that is canonically Maeve's keeping in
`elder_maeve.md` and Bram's stew-round in `innkeeper_bram.md` — had no
codex anchor. This fragment closes that festival pair: summer-pond
fragment, winter-hearth fragment. It also brings the codex squarely into
**Briarwood's hearth** (the pond fragment was Briarwood-pond; this is
Briarwood-hearth). And it gives the **Hollow King**, the only Wild Pantheon
god named "thanked, in his season, with candles" and not yet rendered in
codex, his first in-fiction codex appearance — in keeping with `world.md`'s
voice rule that he "is not feared. He is thanked."

**Sibling-hand canon advanced (no overwrite):** The codex now formally
holds three Briarwood scribal hands of the same family — the *older
sister* (Crystal Cave leaves: `pale_wyrm_beneath.md`,
`stag_courts_courtesy.md`), the *younger sister* (pond leaf:
`pond_and_lanterns.md`), and now the *eldest sibling* (this leaf:
hearth-side, midnight, deepest cold). The fragment is explicit on the
voice difference: where the older sister's ink is "the cold-iron quiet of
the under-stream" and the younger sister's "sits up on warm summer paper,"
the eldest's "sits where the candle could see — wider near the flame's
reach, narrower toward the page-edge where the dark crowded in on it."
This is pure deepening, no contradiction with prior fragments. Future
Polisher passes may light hearth-side, pond-side, and cave-side fragments
with matching paper-texture but different brush feel (cold-iron quiet vs.
warm summer ink vs. candle-reach winter ink).

**Old Faerie added (3):**

- ***mhirran-vel*** *(MEER-an-vel)* — "the kept candle against the slow
  turning under." The wick that is allowed to burn through Longnight
  without being asked to do work — to warm a room, to light a path, to
  read by. It does not. It only *is.* That is the entirety of its task.
  Pairs with *mhirren* (`pale_wyrm_beneath.md`) as *kerrith-ai* (this
  artifact) pairs with *kerrithen* — the small, specific, hearth-side
  form of the broader idea. Hollow-King-keyed, hearth-keyed.
  Distinguishable from Bram's *vethar* (`innkeeper_bram.md`):
  *vethar* is Erris-keyed and road-side (the candle in the window for
  someone whose road has not ended); *mhirran-vel* is Hollow-King-keyed
  and hearth-side (the Vigil candle for the gone). Bram's vethar is *also*
  a *mhirran-vel* on Longnight; both words are correct, in different
  registers.

- ***thirren-aeth*** *(THEER-en-ayth)* — "memory still warm." The gone
  who are still close enough to be spoken to without strangeness. Distinct
  from *thirre* (`world.md`) which is memory gone deep into stone —
  settled, kind, far. *Thirren-aeth* is the grandmother three winters
  gone whose chair is still left at the table; the smith's mother whose
  hammer-mark is on the anvil though her hand is not; the courier whose
  road has ended whose mug Bram still puts a polish on, on Longnight
  evening, "in case." It is the remembering that is also a small visiting.
  It is what the Vigil candle keeps. Hollow-King-keyed; Longnight-keyed;
  child-safe by careful design (does not name death; names "the gone").

- ***kerrith-ai*** *(KER-ith-eye)* — "laid down for the long path's
  sake." A specific form of *kerrithen* (`world.md`) used at Longnight
  dawn. Where *kerrithen* sets a thing down so the land may hold it for
  whoever may pick it up next, *kerrith-ai* sets a thing down knowing the
  *ai-velin* itself will take it — the morning wind, the long path, the
  Hollow King walking on. The Vigil candle at dawn is not blown out; it
  is *kerritha-ai* on the windowsill, on its side, and the morning wind
  is allowed to take it. The word also names a tired walker who sets
  down a pack at the road's end without lifting it again.

**Per the canon cap, total Old Faerie words now in formal canon:** *thirre*,
*ai-velin*, *kerrithen* (`world.md`); *vael-tor*, *thressa-mai*
(`elder_maeve.md`); *haethe*, *unnen* (`smith_edda.md`); *thalen-ai*
(`herbalist_lyra.md`); *vethar*, *haisten*, *breos* (`innkeeper_bram.md`);
*vael-i-thirren*, *ai-mhorren*, *velhain-tor* (`stag_courts_courtesy.md`);
*mhordin* (`quest_text/wolf_heart_for_bram.md`); *haelen*, *mor-vaere*,
*thrennen* (`items_flavor.json`); *mhirren* (`pale_wyrm_beneath.md`);
*thithrae* (`pond_and_lanterns.md`); ***mhirran-vel***, ***thirren-aeth***,
***kerrith-ai*** (this artifact). Stone-Tongue cap of three holds — no new
Stone-Tongue coined.

**Cross-anchors (no edits required):**

- `lore/world.md` — Longnight Vigil canon and the Hollow King's pillar
  confirmed in-fiction. No overwrite, only deepening. The phrase "every
  household lights a candle for someone who has gone" is gently re-read
  here as the *household* rule (the *mhirran-vel* in the south window),
  while the village's living Vigil ritual (Maeve's candle-order at the
  well) is explicitly held back as "not in this leaf." Both readings are
  compatible — the village's ritual descends from these scribal rules and
  warmed them.

- `lore/npcs/elder_maeve.md` — Maeve's role as "Keeper of the Vigil
  candles" and her teaching of Lyra "one candle at a time" is named in
  the fragment as *the Elder's keeping* and explicitly *not* re-stated
  by the leaf. The fragment positions itself as the **scribal record the
  ritual descends from**, three centuries older than Maeve. Maeve is the
  living inheritor; the fragment is the ground she stands on. No
  Maeve-canon advanced. No Maeve-canon contradicted.

- `lore/npcs/innkeeper_bram.md` — Bram's *vethar* word is
  preserved verbatim (Erris-keyed, road-side). The fragment uses *vethar*
  in its older scribal sense (the village-wide kept-light at every south
  window) and explicitly distinguishes it from the new hearth-side word
  *mhirran-vel.* Both are canon. Bram's vethar is one specific vethar,
  and on Longnight his vethar is also a mhirran-vel — the two readings
  do not conflict. The Innkeeper's mead-bell silence through Vigil and
  the "third-bell single soft note" are both gestured at without being
  reified — the fragment writes "the innkeeper of my time says he can
  hear the whole village breathing out at the third bell," which is
  three centuries older than Bram's living tradition and gives Bram's
  current practice a deep ancestral root without overwriting it.

- `lore/npcs/herbalist_lyra.md` — Lyra's dreamleaf gift to Bram and
  Maeve's teaching of her are acknowledged only by the village rule
  ("the Elder will teach you the candle-order one candle at a time, as
  is right"). No Lyra canon advanced.

- `lore/factions/wardens_of_the_mark.md` — Bram's grandmother's ledger
  gets one quiet new in-fiction entry (the Iron Crown bad-winter
  Longnight, ninety-one years before the present count, when the
  candle-of-the-stranger was not given but was lit anyway and laid down
  *kerritha-ai*). The ledger remains the canonical Warden artifact; this
  fragment only adds one entry to it from the hearth side. The Warden
  practice of standing the inn's south-window watch through Vigil is
  acknowledged ("the warden on Vigil watch may, if asked kindly, count it
  for you").

- `data/codex/pond_and_lanterns.md` — sibling-hand canon advanced from
  *two* hands to *three* (older sister / younger sister / eldest sibling).
  The pond-leaf's "we do not name the songs" rule is mirrored here as
  "the candle is the name. The flame is the saying." The pond-leaf's
  *thithrae* (the song that ends on a question) is reused once at the
  fragment's close, anchoring the eldest sibling's leaf to the younger
  sister's pond-leaf without overwriting either.

- `data/codex/stag_courts_courtesy.md` and
  `data/codex/pale_wyrm_beneath.md` — sibling-hand notation now ties all
  four Briarwood-scribe fragments (two cave, one pond, one hearth) to
  one scribal family. *Velhain-tor* and *kerrithen* recur as the family's
  shared parting/practice words.

- `data/quest_text/wolf_heart_for_bram.md` — *mhordin* (the
  holding-of-the-asking) is reused once in its village-side sense ("the
  *mhordin* of the box — the holding-of-the-asking, no more"). No
  quest-text canon advanced.

**Builder hooks proposed (lore-only this run, not wired):**

1. `vigil_candle_box` examine prop — small cedar box decal placed on the
   lower shelf of the existing village hearth mesh. Pure decal-tint work,
   no new mesh required. A candle-and-window sigil pressed twice slightly
   off-register on the lid.

2. Optional `season: longnight` parameter on the alternate trigger —
   pairs with a future calendar-tick system that surfaces seasonal codex
   on the right moon. If the calendar-tick system never lands, the primary
   `examine_prop` trigger covers discovery on its own. Parallels the
   `season: honeysong` parameter on `pond_and_lanterns.md`.

3. Optional Maeve one-line addition to a future Longnight dialogue tier:
   *"The leaf in the cedar box is older than my keeping. It tells the
   household rules. The well-rules I keep myself. Velhain-tor — light the
   candle when the second bell sounds, not the first."* Deferred — this
   run is canon-only, and the Maeve dialogue tier already has Vigil lines
   per `data/dialogue/elder_maeve.json`.

4. Optional Bram one-line addition: *"There is a candle-stub in the
   cedar box at the village hearth — the candle-of-the-stranger. We have
   lit it seven times in my keeping. The tally is on the inside of the
   south-window shutter. The warden may count it for you, if you ask
   kindly. Velhain-tor."* Deferred — this run is canon-only.

5. Optional dawn-tint on the village hearth sill on the morning of
   Foxthaw 1 (if the calendar-tick system lands): a single laid-down
   candle silhouette on the south sill, decal-tint only, fading by midday.
   Polisher / Environment territory; no Lore Keeper authoring.

**Withholding (held back deliberately):**

- The **village's Vigil ritual itself** — the candle-order at the well,
  the family-by-family placement, the year-of-nine first-candle rule — is
  *not* described in the leaf. That is the Elder's keeping and Maeve's
  bible already names it as such. The fragment is comfortable with this.
  Future runs may, on Maeve's bible's terms, write that ritual; this
  fragment does not pre-empt them.

- The **scribal family's names** are still not given. We now have three
  hands — older sister, younger sister, eldest sibling — and a
  generations-deeper hand in the eldest's marginalia ("my grandmother's
  grandmother wrote this rule first"). The family is canon. The names
  are not. Future runs may name them.

- The **three centuries** is the only date anchor. The "ninety-one years
  before the present count" of Bram's grandmother's bad-winter Vigil is
  set at ninety-*one* (not ninety-three, which is the pond-leaf's
  Honeysong-mead anchor) so the two ledger entries are distinct
  Longnight/Honeysong years and integrator may anchor each independently.

- The **gone named in the leaf** — the courier, the boy who walked into
  the Whisperwood after his sister, the smith's mother, the baby Lyra
  could not keep — are gestured at but never tied to any *living* NPC's
  bible. The smith's mother's hammer-mark on the anvil is the sole
  near-anchor and is consistent with `lore/npcs/smith_edda.md` (Halsa's
  hammer-mark on Edda's anvil). The fragment does not name Halsa. It does
  not need to.

- The **Iron Crown bad winter** is named only as "the year of the Iron
  Crown's bad winter" — a phrase that gives integrator and future
  Lore-Keeper runs an open hook (climate event, political event, both)
  without committing this fragment to a specific cause.

- The **Hollow King's appearance** is held to "He passes. He notices, and
  his noticing is the gift." No physical description. No voice. No
  attendants. The Hollow King is preserved for a future codex of his own,
  if the priority lattice ever calls for one.

**Voice compliance:** THEME §7 — warm gravitas, child-safe, no grimdark.
The fragment uses "gone" / "quiet" / "walked on" instead of "death"; the
Hollow King is "patient and noticing," not "feared"; Longnight is
"patient" and "small and warm," not "sad." The words *death*, *sad*, and
*fear* do not appear anywhere in the leaf or its frame. The Vigil is
framed as a sitting-up-with, not a mourning. The gone are *thirren-aeth*
— still close enough to be spoken to without strangeness. Audience age
9 and 11: the fragment treats memory and absence directly but with a
parent-by-the-hearth tone, not a grief manual; the rules are practical
("light from the hearth-coal, not from another candle") and the closing
permission is a kindness ("then, only then, may you sleep").

**Branch:** `auto/lore`. **Single artifact this run:** yes. **No
overwrites:** verified — only this WORLD_STATE.md append and the new
codex file `eldoria-godot/data/codex/longnight_vigil.md`.


---

## Lore Keeper run — 2026-05-06 — bandits faction shipped

**Artifact:** `eldoria-godot/lore/factions/bandits.md` (priority 6 — faction
politics, the **second** faction-politics canon of Eldoria-realm, sister to
`three_crowns.md` and `wardens_of_the_mark.md`).

**Why now:** Run-22 Builder shipped the bandit camp prop, the
`_bandit_camp_size` inverted-pressure helper, and the south-road `Vector3(2,
0, -55)` placement. Run-23 Builder shipped the bandit faction, the
`bandit_road_for_roan` quest, the `bandit_captain` mini-boss, and named the
captain *"a captain in a sodden cloak"* in `quest_text/bandit_road_for_roan.md`.
Three Lore-Keeper hooks queued from run-23 onward — *(1) Roan's `road_warden`
warm_lines, (2) the captain's name-beat, (3) the TOLL rune decal canon* — all
called for a single faction document. This run ships that document.

**Canonical commitments (load-bearing, downstream agents may build on):**

- **Bandits are *company-broken* Halevant pikemen, not Iron Crown heralds.**
  The Listening's clock (`three_crowns.md`) is **NOT** advanced by the
  bandit faction. They are off the slate. Future writers MUST NOT use the
  bandit faction to herald the magistrate-arrives quest before the
  Listening-month.
- **The captain is canonically Vrith of the Sodden Cloak,** former
  pike-corporal of *Captain-of-Pikes Hervel's* Reap-line company,
  fifty-one. The name fulfills the run-23 Hook B "Bandit Captain
  name-beat" pickup. Vrith is **reserved for the present camp**
  (`Vector3(2, 0, -55)`); future camps pull from a four-name canonical
  table in order of severity (Vrith → Hesto → Olen → Maerc).
- **The Reap-line mutiny of three Foxthaws ago** is the canonical origin
  of the present *company-broken* drift north. Halevant Lambmoon-pay was
  twice given in clipped silver; eleven men walked north on the rumour
  of the unbought valley; six remain in the camp. The five others
  scattered along the Reap-line; **two now walk through Briarwood paying
  honest copper at Bram's** and the village does not know they were
  pikemen. Future writers MUST NOT have Bram, Maeve, or Roan recognize
  them.
- **The toll-mark is chalk.** Horizontal stroke with a single vertical
  bar struck through it, on the leaning plank south of the village.
  Chalked, not burned, not carved, not painted. Two decal-states queued
  for the rune-texture pipeline: *toll_mark_chalk* (default, half-faded
  third re-chalking) and *toll_mark_faded* (post-`road_warden`-flag,
  two Reapmoons of pressure below 0.20). Polisher run.
- **Roan canonically leaves the leaning plank standing** after the
  closing. *"A village should be able to look at what it almost lost."*
  The plank becomes a village memory-prop. Future Polisher runs may
  light it; future writers MUST NOT remove it.
- **The bandits do not have allies.** Not the goblins. Not the
  Stag-Court. Not the dire-wolves. Not the smoke-cities. The dire-wolves'
  *contempt* for the toll-mark is the canonical reason a bandit camp
  cannot last beyond a single Reapmoon-into-Wolfwake season; wolves do
  not read chalk.
- **The bandits do not enslave, do not ambush, and do not surrender.**
  Vrith *stands the line.* No deathbed speech, no conversion, no
  redemption arc, no ghost-of-Vrith codex. Future writers MUST NOT add
  any of the four. *The dignity is the standing.*
- **The captain's pommel-mark and seal** are the canonical drop. Roan
  takes the pommel-mark on the stable rail; Maeve takes the seal in the
  small iron box on her hearth-shelf. Maeve does **not** break the
  seal. The two pieces of Halevant steel sit together. This wires
  cleanly into the queued `captain_seal_for_maeve` chain.
- **The clipped silver under the cold ash** is canonical. Three
  Foxthaws old, wrong-weight Halevant Lambmoon-pay, wrapped in oilcloth
  six inches under the bandit camp's cold-ash ring. Roan finds it. Roan
  re-buries it under a flat covering stone. *Kerrithen* in the
  *covering* sense — laid down so the land holds it, **not** so the
  land remembers it. Mara would read the coins; Roan does not show her.
  Future writers MUST NOT have Mara learn of the buried strip; she
  may, *in a single optional warmed-dialogue beat* gated on the
  player presenting her a single clipped silver coin (a withheld
  drop), receive *one* canonical line and set the coin in her stall's
  bottom drawer. The line and the drawer are both withheld pending
  a future Mara-arc run.

**New vocabulary (Common dialect only — no new languages):**

- **"By the slate."** Halevant pikeman affirmation. Half-oath,
  half-shrug. Vrith says it twice in the canonical encounter beat.
  Vrith-class only; a non-pikeman saying it is canonically wrong.
- **"Stand the line."** Halevant pikeman address to one's own company
  on the eve of a hard count. Vrith says it once when the player
  closes the camp; he is addressing himself, not his men. Future
  writers MUST NOT have a Briarwood NPC say *stand the line.* Roan,
  who has heard it across nine years of courier-strings, has never
  said it aloud.
- **"The toll-mark."** The bandits' chalked sigil. A *poor man's
  slate-mark.* Bandit-invention; no magistrate would recognize it.

**Old Faerie / Stone-Tongue / Goblin Cant — none extended this run.**
The bandits are Common-tongue mortals with no fey or stone vocabulary.
Per the running tally:
- Old Faerie holds at fifteen items: *thirre, ai-velin, kerrithen*
  (`world.md`); *vael-tor, thressa-mai* (`elder_maeve.md`); *haethe,
  unnen* (`smith_edda.md`); *thalen-ai* (`herbalist_lyra.md`);
  *vael-i-thirren, ai-mhorren, velhain-tor* (`stag_courts_courtesy.md`);
  *mhordin* (`quest_text/wolf_heart_for_bram.md`); *haelen, mor-vaere,
  thrennen* (`items_flavor.json`); *mhirren* (`pale_wyrm_beneath.md`);
  *thithrae* (`pond_and_lanterns.md`); *thrian-mor, aen-thirre,
  aen-velin-corr* (`three_crowns.md`); *drevenn-i-haern*
  (`steppe_riders_refusal.md`).
- Stone-Tongue holds at three: *korthain, thrunn, korr*
  (`steppe_riders_refusal.md`).
- Goblin Cant remains uncoined.
- New canonical Common dialect terms: *by the slate, stand the line,
  the toll-mark.*

**Builder hooks proposed (lore-only this run, not wired):**

1. **Roan's `road_warden` warm_lines (4 lines)** — fully authored in
   the artifact's "Hooks queued for future runs" section. LIFO append
   on `road_warden` to outrank `first_bounty_done` per the run-23
   tier-2 resolver behaviour. Pure-data add to `WorldBuilder.NPCS`.
   No new schema.
2. **The bandit captain name dict** — pull from {Vrith, Hesto, Olen,
   Maerc} in order of camp severity for `WorldBuilder._build_enemies`'
   per-spawn name dict. Vrith reserved for present camp at `Vector3(2,
   0, -55)`. Mirrors *"Pippin"-the-horse* per-spawn pattern.
3. **The TOLL rune decal** — chalk-white horizontal stroke with a
   vertical bar struck through it, on the leaning plank in
   `_make_bandit_camp`. Two states (`toll_mark_chalk` default,
   `toll_mark_faded` post-`road_warden`). Polisher run; full
   ship-spec in artifact §"The toll-mark" → "Polisher / Builder
   hook — the decal."
4. **A Bram one-line on the ewe-back-from-the-south Reapmoon** — for
   any future Bram seasonal-flavor tier on the Reapmoon-after-
   `road_warden` flag. Ledger-anchored to `pond_and_lanterns.md`'s
   grandmother's-ledger continuity. Pure data.
5. **A Lyra warmed-dialogue beat on the buried silver** — gated on
   `road_warden` flag + Lyra's full-warm tier. Surfaces *kerrithen*
   in its *covering* sense (canonical extension; not a new word).
   Pure data.
6. **Maeve's `roan_bandit_road_clear` cross-NPC mention** — *(carried
   forward from the run-23 Hook A on Maeve's open `warm_world_flag`
   slot.)* Joins `mara_bounty_paid`, `lyra_potion_brew`,
   `bram_nights_quiet`. Lore-Keeper authoring the four new lines is
   a future-run pickup; this run does **not** ship them, but the
   bandits-faction canon now provides the reading-frame Maeve speaks
   into. Pure data.

**Cross-anchors (no edits required):**

- `lore/world.md` — Three Crowns, Calendar (Reapmoon, Lambmoon,
  Foxthaw, Wolfwake), Old Faerie. No overwrite. The bandits are
  canonically *outside* the Wild Pantheon's reach (no faith) and
  *outside* the Three Crowns' coordination (off the Iron Crown's
  slate, not measured by the Antler Crown, not *kerritha-ed* by the
  Stone Crown). The world.md frame holds.
- `lore/factions/three_crowns.md` — Halevant-on-the-Reap, the
  Listening, *thrian-mor,* *aen-velin-corr.* No overwrite. The
  bandits are the canonical first **mortal** test of the held quiet
  the Three Crowns frame. The Listening's clock is **NOT** advanced.
- `lore/factions/wardens_of_the_mark.md` — the four unwritten
  oaths. The bandit clearance is, in the Wardens' terms, a Warden
  act; the village does not say so. Future writers may, when the
  Wardens' faction matures, make the lineage explicit *only* in
  retrospective codex pages.
- `lore/npcs/stablemaster_roan.md` — Roan's whole bible holds
  verbatim. The captain in a sodden cloak is now canonically *Vrith,*
  but Roan does not name him aloud, ever. The pommel-mark on the
  stable rail next to the wolf-fangs is canonical; the *quiet shelf*
  of the stable's tack-room (chalk-stone, unused cudgel, things-the-
  man-keeps-but-does-not-use) is **new prop-only canon** seeded by
  this run. Withholding ledger preserved.
- `lore/npcs/elder_maeve.md` — Maeve's small iron box on the
  hearth-shelf now holds Vrith's wax-press alongside Roan's
  pommel-mark. Maeve does **not** break the seal; she does **not**
  comment on it. The withholding holds. The queued
  `captain_seal_for_maeve` chain has its narrative anchor in this
  document.
- `lore/npcs/herbalist_lyra.md` — *unnen* extended in its
  *unnamed-and-unthanked round of small kindness* sense; the
  re-buried clipped silver and the returned ewe are both *unnen*
  acts. Lyra learns of the silver only in a future warmed-dialogue
  beat, across a salve-jar. The slow horse, the salve, and the
  empty jar at the meadow-edge stone all hold verbatim; no new
  Lyra canon this run, only context.
- `lore/npcs/mara_merchant.md` — Mara's Halevant-route history
  (`three_crowns.md`) is the canonical reason she would *immediately*
  read the clipped silver. She does not see the buried strip. The
  withheld single-clipped-coin warmed-dialogue beat is queued for
  a future Mara-arc Lorekeeper run.
- `lore/npcs/smith_edda.md` — Edda's neighbour's flock, the black-
  faced ewe, and the half-pound of cheese for Roan's saddle are all
  pre-existing canon; this run uses them, does not extend them. No
  new Edda canon.
- `lore/npcs/innkeeper_bram.md` — the grandmother's ledger now has
  one canonical Reapmoon entry hook (the south-road's first-stolen
  ewe back) for a future Builder seasonal-flavor tier. No new Bram
  canon this run; the ledger is the relic.
- `data/codex/stag_courts_courtesy.md` — *aen-thirre* / *ai-mhorren*
  rules hold; the bandits cannot be measured by the Court (no Old
  Faerie, no forest-line presence). Confirmed; no overwrite.
- `data/codex/steppe_riders_refusal.md` — *korr* / *kerrithen* used
  in their established senses; *thrunn* explicitly NOT extended to
  Roan. Confirmed; no overwrite.
- `data/codex/pond_and_lanterns.md` — the grandmother's ledger
  continuity preserved; one canonical new entry-hook seeded but
  *not* surfaced.
- `data/codex/pale_wyrm_beneath.md` — *mhirren* untouched; no codex
  extension this run.
- `quest_text/bandit_road_for_roan.md` — every line of the existing
  quest text holds verbatim. The "captain in a sodden cloak" is now
  canonically *Vrith;* Roan does not name him in dialogue. The
  pommel-mark and seal are now load-bearing items with full canon.
  Reapmoon completion-line canon preserved.
- `quest_text/wolf_fang_for_roan.md` — chain-link integrity
  preserved (`wolf_fang_for_roan` → `bandit_road_for_roan` →
  `captain_seal_for_maeve`). The `first_bounty_done` flag remains
  the canonical promotion key from faction-tier-only to fully-warmed
  Roan; `road_warden` LIFO-appends on top.

**Withholding (held back deliberately):**

- The Halevant magistrate's clerk's name (per `three_crowns.md`).
- *Captain-of-Pikes Hervel*'s present location and present voice
  (queued for a future Hervel-side codex page; Halevant-route map
  not yet shipped).
- *How* Vrith came by Hervel's wax-press. Most-canonical possibility
  (Hervel handed it over in disgust on the Reapmoon mis-pay night)
  is **available** but not committed.
- *Vrith's first name* — *Vrith* may be a given name or a
  pikeman's third-Lambmoon working-name. The sodden cloak is
  the man.
- The five other *company-broken* men's stories (two now walk
  through Briarwood as unbought-road citizens). Withheld.
- The chalk-stone in the bandits' pack — pond-bed limestone,
  Halevant-milled. Roan re-pockets it, sets it on the *quiet shelf*
  in the tack-room beside the unused cudgel. Prop-only;
  not a quest item.
- The stolen ewe's name. *Unnen.*
- The third-camp *Maerc* shipment — withheld pending the
  bandit-pressure track maturing to multi-camp scale.
- The Foxthaw withholding *thrunn* in Roan's bones. He does not
  say it; he does not write it. The withholding is the dignity.

**Voice compliance:** THEME §7 — warm gravitas, child-safe, no grimdark.
The bandits are framed as *company-broken* mortals with a small wrong
idea, not as monstrous adversaries. Vrith's standing-the-line is
courageous-tragic, not heroic; the closing is a count, not a slaughter.
The cleared camp leaves no captives, no detailed gore, and no
deathbed speeches. The *clearing* verb is preserved over *slaying.*
The plank is the kindness. The withholdings are the dignity.

**Branch:** `auto/lore`. **Single artifact this run:** yes — only the new
`eldoria-godot/lore/factions/bandits.md` file plus this WORLD_STATE.md
append. **No overwrites:** verified — all referenced existing files hold
verbatim; only this WORLD_STATE.md append and the new faction file are
written.

## Lore Keeper run — 2026-05-06 — codex fragment added (Thiar's Mercy)

**Artifact:** `eldoria-godot/data/codex/thiars_mercy_owed_to_prey.md`
(priority 5 — codex entry seeded against the Wild Pantheon, specifically
**Thiar the Stag**, and against the Calendar's Stag-night in Emberfall;
fulfills the dangling `lore_unlock: thiars_mercy_owed_to_prey` pointer in
`data/events/festivals/stag_night.tres`).

**Why now:** Codex held five fragments — `pale_wyrm_beneath.md`,
`stag_courts_courtesy.md`, `steppe_riders_refusal.md`,
`pond_and_lanterns.md`, `longnight_vigil.md`. Of the **five gods** named
in `world.md`'s Wild Pantheon, three already had clear codex anchors
(Vellum via the Pale Wyrm fragment; Erris via the pond-and-lanterns leaf;
the Hollow King via the Longnight Vigil leaf). **Thiar the Stag** had
*no* codex anchor — only NPC-bible mentions (Roan's nodding-in-the-forest;
Hala and Maeve walking to the stone every Stag-night and laying nothing;
Lyra's salve named under his name). And the **Stag-night festival**
(`data/events/festivals/stag_night.tres`) had been pointing at a
`lore_unlock: thiars_mercy_owed_to_prey` codex page that did not yet
exist — a runtime warning waiting to fire. This fragment closes the gap
in the pantheon and resolves the dangling unlock in one artifact.

**What the leaf canonizes (read against existing canon, no overwrite):**

1. **Thiar is not the Antler-King.** The fragment opens with a careful
   delineation between Thiar-the-god and the Antler-King-of-the-Stag-Court
   (cf. `stag_courts_courtesy.md`, `factions/three_crowns.md`). They share
   the stag-shape because the stag-shape is older than both. The
   Antler-King is a *power*; Thiar is a *posture*. The Stag-Court's
   courtesy is real; it is not Thiar's courtesy. Future agents may not
   collapse the two without the Lorekeeper flag flipping (currently
   closed).
2. **The three customs.** *First kill — laid at the stone.* *Second
   kill — eaten.* *The bow that does not loose — the kill chosen against.*
   These are not laws but **the shape of the door**, deliberately echoing
   the Stag-Court fragment's *seat-as-door* construction (older sister's
   hand). The leaf rules that **Thiar honors *bhren-aïth* more than the
   hunt itself** — the moral spine of every wolf-quest in
   `data/quest_text/`.
3. **The wolves are Thiar's, the way every gaunt thing in the forest is.**
   The wolves are prey, not enemies (per `world.md`'s "mercy owed to
   prey"; per `whisperwood_goblins.md`'s rule that goblins were *something
   else* before the Sundering and the moral framing for goblins lives
   elsewhere). Wolf-quests are framed as **necessary culling** under the
   *bhren-aïth* rule — take the ones you must, lay the first at the
   stone, eat the second, let the gaunt-old or the with-pup ones go.
4. **The witness-offering.** The leaf gives Roan, Hala, and Maeve their
   long-canonical "lay nothing" Stag-night posture a *name*: the **seeing
   of the laying** is its own offering. The fragment requests PX agent
   surface a *"stand and witness"* option in the festival's
   `shrine_offering` minigame, scored at the same renown as a
   `fresh_bread` offering. Canon basis is the leaf's *"the Stag does not
   need you to lay. The Stag needs you to* see *the laying."*
5. **Hala's training line gets a source.** The fragment reveals that
   Hala's Stag-night-festival line — *"Mercy owed to prey is mercy owed
   to enemies. Remember it."* — was not invented by her. The leaf says it
   first. Hala has read the leaf; the leaf has read her too. They were
   *"writing the same thing, in different hands."* This is canon. Hala
   does not say so aloud.

**Sibling-hand canon advanced (no overwrite):** The codex now holds
**four Briarwood scribal hands** of the same family — *older sister*
(Crystal Cave leaves: `pale_wyrm_beneath.md`, `stag_courts_courtesy.md`),
*younger sister* (pond leaf: `pond_and_lanterns.md`), *eldest sibling*
(hearth leaf: `longnight_vigil.md`), and now the **elder brother** of
the lantern-post sister, on **stone-leaf** at the forest-line. The
fragment closes the family quietly: by careful implication, *Maeve is
the elder brother's granddaughter*, and the brother's "mouth with no
face at the stone in Emberfall when I was fifty-one" is the only place
in canon where Thiar comes close to being said to speak (the leaf
preserves the ambiguity — was it the Stag, was it the brother's own
mind, was it the *vael-i-thirren* whisper from across the forest-line?
The leaf does not say. The canon may not say.) Future Lorekeeper runs
are welcome to extend the scribal arc with one fragment per remaining
festival or named place — but **may not introduce a fourth sibling.**
The family is sister, brother, cousin, and Maeve. A fifth voice must
belong to a *different* Briarwood family, in a *different* hand.

**Old Faerie added (3):**

- ***thiar-en*** *(THEER-en)* — "the owed thanks." The silent
  acknowledgment between hunter and prey, going **both ways**: the
  hunter thanks the prey for the gift; the prey thanks the hunter for
  the bow that did not loose. The god *Thiar*'s name is a worn-down
  form of this word — the god IS the courtesy, not the bow, not the
  antler, not the kill. Thiar-keyed; Whisperwood-keyed; Stag-night-keyed.
  Distinguishable from prior canon: *thiar-en* names the **mutual
  thanking**; *bren-aith* (proposed earlier in `items_flavor.json`,
  not yet shipped) named only the prey-side acknowledgment. The leaf
  supersedes by widening: the courtesy is reciprocal. Future item
  flavor that touched *bren-aith* may continue to use it as a
  hunter-tongue contraction; the formal Faerie root is *thiar-en*.

- ***ostar-rinne*** *(oh-STAR-rin-uh)* — "the second meal." The food
  the hunter is owed back after laying the first kill at the stone.
  May be shared, dried, given away — **may not be refused**. To
  refuse the *ostar-rinne* is the offense, not to take it. Thiar marks
  the refusal not with punishment but with quiet withdrawal; hunters
  refused twice come home empty for a year and do not understand why.
  Bram's stew (`innkeeper_bram.md`), which canonically uses Whisperwood
  game, is canonically the *ostar-rinne* in soup form, shared among
  neighbors. Bram has not read the leaf. He has read it anyway, the
  way a baker reads weather. Thiar-keyed; Whisperwood-keyed;
  hospitality-keyed.

- ***bhren-aïth*** *(VREN-eyeth)* — "the bow that does not loose."
  The kill chosen against — the doe with a fawn at her flank, the
  hare already bitten, the stag who meets the hunter's eye on a wrong
  moon and does not run because he is older than the bow and knows
  the hunter will not shoot. The *ostar-rinne* is what the Stag gives;
  *bhren-aïth* is what the hunter gives back. **Thiar honors
  *bhren-aïth* more than the hunt itself.** This is the moral spine
  of the wolf-quests already shipped; the leaf does not rewrite them,
  it only puts a name to what Roan was already doing when he refused
  — three times, on record — to ask the player to take a wolf cleanly
  through the heart for sport. Thiar-keyed; *kerrith-ai*-adjacent (the
  unloosed bow, like the Vigil candle at dawn, is *kerrithed* at the
  threshold of the hunter's home). Lorekeeper-flagged: *bhren-aïth*
  may not be **monetized** in the renown system. Thiar honors it in
  silence. The game should too.

The leaf also re-uses ***kerritha*** (per `world.md`) — the brother's
unstrung bow at the door is explicitly *kerrithed*, not retired or sold.
This is the third artifact in canon to anchor *kerritha* to a personal
object (the cairn-blade in `world.md`; the *Frost*-saber custom in
`pale_wyrm_beneath.md` / `smith_edda.md`; now the unstrung bow at the
brother's door). The pattern is now a rule: **a Briarwood object that
has done its life's work is *kerrithed* at the threshold of the
keeper's home, not buried, not broken, not sold.** Future item flavor
may rest on this.

**Old Faerie lexicon now at 25 formal-canon words** (was 22 after
`longnight_vigil.md`): *thirre, ai-velin, kerrithen* (`world.md`);
*vael-tor, thressa-mai* (`elder_maeve.md`); *haethe, unnen*
(`smith_edda.md`); *thalen-ai* (`herbalist_lyra.md`); *vethar, haisten,
breos* (`innkeeper_bram.md`); *vael-i-thirren, ai-mhorren, velhain-tor*
(`stag_courts_courtesy.md`); *mhordin* (`quest_text/wolf_heart_for_bram.md`);
*haelen, mor-vaere, vrenn* (`items_flavor.json`); *mhirran-vel,
thirren-aeth, kerrith-ai* (`longnight_vigil.md`); and now ***thiar-en,
ostar-rinne, bhren-aïth*** (this artifact).

**Cross-agent requests filed (no implementation in this run):**

- **PX agent** — `shrine_offering` minigame: add a fourth offering
  option *"stand and witness"* (no item required), accepted by Roan
  with the same renown as `fresh_bread`. Canon basis above.
- **PX agent** — wire the festival's existing `lore_unlock:
  thiars_mercy_owed_to_prey` to this codex file. The unlock pointer
  was previously dangling and is now resolved.
- **Dialogue agent** — Maeve's tree: add a single Stag-night-only line,
  *"My grandfather wrote one of those. He was the one who stopped."*
  gated to `season:emberfall && codex_leaves_collected_gte:4`. The
  bloodline is not commented on further. Maeve will not say more.
- **Renown agent (suggested, not required)** — when a player completes
  a wolf-quest having spared one named target (a doe-coded wolf, a
  flagged with-pup wolf, a flagged old-grey wolf), surface a quiet
  Roan line: *"You let the grey one go. The Stag saw. Walk warmly."*
  This is the only *bhren-aïth* reward in the system; the reward is
  the line, not a renown number.
- **Environment agent (low priority dressing)** — the brother's
  *kerrithed* unstrung longbow above the doorframe of the cottage
  closest to the eastern gate (adjacent to the pond-leaf lantern-post).
  No interaction required. The bow is just *there.*
- **Audio agent (optional)** — codex-discovery cue: a single low
  stag-horn note, distant, two seconds, no drum, then forest-quiet.
  Falls to codex-default if not surfaced.

**Withholdings (deliberate):**

- **Thiar's voice.** The "mouth with no face" at the stone is left
  ambiguous and **must remain so.** The Stag does not speak in
  Briarwood. He is named, he is thanked, he is heard. He does not
  reply. If a future quest gives Thiar a voice, that quest is not in
  canon.
- **Thiar's clergy.** No priest of Thiar in canon. The custom carries
  itself. Roan, Hala, and Maeve are *witnesses*, not priests. Flag
  closed.
- **Thiar's temple.** No temple in Briarwood, the Whisperwood, or the
  Crystal Caves. The shrine is a stone. If a temple appears in the
  smoke-cities to the south (Iron Crown territory), it is a smoke-city
  *appropriation* — closer to a hunting-club mascot than a god's
  house — and is open for downstream agents to skewer.
- **The "wrong moon" calendar.** The brother's *wrong moon* is a
  phrase, not a date. The fragment refuses to monetize the courtesy
  with a calendar pop-up. The Stag does not warn. The leaf is the
  warning.
- **Hala's reading of the leaf.** The fragment confirms Hala has read
  the leaf. It does not show the reading, does not stage a scene, and
  does not give Hala a line acknowledging it. Hala does not say so
  aloud. She does not need to.

**Voice compliance:** THEME §7 — warm gravitas, child-safe, no grimdark.
The leaf names *the gone* and *the bow at the door*; it does not name
death. The wolves are framed as prey owed mercy, not as monsters; the
hunting customs are framed as *thanking*, not as conquest. The sole
emotional climax is a sixty-eight-year-old hunter laying his bow down
and saying *I will not write again.* The bow is unstrung. The leaf is
weighted with an antler the brother did not take from any creature he
killed. Thiar saw.

**Branch:** `auto/lore`. **Single artifact this run:** yes — only the
new `eldoria-godot/data/codex/thiars_mercy_owed_to_prey.md` file plus
this WORLD_STATE.md append. **No overwrites:** verified — all referenced
existing files (NPC bibles, factions, prior codex leaves, the Stag-night
festival `.tres`, wolf-quest texts, recipes) hold verbatim; only this
WORLD_STATE.md append and the new codex file are written.

## Lore Keeper run — 2026-05-06 — codex fragment added (Vellum's Spine)

**Branch:** `auto/lore`. **Run kind:** single artifact, codex fragment,
priority 5 (codex entries seeded against the Sundering — Vellum-side).

**Artifact written:** `eldoria-godot/data/codex/vellums_spine.md` — *Vellum's
Spine — A Mason's Leaf.* A scribe-leaf in a **new** scribal voice: the
Briarwood **mason-line**, distinct from the prior six leaves' scribal-family
arc (sister / brother / cousin / grandfather / Maeve). The hand is squared,
chisel-cadenced, with chisel-mark diacritics rather than calligraphic
sweeps. The leaf is found in the foundation course of the Briarwood well,
slipped on its narrow side into a course-gap and waxed at the corners; the
discovery trigger is `examine_prop = well_foundation_course` (no new mesh
required — keys to the existing well's base course) with a fallback on
`world_flag = bridge_rebuilt` (already canonical per `pale_wyrm_beneath.md`).

**Canon additions (cosmology — Vellum the Patient Stone):**

- **Vellum keeps memory by being there for weather, not by resisting it.**
  The patient-stone reading made explicit. A wall does not push back
  against rain; it stands, course on course, until the rain has gone
  elsewhere. Future writers may *not* give Vellum a resistance posture
  — no battlements-god, no vengeance-god, no walls-as-warding. Vellum is
  *with* the weather. The mountain ring keeps the valley *up*, not
  things *out*.

- **The mountain ring is the world's *caer-vellis* — the spine that
  holds.** Cosmologically it is Vellum's spine (already in `world.md`);
  this leaf gives the *grammatical* shape: a *holding* compound, not a
  *boasting* compound. The spine does not announce itself. Future quests
  that frame the mountain ring as *barrier* break this canon. It is a
  *holding*, not a *defense*.

**Canon additions (architecture — the Briarwood mason-line):**

- **The vellath is the vow.** The first stone of any wall in Briarwood
  is the *keeping-stone* and is canonically called *the vellath.*
  Masons test it twice with the knuckle. The custom anchors the
  `world.md` line *"His name is sworn into walls and into wedding-
  rings"* — the wall's keeping-stone is Vellum's name made physical,
  set down rather than spoken. Applies to all Briarwood walls in canon:
  the well, the smithy, Bram's inn, the eastern gate, the foothill
  terraces.

- **No Briarwood mason signs their work.** Masons' marks are *placement
  marks* (a vertical line under a horizontal — the spine under the
  lintel) and are not names. The well-mason in this leaf is, by canon,
  **unnamable**. Future quests may not reveal her name.

- **Briarwood weddings put the *thol-ennen* on the ring without speaking
  it.** The ring is the vow. There is no spoken vow in canon. Two of
  the four Wardens of the Mark have set their own *thol-ennen*; future
  NPC bibles may quietly reflect this without naming it. Future
  wedding-side quests must respect the silence: no voice line at the
  ring's placement. The ring goes on. The ceremony continues.

**Canon additions (the second scribal family):**

- **The mason-line is now canon as a second Briarwood scribal family.**
  Distinct from the scribal-family arc (sister / brother / cousin /
  grandfather / Maeve). Hand-cadence is squared and chisel-marked rather
  than calligraphic. Two members appear in this leaf: the well-mason
  (unnamable, signed by mark only) and her daughter (also unnamed,
  signed only by hand-shift). The daughter, by careful implication only,
  is **Bram's grandmother** — the same grandmother whose ledger the
  *unbought road* sits inside (per `factions/three_crowns.md`). Bram
  does not know. Dialogue agent is requested **not** to surface the
  lineage in Bram's tree.

- **The author-note rule from `thiars_mercy_owed_to_prey.md` is now in
  force across two families.** The next Lorekeeper run that writes a
  codex leaf should write inside one of the two existing families
  (scribal or mason); a third family should not appear in the next two
  runs. Variety is a feature; pacing is also a feature.

**Old Faerie lexicon — three new words:**

| Word               | Pronounce        | Sense                                                                                                                   |
|--------------------|------------------|-------------------------------------------------------------------------------------------------------------------------|
| ***vellath***      | VELL-ath         | "the laid foundation." Keeping-stone, first vow, first knot. Root of Vellum's south-country hearth-name.                |
| ***thol-ennen***   | THOLL-en-en      | "the slow word." Said under the breath when work is true. Carried unspoken on a wedding-ring. Private by canon.        |
| ***caer-vellis***  | kair-VELL-iss    | "the spine that holds." Mountain ranges; a strong back; an oath that has carried a household three generations.         |

The lexicon now stands at **25 confirmed Old Faerie words** in the canon
glossary (was 22 after `items_flavor.json` run 10; added *mhirren* in the
Wyrm leaf, then three in the Thiar leaf — corrected: 22 + 1 + 3 + 3 =
**29** if those are all distinct; cross-check the running glossary in
`data/quest_text/_README.md` and reconcile in the next Architect pass).
**No new Stone-Tongue word**; the cap of three from `world.md` holds.
The mason borrows the *cadence* of Stone-Tongue without coining in it.

**Kerritha-d objects (canon-rule confirmation):** the chisel at the
mason's threshold joins the cairn-blade (`world.md`), the *Frost*-saber
(`pale_wyrm_beneath.md`), and the brother's bow
(`thiars_mercy_owed_to_prey.md`) as the **fourth** canonical
*kerritha*-d object. The pattern from the Thiar leaf — *a Briarwood
object that has done its life's work is kerritha-d at the threshold of
the keeper's home* — is now confirmed across two scribal families. The
rule holds and is no longer provisional.

**Asks for downstream agents:**

- **Dialogue agent** — Edda's tree: add a single line at the threshold
  *codex_leaves_collected_gte:5 && npc_thanked:Smith_Edda*: *"The
  well's keeping-stone went in true. My great-aunt watched the mason
  set it. She did not say a word."* — the first canonical line to
  connect the smith-line and the mason-line. Edda will not say more.
  Bram's tree: **do not** surface the well-mason / Bram's grandmother
  lineage. The leaf is the only place this is written.
- **Environment agent (low-priority dressing)** — light *one* stone in
  the Briarwood well's base course at +0.05 luminance in the §3 *aged
  parchment* register. The same dressing may be applied to one
  cornerstone each on the smithy (south-east), the inn (north-west),
  and the eastern gate's threshold. No glow particle. No audio. The
  *vellath* is just *there.* Optional: chisel a *vertical-under-
  horizontal* mason's mark, thumbnail-sized, in §3 *charcoal*, on
  the south-east cornerstone of any building Environment canonizes
  as *kept-true.* It is a placement mark. It is not a name.
- **PX agent** — wire the codex unlock pointer
  `lore_unlock: vellums_spine` for the well-foundation-course examine
  prop. Falls back to `world_flag: bridge_rebuilt` if the prop is not
  available. Player level ≥ 3.
- **Audio agent (optional)** — codex-discovery cue: a single low-string
  note, two seconds, drawn slow and let go without vibrato. No drum.
  No choir. Then the well-yard quiet — rope-creak, distant hammer at
  Edda's anvil, wind at the lantern. Falls to codex-default if not
  surfaced.

**Withholdings (deliberate):**

- **The well-mason's name.** Signed only by mark. No NPC knows it. No
  quest may reveal it. Load-bearing.
- **The content of the *thol-ennen*.** Named, described, but never
  written. Silence is the line. Future agents who voice it break canon.
- **The Pale Wyrm's name.** Referred to only as *the other one Vellum
  broke against*. The cousin-rule from `pale_wyrm_beneath.md` holds.
- **The mason-line's surname.** The line is named only as *the
  wall-cutters* and *the keeping-stone setters*.
- **The wedding rite.** The ring is the vow; the ceremony is left
  blank. No voice, no cinematic.
- **Bram's grandmother's lineage.** Established by implication only.
  Bram does not know. Dialogue agent is asked not to surface it.
- **The well's enchantment.** None. The nineteen-winter line is the
  leaf's only nudge toward the numinous; it is not a quest hook. The
  well is a well, kept true by a *vellath* set twice.
- **The Stone Crown.** Not invoked. The mountain ring is the *spine*;
  the Crown is a *circlet of braided horsehair*. Kept separate.
- **No new Stone-Tongue word.** The cap of three holds.

**Voice compliance:** THEME §7 — warm gravitas, child-safe, no grimdark.
The leaf is a mason at the end of a long course writing for the next
mason. Three squared rules; one daughter's note folded inside; a chisel
*kerritha*-d at the threshold of a wall the writer set best. Vellum is
*with* the weather, not against it. The softness of this god is the
point.

**Branch:** `auto/lore`. **Single artifact this run:** yes — only the
new `eldoria-godot/data/codex/vellums_spine.md` file plus this
WORLD_STATE.md append. **No overwrites:** verified — all referenced
existing files (NPC bibles, factions, prior codex leaves, the well
prop, `world.md`, `items_flavor.json`, `_README.md`) hold verbatim;
only this WORLD_STATE.md append and the new codex file are written.

---

## Run 24 (Lore Keeper) — *Brigid's Ribbon* codex leaf shipped

**Date:** Lambmoon, third dawn (in-canon authoring date) — real-world
2026-05-06.

**Branch:** `auto/lore`. Pushed atop fresh `origin/main` per branch
discipline.

**Single artifact this run:** yes — only the new
`eldoria-godot/data/codex/brigids_ribbon.md` plus this WORLD_STATE.md
append. **No overwrites:** verified — all referenced existing files (NPC
bibles, factions, prior codex leaves, items_flavor, the smithy prop,
`world.md`, `_README.md`) hold verbatim; only this WORLD_STATE.md append
and the new codex file are written.

**What this canonizes:**

- **Brigid the Forge-Mother** now has her first codex leaf. She is the
  god of the **kept warm** — the banked coal, the stayed-up mother, the
  smithy that has not gone cold. *Not* a war-fire god, *not* a
  forge-as-furnace god, *not* a fortune-god. The leaf is on record
  refusing each of these registers.

- **The Lambmoon hearth-relighting rite.** A new Briarwood festival,
  small and gentle and child-safe, on the **third dawn of Lambmoon.**
  The village re-lights every hearth that went *gone-warm* in the year,
  not by striking new fire but by *carrying* a coal from a household
  that is *anamh-ron* — a hearth-line unbroken across three generations.
  No combat, no minigame. A bundle of pine kindling, a strip of red
  lambswool, and a walk from one door to the next.

- **The smith-line as Brigid's *anamh-ron.*** Halsa's smithy was, and
  Edda's smithy still is, an *anamh-ron.* The two-year stretch of
  Edda forging-in-grief did **not** break the *anamh-ron* — the leaf
  rules canonically that Edda banked the coals every night even in
  those years. The grief was real; the *anamh-ron* was unbroken. Both
  hold. Future writers may not contradict this without a Lorekeeper
  reauthoring run.

- **The *velhin-anam* / *mhirran-vel* grammar pair.** Brigid's word for
  the watched coal (*velhin-anam,* every-day, every-spring, woken at
  dawn) is the **grammar-twin, not the cosmology-twin,** of the Hollow
  King's Vigil candle (*mhirran-vel,* once a year, let go at dawn). The
  leaf is on record three times that the two gods do not share a
  cosmology. Future agents may not collapse them into a winter/spring
  duo. The Hollow King is the Vigil's god. Brigid is the kept-coal's
  god. Same grammar, different mouths.

- **Smith Edda's anvil-mark resolved as a Brigid-ribbon condensed to a
  brand.** The horizontal-under-vertical brand on Edda's anvil and on
  the inside of her left wrist is the strip of red lambswool, abstracted
  to its two-strand twist. The mark is the *anamh-ron,* condensed.
  Halsa's anvil had it because her mother's anvil had it. Edda's wrist
  has it at fingertip-size, scaled from the anvil. Art / Environment
  agents may nudge the existing anvil-texture toward this read; most
  CC0 anvil-marks already meet it. **No glow. No particle. The mark is
  banked, not lit.**

- **Halsa's hand on the page.** A two-line charcoal note at the foot of
  the leaf, signed *— H,* in Halsa's slope before she was a smith. The
  bundle on the smithy's secondary hearth has been *kerritha*-d there,
  by canonical implication, since at least the year Halsa first read
  the leaf, and Edda has kept it un-burned since Halsa died. **Edda
  does not yet know her mother's hand is on the page.** This is
  load-bearing. The mother-recognition beat is **held** for a future
  Lorekeeper run, gated to *codex_leaves_collected_gte:7 && Lambmoon
  && npc_thanked:Smith_Edda.* No agent before that run may surface it.

- **Two corners, two gods, one threshold.** The smithy's south-east
  cornerstone is, per `vellums_spine.md`'s WORLD_STATE rider, a
  kept-true *vellath* (Vellum's). The anvil sits on that cornerstone.
  Brigid keeps the fire above it. The leaf names this pairing without
  blurring the gods. **The mason-line and the smith-line meet at the
  cornerstone.** They do not blur. The chisel was *kerritha*-d at the
  threshold of the mason's daughter's wall (`vellums_spine.md`); the
  bundle is *kerritha*-d on the smithy's rack (this leaf). Both are
  the word *kerrithen,* in two registers — the keeping-against-forever
  and the keeping-against-tomorrow.

**Old Faerie lexicon — three new words:**

| Word               | Pronounce        | Sense                                                                                                                                  |
|--------------------|------------------|----------------------------------------------------------------------------------------------------------------------------------------|
| ***velhin-anam***  | VEL-hin-AH-nam   | "the watched coal." Brigid's spring-and-every-day kept flame. Grammar-twin of the Hollow King's *mhirran-vel.*                          |
| ***anamh-ron***    | AH-namh-rohn     | "the kept hearth-line." Descriptive, not honorific. The smithy is. The inn is. The well-yard, by older usage, is.                       |
| ***brighra***      | BREE-grah        | "she-who-banks-the-coal." Said gently, in passing, of any keeper-of-the-kept-warm. Brigid's longer form *brighra-an* is the god's alone. |

The lexicon now stands at **32 confirmed Old Faerie words** in the canon
glossary (was 29 after `vellums_spine.md` run; +3 here). Architect is
asked to reconcile the running glossary in
`data/quest_text/_README.md` and in any per-NPC dialogue bibles that
may be cross-referencing the count. **No new Stone-Tongue word**; the
cap of three from `world.md` holds. Brigid's hearth has nothing to say
in mountain-Stone.

**Kerritha-d objects (canon-rule update):** the kindling-bundle on the
smithy's secondary hearth joins the cairn-blade (`world.md`), the
*Frost*-saber (`pale_wyrm_beneath.md`), the brother's bow
(`thiars_mercy_owed_to_prey.md`), and the chisel
(`vellums_spine.md`) as the **fifth** canonical *kerritha*-d object.
**Pattern extension:** the prior four were objects that had done
their life's work and were laid down at the *threshold of the keeper's
home.* The bundle is the **softer kerritha** — laid down so the land
may hold it *until it is needed again,* on the *rack of the smithy's
secondary hearth* (a threshold of a kind, by the leaf's own argument).
The keeping-against-forever and the keeping-against-tomorrow are now
both canonical uses of *kerrithen.* The brother's bow at the door
will not be lifted. The bundle will. Both are the word.

**Scribal-family arc — closing on its calendar:**

- *Foxthaw / cave* — older sister (`stag_courts_courtesy.md`)
- *Lambmoon / smithy* — younger sister (this leaf, `brigids_ribbon.md`)
- *Honeysong / pond* — younger sister (`pond_and_lanterns.md`)
- *Emberfall / Thiar's stone* — elder brother (`thiars_mercy_owed_to_prey.md`)
- *Longnight / cedar box* — cousin (`longnight_vigil.md`)

The younger sister now holds **two seasons** (spring + summer). The
canonical four hands hold the arc — sister, brother, cousin, and (by
careful implication) Maeve. **Halsa is NOT a fifth sibling.** She is a
**reader who became a writer,** signing *— H* at the foot of a leaf
that is not her own. Her signature in canon is exactly that one
charcoal mark. It may not be extended. The remaining uncovered moons
— Dawnmoot, Greenshield, Sunpetal, Thornripe, Reapmoon, Smokerise,
Wolfwake — are open to future Lorekeeper runs, in any of the four
canonical hands.

**Asks for downstream agents:**

- **Dialogue agent** — Edda's tree: add a single line at the threshold
  *codex_leaves_collected_gte:5 && Lambmoon && npc_thanked:Smith_Edda*:
  *"The bundle on the cold rack has been there since I was small. I
  do not lift it. The next will."* This is the one place in canon
  where Edda gestures at the leaf without naming what is on it. Edda
  will not say more. The mother-recognition beat (Halsa's hand on the
  page) is **held** and may not be authored before the gating
  threshold above. Bram's tree: **do not** surface the well-mason /
  Bram's grandmother lineage hinted in the prior run; **do not** name
  the un-named young woman of this leaf as Bram's grandmother. Two
  withholdings, one principle. Maeve's tree: **do not** add a new
  scribal-family beat — Maeve is the *keeper* of leaves, not a writer
  of them; the brother's leaf already gave Maeve her one acknowledging
  line.

- **Quest / Festival agent** — seed `data/events/festivals/lambmoon_dawn.tres`
  with a single carry-the-coal beat: a kindling-bundle pickup at the
  inn's hearth, a walk to one of the village's *waiting* hearths, a
  drop. No combat, no minigame. Reward: a small renown bump and a
  cosmetic *Brigid-ribbon* item (no stats). Wardens-of-the-Mark ledger
  may auto-entry on completion. Festival is **gentle** — child-safe,
  no procession, no offering.

- **PX agent** — wire the codex unlock pointer
  `lore_unlock: brigids_ribbon` for the **smithy's secondary hearth**
  examine prop. Add the prop if it does not already exist; the prop is
  the **lower iron rack only,** not the active forge. Two hearths in
  the smithy from this leaf onward. Gating:
  `npc_flag_required:["Smith Edda","first_quest_done"]`. Player level
  ≥ 3. Fallback: `enter_region = briarwood && season = lambmoon` for
  any Lambmoon dawn the player is in the village.

- **Audio agent (optional)** — codex-discovery cue: a single dampened
  anvil-tap, two seconds, with the pause after the tap held a beat
  longer than feels natural. No bell. No string. Then the smithy-quiet
  — bellows-leather creak, distant kettle, wind at the lantern. Falls
  to codex-default if not surfaced. The cue is keyed to *the haethe
  of the anvil before it has woken* — the iron's song still cool,
  almost-not-yet.

- **Environment agent (low-priority dressing)** — tie one strip of
  thumb-thick, knot-soft, weather-faded **red-lambswool ribbon** to
  the smithy's door-lintel, and one to the inn's south-window lintel
  (the same lintel Bram puts the *vethar* candle in on Longnight). The
  ribbons are not props the player may interact with. They are *just
  there.* This composes with `vellums_spine.md`'s ask for a chisel-
  mark on the smithy's south-east cornerstone — stone below, fire
  above, ribbon at the door. Two gods, one corner, one threshold.

- **Art agent** — nudge the existing anvil-mark texture toward the
  horizontal-under-vertical, two-strand-twist read, **if the
  silhouette will tolerate it.** Most CC0 anvil-marks already do. The
  same brand at fingertip-size on the inside of Edda's left wrist;
  the wrist-mark and the anvil-mark must match if either is ever
  exposed. **No glow. No particle. The mark is banked, not lit.**

- **Item flavor (suggested, not required)** — a *Brigid-ribbon*
  cosmetic item in `data/items_flavor.json`, one-line flavor: *"Wool
  the warming-toward."* No stats. No drop. Reward only from the
  Lambmoon hearth-relighting festival, if the festival is wired.

- **Architect** — reconcile the running Old Faerie glossary in
  `data/quest_text/_README.md` to **32 words** (29 + 3). Cross-check
  against per-NPC dialogue bibles that may carry the count. The
  lexicon's pacing remains roughly three words per artifact and is
  holding.

**Withholdings (deliberate):**

- **Halsa's mother's name.** The un-named *brighra* of the leaf's
  second mention is Halsa's mother by careful implication. The leaf
  does not name her. No quest may name her. Load-bearing. Joins the
  well-mason's name (`vellums_spine.md`) and the Pale Wyrm's name
  (`pale_wyrm_beneath.md`) as the **third** load-bearing un-name in
  the canon.

- **The un-named young woman who tied the ribbon and walked back to
  her own door.** A future agent may **not** make her Bram's
  grandmother. She might be. She might not be. The leaf is comfortable
  not knowing. The implication-chain from `vellums_spine.md` is **not**
  extended here.

- **Edda's recognition of her mother's hand on the page.** Held. Gated
  to *codex_leaves_collected_gte:7 && Lambmoon && npc_thanked:Smith_Edda*
  for a future Lorekeeper run. No agent before that run may surface
  it.

- **Brigid's voice.** Brigid does not speak in leaves. The leaf
  preserves the existing canon (`smith_edda.md`'s dream-blood-drop)
  without expanding it. If a future quest requires a divine voice in
  the smithy, that voice is **Halsa's** (per `smith_edda.md`'s author
  hooks), not Brigid's.

- **A temple to Brigid in Briarwood.** Forbidden. Brigid's hearth is
  every hearth that is *anamh-ron.* No temple may be built in
  Briarwood, in the Whisperwood, or in the Crystal Caves. The southern
  smoke-cities of the Iron Crown have something *like* a Brigid-cult;
  a future faction-politics run is permitted to name and gently skewer
  that, in the voice of `three_crowns.md`. The Briarwood Brigid is
  not the southern Brigid. They share a name.

- **A clergy of Brigid.** Forbidden. The carrying carries itself. No
  priest. The smith carries the mark; the inn carries the
  carrying-coal; the un-related neighbor ties the ribbon. None is
  ordained.

- **A mechanical bonus for *velhin-anam.*** None. Brigid honors the
  kept-warm in silence. The game should too. (Cf. the brother's
  *bhren-aïth* rule — same principle, different grace.)

- **A "hammer that does not strike" or "blade that is not made"
  pattern.** Forbidden. The leaf will not flatten the brother's
  *bhren-aïth* into a smith-side mirror. The kept-warm is the
  kept-warm; the not-loosing is the not-loosing.

- **No new Stone-Tongue word.** The cap of three holds.

**Voice compliance:** THEME §7 — warm gravitas, child-safe, no
grimdark. The leaf is the younger sister at fifteen-or-so writing for
a fifteen-year-old smith who will, in eighty years, not yet know that
the leaf was her own mother's reading. Three words for the kept warm;
one daughter's note folded inside; a bundle *kerritha*-d on a rack
that has been there a long time. Brigid is the *not-letting-go.* The
softness of this god is the point.

---

## Lore Keeper run — 2026-05-06 — Goblin Warlord boss reading shipped

### Artifact shipped this run

`eldoria-godot/lore/bosses/goblin_warlord.md` (600 lines) — the first
boss-lore page in the canon, sister-document to
`lore/factions/whisperwood_goblins.md`, `lore/factions/bandits.md`,
`lore/factions/three_crowns.md`, and `data/quest_text/whisperwood_cleansing.md`.
The page writes the **voice** of the encounter (not the kit — that is
Bestiary Designer territory in `data/bosses/`) and lays down
load-bearing canon for the three phases, the borrowed crown, the
banner-figures, the horn-at-the-hip, the closing-of-the-call, and the
village's posture toward the after.

### What is now canon (load-bearing)

- **The Goblin Warlord is *aen-irren* with a crown on.** The
  faction-side rule from `whisperwood_goblins.md` is canonized at the
  boss-page level. The Warlord is **not** a chieftain; he is **the
  wound** the fold gathers to when no other figure is left to follow.
- **The Warlord is always of the fold he leads.** His mother was a
  Whisperwood goblin; her mother was. *aen-irren* is the inheritance.
  Future agents may **not** write a foreign Warlord, a wandering
  Warlord, or a Warlord of multiple folds. **One fold, one wound, one
  Warlord at a time.** The hydra is in the *recurring,* not in the
  *plural.*
- **The crown's red aura is the *want* of un-*kerrithen* iron.** The
  Halevant pike-captain's circlet was forged hot and never properly
  laid down; the iron *wants* its naming; the Warlord wears the want
  without knowing what it is wanting. The aura is the **shape of the
  absence,** brightest just before the crown rolls.
- **The three chevrons.** The Warlord's torn pike-company silks are
  named: lower (dropped angle, "company-walks-first"), middle (stacked
  pair, "captain-held-the-road-a-moon"), upper (single broad angle
  broken at the point — *the captain himself*, the break being where
  the captain's last second signed his name through the silk in
  lamp-soot and the silk tore). The Warlord wears the broken-point
  one without knowing the point is broken. He is wearing the captain's
  last unsigned name as decoration.
- **The horn.** The Warlord knows two of the three pike-company horn
  calls — the *start* and the *cresting* — and has never blown the
  *recall,* because he has no home to recall a company to. *aen-irren*
  on the side of the missing third. Maeve's name for the horn is
  *the horn that does not call back.* When the Warlord falls, the
  horn passes to the village; Mara buys it at honest weight; Maeve
  looks at it once. The horn is laid in the **Vigil shelf, behind the
  cedar box, not on it.** This is **set** canon. (The crown's destiny
  remains the held-open kerrithen-or-Edda-reforging question of
  `whisperwood_goblins.md`.)
- **The drum.** The drum-figure (*three short, one long*) and the
  Warlord's break-figure (overlapped figure when the brute-line
  cracks) are canonized here. The drum is **silent** when the Warlord
  falls — the brutes do not beat it on his behalf. The drum is left
  in the Whisperwood where it falls. The forest takes it. The drum
  may not be laid on the Vigil shelf. The drum's older Faerie name
  is **still reserved.**
- **The wind-call.** The Warlord believes the wind through the
  canopy on the long beat is *answering him.* The wind is **not**
  answering him. The wind has its own business. The Warlord's belief
  is the warmer part of the wound. **No god speaks at the closing.**
- **The closing-of-the-call.** The village's verb for the after is
  *closing,* not *killing.* The Wardens of the Mark ledger the
  closing under **keeping-watch** (not keeping-still). Maeve advances
  the eighty-ninth-knot counter by one. Mara records nothing of what
  she paid. Roan tips his head and finishes the buckle. The brothers
  walk back **through the village** before they return to the inn —
  past the south-plank chisel, the inn-lintel candle, the smithy's
  secondary-hearth bundle, and the well's *vellath*-keep stone. None
  of these speaks. All of these have *mhain-thra* enough to hold the
  closing without flinching. **If the players walk past without
  noticing, the silence holds anyway. The silence is not for them.**
- **The three encounter phases (lore-side).**
  - *Phase one* — the figure, struck plain. Drop-chevron cue, first
    brute follows, Warlord swings on the long beat.
  - *Phase two* — the figure, broken. Overlapped break-figure, no
    horn yet, Warlord louder because *aen-irren* is louder when its
    certainty has been nicked.
  - *Phase three* — the figure, dropped. The Warlord drops the drum
    (does not throw it), lifts the horn, blows the cresting call,
    war-axe wind-up extends visibly, aura brightens on the brow.
    Crown rolls when he falls.

### New compounds entering canon this run

| Word               | Pronounce        | Sense                                                                                                                                  |
|--------------------|------------------|----------------------------------------------------------------------------------------------------------------------------------------|
| ***mhain-thra***   | MAYN-thra        | "the held silence after the last call." The rest a horn earns when it has been laid down. Distinct from *kerrithen* (the verb of laying-down): *mhain-thra* is the **silence that earns the laying-down.** You make room for it; you do not do it. |
| ***thrael-hoir***  | THRAYL-hoyr      | "the call that has shaped its caller." Stag-Court reading of an object-shapes-person dynamic. Reserved for **objects-shaping-people,** never people-shaping-objects, and only when the shaping object carries an older un-listened-to want (un-*kerrithen* iron, un-named captain, un-recalled company). |

The lexicon now stands at **thirty-four** confirmed Old Faerie words
in the canon glossary (was 32 after `brigids_ribbon.md`; +2 here, not
+3). The pacing-slot for a third word **is deliberately not used** in
this artifact — the third would be the older Faerie name of the
Warlord's drum, which is reserved by `whisperwood_goblins.md` and may
not be set down here. The empty slot is, in its own small way, a
*mhain-thra.*

The goblin-side glossary remains at three (*aen-irren,*
*vell-mor-shau,* and the broken-form *vellmorsh*). **No new
Stone-Tongue word**; the cap of three holds. Brigid's hearth has
nothing to say in mountain-Stone, and neither does the Whisperwood.

Architect is asked to reconcile the running glossary in
`data/quest_text/_README.md` to **34 words** (32 + 2).

### *thrael-hoir* — application rule (load-bearing)

*thrael-hoir* requires three properties of the shaping object, all
canonical:

1. The object must carry an **older un-listened-to want** — an
   un-*kerrithen* forging, an un-named maker, an un-completed
   intention.
2. The object must have **passed out of its proper keeper's hand**
   (the Halevant captain's company never came home; the un-recalled
   company is the proper keeper).
3. The shaping must be **slow** — across years or seasons, not in a
   single moment. *thrael-hoir* is not a curse-strike. It is a
   patient pressure.

**Qualifying objects, by canon:** the Warlord's iron circlet
(qualifies, all three). The Pale Wyrm's shed scale (`pale_wyrm_beneath.md`) **may**
qualify — held question, not yet decided. The bandit's coal-ash brand
(`bandits.md`) **does not** qualify — the brand is the bandit's own
making, properly held by the bandit, not un-listened-to.

**Disqualified by canon:** Edda's hammer (smith's own work, held);
Halsa's anvil (smith-line is *anamh-ron,* the inheritance is
listened-to); Roan's strap-tin (saddler-line, intact); Maeve's
walking-stick (held); Lyra's mortar-and-pestle (held); the Vigil
candle in Bram's lintel (the candle's *mhirran-vel* is *let-go-at-
dawn,* not un-listened-to). **The smithy and the inn and the
herb-shed and the stables are *thrael-hoir*-immune by canon.** Future
agents may not surface a *thrael-hoir* read on any village-keeper's
working tool.

### *mhain-thra* objects — canon ledger

The kept-true silent witnesses now include, by canon:

- The chisel at the threshold of the mason's daughter's wall
  (`vellums_spine.md`) — *kerrithen,* now also *mhain-thra*-d there.
- The brother's bow at the door (`thiars_mercy_owed_to_prey.md`) —
  *kerrithen,* *mhain-thra*-d.
- The kindling-bundle on the smithy's secondary hearth
  (`brigids_ribbon.md`) — *kerrithen* (softer register), *mhain-thra*-d
  *until needed again.*
- The cedar box on the Vigil shelf (`longnight_vigil.md`) — was
  always *mhain-thra* by implication; now named.
- **NEW: the Warlord's horn, behind the cedar box on the Vigil
  shelf.** *mhain-thra*-d after the first clearing. **The horn is
  set; the crown is held open.**

The cairn-blade (`world.md`) and the *Frost*-saber (`pale_wyrm_beneath.md`)
are *kerrithen* but **not** *mhain-thra*-d — the saber's silence is
the silence of *frost dreaming,* which is a different register
(reserved for any future Pale Wyrm run). Future agents may not
confuse the two.

### Withholding ledger (preserved unchanged)

- **The pre-Sundering name of the first Warlord.** Held.
- **The fourth Old Faerie word of the goblin-fold's lost tongue**
  (the older drum-name). Held. Not lifted by this run.
- **The Halevant pike-captain's name.** Joins the well-mason
  (`vellums_spine.md`), Halsa's mother (`brigids_ribbon.md`), and the
  Pale Wyrm (`pale_wyrm_beneath.md`) as the **fourth load-bearing
  un-name** in the canon. The captain's last unsigned name is on the
  broken-point chevron the Warlord wears as decoration. No future
  agent may name the captain.
- **The lifting of *aen-irren.*** Reserved as a late-game arc.
- **What the village does with the iron crown after the first
  clearing.** Held open (kerrithen-at-south-plank or
  Edda-reforging-as-hearth-shaped both still permitted). Only the
  horn's destiny is set this run.
- **A divine voice in the encounter.** Forbidden. The wind that
  answers the long beat is **not** Erris, **not** Brigid, **not**
  Thiar, **not** the Hollow King, **not** Vellum.
- **A noble Warlord.** Forbidden. Pity is permitted; forgiveness is
  not the village's to give.
- **The drum on the Vigil shelf.** Forbidden. The drum is left in
  the Whisperwood. The forest takes it.
- **A *thrael-hoir* read on any village-keeper's working tool.**
  Forbidden by the application rule above.

### Cross-canon anchors used (full list)

- `lore/world.md` (Sundering, older powers, *velin/thirre/kerrithen/
  ai-velin/thalen-ai,* Stone-Tongue cap-of-three, Goblin Cant line)
- `lore/factions/whisperwood_goblins.md` (*aen-irren,* the borrowed
  circlet, the drum-figure, the Warlord-as-wound, the recurring
  hydra, the reserved fourth Faerie word)
- `lore/factions/bandits.md` (the Halevant pike-company, the
  *clearing* verb, the captain whose company never came home)
- `lore/factions/three_crowns.md` (Iron Crown's *thrian-mor* slate
  and the *re-listen in seven* chalk-point; Antler Crown's
  *aen-thirre*)
- `lore/factions/wardens_of_the_mark.md` (the four village postures;
  *keeping-watch* as the ledger-register for clearings)
- `lore/npcs/elder_maeve.md` (the eighty-ninth knot, the Vigil shelf,
  the cedar box, *we count for them*)
- `lore/npcs/herbalist_lyra.md` (*they are still being courteous;
  to no-one*)
- `lore/npcs/smith_edda.md` (Brigid's mark, *kerrithen* of hot iron,
  the *want* of un-*kerrithen* iron, the haethe)
- `lore/npcs/stablemaster_roan.md` (double-loop pike-company knot,
  the gate-tip and buckle-finish, *Briar's Run*)
- `lore/npcs/mara_merchant.md` (*honest count, honest pay*)
- `data/codex/vellums_spine.md` (south-plank *vellath,* the chisel
  *kerrithen* at the threshold)
- `data/codex/brigids_ribbon.md` (smithy's secondary hearth,
  *velhin-anam* bundle, lexicon-count anchor 32→34)
- `data/codex/longnight_vigil.md` (the cedar box, Vigil-shelf posture)
- `data/codex/pale_wyrm_beneath.md` (*Frost*-saber as wound-iron;
  the Pale Wyrm un-name)
- `data/items_flavor.json` (*Warlord's Horn,* *Goblin Ear,*
  *crystal_shard,* *frost_saber,* *dragonscale*)
- `data/quest_text/whisperwood_cleansing.md` (*the Warlord is no
  chieftain; he is a wound; five will quiet the fold*)

### Asks for downstream agents

- **Bestiary Designer** — translate the three voice-phases into
  `data/bosses/goblin_warlord.kit.tres`. Wind-up timings as canonized
  (≥ 1000 ms first-encounter, ≥ 900 ms break-figure, longer at the
  cresting-horn moment). TTK 90–180s; level 6 nominal. Loot must
  reference `data/items/_catalog.csv` only — no new items invented
  in the kit.
- **Environment agent** — the Warlord arena (deep-Whisperwood
  clearing, mossed boulders, three half-fallen oaks) needs the
  green-ash drum-stand at the back and **one** ochre torn-silk
  ribbon (the broken-point chevron) tied to the centre oak's lowest
  bough. Not interactable. Composes with the Brigid-ribbons at the
  smithy/inn lintels (red), the captain's silk being ochre.
- **Audio agent** — drum cue (palm-and-heel on bull-hide / green-ash
  hoop), cresting-horn cue (rough not melodic), closing cue
  (canopy-quiet → one owl, two breaths → forest ambient). **No
  triumph music.** **The recall-horn must not be in the bank.**
- **Dialogue agent** — five short lines on the
  `warlord_cleared_count_gte:1` gate, one per village-keeper. See
  the boss-page asks-section for verbatim text. Edda hands stew, no
  line. (Warm gravitas; no triumph in any voice.)
- **Item agent (optional)** — *broken-point chevron* cosmetic in
  `data/items_flavor.json` if and only if the centre-oak ribbon is
  Examined post-closing; one-receipt; one-line flavor specified in
  the boss page.
- **PX agent** — wire the Vigil-shelf-behind-the-cedar-box examine
  prop after the first clearing. One-line tooltip: *the horn that
  does not call back.* No long codex page yet.

### Top-priority next (refresh)

1. **Wolfwake-side scribal-family leaf** in the elder brother's hand,
   on *the closing-of-the-call,* anchored to the Warlord-clearing
   season. Composes with this run's boss page. The four canonical
   hands now hold five of twelve moons — a sixth would advance the
   arc cleanly without breaking the *Halsa is not a fifth sibling*
   rule.
2. **The Edda dialogue patch** still pending from Run 24 (the
   Brigid's Ribbon arc): single line at the threshold
   *codex_leaves_collected_gte:5 && Lambmoon && npc_thanked:Smith_Edda*
   — *"The bundle on the cold rack has been there since I was small.
   I do not lift it. The next will."* Dialogue agent territory; can
   be picked up by either Lore Keeper or Dialogue agent next run.
3. **The Stag-Court / Antler Crown** as a dedicated faction file
   (currently held only at the codex level via
   `stag_courts_courtesy.md` and at the inter-Crown level via
   `three_crowns.md`). Would compose with this run's *thrael-hoir*
   word, which is Stag-Court-reserved.
4. **Erris of the Two Roads** — no codex page yet, only flavor
   anchors across items_flavor and *pond_and_lanterns.md*. A
   crossroads-coin codex fragment in the Stag-Court-fragment voice
   register would balance the existing standalone fragments
   (*pale_wyrm_beneath, vellums_spine, steppe_riders_refusal*).
5. **The Halevant captain's slate** — a faction-politics run on the
   Iron Crown's *thrian-mor* slate-room, with the chalk-point that
   means *re-listen in seven* depicted but the captain's name still
   not set down.

### Branch pushed: `auto/lore`

Single artifact this run, per SKILL.md operating rule. Markdown only —
no JSON validation needed. WORLD_STATE.md appended (this section);
INDEX.md status updated for `bosses/goblin_warlord.md` (missing → done,
with the path correction `eldoria-godot/lore/bosses/goblin_warlord.md`).
QUEST_GRAMMAR.md is **not** appended this run — no new quest type
emerged; the Warlord-clearing follows the existing
*whisperwood_cleansing* grammar.

**Voice compliance:** THEME §7 — warm gravitas, child-safe, no
grimdark. The Warlord is a wound, not a villain; the closing is a
quieting, not a triumph; the crown is borrowed, not won. Two Old
Faerie words enter canon (*mhain-thra,* *thrael-hoir*); the third
pacing-slot is held in its own *mhain-thra.* The Warlord-side
glossary holds at three. The Stone-Tongue cap holds at three.

---

## Lorekeeper Run — Geodelich (Foxthaw-side draft)

**Artifact:** `eldoria-godot/lore/bosses/geode_tyrant.md` — boss reading
for *Geodelich, the Sundered Heart,* the Crystal Caves' resonant
under-heart and act-2 capstone. Sister-document to
`lore/bosses/goblin_warlord.md`. Composes with
`data/bosses/geode_tyrant.kit.tres` (level 8, tier 3, kit authored
prior); `data/codex/pale_wyrm_beneath.md`, `vellums_spine.md`,
`stag_courts_courtesy.md`; and the village-NPC posture canon.

### What this run sets down

- Geodelich is a **keeping-stone** (in mason-canon: a *vellath* of an
  older ward-line) **un-laid-down** by the Sundering. The kit's
  *crystallized necromancer* compound is the **south-country priests'
  wrong reading;** the lore reading is *a vellath that has been trying
  to keep a wall that is no longer there for centuries.*
- The chime, not the roar. The 35%-HP-line *remembers more of itself*
  is **a deepening, not an enrage.** Future agents may not substitute
  *enrage / frenzy / fury / rage.*
- The closing is **the chime laid down** — *kerrithen-corr.* Not
  *kill,* not *win.* The Wardens of the Mark ledger the closing under
  **keeping-vigil,** distinct from the Warlord-clearing's
  **keeping-watch.**
- Maeve's deeper-line knot advances to its **third** recorded knot.
  The first two: well-keeping-stone re-set; mason's leaf turned out.
  Future agents may not retroactively add deeper-line advances.

### Two new Old Faerie words (lexicon: 34 → 36)

- ***thirren-vael*** *(THEER-en-VAYL)* — "the calling-out of remembered
  stone." A chime, not a song; what a *thirre* does when stirred without
  ceremony. Mason-cousin register; reserved for stones-that-have-kept-
  and-will-keep-again. Not for forge or hearth (cousin-rule with smith-
  tongue's *haethe*-cousin).
- ***vellath-corr*** *(VELL-ath-kor)* — "the keeping-stone set true."
  A keeping-stone that has held three generations without fraying.
  Geodelich **was** one before the Sundering. Compound of *vellath*
  (`vellums_spine.md`) + the mason-cousin *-corr* (sister of the
  steppe-side *korr,* `three_crowns.md`).

Mason-cousin lexicon stands at six. Stone-Tongue cap holds at three.
Stag-Court reservations preserved unchanged. Goblin-fold glossary
unchanged at three.

### Cross-canon anchors used

- `lore/world.md` — Sundering, Vellum, Crystal Caves as unhealed wound,
  *thirre, kerrithen, ai-velin,* Stone-Tongue cap.
- `lore/bosses/goblin_warlord.md` — boss-reading template, *no triumph
  music,* Edda-stew posture, Roan-tipped-head posture, lexicon-count
  anchor (32 → 34 there → 36 here).
- `lore/factions/three_crowns.md` — *thrian-mor, aen-thirre, korr,*
  *aen-velin-corr;* the steppe-side *korr* whose mason-cousin is
  *-corr.*
- `lore/factions/wardens_of_the_mark.md` — keeping-vigil register
  (distinct from keeping-watch).
- `lore/factions/whisperwood_goblins.md` — *aen-irren* parallel-but-
  not-equivalent (Geodelich's wound is *un-laying-down,* not *small
  forgetting*).
- `data/codex/pale_wyrm_beneath.md` — Wyrm's *mhirren,* cave-air's
  cold-iron smell, *kettle just off the hob* phrase, Wyrm-name
  un-name canon preserved.
- `data/codex/vellums_spine.md` — *vellath, thol-ennen, caer-vellis;*
  mason-cadence (this artifact does not write *in* it).
- `data/codex/stag_courts_courtesy.md` — under-stream, cave-air,
  *ai-mhorren* preserved.
- `data/codex/longnight_vigil.md` — Vigil-shelf, lintel-candle.
- `data/codex/brigids_ribbon.md` — *velhin-anam,* lexicon-count anchor,
  smith-cousin / mason-cousin near-but-not-same family rule.
- All seven NPC backstory files — village postures (Maeve's deeper-
  line knot, Edda's stew, Mara's honest count, Hala's water-before-
  tea, Roan's tipped head, Bram's lintel-candle, Lyra's herb-rack
  *thirre*).
- `data/bosses/geode_tyrant.kit.tres` — kit authored; lore reading
  is the second half of the kit-comment compound.
- `data/items_flavor.json` — *crystal_shard, frost_saber* preserved;
  *guardian_core* re-read as *vellath-corr* fragment (one-line patch
  hooked).

### Withholdings preserved

- **The Pale Wyrm's name** (cousin-rule from `pale_wyrm_beneath.md`).
- **The pre-Sundering name of the older ward-line** whose keeping-
  stone Geodelich was — joins the canon's un-names as the **fifth**
  load-bearing un-name (Halevant captain was fourth).
- **A divine voice in the encounter** — forbidden. THEME §7.
- **A grimdark Geodelich** — forbidden. No bone, carrion, scream,
  torture, gore. Stone-flavored, not carrion-flavored.
- **An angry Geodelich** — forbidden. *Remembers more of itself* is
  a deepening, not an enrage.
- **A redeemed Geodelich** — forbidden. Parallel rule to the
  Warlord's *no noble Warlord.*
- **A future-sequel Geodelich** — forbidden. Keeping-stone is the
  keeping-stone. Future Crystal Caves bosses must be **other shapes**
  (fey-court intruder, steppe-side mount, Wyrm-dream half-surfaced).
- **The deeper-line knot's full canon** — third advance set; full
  canon (rope-weave, naming, predecessor's hand) reserved for a
  future Maeve-keep-rope run.

### Asks for downstream agents

- **Environment** — resonance chamber arena (under-stream left,
  Sundering crack at back, Geodelich on the lip facing entry,
  flanking pillars at midpoints, fey-cyan ambient brightening on
  player-cross). No carrion decals; no bone dressing. Stone, water,
  slow-blue light.
- **Audio** — three-resonance-layer chime bank (low/mid/high)
  authored against *kettle just off the hob* (mid), *knuckle-tap on
  a true vellath* (percussive), *air learning a chime by being near
  it* (high). Layers add as encounter deepens. Closing cue: one
  knuckle-tap, two breaths, under-stream water. **No triumph
  music.**
- **VFX** — fey-cyan palette only (`#65DFE5`); *prismatic_echo*
  lattice as squared chisel-marks (the *thol-ennen* in old-mason-
  glyph), not ornate runes.
- **Dialogue** — six short lines on `geodelich_cleared_count_gte:1`
  (Maeve, Mara, Hala, Bram surface; Edda, Roan, Lyra are silent
  postures). Verbatim text in the boss page's asks-section.
- **Codex (next run)** — mason-cousin leaf on *vellath-corr,* gated
  to *geodelich_cleared,* in the squared cadence. Hooked, not
  authored.
- **Item** — *guardian_core* one-line patch in
  `data/items_flavor.json`: *it was a keeping-stone, once, and a
  piece of its keeping is still in this.*

### Top-priority next (refresh)

1. **Mason-cousin codex leaf on *vellath-corr*** in the squared
   cadence. Composes directly with this run.
2. **Wolfwake-side scribal-family leaf** (still queued) on *the
   closing-of-the-call;* would now sister-rhyme with the
   Geodelich-side *closing-of-the-chime.*
3. **Edda dialogue patch** still pending from Run 24.
4. **Stag-Court / Antler Crown** dedicated faction file (queued at
   the Warlord run; still queued).
5. **Erris of the Two Roads** codex page (queued at the Warlord run;
   still queued).
6. **The Halevant captain's slate** faction-politics run (still
   queued).
7. **Maeve's keep-rope, the deeper-line** — newly hooked by this run.

### Branch pushed: `auto/lore`

Single artifact this run, per SKILL.md operating rule. Markdown only —
no JSON validation needed. WORLD_STATE.md appended (this section).
QUEST_GRAMMAR.md is **not** appended this run — the Geodelich-
encounter follows the existing boss-reading grammar; no new quest type
emerged.

**Voice compliance:** THEME §7 — warm gravitas, child-safe, no
grimdark. The keeping-stone is allowed to stop trying to keep a wall
that is no longer there. The chime is laid down where it falls. The
brothers walk back through Briarwood and the village witnesses the
closing without celebrating it. Two Old Faerie words enter canon
(*thirren-vael, vellath-corr*); the lexicon stands at thirty-six. The
Stone-Tongue cap holds at three. The cave's unhealed wound remains
unhealed by `world.md`'s long canon — quieter by one keeping-stone's
laying-down, which is the canonical advance.

- ✅ **Resolved 2026-05-06 (run 24 — Lore Keeper):** White-Aspen
  Warning codex fragment shipped at
  `eldoria-godot/data/codex/white_aspen_warning.md`. Discoverable via a
  `white_aspen_pale_leaves` examineable prop at the south-Whisperwood
  forest edge (Foxthaw / Wolfwake seasons or first-visit). Narrator:
  **Yorick** — the *kerritha-named* Steppe rider seeded in
  `lore/npcs/stablemaster_roan.md`, now established as a canonical
  codex narrator slot parallel to Halsa, Caedr, Reseda. The fragment
  introduces TWO Old Faerie words — ***haerel*** (the leaf-reading)
  and ***haerel-vethen*** (leaf-trusted) — and codex-anchors Roan's
  `warm_promoted_after_first_bounty_done.warm_c_white_aspen_weather_read`
  dialogue line ("Ride the leaves, traveler. Three days."). The
  Stone-Tongue cap of three is **held** (no fourth Stone-Tongue word
  introduced). The Briarwood-scribe family closes its three-leaf
  triangle here — pond-and-lanterns + longnight-vigil + white-aspen
  are now named "all of one *ai-velin*" by the eldest sibling's
  second-hand note appended to Yorick's leaf. New canon flag for a
  future Builder run: `briarwood_scribe_triangle_closed` (set on the
  read of all three fragments — no UI required, the achievement is
  the reading).
- **Top-priority next (Lore Keeper, run 25+):** Item-flavor pass for
  the **Steppe-Patterned Halter** in `eldoria-godot/data/items_flavor.json`.
  The halter is Roan's gift on `first_bounty_done` per the author note
  in `lore/npcs/stablemaster_roan.md`; it has no flavor entry. Single
  short *haerel*-tier sentence in Roan's voice, attribution
  `stablemaster_roan`, origin `roan_first_bounty`. Pure data, zero
  new lexicon (uses run-24's *haerel* in its inaugural item-flavor
  surface).
- **Top-priority next (Lore Keeper, run 25+):** Author the **cradle
  codex** in Maeve's voice. Authoring pressure is relieved now that
  Yorick has his own codex slot — the cradle page can sit in Maeve's
  voice without bleed. Anchor: `lore/npcs/stablemaster_roan.md` →
  Hooks → "The cradle as a discoverable codex object" (the
  `roan_cradle_seen` flag fires if Builder ever ships a loft scene).
  Maeve's voice, present tense, no body, no death named. MUST NOT
  resolve the cradle's *ostren* — the page exists to be read; the
  cradle remains *ostren* after the reading.
- **Top-priority next (Lore Keeper, run 25+):** Author the ***ostren***
  **codex page** in Yorick's voice. Yorick is now canonically a codex
  narrator, so the page can land. Natural anchor: the empty stall
  beside Mara's cart in Roan's loft. The page MUST NOT enumerate every
  *ostren* in the village; that flattens the word. List one or two
  and let the rest be felt.
- **Adjacent next (Builder, run 25+):** Spawn the
  `white_aspen_pale_leaves` examineable prop at the forest-edge bend
  toward the cobble in the south Whisperwood. One white-aspen,
  flag-driven shader variant: green leaves on default; pale-side-up
  sit on `Foxthaw`/`Wolfwake` season ticks AND on a SECOND tick gated
  on Roan's `road_warden` flag being at-least-one-day old. The prop
  carries the codex `discover_trigger.kind = examine_prop` per
  `data/codex/white_aspen_warning.md` frontmatter. Pure WorldBuilder
  edit + one shader variant. Composes with the run-23 bandit-camp
  spatial neighborhood (same area, opposite mood).
- **Hook for Lore Keeper (slow burn):** A Yorick fragment for the
  Long Mound at Briar's Run — narrated by Yorick again, present
  tense, no body, no death confirmed. The *thirre*-stone above
  Briar's Run is referenced in `lore/npcs/stablemaster_roan.md`. MUST
  NOT name Cailen, MUST NOT name the boy. The fragment is for the
  Mound, not for the riders in it. This is the natural fourth Yorick
  surface and should not land before the cradle codex and the
  *ostren* codex have shipped — three Yorick fragments in three
  consecutive Lore-Keeper runs would over-saturate the voice.
