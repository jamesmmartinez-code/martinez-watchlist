# Level Bands — Realm of Eldoria

**Owner:** PX agent. Other agents READ this; do not edit it without flagging PX.

## Purpose
Single source of truth for "at level N, the player has X HP, Y damage, Z items, in act Z." Every other curve hangs off this one.

The numbers below are **derived from current code** (Player.gd, Items.gd, World.gd QUEST_CATALOG, WorldBuilder.gd `_spawn_enemy` calls) as of 2026-05-05. When code changes, this doc is the *intent*; if the gap widens, file a flag in `qa/_px_flags.md` rather than silently letting the doc drift.

---

## Player formulas (from Player.gd)

| Stat | Base @ L1 | Per level | Notes |
|---|---|---|---|
| HP | 120 | +18 | Refilled to full on level-up |
| MP | 30 | +10 | Refilled to full on level-up |
| Attack damage (base) | 14 | +1.5 (int floor) | Plus weapon bonus, plus variance −2..+4 |
| Crit chance | 0.14 | +0 (gear only) | Trinkets / weapons add up to +0.18 each |
| Crit multiplier | 2.15× | — | Flat |
| Attack range | 2.7m | — | Forgiveness for Alden's aim |
| Attack arc | 118° | — | Wide enough for kid-imprecise aim |
| Swing total | 0.44s | — | 0.16s windup + 0.28s lockout |
| Gold start | 50 | — | — |
| Respawn | 2.5s death anim → SAFE_SPAWN (0,3,10) | — | Full HP/MP restore |

XP curve: `xp_for_next_level = 85 + level*55 + level²*7`

| Gate | XP needed | Cumulative |
|---|---|---|
| L1 → L2 | 147 | 147 |
| L2 → L3 | 223 | 370 |
| L3 → L4 | 313 | 683 |
| L4 → L5 | 417 | 1100 |
| L5 → L6 | 535 | 1635 |
| L6 → L7 | 667 | 2302 |
| L7 → L8 | 813 | 3115 |

Average swing damage (no weapon): `(14 + level*1.5 + 1_variance) * 1.161_crit_avg`

| Level | Avg per swing (no weapon) | Effective DPS (max, perfect aim) |
|---|---|---|
| 1 | 17.4 | 39.5 |
| 3 | 20.9 | 47.5 |
| 5 | 24.4 | 55.5 |
| 7 | 28.0 | 63.6 |

**Real-world DPS for a 9-year-old** is roughly 45–55% of max due to movement, whiffs, and re-positioning. Use that band when sizing creature HP — see `difficulty_targets.md`.

---

## Bands

### Band 1 — "First five minutes" (L1, 0–150 XP)
- HP: 120 / 120 (no upgrades)
- Weapon: none → starter `rusty_sword` (3 dmg) from first chest or Mara's stall stock
- Armor: none → `cloth` (2 armor, 4% reduction)
- Avg swing: 17 (no weapon) → 21 (rusty)
- Expected fights: 1–2 lone Goblin Scouts; nothing in the brute camp
- Time-to-first-kill target: **30s after the controls toast**
- Goal of band: prove "I can hit things and they die" before any quest text

### Band 2 — "First quest" (L1–L2, 150–400 XP)
- HP: 120–138
- Weapon: `iron_sword` (6) very likely from first chest pool
- Armor: `cloth` or `leather` (2–6 armor)
- Avg swing: ~24 with iron + L2 stats
- Expected fights: 5 goblin scouts (Maeve cleansing) OR 6 ear-bounty (Mara)
- Quest income: +60–80 XP per quest, +60–90 gold
- Time-to-band-end: **8–12 min from new save**

### Band 3 — "Branching arc" (L2–L3, 400–700 XP)
- HP: 138–156
- Weapon: `iron_sword` → `steel_blade` (12) likely from chests or smith
- Armor: `leather` → `chainmail` (12 armor, 19% reduction)
- Avg swing: ~33 with steel + L3
- Expected fights: brutes (56 hp) become real; first wolf pack (3–4 dires)
- Quests in band: any of Lyra (pelt), Roan (fang), Mara (ear) — usually 2 of 3 by band end
- Time-to-band-end: **20–30 min from new save**

### Band 4 — "Whisperwood elder" (L4–L5, 700–1700 XP)
- HP: 174–192
- Weapon: `steel_blade` → `frost_saber` (22, +6% crit) or `ember_axe` (26)
- Armor: `chainmail` → `steel_plate` (22 armor, 31% reduction)
- Avg swing: ~50–55 with rare weapon + L5
- Expected fights: full goblin camp (3 scouts + 1 brute), reduced wolf packs, all four wolf-quests in flight
- Quests cleared: 4 of 6 typical
- Time-to-band-end: **45–60 min**

### Band 5 — "Boss-ready" (L5–L7, 1700–3100 XP)
- HP: 192–228 (without armor HP bonus)
- Weapon: `frost_saber` / `ember_axe` / `shadow_dagger` (18, +18% crit)
- Armor: `steel_plate` → `emberforge` (34 armor + 35 HP, 40% reduction)
- All wolf reducers stacked → wolf pressure ≈ 0.1, single survivor wolf
- All 6 quests cleared → "Wolf-Tamer" achievement available
- TTK on Goblin Brute should be **3–5s** here, otherwise the boss step-up reads wrong
- Time-to-band-end: **75–90 min**

### Band 6 — "Warlord" (L7+, 3100+ XP)
- Boss: 600 HP, 22 base damage; slam 1.4×, charge 1.6× (max ~35 dmg per slam)
- Player at L7 with `frost_saber` + `emberforge`: avg swing ≈ 53, effective DPS ≈ 28 realistic
- Theoretical fight: 600 / 28 ≈ **21s of contact time**, but boss patterns gate contact to ~50% of clock
- Realistic boss fight target: **40–70s** (see `difficulty_targets.md`)
- Loot: `frost_saber` / `ember_axe` / `dragonfang` / `dragonscale` from Warlord drop table

### Band 7 — "Cave & beyond" (post-boss, scaffolded)
- Skeletons (36 hp, 8 dmg, 24 xp) — slightly easier than brutes; cave-tier intro
- Crystal Elementals (70 hp, 14 dmg, 55 xp) — peer with brutes
- Crystal Guardian — boss-tier, see WorldBuilder spawn
- Player should arrive at `dragonfang` (42) + `dragonscale` (52, +80 HP) by mid-cave
- This band is mid-build; PX checks every run

---

## Things this band table commits to

1. **L1–L2 lasts ≤ 12 min.** The first level-up beat is the strongest "I'm getting somewhere" reinforcement Alden gets.
2. **Every band hands the player at least one new gear silhouette.** No band where the visible gear stays static.
3. **HP bonus from armor (emberforge +35, dragonscale +80) lands BEFORE the boss.** PX has flagged this for `item-designer` to verify drop rates support it (see `qa/_px_flags.md`).
4. **Damage variance is asymmetric** (`-2..+4`, avg +1). This is intentional — it skews high so kids feel like they "rolled big" more often than rolled low.

## Bands the doc does NOT commit to

- Specific drop-rate guarantees (item-designer's lane — coordinate via flags).
- Exact swing-cadence numbers beyond what Player.gd already exports.
- Hard caps on level (no level cap in code today; intentional).
