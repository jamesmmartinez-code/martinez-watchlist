# Act Gates — what unlocks each act

**Owner:** PX. Builder, NPC, and quest agents read this.

The world doesn't have hard "act" gates today (no scene transitions block content). This doc names the **soft acts** — the bands where the player's experience changes shape — and what triggers each transition.

## Act 1 — Briarwood (the safe village)

**Starts:** new save, spawn at SAFE_SPAWN (0, 3, 10), HUD controls toast appears.
**Ends:** first quest accepted from any of the 6 questgivers.
**Length:** 3–8 min.

What's available:
- All 7 NPC interactions (Maeve, Edda, Mara, Lyra, Bram, Roan, Hala)
- Pippin the horse, the well, the village layout
- 2 nearby Goblin Scouts (just past the village edge)
- 0 quest progress, 0 XP

Gate to Act 2: **player accepts a quest** (`active_quest != {}`). No code change needed; the quest panel button does it.

## Act 2 — Whisperwood (the wood thickens)

**Starts:** first quest accepted.
**Ends:** any one quest turned in.
**Length:** 8–25 min depending on which quest.

What's available:
- All Act 1 content
- Goblin scout patrols (1 brute camp gated to mid-Whisperwood)
- Wolf packs (4 wolves at fresh-save pressure)
- 2 common chests, 1 rare chest in Whisperwood

Gate to Act 3: **at least one quest completed** (`world_flag` set: any of `whisperwood_safer`, `mara_bounty_paid`, `lyra_potion_brew`, `roan_bounty_paid`, `hala_wolf_form_done`, `bram_nights_quiet`).

## Act 3 — The Reducers (compounding world state)

**Starts:** first quest turn-in.
**Ends:** at least 4 of 6 reducers done (faction pressure visibly thinned).
**Length:** 30–45 min.

What changes:
- NPCs warm: dialogue switches to `warm_lines` for those whose flag is set
- Faction pressure visibly drops: wolf packs thin (4 → 3 → 2 → 1), goblin spawn schema tilts toward fewer brutes
- Adaptive cooldown / chase speed / damage / xp lerp on faction pressure (run 7–10 effects in code)
- Surviving wolves get the ⚡ "agitated" prefix and the harder stats

Gate to Act 4: **wolf-tamer achievement available** (Lyra + Roan + Hala flags), **OR** boss arena entered for the first time.

## Act 4 — The Warlord (boss confrontation)

**Starts:** boss arena trigger or wolf-tamer earned.
**Ends:** Warlord defeated.
**Length:** ≤ 15 min including retries.

What's available:
- All prior content
- Warlord arena (deep Whisperwood, see `_build_boss_arena`)
- Death loop should be tight (see `feel_specs.md`) — kid retries shouldn't feel punishing
- Adds spawn at boss low-HP (Warlord's Guard, hp 32, dmg 7)

Gate to Act 5: **boss dead** → world flag (TBD: not currently set; PX flag for Builder to add `warlord_slain` flag on boss death).

## Act 5 — The Crystal Cave (post-boss)

**Starts:** Warlord defeated.
**Status:** scaffolded, not finished.

What's there:
- Skeletons (36 hp, undead-tinted)
- Crystal Elementals (70 hp, blue-glow tint)
- Crystal Guardian (mini-boss, see WorldBuilder spawn)
- Cave geometry generated — see WorldBuilder, but no quest hooks yet

PX doesn't size act 5 yet — content is too thin. Feed back when there are 2+ cave-themed quests in QUEST_CATALOG.

## Estimated time-to-each-gate (cumulative, kid-paced)

| Gate | Minutes from new save |
|---|---|
| Quest accepted (→ Act 2) | 3–8 |
| First quest turned in (→ Act 3) | 12–30 |
| 4 of 6 quests done (→ Act 4) | 45–75 |
| Warlord defeated (→ Act 5) | 60–105 |

This means a **single 90-minute play session** can take Alden from new-save through boss-kill on a "best path." Owen is faster, more like 60–75 min.

## What this doc commits to

1. **No hard gates today** — every door is soft, opened by world-state flags. Adding a hard "you must be L5 to enter the cave" would feel punishing for Alden if she explored ahead.
2. **All 6 questgivers are valid Act 2 launchers.** No "right" first quest. Pick whichever NPC the kid talked to first.
3. **The boss does NOT require all 6 quests.** It requires *enough* — the achievement gate is decorative, not a lock. Filed: confirm with builder that boss arena is reachable at any band-5 readiness.
