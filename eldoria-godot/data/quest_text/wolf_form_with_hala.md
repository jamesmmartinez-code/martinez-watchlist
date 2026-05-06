---
quest_id: wolf_form_with_hala
giver: Trainer Hala
region: whisperwood
voice: data/dialogue/trainer_hala.json
canon_anchors:
  - lore/world.md (Wild Pantheon → Thiar the Stag; Calendar → Emberfall, Stag-night)
  - lore/npcs/trainer_hala.md (the wraps, the staff, breath-first-then-blade)
  - data/dialogue/trainer_hala.json (warrior-monk cadence, sword-forms)
old_faerie_used:
  - vael-haerin (introduced in this artifact — see _README.md → Glossary)
---

# Wolf-Form — quest text

## Pitch (Trainer Hala, on offering)

*standing in third form. Staff at rest, butt-end on the ground, top
just clear of her shoulder.* — Four wolves, traveler. Not for the
killing — for the *form.* A blade learns from the thing it cuts.
**Breath first, then blade.** Bring me the count, not the carcass; the
wolves will know we counted.

## Accept (Trainer Hala, on player accept)

*small bow over the staff.* — Walk warmly. The form will hold.

## In progress (Trainer Hala, on revisit before completion)

*moving through second form.* — Two? The form does not rush. The
wolves do not rush. Breath first. Then blade.

## Turn-in (Trainer Hala, on satisfied return)

*sets down the staff. Inclines her head — the warrior-monk's
acknowledgement, not the elder's.* — Four. The form has held.
*takes a small parcel from her sash.* — Honeyed oats, for the breath
after the breath. *Vael-haerin*, traveler — the homeward leg. The
walk back from a deed is the part the form does not teach. You teach
yourself that one.

## After (Trainer Hala, in subsequent dialogue)

*moving through fourth form.* — You hold the third now. The fourth is
patience. Walk warmly.

## Notes for Builder

- `Vael-haerin` is introduced in this artifact (see `_README.md →
  Glossary`). Hala is the only NPC who uses it in turn-in dialogue; for
  any other NPC who later acquires it, gloss the use as her teaching.
- The honeyed-oats parcel is flavor; not an item entry. If a future
  Builder run wants to surface it as a consumable, the Lore-Keeper
  recommendation is `hala_oats` at +5 stamina or equivalent — but the
  dialogue line stands without the item.
- Hala will NOT speak Thiar's name to the player aloud. The hunters
  do; Hala does not. (She lays a kill at his stone privately. The
  player is not present.) Future after-lines must keep this.
