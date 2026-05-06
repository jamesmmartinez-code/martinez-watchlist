# Quest Grammar — Realm of Eldoria

A single, unified data model that every quest type uses. New quest kinds must
fit this grammar; do not invent ad-hoc shapes per quest.

## Universal Quest Shape

```gdscript
{
  # Who & why (story layer)
  "actor":       String,       # giver NPC name, e.g. "Elder Maeve"
  "motivation":  String,       # in-character reason: "fear", "greed", "duty"
  "target":      String,       # what / who: "goblin", "wolf_pelt", "warlord"
  "location":    String,       # where it happens: "Whisperwood", "Crystal Caves"
  "urgency":     String,       # "calm" | "rising" | "now" — drives UI tone

  # Trigger (when it appears)
  "world_trigger": Dictionary, # e.g. { "kind": "player_level", "value": 1 }
                               # or { "kind": "faction_pressure", "id": "...", "gte": 0.5 }
                               # or { "kind": "npc_thanked", "npc": "..." }

  # Mechanics (gameplay layer)
  "kind":        String,       # "kill" | "fetch" | "escort" | "defend" | "explore"
  "needed":      int,          # how many
  "item":        String,       # for fetch: material id
  # for kill: target field is the enemy_kind string

  # Reward
  "xp_reward":      int,
  "gold_reward":    int,
  "reward_item":    String,    # optional
  "reward_item_qty": int,      # optional

  # Consequence (post-completion world change)
  "consequence":  Dictionary,  # e.g. { "faction": "whisperwood_goblins",
                               #        "pressure_delta": -0.2 }
                               # or { "npc_flag": ["Elder Maeve", "first_quest_done"] }
                               # or { "world_flag": "whisperwood_safer" }

  # State (runtime, written by Player)
  "killed":      int,          # for kill
  "collected":   int,          # for fetch
  "giver":       String,       # snapshot of actor for turn-in matching
  "title":       String,       # display title
  "text":        String,       # display description
}
```

## Currently Implemented Kinds

| Kind   | Status   | Notes                                              |
|--------|----------|----------------------------------------------------|
| kill   | shipped  | counts `kills_by_kind[target]`; e.g. Whisperwood Cleansing |
| fetch  | shipped  | counts inventory.count(item); e.g. Pelts for the Salve     |
| escort | reserved | needs follower AI on NPC.gd                        |
| defend | reserved | needs spawn-wave system + objective marker         |
| explore| reserved | needs region triggers (no Area3D regions yet)      |

## Currently Active Quests in `World.QUEST_CATALOG`

1. `whisperwood_cleansing` — Elder Maeve · kill 5 goblins · +80 XP / +60 gold
2. `pelt_for_lyra`         — Herbalist Lyra · fetch 4 wolf_pelt · +70 XP / +45 gold + 2× Greater Health Potion
3. `ears_for_mara`         — Mara the Merchant · fetch 6 goblin_ear · +60 XP / +90 gold
4. `wolf_fang_for_roan`    — Stablemaster Roan · fetch 5 wolf_fang · +65 XP / +50 gold
5. `wolf_form_with_hala`   — Trainer Hala · kill 4 wolf · +90 XP / +35 gold
6. `wolf_heart_for_bram`   — Innkeeper Bram · fetch 3 wolf_heart · +70 XP / +55 gold

**Faction-pressure ladder (compound design — 4 reducers stack on `dire_wolves`):**
- `pelt_for_lyra` -0.1, `wolf_fang_for_roan` -0.1, `wolf_form_with_hala` -0.1,
  `wolf_heart_for_bram` -0.1 → fresh-save 0.5 → 0.1 (run-6 third cliff < 0.15
  collapses pack size to 1; only the apex/scarred survivor remains).
- `whisperwood_cleansing` -0.2, `ears_for_mara` -0.15 → goblin reducers
  (two reducers; further pressure-relief via faction events).

## Migration Notes

✅ **Shipped 2026-05-04 (run 2):** The 3 existing quests are now backfilled
with the full grammar (`actor`, `motivation`, `location`, `urgency`,
`world_trigger`, `consequence`). The `consequence` resolver lives in
`World.gd → apply_consequence(consequence: Dictionary)` and is invoked from
`_on_turn_in_quest()` after `complete_quest_if_done()` succeeds. Supported
consequence keys:

- `faction` (String) + `pressure_delta` (float) — adjusts
  `World.factions[id].pressure`, clamped to [0.0, 1.0].
- `world_flag` (String) [+ `world_flag_value` (Variant, default true)] —
  sets `World.world_flags[name]`.
- `npc_flag` ([npc_name, flag_name]) — appends to `World.npc_flags[npc]`,
  deduplicated. Dialogue and AI may read these flags.
- `toast` (String) — optional player-facing message via `_show_toast`.

Read accessors (queryable schema, all on World): `faction_pressure(id)`,
`has_world_flag(name)`, `npc_has_flag(npc, flag)`.

Any new quest MUST specify `consequence`, even if it is `{}` for an
explicitly-empty consequence (signals "intentionally inert" to reviewers).

## Authoring Rules

- A new quest MUST specify `actor`, `kind`, `target`/`item`, `needed`,
  `xp_reward`, `gold_reward`, `title`, `text`.
- A new quest SHOULD specify `motivation`, `location`, `urgency`,
  `world_trigger`.
- A new quest MUST specify `consequence` (use `{}` for intentionally inert).
- Reward items MUST exist in `Items.ITEMS`.
- Target enemy_kinds MUST exist in `Items.DROP_TABLE`.
