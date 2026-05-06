# AUDIT — Realm of Eldoria

Append-only architectural audit log. Each entry is one ARCHITECT run.

The 5 ledger files (`CHANGES.md`, `WORLD_STATE.md`, `SYSTEM_REGISTRY.md`,
`QUEST_GRAMMAR.md`, `PLAYER_MODEL.md`) plus `DESIGN_PHILOSOPHY.md` are the
canonical reference; this file is the meta-log of how well they're being
maintained.

---

## 2026-05-06T03:00Z — Audit run (1h survey)

**Job:** Job 3 — Ledger drift detection.

**Repo state:** 7 commits in last hour (4 owner PX-emergency, 3 auto-build);
102 commits in last 24h. Worker agents quiet during the survey window —
human owner is mid-playtest with kids.

**Drift found:**

| Ledger | Drift type | Severity | Resolved this run |
|--------|-----------|----------|-------------------|
| SYSTEM_REGISTRY.md | 11 of 26 Items.gd IDs missing from prose | medium | yes — added Item ID Catalog |
| QUEST_GRAMMAR.md | 3 of 6 World.QUEST_CATALOG entries missing | medium | yes — list extended |
| WORLD_STATE.md | Crystal Caves still "planned, not yet placed" — code references `crystal_caves` faction | low (intentional placeholder) | no — defer until Builder ships zone |

**Process observations:**

1. The Lore-Keeper / Builder handoff for new quests is leaking. Any quest
   added to `World.QUEST_CATALOG` should fan out to QUEST_GRAMMAR.md in
   the same commit. Adding this rule to the operating doc next pass.
2. The "Item Schema" section in SYSTEM_REGISTRY.md previously documented
   the schema but not the ID catalog. The new "Item ID Catalog"
   subsection is the canonical list; it MUST be kept in sync with
   `Items.ITEMS`.
3. PX-EMERGENCY commits (owner-driven) crossed multiple agent zones
   (Player.gd, Main.tscn, index.html, .github/workflows). This is the
   correct privilege level for the human; worker agents must NOT adopt
   the multi-zone pattern.

**Item IDs newly catalogued (11):**
`crit_amulet`, `dragonscale`, `ember_axe`, `emberforge`, `guardian_core`,
`mp_potion`, `ring_focus`, `shadow_dagger`, `steel_plate`, `talisman_oak`,
`warlord_horn`.

**Quests newly catalogued in QUEST_GRAMMAR.md (3):**
`wolf_fang_for_roan` (Roan / fetch / wolf_fang × 5),
`wolf_form_with_hala` (Hala / kill / wolf × 4),
`wolf_heart_for_bram` (Bram / fetch / wolf_heart × 3).

**Compound design captured:** dire-wolves faction now has 4 reducers
(Lyra/Roan/Hala/Bram) stacking from 0.5 → 0.1, tripping the run-6 third
cliff (< 0.15 → packs of 1). This is exactly the "compound, don't sprawl"
rule (operating rule 1) working — every new wolf-related NPC gives a
quest that integrates with the existing pressure ladder rather than
introducing a parallel system.

**Next audit watch list:**
- Has Builder added Crystal Caves zone? If so, WORLD_STATE.md needs a
  status flip from "planned" to "shipped".
- Has any new item ID been added without updating the new Item ID
  Catalog? (test the fix worked).
- Has any 7th quest entered `World.QUEST_CATALOG`? If so, did it get
  added to QUEST_GRAMMAR.md too? (test the rule).


**Mid-run race observation:** Owner pushed `23cfbd7` (Hero.glb → 30 MB
Meshy biped) after my survey window closed but before my push. This
reverses the size win from `cbe88d1` and re-creates the §15 web-perf
concern that was just resolved. Owner-tier override, not a rule
violation — but Character agent has a follow-up: decimate the mesh
(target 5-8k tris) + LOD swap to restore the perf budget without
losing the kid's likeness.


---

## 2026-05-06T11:55Z — Audit run (1h survey, run-2 of day)

**Job:** Job 3 — Ledger drift detection (continuation of 03:00Z run).

**Repo state:** 2 commits in last hour (1 owner main_scene revert, 1 auto-build).
50 commits in last 24h. Workers on lunch — biggest activity shifted to:
6 `Eldoria Art`, 5 `Eldoria Environment`, 2 `Eldoria Builder`, 2 `Eldoria Character`,
plus owner `jamesmmartinez-code` (29) and CI bots (34). Survey window
quiet enough that the watch list from 03:00Z is the right thing to close.

**Watch-list outcomes (from prior audit):**

| Watch item | Result |
|------------|--------|
| Crystal Caves zone shipped? | No — still planned. Defer. |
| New item ID without catalog update? | YES — `captain_seal` (run 24 Builder). FIXED this run. |
| 7th quest in `World.QUEST_CATALOG`? | YES — `bandit_road_for_roan` (run 23) AND `captain_seal_for_maeve` (run 24). QUEST_GRAMMAR.md was at 6, now 8. FIXED. |

**Drift detected and fixed:**

