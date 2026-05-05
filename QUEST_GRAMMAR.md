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

## Migration Notes

The current quest dictionaries use a SUBSET of the grammar above. They have
`giver, role, kind, target/item, needed, title, text, xp_reward, gold_reward,
[reward_item, reward_item_qty]`. They are MISSING `actor`, `motivation`,
`location`, `urgency`, `world_trigger`, `consequence`. These fields are
optional today but become mandatory for any new quest type.

A future run should backfill the existing 3 quests with the full grammar AND
introduce a `consequence` resolver in World.gd that applies the consequence
dictionary on `complete_quest_if_done()`. That single addition unlocks NPC
memory, faction shifts, and reactive dialogue from one entry point.

## Authoring Rules

- A new quest MUST specify `actor`, `kind`, `target`/`item`, `needed`,
  `xp_reward`, `gold_reward`, `title`, `text`.
- A new quest SHOULD specify `motivation`, `location`, `urgency`,
  `world_trigger`.
- A new quest MUST specify `consequence` once the consequence resolver lands.
- Reward items MUST exist in `Items.ITEMS`.
- Target enemy_kinds MUST exist in `Items.DROP_TABLE`.
