# Canon QA — Audit 2026-05-05

**Run:** auto/canon-qa
**Scope:** `THEME.md`, `eldoria-godot/lore/**`, `eldoria-godot/data/**`
**Sparse-checkout note:** `Items.gd`, `WorldBuilder.NPCS`, `pacing/`, `concept/` (other than README), `mood-boards/` (other than README), `recipes/`, `quests/`, `data/items/_catalog.csv`, and the `.tres` set are not present in the working tree this cycle. Findings that depend on those are marked **N/A** with a future-debt flag.

**Branch comparator:** `auto/canon-qa` did not exist on `origin` at start of this run — this is the **first audit cycle**, so every flag below is NEW. Future cycles will diff against this audit.

---

## Counts

| Severity | Count |
|----------|-------|
| **S1**   | **2** |
| **S2**   | **10** |
| **S3**   | **6** |

---

## Check 1 — Orphan ids (cross-ref graph)

Graph at `eldoria-godot/qa/cross_ref_graph.json`. 7 NPCs / 25 items / 2 codex / 25 Old Faerie words / 1 Stone-Tongue word harvested via the Lorekeeper-style frontmatter regex (additional Stone-Tongue words `aei`, `thurra`, `kel-vethran`, `korthain`, `thrunn`, `korr` are present in narrative prose but not in the canonical bullet-list lexicon header — see flag CQ-S3-04).

