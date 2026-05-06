---
quest_id: bandit_road_for_roan
giver: Stablemaster Roan
region: south_road
voice: data/dialogue/stablemaster_roan.json
canon_anchors:
  - lore/world.md (Three Crowns → Iron Crown; Calendar → Reapmoon)
  - lore/npcs/stablemaster_roan.md (the courier-string, the runner-line, the south road)
  - lore/factions/wardens_of_the_mark.md (the keeping-running)
  - CHANGES.md (run-23, run-24: prereq for captain_seal_for_maeve)
old_faerie_used:
  - kerrithen (canonical, used in passing — same sense as wolf_fang turn-in)
---

# The Bandit Road — quest text

## Pitch (Stablemaster Roan, on offering)

*tightening Pippin's girth. Does not look up.* — The south road is
closed, traveler. Bandits — a captain in a sodden cloak, by the
courier-talk. The runner-line south of the village has gone three
weeks without a rider. We do not lose runners on Roan's watch. Clear
the captain. The road clears with him.

## Accept (Stablemaster Roan, on player accept)

*single nod.* — Ride the leaves.

## In progress (Stablemaster Roan, on revisit before completion)

*brushing Pippin, looking past the player at the south road.* — The
runner-line is still quiet, traveler. Quiet is not finished.

## Turn-in (Stablemaster Roan, on satisfied return)

*takes the captain's pommel-mark. Weighs it once on his palm. Sets it
on the stable rail next to the row of fangs from the spring run.* —
Done. The line will run again by **Reapmoon.** *quietly, without
turning.* — You will speak to Maeve, traveler. The captain wore a
seal. She will want it. The road's name is hers to keep — mine is the
running of it.

## After (Stablemaster Roan, in subsequent dialogue)

*small, dry. Hand on Pippin's withers.* — The runners come back now.
They forget to thank the road. That is how you know it is a road
again.

## Notes for Builder

- This quest is the chain's middle link:
  `wolf_fang_for_roan` → **`bandit_road_for_roan`** →
  `captain_seal_for_maeve`. Roan's turn-in line ABOVE is the canonical
  hand-off to Maeve — Builder should fire Roan's after-line as a
  one-shot the first time the player returns to the village
  post-completion, then fall back to the laconic `default` line.
- The captain in the sodden cloak is currently unnamed in canon; run-23
  Hook B and run-24 Hook D both flag the naming as a future Lore-Keeper
  pickup. This quest_text intentionally does NOT name him. If a later
  run names him (e.g. *Vrith of the Sodden Cloak*), update the pitch's
  "captain in a sodden cloak" line and Roan's turn-in to use the name
  in the after-line only — Roan would not name a man twice.
- `Reapmoon` is the canonical month-name (`lore/world.md` → Calendar).
  Do not paraphrase to "harvest moon" or "autumn moon."
