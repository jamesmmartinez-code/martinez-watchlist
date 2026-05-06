---
quest_id: wolf_heart_for_bram
giver: Innkeeper Bram
region: whisperwood
voice: data/dialogue/innkeeper_bram.json
canon_anchors:
  - lore/world.md (Calendar → Longnight Vigil; Wild Pantheon → The Hollow King)
  - lore/npcs/innkeeper_bram.md (the kettle, the red-leather ledger, the second mug)
  - lore/npcs/elder_maeve.md (the Vigil, the Halsa-candle, Maeve's not-yet-stew)
  - data/dialogue/innkeeper_bram.json (ladle in hand, ruddy-cheeked)
  - data/dialogue/elder_maeve.json :: longnight_vigil, boss_slain (the stew handoff)
old_faerie_used:
  - mhordin (introduced in this artifact — see _README.md → Glossary)
---

# Hearts for the Vigil-Stew — quest text

## Pitch (Innkeeper Bram, on offering)

*ladle in hand, leaning on the bar so the apron does not catch the
embers.* — Three wolf-hearts, traveler — for the **Vigil-stew.** Maeve
says she will take it this year, and a Vigil-stew without three hearts
is not a Vigil-stew. *winks; ruddy-cheek smile.* — Don't tell her I
asked you. Call it a kitchen errand.

## Accept (Innkeeper Bram, on player accept)

*beaming.* — Stew on the hearth when you're back, traveler. I'll keep
the door.

## In progress (Innkeeper Bram, on revisit before completion)

*polishing a mug with the corner of his apron, even though the mug is
already clean.* — The kettle's on, traveler. The kettle's always on.
Take your time. *Mhordin* — the inn keeps the asking warm.

## Turn-in (Innkeeper Bram, on satisfied return)

*takes the hearts in his apron. Doesn't unwrap them — he knows the
weight.* — Three. Right and proper. *pours a second mug without asking
and slides it across.* — That's for the cold in your fingers. The
stew will be ready by **Longnight.** Maeve will eat it. *quietly, with
the ladle stilled.* — Tell her I said it's the same stew. It will mean
something to her.

## After (Innkeeper Bram, in subsequent dialogue)

*ruddy-cheek smile, ladle in motion again.* — The Vigil's looked-after,
traveler. Bram's looked-after. You're looked-after.

## Notes for Builder

- "It's the same stew" is the canonical Bram-to-Maeve cross-NPC beat.
  Maeve's `boss_slain` line in `dialogue/elder_maeve.json` already
  reads *"Tell Bram I'll take the stew this year. Tell him I said
  so."* — Bram's turn-in here is the *other half* of that exchange.
  The two lines are designed to be played in either order.
- `Mhordin` is introduced in this artifact (see `_README.md →
  Glossary`). Bram is the canonical first user; the inn IS the
  village's `mhordin` — the holding-of-the-asking — by canon.
- The red-leather ledger above the bar is the future-Bram hook
  (`WORLD_STATE.md`, run-23 onwards). This page must NOT name what is
  in the ledger. The reserved-text line stays reserved.
