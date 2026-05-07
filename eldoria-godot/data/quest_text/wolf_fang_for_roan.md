---
quest_id: wolf_fang_for_roan
giver: Stablemaster Roan
region: whisperwood
voice: data/dialogue/stablemaster_roan.json
canon_anchors:
  - lore/world.md (Tongues → Stone-Tongue; Calendar → Greenshield, Honeysong)
  - lore/npcs/stablemaster_roan.md (Briar's Run, Pippin, the courier-string, kerrithen as practice)
  - data/codex/steppe_riders_refusal.md (korr; the rider's "ride the leaves" idiom)
  - data/dialogue/stablemaster_roan.json (single nod, laconic)
old_faerie_used:
  - kerrithen (canonical, lore/world.md)
---

# Fangs for the Courier-String — quest text

## Pitch (Stablemaster Roan, on offering)

*brushing Pippin's flank. Does not stop brushing.* — Five fangs,
traveler. The pack down the courier-line has lost discipline; a sound
rider on a sound horse should not be losing horses to wolves on a
**Greenshield** evening. Five fangs, and the line walks itself for a
season.

## Accept (Stablemaster Roan, on player accept)

*single nod.* — Ride the leaves.

## In progress (Stablemaster Roan, on revisit before completion)

*does not look up from the curry-comb.* — The line is quieter,
traveler. Quiet is not finished. Quiet is *closer-to-finished.*

## Turn-in (Stablemaster Roan, on satisfied return)

*takes each fang. Weighs it once on his palm. Sets them in a row on
the stable rail, longest to shortest, the way a Steppe-rider lays
horseshoes after a Long Ride.* — Five. Briar's Run will read this on
her hooves by **Honeysong.** — *quietly, of the longest fang.* —
*Kerrithen*, traveler. We do not throw away a fang that earned itself.
Lay it at the cairn-stone behind the stable when you are done. The
ground will keep it.

## After (Stablemaster Roan, in subsequent dialogue)

*small, dry.* — The road south goes quieter. Ride the leaves.

## Notes for Builder

- The `kerrithen` line in turn-in is Roan's canonical use of the verb;
  see `lore/world.md` and `stablemaster_roan.md` for the
  laying-down-not-throwing-away sense. The cairn-stone reference is
  hookable for a future Builder run (a small Briarwood-stable prop).
- "Ride the leaves" is Roan's ONE allowed Steppe idiom in Common
  (per `data/codex/steppe_riders_refusal.md` author note). Do not
  multiply.
- This quest is the chain's first link: completing it sets the flag
  that gates `bandit_road_for_roan`, which gates
  `captain_seal_for_maeve`. The order is canonical.
