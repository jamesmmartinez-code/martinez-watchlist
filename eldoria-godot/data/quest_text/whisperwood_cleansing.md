---
quest_id: whisperwood_cleansing
giver: Elder Maeve
region: whisperwood
voice: data/dialogue/elder_maeve.json
canon_anchors:
  - lore/world.md (Wild Pantheon → Vellum; Calendar; the Whisperwood)
  - lore/npcs/elder_maeve.md (Vigil candles, the carved acorn, the eighty-ninth knot)
  - lore/factions/wardens_of_the_mark.md (the keeping-vigil)
  - data/dialogue/elder_maeve.json (mood-keyed voice tree; voice_rules)
old_faerie_used:
  - ai-velin (canonical, lore/world.md)
---

# Whisperwood Cleansing — quest text

## Pitch (Elder Maeve, on offering)

*taps the hawthorn stick, does not look at the forest line.* — The
Whisperwood is restless tonight, traveler. Five drum-circles I can count
from my doorstep, and that is five too many. Walk down to the forest at
first light. **Five goblins** — no more, no less. Leave the rest for the
Wardens. The Warlord is no chieftain; he is a wound. Five will quiet the
wound.

## Accept (Elder Maeve, on player accept)

*small nod.* — Walk warmly. Bring me the count, traveler — not the
trophy. I am old. I want the *count.*

## In progress (Elder Maeve, on revisit before completion)

*does not lean on the stick yet.* — The drums are quieter, but five is
not five yet. *Vellum keeps memory. Mornings keep promises.* Walk warmly.

## Turn-in (Elder Maeve, on satisfied return)

*long pause.* — Five. *Ai-velin*, traveler. The Whisperwood will sleep
tonight. *holds out a small carved acorn.* — Take this. It is nothing. It
is also a promise. The village remembers who walks for it.

## After (Elder Maeve, in subsequent dialogue)

*does not look at the forest line.* — Three children in the lane asked
me yesterday if you were a hero. I told them heroes are the ones who
come back.

## Notes for Builder

- Mood-keys this page covers: `default` / `after_first_quest_complete`
  /`stranger`-flavored pitch / morning-tinted in-progress.
- The carved acorn is intentionally non-statted flavor (per
  `dialogue/elder_maeve.json :: consequence_hooks`). Do not promote it
  to an `Items.ITEMS` entry without Lore-Keeper sign-off.
- Withholding still in force: Maeve does not name **Aelis** or
  **Cailen** in any line. The voice_rules in the dialogue bible apply
  unchanged.
- This is Maeve's tier-1 quest. Her tier-2 (`captain_seal_for_maeve`)
  loads only after the chain through Roan completes.
