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
