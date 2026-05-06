# Difficulty Targets — TTK & damage budgets

**Owner:** PX. Bestiary, item-designer, and combat agents read this; flag PX before changing.

## Definitions

- **TTK (time-to-kill)**: how long it takes a *competent kid* (Alden ≈ 9, occasionally distracted) to kill a single creature, **measured from first contact to creature death**. Not theoretical max DPS — the realistic clock.
- **Effective DPS** for kid play: 0.50 × theoretical DPS. Movement, whiffs, and "wait, where's the goblin" account for the other 50%.
- **Boss contact ratio**: fraction of the boss fight where the player can actually swing. Boss patterns gate this to ~50% of wall-clock (slam 0.9s telegraph + 3.5s recovery; charge 0.78s telegraph + 4.2s windback).

## TTK band targets

| Tier | Examples | TTK target (s) | At what level | Notes |
|---|---|---|---|---|
| Trash | Goblin Scout, lone Wolf | **2.0–4.0** | L1–L3 | Should die in 1–2 swings by L3 |
| Standard | Dire Wolf, Restless Skeleton | **2.5–4.5** | L2–L4 | Two-hit feel by L4 |
| Tough | Goblin Brute, Crystal Elemental | **4.0–7.0** | L3–L5 | Three-hit "real fight" feel |
| Elite | Crystal Guardian | **8–14** | L5–L7 | Mini-boss step toward Warlord |
| Boss | Goblin Warlord | **40–70** | L6–L7 | Phase-aware; not a DPS-check |

If a creature lands **outside its band by ≥25%**, file `qa/_px_flags.md` against the bestiary or item-designer.

## Damage-taken budget per fight

How much HP a kid should expect to spend on each tier, assuming average defensive play:

| Tier | HP cost (post-armor, % of max) | Heal needed before next fight |
|---|---|---|
| Trash | ~5–10% | No |
| Standard | ~10–18% | Optional (no, if back-to-back) |
| Tough | ~18–30% | Yes — pot or rest |
| Elite | ~35–55% | Yes — pot |
| Boss | ~70–100% (multi-pot fight) | New attempt resets |

## Current TTK measurements (2026-05-05 snapshot)

Computed from Player.gd swing numbers, Items.gd weapon table, and current Enemy.gd HP. Realistic DPS = 0.50 × theoretical.

### L1, no weapon (avg swing 17, eff DPS 19.7)

| Mob | HP | Swings to kill | TTK (s) | Band? |
|---|---|---|---|---|
| Goblin Scout | 28 | 2 | 0.88 → realistic ~1.4 | ✅ low edge |
| Goblin Brute | 56 | 4 | 1.76 → realistic ~2.8 | ⚠ too easy for L1 — no kid SHOULD fight a brute at L1 (camp gating handles this in WorldBuilder) |
| Dire Wolf | 40 | 3 | 1.32 → realistic ~2.1 | ✅ |

### L2 with iron_sword (avg swing 24, eff DPS 27.3)

| Mob | HP | Swings to kill | TTK (s) | Band? |
|---|---|---|---|---|
| Goblin Scout | 28 | 2 | 0.88 → realistic ~1.4 | ✅ on the floor |
| Goblin Brute | 56 | 3 | 1.32 → realistic ~2.1 | ⚠ TOO FAST for tier "Tough" (target 4–7s). Brute reads as trash by L2 — see flag |
| Dire Wolf | 40 | 2 | 0.88 → realistic ~1.5 | ⚠ TOO FAST for "Standard" (target 2.5–4.5s) |
| Restless Skeleton | 36 | 2 | 0.88 → realistic ~1.4 | ✅ |

### L4 with steel_blade (avg swing 35, eff DPS 39.8)

| Mob | HP | Swings to kill | TTK (s) | Band? |
|---|---|---|---|---|
| Goblin Brute | 56 | 2 | 0.88 → realistic ~1.4 | ❌ outside band (target 4–7s) — at L4 with mid-tier gear the brute should still be a 3-hit fight |
| Crystal Elemental | 70 | 2 | 0.88 → realistic ~1.8 | ⚠ low edge of "Tough" |
| Dire Wolf | 40 | 2 | 0.88 → realistic ~1.0 | ✅ at this level wolves should die in one or two |

### L7 with frost_saber + emberforge (avg swing 60, eff DPS 68)

| Mob | HP | Swings to kill | TTK (s) | Band? |
|---|---|---|---|---|
| Boss (Warlord) | 600 | 10 | 4.4 contact-time → realistic 8.8s contact / ~17s wall | ❌ boss is **way under target** (40–70s) — see boss flag |

## PX recommendations to other agents

1. **@bestiary — Brute HP needs +50–80%.** At L3+ with iron_sword the brute is a 2-hit fight; target was 4–7s. Bump `Goblin Brute` HP from 56 to ~95 and `damage` from 11 to 13 to keep its threat shape. Filed in `qa/_px_flags.md`.

2. **@bestiary — Boss HP is too low.** 600 is a 10-swing fight with mid-game gear. Target is 40–70s realistic; at 50% contact-ratio that's 20–35s of swing time, or **60+ effective swings**. Boss HP should be **~1500** to land in band. Phase 2 (charge/slam) already gates contact, so we don't need to multiply player damage taken — just lift the HP pool. Filed.

3. **@item-designer — Variance ceiling on legendary weapons.** `dragonfang` (42 base) at L7 swings 60 average. Versus the buffed boss (1500) that's still ≤25 swings = under target. The dragonfang IS allowed to feel like the boss-killer, but make sure the L7+ player doesn't reach it pre-boss (drop pool gating already handles this — verify).

4. **@combat — Crit chance trinket cap.** With `Hawk's Amulet` + `shadow_dagger` the player can hit ~32% crit. At 2.15× that's avg multiplier 1.37, effectively +18% DPS over the L7 reference. This is fine, but note it: kid mastery loop reward, not a balance bug. No action needed.

## Damage-taken spot checks

| Fight | Mob dmg | Swings to kill player @ L5 (HP 192, 31% armor red.) | Realistic time before kid dies |
|---|---|---|---|
| Goblin Brute alone | 11 → 7.6 actual | 25 hits to kill | Effectively never (kid will heal) |
| Brute + 3 scouts | mixed | ~14 hits if all land | ~10s of bad play |
| Boss melee | 22 → 15 actual | 13 hits | 26s of pure standing-still |
| Boss charge (1.6×) | 35 → 24 actual | 8 hits | One bad pattern read = trouble |

The boss damage feels right. The boss HP doesn't.
