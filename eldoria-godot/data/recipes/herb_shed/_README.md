# Herb-Shed Recipes — Lyra's Mortar

## Tier-1 (5 recipes; cap is 8)
Bootstrap pass — covers all three existing flavor-anchored consumables (hp_potion_s, mp_potion)
plus craft components that feed downstream tier-2 work.

| Recipe                       | Output             | Unlock          |
|------------------------------|--------------------|-----------------|
| herbshed_hp_potion_s         | hp_potion_s ×1     | auto            |
| herbshed_mp_draught          | mp_potion ×1       | recipe_book     |
| herbshed_cure_wolf_pelt      | leather_strip ×4   | npc_taught      |
| herbshed_oak_talisman        | talisman_oak ×1    | quest_complete  |
| herbshed_marshmint_dye       | marshmint_dye ×2   | auto            |

## Tier-2 (4 recipes; cap is 8) — Whisperwood unlock
Tier-up rule: every tier-2 recipe consumes ≥1 Whisperwood-region material
(wolf_fang, wolf_pelt, wolf_heart, bark_tannin_oak harvested from a Whisperwood-fallen oak,
or thalen-ai seventh herb that ripens only after the apology-aloud quest).

| Recipe                       | Output             | Unlock          | New-region input |
|------------------------------|--------------------|-----------------|------------------|
| herbshed_hp_potion_l         | hp_potion_l ×1     | quest_complete  | wolf_heart + thalen-ai |
| herbshed_thiar_salve         | thiar_salve ×2     | recipe_book     | bark_tannin_oak  |
| herbshed_leather_vest        | leather ×1         | npc_taught      | leather_strip (cured wolf_pelt) |
| herbshed_fang_focus          | ring_focus ×1      | quest_complete  | wolf_fang        |

## Tier-3 plan (next pass) — Crystal Caves unlock
- herbshed_caves_water_blessing — Crystal Caves under-stream water; tier-3 buff potion
- herbshed_haethe_focus — uses crystal_shard; once-per-day mana spike

## Items still NEEDED from item-designer
### Tier-1 carryover
- herb_hearts_ease, herb_dogwort, herb_marshmint, herb_starveil
- bark_tannin_oak, beeswax_dab, clay_flask_empty
- well_water_clear, hemp_cord, marshmint_dye, leather_strip
- whisperwood_oak_disc

### Tier-2 (this pass)
- herb_thalen_ai (input)  — Whisperwood-cycled seventh herb, ripens after apology quest
- thiar_salve (output)    — tier-2 salve, single-use pre-fight buff (also re-used as input to fang_focus)
- bone_needle (input)     — Whisperwood salvage; pierces leather-vest back-seam

### Tier-3 (future)
- cave_under_stream_water — for tier-3 caves blessing