**Orphans surfaced:**
- `practice_cudgel` referenced as `after_first_quest_complete` reward in `data/dialogue/trainer_hala.json` — **no entry in `data/items_flavor.json`**.
- `Steppe-Patterned Halter` (= `roan_halter_gifted` flag) referenced in `data/dialogue/stablemaster_roan.json` and `lore/npcs/stablemaster_roan.md` — **no entry in `data/items_flavor.json`**.
- `Yew-and-Lantern Brass Token` (Mara's apprenticeship-invitation reward) — reserved-future, not yet committed; tracked only.
- `bram_road_knife` (Honeysong Eve quest reward) — reserved-future, not yet committed; tracked only.
- `paper_lantern` (Honeysong Eve fetch item) — reserved-future, not yet committed; tracked only.

**N/A this cycle (sparse-checkout):** Items.gd id parity for the 25 items in `items_flavor.json` cannot be verified — the file's `_meta.convention` says *"Each entry mirrors an Items.gd id"*, and that file is outside the audit's checked-out paths. Future cycle: pull `Items.gd` into the sparse-checkout list and diff key-set.

## Check 2 — NPC voice consistency

Dialogue `voice_rules` blocks consistently match each NPC bio. Verified spot-by-spot:

| NPC | Voice rule asserted in JSON | Bio anchor |
|-----|-----------------------------|------------|
| Edda | Never names a blade Frost; `*hammer-clang*` tic | `smith_edda.md` §"How she sounds" OK |
| Maeve | Vellum-only invocations; `vael-tor-i` we-form | `elder_maeve.md` §"How she sounds" OK |
| Bram | Erris-only invocations; `*polishes mug*` tic | `innkeeper_bram.md` §"How he sounds" OK |
| Lyra | Both-hands tic; Erris/Hollow King/Thiar-on-hunt-only | `herbalist_lyra.md` §"How she sounds" OK |
| Mara | `*jingle, jingle*` tic; Erris under-breath | `mara_merchant.md` §"How she sounds" OK |
| Roan | `*(adjusts a strap)*` tic; no god aloud; gate-lantern coin | `stablemaster_roan.md` §"What he sounds like" OK |
| Hala | Staff tics; *Vellum keeps* (witnessed, not prayed) | `trainer_hala.md` §"How she sounds" OK |

Cross-NPC **lexicon-coding** rules respected: Lyra uses `vethar` only in reference to Bram's window candle (`boss_slain` line); Hala uses `vael-tor-i` exactly once, in `stag_night_walk`, with an explicit lore-note acknowledgement that Maeve owns the word and this is the sole permitted surfacing. OK.

**Bio-integrity issues found at this depth (cataloged in flags as canon-coherence, separate from voice):** see CQ-S1-02, CQ-S2-01..05, CQ-S2-09..10.

## Check 3 — Region / faction consistency

| Item | Region/Faction claim | Cross-canon | Verdict |
|------|----------------------|-------------|---------|
| `chainmail` | Iron Crown make, Briarwood-mended | world.md | OK |
| `crit_amulet` | Stone Crown rider-make | world.md | OK |
| `crystal_shard` / `dragonscale` / `guardian_core` | Crystal Caves *thirre* | world.md | OK |
| `wolf_pelt` / `wolf_fang` | Whisperwood, dire-wolf | world.md | OK |
| `goblin_ear` | Whisperwood, goblin | world.md | OK |
| `frost_saber` | Briarwood forge, Edda-made | **CONTRADICTS smith_edda.md AND trainer_hala.md** | **S1 — CQ-S1-01** |
| `dragonfang` | Pre-Sundering relic, Pale Wyrm-touched | world.md | OK |
| `ring_focus` | Mara's southern jeweler + Edda hammer + Caves shard | mara_merchant.md | OK |
| `ember_axe` | Briarwood forge, hot-side, Brigid-marked | smith_edda.md voice | OK |

Codex region claims (`region: crystal_caves` for both fragments) align with world.md's "Crystal Caves are the wound itself" + the codex's own canon that the Caves are a *thirre* held jointly by Vellum and the Stag-Court. OK.

## Check 4 — Item ↔ Recipe

**N/A this cycle.** No `recipes/` directory in repo; no `acquired_via:craft` field exists in any `items_flavor.json` entry. Logged as future-debt: **CQ-S3-01**.

## Check 5 — Quest ↔ Reward

**Partial.** No `quests/` directory and no formal quest manifest in repo this cycle. Quest-shape references are scattered in dialogue `consequence_hooks` and bio `Hooks for future runs` sections. Spot checks against the rewards mentioned in those hooks:

- `pelt_for_lyra` turn-in (Lyra's existing quest, per her dialogue `after_first_quest_complete`) — flavor reward (salve) is canonically *unnamed*, not a bag-item; OK.
- `whisperwood_cleansing` (Maeve's first quest) — reward is the carved acorn, intentionally non-stat flavor; lore-note flags it as *"does not need to enter Items.ITEMS unless Builder wants a collectible"*. OK.
- `ears_for_mara` (Mara's existing quest) — bounty payable in coin, no flavor item required.
- Hala's standing-form quest hook → reward is hand-bound practice cudgel from "the row of six" → **item not catalogued** (see CQ-S2-06).
- Roan's wolf-bounty hook → reward is `Steppe-Patterned Halter` → **item not catalogued** (see CQ-S2-07).
- Mara's `lost_courier_pouch` hook → reward is `Yew-and-Lantern Brass Token` → reserved future; tracked.
- Bram's Honeysong Eve hook → reward is `bram_road_knife` → reserved future; tracked.

PX/level-band cross-check N/A — `pacing/level_bands.md` is not in repo.

## Check 6 — Concept-art coverage

`concept/` and `mood-boards/` each contain only a `README.md`. **No concept-reference plates exist for any of the 7 NPCs, the 4+ regions, or the named creatures (goblin / goblin brute / goblin warlord / dire wolf / crystal elemental / skeleton / bandit) listed in `THEME.md` §4.** Logged as **CQ-S2-08** with a `CONCEPT_NEEDED` shortlist for Art Director.

## Check 7 — Catalog reconciliation

**N/A this cycle.** No `data/items/_catalog.csv`, no `.tres` set in repo. The 25 entries in `data/items_flavor.json` are the only structured item registry that currently exists. Logged as future-debt: **CQ-S3-02**.

---

## Inline-flag queue

Full per-file flags written to `eldoria-godot/qa/_canon_flags.md`. Summary table:

| ID | Sev | File | Title |
|----|-----|------|-------|
| CQ-S1-01 | S1 | `data/items_flavor.json#frost_saber` | Frost Saber attribution to Edda contradicts §smith_edda voice rule "never named a blade Frost" |
| CQ-S1-02 | S1 | `lore/npcs/innkeeper_bram.md` | Bram's "11 years ago" arrival contradicts Lyra (21+ yrs ago) and Hala (11 yrs ago at the inn already) bios |
| CQ-S2-01 | S2 | `lore/npcs/innkeeper_bram.md` | Internal: "11 years ago" + "3 years walking" + "8 years ago Caedr left" + "9 years no signpost" — math fails |
| CQ-S2-02 | S2 | `lore/npcs/innkeeper_bram.md` <-> `lore/npcs/herbalist_lyra.md` | Caedr disappeared "8 years ago" (Bram) vs "ten years later" (Lyra) |
| CQ-S2-03 | S2 | `lore/npcs/elder_maeve.md` <-> `lore/npcs/mara_merchant.md` <-> `lore/npcs/innkeeper_bram.md` | Water-stained letter return: Maeve "three years ago", Mara + Bram "two springs ago" |
| CQ-S2-04 | S2 | `lore/npcs/mara_merchant.md` | Internal: "Eight years into her Briarwood life" (= 4 yrs ago) vs "twelve Lambmoons ago" (= 12 yrs ago) for the same letter-pickup |
| CQ-S2-05 | S2 | `lore/npcs/elder_maeve.md` | Maeve age math: 19 + 11 walked + 42 since return = 72; bio states 68 |
| CQ-S2-06 | S2 | `data/dialogue/trainer_hala.json` <-> `data/items_flavor.json` | `practice_cudgel` reward referenced; not in items catalog |
| CQ-S2-07 | S2 | `data/dialogue/stablemaster_roan.json` <-> `data/items_flavor.json` | `Steppe-Patterned Halter` referenced; not in items catalog |
| CQ-S2-08 | S2 | `concept/` (root) | All 7 NPCs + named regions + named creatures lack concept reference plates |
| CQ-S2-09 | S2 | `lore/npcs/elder_maeve.md` <-> `lore/npcs/herbalist_lyra.md` <-> `lore/npcs/smith_edda.md` | Hawthorn knot-stick: rule says "since she became Elder" (22 yrs) but Halsa (k37) and Lyra (k89) pre-date Maeve's Eldership |
| CQ-S2-10 | S2 | `lore/npcs/trainer_hala.md` | Hala age math: 26 at Aurel + 4 moons walked + 11 yrs in Briarwood ≈ 38; bio states 42 |
| CQ-S3-01 | S3 | `eldoria-godot/recipes/` (missing) | No recipes dir; check 4 cannot run until crafting ships |
| CQ-S3-02 | S3 | `eldoria-godot/data/items/_catalog.csv` (missing) | No catalog CSV; check 7 cannot run until catalog ships |
| CQ-S3-03 | S3 | `eldoria-godot/quests/` (missing) | No formal quest manifest; quest-↔-reward reduced to dialogue-hook scan |
| CQ-S3-04 | S3 | `lore/world.md` + `lore/npcs/trainer_hala.md` | Stone-Tongue lexicon (`aei`, `thurra`, `kel-vethran`, `korthain`, `thrunn`, `korr`) not in any file's bullet-list lexicon header |
| CQ-S3-05 | S3 | `data/dialogue/*.json` (Bram + Roan + Hala) | Longnight stew round size: 2 (Bram bio: Edda → Maeve), 3 (Roan bio adds Roan), 4 (Hala bio adds Hala) — round structure not formalized |
| CQ-S3-06 | S3 | `data/items_flavor.json#_meta.canon_anchors_used` | List omits `lore/npcs/innkeeper_bram.md` and `lore/npcs/trainer_hala.md` — anchors out of date |

---

## Owners notified (in flags)

`@quest-writer`, `@item-designer`, `@bestiary-designer`, `@event-designer`, `@lore-keeper`, `@character-specialist`, `@art-director`. See `_canon_flags.md` for the per-flag OWNER assignment.

## Next cycle

- Pull `Items.gd`, `WorldBuilder.NPCS`, `pacing/level_bands.md`, `concept/` plates (when shipped), `recipes/`, `quests/` into the sparse-checkout list to enable checks 4, 5, and 7.
- Diff against this audit for **NEW** flags only — established flags here become baseline.
- Re-verify CQ-S1-02 / CQ-S2-01..05 / CQ-S2-09..10 once `@lore-keeper` has had a pass.
