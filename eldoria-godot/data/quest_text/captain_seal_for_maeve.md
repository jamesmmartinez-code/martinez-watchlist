---
quest_id: captain_seal_for_maeve
giver: Elder Maeve
region: south_road
voice: data/dialogue/elder_maeve.json
canon_anchors:
  - lore/world.md (Tongues → kerrithen; Wild Pantheon → Vellum)
  - lore/npcs/elder_maeve.md (the mantle, the keeping-vigil)
  - lore/factions/wardens_of_the_mark.md (the captain's seal as memorial gesture)
  - WORLD_STATE.md (run-24 → maeve_seal_kept world flag, eighth in the ledger)
  - CHANGES.md (run-24 → captain_seal_for_maeve canonization)
old_faerie_used:
  - kerrithen (canonical)
  - ai-velin (canonical — used at parting)
---

# The Captain's Seal — quest text

## Pitch (Elder Maeve, on offering)

*sitting by the hearth. The iron-cast hand-stamp is not yet on her
mantle, but she speaks of it as if it already were.* — The south-road
captain wore a seal on a leather thong, traveler. He is dead now — the
Wardens have cleared his road; Roan will tell you the running of it,
if you ask, and he will tell it short. The seal is a little iron hand,
*kerritha-ed* nowhere yet. Bring it to me. The road's name is mine to
remember.

## Accept (Elder Maeve, on player accept)

*does not stand. Does not lean on the stick.* — Walk warmly. Bring it
slow. I have waited longer for less.

## In progress (Elder Maeve, on revisit before completion)

*one hand on Pippin's-old-strap, the leather thong hung above her
door — the strap a Steppe-rider left behind a lifetime ago.* — The
road is clear. The hand is not yet on my mantle. Take your time. Time
is the one thing the village has not yet run out of.

## Turn-in (Elder Maeve, on satisfied return)

*takes the iron-cast in both hands. Sets it on the mantle without
looking up — without ceremony, without a candle. The way a smith sets
down a hammer that has finished its work.* — *Vellum is patient.* The
road has a name now. *Kerrithen*, traveler. The Wardens kept what the
road could not keep itself. *long pause. Looks up, finally.* — You may
sit. Bram has stew on. I will have a bowl this year. *Ai-velin*, the
runners will write home before Reapmoon.

## After (Elder Maeve, in subsequent dialogue)

*does not look at the mantle, but the hand is there.* — The road
south reaches Briarwood again. We do not say *thank you* to a Warden,
traveler. We *kerritha* the work.

## Notes for Builder

- This is Maeve's TIER-2 quest and the eighth quest-issued world flag
  (`maeve_seal_kept`). The chain in: `wolf_fang_for_roan` →
  `bandit_road_for_roan` → **`captain_seal_for_maeve`** must be
  preserved by the prereq resolver.
- Maeve's "I will have a bowl this year" line is the closing of the
  Bram cross-NPC handshake — see `wolf_heart_for_bram.md → Notes for
  Builder` and `dialogue/elder_maeve.json :: boss_slain`. Authoring
  parity is intentional; do not edit one half without the other.
- The leather thong above the door is **NOT** Cailen's. It is Pippin's,
  re-purposed. Future writers must not promote the thong to Cailen
  canon. Maeve's brother is the Stag-Court / Halsa silence; he is not
  this strap.
- The seal becomes a visible mantle prop under Builder's run-25 hook
  (Hook A → seal_kept warm_lines; Hook B → Edda's first warm tier
  reads `maeve_seal_kept`). This quest_text does not gate either; the
  prop is a separate Builder run.
- Withholding still in force: Maeve does not name the captain. If a
  later Lore-Keeper run canonizes the captain's name (run-23 Hook B,
  run-24 Hook D), Maeve's voice does NOT acquire it. The captain's
  name is Roan's vocabulary, not Maeve's. She will keep the road, not
  the man.