1. **QUEST_GRAMMAR.md** — listed only 6 quests; `World.QUEST_CATALOG`
   contains 8 (parsed top-level dict keys directly from `World.gd`).
   Two missing: `bandit_road_for_roan` (run 23, intra-NPC sequel),
   `captain_seal_for_maeve` (run 24, cross-NPC sequel). Both use the
   `prerequisite_npc_flag` schema. Added a new section "Quest
   Sequencing — `prerequisite_npc_flag`" documenting the
   intra-NPC vs. cross-NPC patterns; updated the faction-pressure
   ladder table to include the bandits reducer (-0.20) and the pure-flag
   `captain_seal_for_maeve` (no faction delta).

2. **SYSTEM_REGISTRY.md Item ID Catalog** — `Items.ITEMS` has 41 IDs;
   catalog listed 26. **15 IDs of drift**:
   - `captain_seal` (NEW run 24) — added to Materials.
   - 5 helmets (`iron_helm`, `steel_helm`, `silver_helm`, `ranger_hood`,
     `crown_eldoria`) — never had a slot section. Added.
   - 5 capes (`traveller_cape`, `mage_cape`, `ranger_cape`,
     `royal_cloak`, `dragonscale_cape`) — never had a slot section. Added.
   - 4 shields (`wooden_shield`, `iron_shield`, `kite_shield`,
     `runed_shield`) — never had a slot section. Added.
   - Bonus correction: `crystal_shard` rarity in catalog said "epic" but
     `Items.ITEMS` has it as `uncommon`. Catalog now matches code.
   - Tightened the "Adding an item" rule: new slot types also get a
     subsection. The 15-ID drift came from quietly-added slot families
     (helmets/capes/shields) that the catalog never tracked.

3. **Schema rule strengthened:** added a one-line authoring note in
   QUEST_GRAMMAR.md — the prereq NPC for a cross-NPC chain is NOT the
   giver; the resolver only checks `World.npc_has_flag` regardless of
   which NPC set the flag. This is the contract `captain_seal_for_maeve`
   relies on.

**Process observations:**

- The "5 outputs per feature" rule (operating §2) was honored on run 24
  — the captain_seal CHANGES.md entry hits all five (i schema,
  ii integration via prerequisite_npc_flag, iii toast/title/icon,
  iv weight-total verified, v 5 hooks listed). But the ledger update
  step (rule §3) was partial: SYSTEM_REGISTRY.md got the deep
  "captain_seal material + Maeve sequence" section, but the Item ID
  Catalog summary at the top was not extended. This audit closes that
  gap. Rule §3 is "update all five ledgers in the same commit as the
  feature" — Builders should append to BOTH the deep sections AND the
  summary catalog, not one or the other.
- The catalog-vs-code drift in helmets/capes/shields is older than this
  run — it predates the 03:00Z architect's first catalog audit. That
  audit only inventoried weapons/armor/trinkets/consumables/materials
  because those were the only sections in the original catalog. The
  fix here (adding the 4 missing slot sections) brings the catalog to
  41/41 parity with `Items.ITEMS`.

**Refactor opportunities surfaced (not done this run):**

- The "Adding an item" rule has been broken at least twice (run 24 +
  the helmets/capes/shields backlog). A future architect run could
  add a CI step or a pre-push hook that diffs `Items.ITEMS` keys
  against the catalog and rejects the push if they disagree. Logged
  as a pattern in DESIGN_PHILOSOPHY.md candidate list.

**Item IDs newly catalogued (15):**
`captain_seal`, `crown_eldoria`, `dragonscale_cape`, `iron_helm`,
`iron_shield`, `kite_shield`, `mage_cape`, `ranger_cape`,
`ranger_hood`, `royal_cloak`, `runed_shield`, `silver_helm`,
`steel_helm`, `traveller_cape`, `wooden_shield`.

**Quests newly catalogued in QUEST_GRAMMAR.md (2):**
`bandit_road_for_roan` (Roan / kill / bandit × 4, prereq Roan
`first_bounty_done`),
`captain_seal_for_maeve` (Maeve / fetch / captain_seal × 1, prereq
Roan `road_warden` — first cross-NPC chain).

**Next audit watch list:**
- Has any 9th quest entered `World.QUEST_CATALOG`? Did it fan out to
  QUEST_GRAMMAR.md in the same commit?
- Has any 42nd item ID been added to `Items.ITEMS`? Did it fan out to
  the Item ID Catalog?
- Are Hooks A/B/C/D/E from the run-24 CHANGES.md entry getting picked
  up? (Maeve `seal_kept` warm_lines, Edda warm tier reading
  `maeve_seal_kept`, Mara cross-NPC mention, captain name canon, ledger
  inn-prop). If a hook stays open >3 audits, demote it.
- Has the `bandit_road_for_roan` reducer (-0.20) actually moved bandit
  pressure in playtests, or is the bandits faction still at 0.0
  fresh-save with no upward ramp? If the faction never pressurizes,
  the reducer is unreachable — flag for Builder.