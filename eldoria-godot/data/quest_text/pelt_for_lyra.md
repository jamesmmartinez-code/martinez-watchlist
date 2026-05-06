---
quest_id: pelt_for_lyra
giver: Herbalist Lyra
region: whisperwood
voice: data/dialogue/herbalist_lyra.json
canon_anchors:
  - lore/world.md (Tongues → Old Faerie; Calendar → Foxthaw)
  - lore/npcs/herbalist_lyra.md (heart's-ease, dogwort, marshmint; Wennet's coat; thalen-ai)
  - data/items_flavor.json :: hp_potion_l (the salve cadence)
  - data/dialogue/herbalist_lyra.json (gentle posture, leaf-tangled)
old_faerie_used:
  - thalen-ai (canonical, lyra bible — "a kindness asked gently")
---

# Pelts for the Salve — quest text

## Pitch (Herbalist Lyra, on offering)

*rolls a heart's-ease leaf between her fingers; does not stop the
rolling while she speaks.* — Four pelts, traveler. Wolf, by preference
— the heat in the fur is what binds the salve. Cure them in the
village pond before you bring them; that is the work I am asking, more
than the killing. *thalen-ai* — a kindness asked gently. Wennet has a
coat to grow back, and the children's salve will not wait for
Greenshield.

## Accept (Herbalist Lyra, on player accept)

*nods, returning to her marshmint pestle.* — Walk warmly.

## In progress (Herbalist Lyra, on revisit before completion)

*does not look up from the grinding.* — Two? Three? The cure-pond
freezes in **Foxthaw**, traveler. Bring them while the water still moves.

## Turn-in (Herbalist Lyra, on satisfied return)

*sets down the pestle. Sorts each pelt by weight, by direction-of-coat,
by the side the wolf was sleeping on.* — Four. Each cured kindly.
*takes a folded packet from her apron, and a second packet from the
shelf above the dogwort.* — Two greater health potions, and a small
draught for the long road. The salve will be ready by Honeysong. Wennet
thanks you — she does not say so, but the coat says it.

## After (Herbalist Lyra, in subsequent dialogue)

*looking up from her bench, briefly.* — You walk like someone who has
carried a wolf back. The herbs notice.

## Notes for Builder

- Reward delivery in turn-in: 2× `hp_potion_l` (mirrors the legacy
  catalog's `reward_item / reward_item_qty` shape — keep the second
  packet a flavor beat, not a duplicate item entry).
- The cure-pond detail is a Lyra-specific authoring constraint: she
  will *always* speak of curing the pelt, never of skinning it. Future
  in-progress lines must keep this. Skinning is Roan's vocabulary.
- `thalen-ai` is canonical Lyra-vocabulary; do not put it in another
  NPC's mouth without Lore-Keeper sign-off.
