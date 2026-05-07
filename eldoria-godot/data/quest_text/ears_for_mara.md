---
quest_id: ears_for_mara
giver: Mara the Merchant
region: whisperwood
voice: data/dialogue/mara_merchant.json
canon_anchors:
  - lore/npcs/mara_merchant.md (honest coin, never haggles, the unopened letter)
  - data/items_flavor.json :: ring_focus ("Three hands, one ring")
  - data/dialogue/mara_merchant.json (tips her head, finishes the strap)
  - lore/world.md (Three Crowns → Iron Crown / smoke-cities)
old_faerie_used:
  - aen-thirre (introduced in this artifact — see _README.md → Glossary)
---

# Ears for the Bounty-Clerk — quest text

## Pitch (Mara the Merchant, on offering)

*tips her head. Finishes the strap she is drawing through a buckle.
Does not look up while she speaks.* — Six goblin-ears, traveler. The
southern bounty-clerk pays clean coin for them, and the road south is
calmer when the count comes in. Not a haggle — a count. Bring them when
you have them. I will not ask twice.

## Accept (Mara the Merchant, on player accept)

*tips her head.* — Walk warmly.

## In progress (Mara the Merchant, on revisit before completion)

*tipping her head, finishing a different strap.* — I will not ask,
traveler. The clerk is patient. Mara is patient. The road is patient.
Patience is the cheapest goods I sell.

## Turn-in (Mara the Merchant, on satisfied return)

*takes the count without looking. Weighs the pouch on the back of her
hand, the way a fisherwife weighs a fish.* — Six. Honest coin for
honest count. The road south will write to me by **Greenshield.** *small,
without ceremony.* — The clerk is not a friend, traveler. The clerk is
a customer who pays. There is a difference.

## After (Mara the Merchant, in subsequent dialogue)

*tipping her head, smiling small.* — *Aen-thirre*, traveler. Stone-of-
thanks. You have one of three hands now.

## Notes for Builder

- The `aen-thirre` line is the FIRST Old Faerie word Mara uses aloud
  in canon. It is reserved for *after* turn-in and only fires once per
  player on the post-turn-in greeting; subsequent revisits should fall
  back to the existing `mara_merchant.json :: default` line.
- `Three hands, one ring` is the canonical setup for the
  `ring_focus` payoff in `shards_for_mara`. Do not echo it here.
  Mara's after-line points *at* the ring without naming it.
- Mara never haggles. Future in-progress lines must keep her tone
  unhurried; she will not pressure the player even at zero progress.
