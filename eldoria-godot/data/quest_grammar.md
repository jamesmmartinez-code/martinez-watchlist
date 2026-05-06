# Quest Grammar — `.tres` Extension Notes

> The single source of truth for the quest data model is
> [`/QUEST_GRAMMAR.md`](../../QUEST_GRAMMAR.md) at the project root.
> This file is the **append-only addendum** that the quest-writer agent
> uses to document multi-stage / branched quest shapes that live as
> `.tres` Resource files under `data/quests/<region>/<id>.tres`.
>
> Canonical fields in the root grammar (actor, kind, target/item, needed,
> xp_reward, gold_reward, title, text, motivation, location, urgency,
> world_trigger, consequence) MUST still be populated in every `.tres`.
> The richer fields below are additive: a single-stage runtime can
> ignore them; a multi-stage runtime can use them.

---

## `.tres` extension fields

These fields live inside the `metadata/quest = { … }` dict on a quest
resource. They sit alongside the canonical fields — a quest is valid if
both the canonical surface and the extended surface are present.

| Field            | Type      | Purpose                                                             |
|------------------|-----------|---------------------------------------------------------------------|
| `id`             | String    | Snake_case quest id; matches the file stem and the registry key.    |
| `region`         | String    | Folder name under `data/quests/` and a key in `_index.tres :: regions`. |
| `act`            | int (1-5) | Story-act gate. 1 = tutorial, 5 = endgame.                          |
| `level_band`     | String    | Player-level band, e.g. `"6-8"`. Informs reward tuning.             |
| `hook`           | String    | Single-line journal entry, ≤140 chars. The "9-year-old keep playing" line. |
| `prereqs[]`      | Array     | Each item: `{kind: quest_completed/world_flag/player_level, …}`.    |
| `stages[]`       | Array     | Ordered. Each: `{id, objective, location, completion_trigger, optional fail_trigger}`. |
| `branches[]`     | Array     | Optional. Choice points; each: `{id, prompt, options[]}`.            |
| `dialogue_placeholders` | Dict | Lore-keeper hand-off tokens (`<<DLG: purpose>>`).                  |
| `rewards`        | Dict      | `{xp, gold, items[], faction_rep{}, unlocked_content[]}`. The legacy flat `xp_reward / gold_reward / reward_item` MUST also be set for runtime back-compat. |
| `repeatable`     | bool      | Default false.                                                      |

### `completion_trigger` kinds (tres-only, beyond legacy `kill`/`fetch`)

| Kind                | Shape                                              | Notes                                                |
|---------------------|----------------------------------------------------|------------------------------------------------------|
| `dialogue_accept`   | `{kind, quest_id}`                                 | Stage clears when the player accepts the offer.      |
| `dialogue_turnin`   | `{kind, quest_id}`                                 | Stage clears at hand-in dialogue.                    |
| `enter_region`      | `{kind, region}`                                   | Reserved — Area3D regions not yet wired (root grammar marks `explore` reserved). |
| `inventory_count`   | `{kind, item, gte}`                                | Same semantics as legacy fetch's `collected` counter.|
| `kill_count`        | `{kind, target, gte}`                              | Same semantics as legacy kill's `killed` counter.    |
| `world_flag`        | `{kind, id, value?}`                               | Stage clears when a flag transitions to value.       |
| `npc_flag`          | `{kind, npc, flag}`                                | Stage clears when an NPC flag is set.                |

### `prereq` kinds

| Kind                | Shape                                              |
|---------------------|----------------------------------------------------|
| `quest_completed`   | `{kind, id}`                                       |
| `world_flag`        | `{kind, id}` — flag must be true                   |
| `npc_flag`          | `{kind, npc, flag}`                                |
| `player_level`      | `{kind, gte}`                                      |
| `item_held`         | `{kind, item, gte}`                                |

### Authoring guard-rails (additive to the root grammar)

- **Hook discipline.** Re-read the hook out loud. If it does not pass
  the "would a 9-year-old keep playing?" sniff test, rewrite it before
  commit. Lead with mystery or want, not exposition (THEME §7).
- **Lore silence.** If the canon is silent on a faction, region, or
  named character your quest needs, write `# LORE_GAP: <topic>` as a
  comment in the `.tres` and pick a different quest. Do **not** invent.
- **Catalog fidelity.** Items in `rewards.items[]` MUST exist in
  `Items.ITEMS`. Targets in `kill_count` triggers MUST exist in
  `Items.DROP_TABLE`. If they do not, write `# NEEDS:item:<id>` or
  `# NEEDS:enemy:<kind>` and pick a different quest.
- **Engine NEEDS.** Multi-stage runtime, prereq resolver, region
  triggers, branch resolution — none are wired yet. New `.tres` quests
  that depend on them must list those deps in a `# NEEDS:engine:<dep>`
  comment block at the top of the file.
- **Dialogue stays in placeholder.** Never write full dialogue trees
  here. Use `<<DLG: purpose>>` so lore-keeper expands them in voice.
- **Branches are not mandatory.** Per the skill: *"not every quest
  needs one."* Add a branch only when the choice has a real
  consequence the player can feel in the world afterward.

---

## Per-run log

### 2026-05-05 — Quest-writer run 1

- Authored: `crystal_caves/shards_for_mara.tres` — Mara fetch, 5 crystal
  shards, level band 6-8, ring_focus reward.
- Anchored to canon: `items_flavor.json :: ring_focus` ("Three hands,
  one ring …"); `data/codex/stag_courts_courtesy.md` (under-stream + cold-
  iron air); `lore/world.md` (Honeysong Eve / lantern boats).
- Created `data/quests/_index.tres` registry; bootstrapped region keys.
- NEEDS raised: `engine:multi_stage_quest_runtime`,
  `engine:prereq_resolver`, `engine:enter_region_trigger`,
  `lore:regions_folder`.
- Branch: `auto/quest`.
