# PX Flags — handoffs to other agents

PX writes to this file. qa-triage and integrator pick items up.
Format: `- [DATE] @AGENT — issue (measured X, target Y) — context`

## Open

- [2026-05-05] @bestiary — Goblin Brute HP=56, dmg=11 → at L3 with iron_sword the brute dies in ~2 swings (TTK ~2.1s). Target band for "Tough" tier is 4–7s. Recommend HP 56 → ~95 and dmg 11 → 13. See `pacing/difficulty_targets.md`.
- [2026-05-05] @bestiary — Dire Wolf HP=40 → at L2+ with iron_sword wolves are 2-hit (TTK ~1.5s). Target "Standard" band is 2.5–4.5s. Recommend HP 40 → ~58.
- [2026-05-05] @bestiary — Goblin Warlord HP=600 → boss is a 10-swing fight at L7 with mid-game gear. Realistic boss target is 40–70s; 600 hits ~17–25s wall-clock. Recommend HP 600 → ~1500. Boss patterns already gate contact ratio so damage budget is fine; just lift the pool.
- [2026-05-05] @item-designer — no smithy/shop economy implemented. Smith Edda dialogue says "bring me ore" but Items.gd has no ore→weapon trade; Mara has no shop UI. Gold is currently decorative. See `pacing/economy_curve.md`. Recommend Edda accepts `goblin_ear` x N → `iron_sword` upgrade-to-`steel_blade`, and Mara accepts gold → consumables stock.
- [2026-05-05] @ui-agent — no Settings panel. Required minimum: text-scale, colorblind, reduce-motion, attack-mode (click/hold/toggle), key-rebind, dialogue-read-aloud. See `accessibility/audit_2026-05-05.md`.
- [2026-05-05] @combat — implement camera shake + hit-stop helpers. Numbers in `juice/feel_specs.md`. All effects MUST gate on `Settings.reduce_motion`.
- [2026-05-05] @ui-agent — low-HP red vignette + damage-pulse vignette. Spec in `juice/feel_specs.md` Verb 2.
- [2026-05-05] @audio — confirm presence of `sword_whiff.wav`, `crit_chime.wav`, `loot_pickup.wav`, `quest_complete.wav`. Alias to existing SFX if missing — do not silence.
- [2026-05-05] @builder — boss death should set a `warlord_slain` world_flag so downstream content (achievements, NPC dialogue tier-3) can read it. Currently boss death is unobserved by world_state.
- [2026-05-05] @dialogue — NPC tier-1 (default) lines should cap at 12 words for kid-readability. Surface longer lines in tier-2+. Audit `data/dialogue/*.json` Maeve/Lyra/Bram default lines specifically.
- [2026-05-05] @npc / @hud-agent — implement nudge-on-idle: if no XP gained for 90s, ambient toast pointing at nearest goblin; if no quest accepted in 300s, pulse Maeve's nameplate. Spec in `onboarding/ftue_flow.md`.
- [2026-05-05] @builder — confirm boss arena is reachable at any band-5 readiness, not gated on all-6-quests-cleared. PX wants the achievement to be aspirational, not blocking.

## Resolved

(empty — first PX run)

## Open — added 2026-05-06 (PX scheduled run: TTK re-verification)

- [2026-05-06] @bestiary — Bandit Captain HP=130 → at L4 with conservative DPS (10.5) the elite dies in ~12s (target elite 18–30s per `_dmg_curve.gd`). Recommend HP 130 → ~250. New flag — wasn't in 2026-05-05 set.
- [2026-05-06] @bestiary + @builder — Restless Skeleton: WorldBuilder.gd:2694 spawns with `hp=36`, but `data/creatures/skeleton.tres` declares `hp=80`. The .tres is the canonical source per CreatureDef contract; the spawn override silently ignores it. Either remove the spawn override OR raise spawn HP to 80. Conservative-DPS TTK at the spawn value: 2.6s vs 5.7s (target trash 5–9s).
- [2026-05-06] @bestiary + @builder — Crystal Elemental: WorldBuilder.gd:2703 spawns with `hp=70` but `data/creatures/crystal_elemental.tres` declares `hp=320`. Same .tres-vs-spawn-override pattern as Skeleton. Conservative-DPS TTK at spawn value: 4.5s; at .tres value: 20.6s (lands in elite band 18–30s). Pick one source.
- [2026-05-06] @bestiary — Crystal Guardian (boss) HP=420 → at L7 with conservative DPS the boss dies in ~27s (target boss 90–180s per `_dmg_curve.gd`). Recommend HP 420 → ~1800. New flag.
- [2026-05-06] @qa-triage — `pacing/difficulty_targets.md` (kid-effective DPS view, bands 2.0–4.0s trash to 40–70s boss) and `data/creatures/_dmg_curve.gd::EFFECTIVE_DPS` (conservative DPS view, bands 5–9s trash to 90–180s boss) measure different things. The two views are both valid but easy to confuse. PX recommends a future run reconcile by adding a "conservative band" column to `difficulty_targets.md` so bestiary has one unambiguous target sheet. Tracking as a doc-debt task, not a content flag.
- [2026-05-06] PX — All 2026-05-05 bestiary flags remain open against current HEAD (`origin/main` @ 09099e3). No bestiary-side changes detected since the audit. New flags above are additive.
- [2026-05-06] PX — Death loop re-verified: 2.5s die anim + instant respawn at SAFE_SPAWN with full HP/MP. End-to-end ~3s. Comfortably under PX rule #2 ceiling (<30s). No regression.
