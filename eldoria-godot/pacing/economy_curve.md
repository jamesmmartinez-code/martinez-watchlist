# Economy Curve — XP, gold, items per band

**Owner:** PX. Item-designer + WorldBuilder agents read this; coordinate via `qa/_px_flags.md`.

## Targets per band

A "band-clear" is: kill expected mobs + complete expected quests + open expected chests.

| Band | XP earned | Gold earned | Net pots used | Net pots in pouch end | Time |
|---|---|---|---|---|---|
| 1 (first 5 min) | 35–80 | 20–40 | 0–1 | 1–2 | 5 min |
| 2 (first quest) | 200–280 | 110–170 | 1–3 | 2–4 | 8–12 min |
| 3 (branching arc) | 400–550 | 200–320 | 4–7 | 3–5 | 20–30 min |
| 4 (Whisperwood elder) | 800–1100 | 350–500 | 8–14 | 4–6 | 45–60 min |
| 5 (boss-ready) | 1500–2200 | 600–900 | 12–22 | 6–10 | 75–90 min |
| 6 (Warlord) | +480 (boss xp) | +120 (boss gold) | 4–8 in fight | 0–3 left after | 5–15 min fight |

## Quest income (from World.gd QUEST_CATALOG)

| Quest | Giver | Kind / target | Needed | XP | Gold | Bonus |
|---|---|---|---|---|---|---|
| whisperwood_cleansing | Maeve | kill goblin | 5 | 80 | 60 | — |
| pelt_for_lyra | Lyra | fetch wolf_pelt | 4 | 70 | 45 | 2× hp_potion_l |
| ears_for_mara | Mara | fetch goblin_ear | 6 | 60 | 90 | — |
| wolf_fang_for_roan | Roan | fetch wolf_fang | 5 | 65 | 50 | — |
| wolf_form_with_hala | Hala | kill wolf | 4 | 90 | 35 | — |
| wolf_heart_for_bram | Bram | fetch wolf_heart | 3 | 70 | 55 | — |

**Quest-only income totals (all 6):** 435 XP + 335 gold + 2× greater health potions.
**Mob XP from completing the 6 quests' kill counts:** ≈ 5 goblins × 18 + 6 ears (≈ 6 goblins × 18) + 4 pelts (≈ 11 wolves × 28) + 5 fangs (≈ 13 wolves) + 4 wolves (Hala) + 3 hearts (≈ 12 wolves) — but kills overlap.

A real run that turns in all 6 quests passes through ~25–35 unique kills, so roughly **+650–900 mob XP on top**. Total quest-arc XP ≈ **1100–1350**, just enough to land L4–L5.

## Gold sinks

Today's intentional sinks (Items.gd `value` / smithy gating not implemented yet):

| Item | Value | When meaningful |
|---|---|---|
| iron_sword | 18 | Band 2 (most kids never buy — drop covers it) |
| chainmail | 80 | Band 3 (gold-gated upgrade if smithy buys come online) |
| steel_blade | 55 | Band 3 |
| steel_plate | 280 | Band 4 |
| frost_saber | 210 | Band 4–5 |
| emberforge | 620 | Band 5 — first major gold sink |
| dragonfang | 1500 | Band 6+ — basically loot-only |

⚠️ **Issue**: there's no smithy purchase loop today. Smith Edda's dialogue says "Bring me ore" but Items.gd has no ore→weapon trade. Mara's shop has no implementation either. Until those land, `gold` is decorative.

**Filed for `qa/_px_flags.md`**: smithy/shop economy needs an implementation pass — currently gold accumulates with no spend hook, which kills the upgrade-loop motivation.

## Pot economy

Health potions on the wolf drop table at weight 22 (`hp_potion_s`, qty 1–2) = ~22% chance per wolf kill, expected ~0.33 pots per kill. Expected 11-wolf grind for Lyra → ~3.6 lesser pots banked. That's healthy.

Goblin drop table has `hp_potion_s` at weight 36 → ~31% chance, ~0.31 per kill. A 5-goblin Maeve grind → ~1.6 pots banked.

`hp_potion_l` (Greater) heals 130 (per item flavor refine note); only on Warlord drops or Lyra's quest reward (2× immediate). PX target: kid enters Warlord fight with **2–4 lesser + 2 greater pots**. With current drop math that's reachable but tight; flag if observed otherwise.

## "Why this curve"

1. **L1→L2 in 8–12 minutes.** First level-up shouldn't be a slog. 147 XP gate, ~18 XP per scout = 8 scouts; Maeve quest is 5 + 80 reward = level on completion.
2. **All quests bring you to ~L4–L5.** That's the right level for the boss step-up.
3. **Gold is meaningful only by band 5.** Until then drops are the upgrade engine. Once `emberforge` (620g) is reachable, gold starts to feel like a real choice.
4. **Pots are NEVER scarce by design.** Kid game — running out of pots mid-fight feels punishing in a way Alden won't recover from. Drop rates lean generous on purpose.
