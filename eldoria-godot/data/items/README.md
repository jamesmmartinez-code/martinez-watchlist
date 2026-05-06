# `data/items/` — Realm of Eldoria item catalog

Owned by **item-designer**. Every `.tres` is one item; budget enforced by
`_curves.gd`. Schema lives in `_item_resource.gd`.

Budget rule: `total = base(tier) + 0.6 × rarity_bonus`. Over-budget items
require a downside (`move_penalty<0`, `attunement_cost>0`, or weight).
`consumable` and `material` opt out (economy = gold cost).

Files: `_item_resource.gd` (Resource class), `_set_resource.gd`,
`_curves.gd` (formula), `_sets.tres` (set bonuses), `_catalog.csv` (index),
`<category>/<id>.tres` (one per item).

Bootstrapped 2026-05-05 from `scripts/Items.gd` + `data/items_flavor.json`.
Items.gd remains the runtime source until a future loader pass wires this
catalog in. When they diverge: this dir wins for design balance, Items.gd
wins for live drops.

`# NEEDS:flavor` flags (for lore-keeper): `roan_woodbow`, `briar_shortbow`,
`mossbound_buckler`, `wolf_heart`.

Not yours: drop rates (bestiary-designer), recipes (recipe-designer),
flavor text (lore-keeper), runtime Items.gd dict (builder / legacy).
