## 2026-05-05 (integrator run 4) — 4 branches merged, 2 carried gaps

### Branches merged into main
- `auto/builder` (1 commit) — `player_renown` first-class scalar + RenownLabel HUD + Lyra `use_json_dialogue:true` flip (closes 3-run carried gap)
- `auto/polisher` (1 commit) — `Chest.gd` interaction polish (10 REFINE-tagged tweaks)
- `auto/art` (1 commit) — 6 procedural 64×64 affix overlay icons (frost, embers, bear, swiftness, dragon, stars) + `gen_affix_icons.py` + `AFFIX_SUFFIXES.affix_icon_path` metadata
- `auto/lore` (1 commit) — `mara_merchant.md` NPC backstory + WORLD_STATE.md lexicon notes

### Branches skipped
- `auto/character` — 0 ahead (no new work this run)
- `auto/qa` — 0 ahead
- `auto/environment`, `auto/audio` — branch does not exist

### Conflict resolved
- `WORLD_STATE.md` had a content conflict where Builder appended a "Renown — first-class scalar (run 11)" section AND Lore appended lexicon/origin notes to the same trailing region of the file. Both additions were non-overlapping appendix-style content; resolution kept BOTH sections in original order (builder's renown notes first, then lore's lexicon notes). No information lost.

### [INTEGRATOR-GAP] — affix icons authored but not consumed
Builder/Items.gd now emits `affix_icon_path:"res://assets/icons/affix/<name>.png"` on every `AFFIX_SUFFIXES` entry, and Art/run-4 ships the matching PNGs. However, NO UI code (Inventory.gd, loot tooltips, item display) actually reads `affix_icon_path` to render the badge. Today the field is metadata-only — `icon_overlay` (emoji) is still the only thing rendered. The ATTRIBUTION.md sibling note in `assets/icons/affix/` explicitly documents the intent ("UI to prefer affix_icon_path over icon_overlay when present") but the consumer-side patch is missing. **Next polisher/builder run should:** in whatever script renders affix indicators on inventory slots/tooltips, branch on `affix.has("affix_icon_path") and ResourceLoader.exists(affix.affix_icon_path)` and prefer the PNG over the emoji.

### [INTEGRATOR-GAP] — NPC backstory markdown is still orphan
`eldoria-godot/lore/npcs/` now holds `elder_maeve.md`, `smith_edda.md`, `innkeeper_bram.md`, `herbalist_lyra.md`, and (new this run) `mara_merchant.md`, plus `lore/world.md`. Nothing in `eldoria-godot/scripts/` reads any of those files. They are author-time reference material for dialogue writers (and for the lore agent itself) but there is no `LoreLoader.gd`, no `lore_book` UI, no NPC method that surfaces a snippet. This was already noted in earlier integrator runs and remains carried. **Next builder run could:** add a tiny `LoreLoader` autoload that exposes `get_npc_lore(npc_name) -> String` reading `res://lore/npcs/<slug>.md` and surface a single quote in the dialogue-end footer (or a `[J]ournal` keybind) so the markdown becomes player-visible.

### Next run TODO
- Feed both gaps above to next builder/polisher run.
- `auto/character` and `auto/qa` haven't pushed in 2+ runs — worth checking whether those agents are healthy or if the work-picker is starving them.

## 2026-05-05 (run 10) — Boss world-flag wire (`seen_warlord` / `warlord_dead`) + Bram JSON opt-in

### Build target picked
- Read THEME.md fully (§1–14 visual canon + §12 motion/life + §13 ground
  contact + §14 push discipline).
- THEME §7 cited: "Each NPC sounds like ONE specific person (catchphrases,
  speech rhythm). Old Faerie / Common-tongue distinction." This run lights
  up six dormant authored lines — three NPCs each speaking a distinct
  boss_alive line and a distinct boss_slain line — that were sitting in
  `data/dialogue/*.json` reachable in code but unreachable in play because
  no system was writing the gating world flags.
- Mood-board panel: N/A — sparse-checkout for this run excludes
  `mood-boards/`. File zone is .gd + .md only.
- Backlog item: NOT one of backlog 1–11. Promoted from CHANGES.md run-9
  ("Auto: JSON dialogue trees made live — DialogueDB.gd … Fail-soft on 4
  World fields not yet shipped"). Two of those fail-soft fields
  (`seen_warlord` for boss_alive, `warlord_dead` for boss_slain) are wired
  in this run by Boss.gd writes to `World.world_flags`. The other two
  (player_renown, npc_seen) are flagged as next-priority hooks in
  WORLD_STATE.md so a follow-up Builder/Polisher run picks them up.

### Build
- `eldoria-godot/scripts/World.gd` (+15): new public method
  `func set_world_flag(name: String, value: Variant = true) -> void`.
  Sister of `apply_consequence`'s flag step — same `world_flags[name] =
  value` write + `_check_achievements()` re-run, but with no faction /
  NPC / toast side-effects. For emergent runtime events that aren't
  quest consequences. Returns immediately on empty name.
- `eldoria-godot/scripts/Boss.gd` (+24 / -0):
  - In `_physics_process`, immediately after `_intro_played = true`
    (the once-per-session intro sting at <30m), call
    `world.set_world_flag("seen_warlord", true)`. Wraps the call in a
    `has_method` guard so older World autoloads (test scenes / partial
    builds) silently fall through.
  - In `_die`, after the existing `hide_boss_hp_bar` / `_show_toast`
    calls and BEFORE the `quest_listeners.on_enemy_killed` hook, call
    `world.set_world_flag("warlord_dead", true)`. Same `has_method`
    guard. Permanent — never cleared on player respawn.
- `eldoria-godot/scripts/WorldBuilder.gd` (+13 / -0):
  - Innkeeper Bram's NPCS entry gains `"use_json_dialogue":true`. Bram
    is now the THIRD opted-in NPC. His JSON (`innkeeper_bram.json`)
    carries 15 keys including all four boss-state lines, the warmest
    `low_health_player` line in the village, and the `honeysong_eve`
    festival hook — all already authored, all now reachable.
- `WORLD_STATE.md`: new ✅ Resolved entry (run 10) under Active Hooks
  with the boss-flag wire details, the Bram opt-in, and three new 🔥
  top-priority hooks (Mara/Lyra/Roan/Hala JSON authoring; player_renown
  field wire; npc_seen tracker for `stranger` keys).
- `SYSTEM_REGISTRY.md`: new section "World API additions (run 10)"
  documenting `set_world_flag`, plus an updated NPC-JSON-opt-in table
  showing Bram joining Maeve and Edda.
- `CHANGES.md`: this entry.

### 5-output rule
- (i)   **Integration with world state:** Two flags newly written
        (`seen_warlord`, `warlord_dead`); both are queried by DialogueDB
        TODAY but nothing was writing them yet — this run closes the
        write half of the loop. New READER count for `world_flags`
        unchanged (still DialogueDB + has_world_flag callsites); new
        WRITER paths added in `Boss._physics_process` and `Boss._die`.
        WORLD_STATE.md `Active Hooks` updated with Resolved entry +
        three follow-up hooks.
- (ii)  **Queryable schema:** `World.set_world_flag(name, value=true)`
        is a new public method, documented in SYSTEM_REGISTRY.md "World
        API additions (run 10)". Same shape as `apply_consequence` step
        2 minus the side-effects, so Achievements still re-runs on
        every flag flip. NPC opt-in table updated to show three NPCs.
- (iii) **Player feedback (visible/audible/UI):** Six dormant authored
        lines now reachable in the player flow. On boss-encounter:
        Maeve, Edda, Bram each speak a unique `boss_alive` line on the
        same world tick the player crosses 30m of the Warlord. On boss
        death: same three NPCs speak distinct `boss_slain` lines on the
        same tick the Warlord's HP reaches 0. UI path is unchanged
        (same `show_dialogue` group call); the resolver simply has more
        keys to match. Edda's tic *hammer-clang* + *one hard
        hammer-strike* on the post-kill line is the catchphrase
        payoff THEME §7 promised.
- (iv)  **Evaluation:** Naive paren-balance check
        (`src.count(o)==src.count(c)` for `()`, `[]`, `{}`) passes on
        all three modified files: World.gd 426/426 paren, 60/60
        bracket, 29/29 brace; Boss.gd 231/231 paren, 4/4 bracket, 0/0
        brace; WorldBuilder.gd 1131/1131 paren, 83/83 bracket, 37/37
        brace. New `var` declarations carry explicit type annotations
        (Godot 4.6 strict-mode compliant) — `var w_intro: Node`,
        `var w_die: Node`. The `set_world_flag` signature uses
        `value: Variant = true` so the common-case call is one token
        shorter at the callsite, and `name == ""` early-returns to
        match the rest of World.gd's empty-string guard pattern. Both
        Boss callsites guard on `has_method("set_world_flag")` so a
        partial-build World silently degrades rather than crashing.
- (v)   **Future hooks (≥ 2):**
        1. **Author Mara / Lyra / Roan / Hala JSON trees** — pure data
           PR. Lore Keeper lane. Each new JSON gives the NPC the same
           9-key DialogueDB priority surface; one `use_json_dialogue`
           toggle in WorldBuilder lights it up. Mara is highest-leverage
           (only NPC who trades, so `low_health_player` reads as "she
           comps a potion" — mechanically distinct).
        2. **Wire `World.player_renown: int`** (or alias
           `unlocked_achievements.size()` as a read-only computed property).
           DialogueDB's `high_renown` predicate reads
           `world.player_renown >= renown_threshold` (default 100); JSON
           lines for Maeve and Edda are pre-authored. Single field
           addition + one quest hook → two more dormant lines reachable.
        3. **Wire `World.npc_seen: Dictionary`** flipped on first
           interaction in NPC.gd. Lights up the `stranger` JSON keys
           for every JSON-opted NPC. Two-line patch on `_on_interact`
           (mark seen at end of function).
        4. **"Met the Warlord" / "Warlord Slain" achievements** —
           drop a predicate matching `world_flag == "seen_warlord"`
           and another matching `world_flag == "warlord_dead"` into
           `Achievements.ACHIEVEMENTS`. The `set_world_flag` already
           re-runs `_check_achievements()`, so the unlock toast fires
           the moment the flag flips. Pure data add — no engine code.
        5. **Boss-defeat consequence on factions** — extend `Boss._die`
           to write `factions["whisperwood_goblins"].pressure = 0.0`
           (or call `apply_consequence` with the right payload). The
           Warlord dying should crater the goblin faction pressure,
           which then cascades to the FIVE existing pressure consumers
           (NPC dialogue tier 3, goblin spawn density, wolf spawn
           density, enemy attack cooldown, enemy chase speed). One
           write → five visible world changes.

### Phase reached
Builder — feature shipped, 5/5 ledgers updated (World.gd, Boss.gd,
WorldBuilder.gd, WORLD_STATE.md, SYSTEM_REGISTRY.md, CHANGES.md), ready
to commit to `auto/builder`.

### Next run should pick up
**Mara / Lyra / Roan / Hala JSON authoring** (lore agent, parallel) and
**player_renown wire** (Builder, single field). Both compound on this
run with no new dialogue-code edits. The JSON-resolver path is now the
data path; future authoring is content, not engineering.

---

## 2026-05-05 — QA: Player.gd indent fix
Parse error at Player.gd:314 — `call_deferred("save_game")` was inserted at 1-tab indent inside the while loop, orphaning all the level-up effects (max_hp/mp gain, LEVEL UP popup) at the wrong indent level. Re-indented level-up effects back into the while loop body and moved `call_deferred` to run once after all level-ups complete (1 tab, before `stats_changed.emit()`). This unblocks NPC.gd and WorldBuilder.gd which depend on the Player class.

# Realm of Eldoria — Build Ledger

Running record of what's been built, what's deployed, what's next. Append new entries at the top.

Deploy command (run from your Mac terminal):
```
cd "/Users/jamesmartinez/Library/Application Support/Claude/local-agent-mode-sessions/794a2df1-963f-473e-b0d0-194a5b136adf/9d25261c-681d-4498-8c12-d926cbaa244a/local_cdbfb2a3-6ded-4fe9-8a31-53177f14881a/outputs" && bash full-deploy.sh
```


## 2026-05-04 (run 8) — Roan dire_wolves faction-tier dialogue (smoke-tests Tier 3 as sole warming channel)

### Plan
- 5 ledgers consulted. Top-priority hook from WORLD_STATE was Roan's
  `dire_wolves` faction tier: smoke-tests the 4-tier dialogue stack on
  an NPC with no `warm_flag` AND no `warm_world_flag`. Schema in place
  since run 4 (Maeve), but Maeve has a `warm_flag` so the faction tier
  was always a SECONDARY path on her. Roan proves the faction tier
  works as a SOLE warming channel.
- Rule 1 (compound, don't sprawl): no new primitive — recombines the
  existing 4-tier dialogue stack (NPC.gd, runs 3 / 3-followup / 4) with
  the existing `dire_wolves` faction scalar (runs 6 / 7). Adds the FOURTH
  visible consumer of `dire_wolves` after spawn density, adaptive
  cooldown, and the wolf-pressure write path. Single-NPC data-only edit.
- Rule 5 (endless ≠ infinite map): one quest completion (`pelt_for_lyra`)
  now fans out to FOUR visible signals — fewer wolves, faster surviving
  wolves, ⚡ agitation prefix, and now Roan narrating the change.

### Build
- `eldoria-godot/scripts/WorldBuilder.gd` (+19 / -1):
  - Roan's NPCS entry gains `warm_faction_id:"dire_wolves"`,
    `warm_faction_below:0.5`, `warm_faction_lines` (4 buckets:
    morning / midday / evening / night).
  - 14-line compound docblock above the new fields explaining: (a) Roan
    has no `warm_flag` so this is the sole warming channel, (b) threshold
    0.5 mirrors the run-6 first cliff so warming triggers on the same
    quest that drops wolf count, (c) the four-leg `dire_wolves` compound.
- `WORLD_STATE.md`: top-priority hook (Roan dialogue) marked Resolved with
  full integration note. NPC Memory table row for Roan flipped from
  "neutral / no quest yet" to "warms when wolves quiet / 4 (faction, run 8)
  / dire_wolves pressure < 0.5". Faction State table row for Dire Wolves
  now lists Roan dialogue as a third consumer alongside spawn density and
  adaptive cooldown. Two new top-priority hooks promoted: Roan-issued
  wolf-bounty quest (-0.1 reducer) and a future Roan `warm_flag` tier
  on `first_bounty_done` once that quest ships.
- `SYSTEM_REGISTRY.md`: NPC Schema "Tier 3" entry now cites run 8 as the
  generalization run (Roan = sole-warming-channel proof) alongside run 4
  (Maeve = secondary-tier proof). Updated consumer count for
  `World.faction_pressure()` to reflect Roan as a new dialogue reader.
- `CHANGES.md`: this entry.

### Rule-2 outputs delivered
- (i)   World state: no new writes; new READ of `dire_wolves` pressure
        from a SECOND NPC dialogue path (after Maeve's `whisperwood_goblins`
        path). WORLD_STATE.md updated with the new consumer in the NPC
        Memory table and the faction-state table.
- (ii)  Queryable schema: no schema additions — exercises the existing
        `warm_faction_id` / `warm_faction_below` / `warm_faction_lines`
        contract that has been documented in SYSTEM_REGISTRY.md since
        run 4. SYSTEM_REGISTRY.md "Tier 3" entry now documents both
        usage modes (secondary tier behind a flag, OR sole warming
        channel). Authoring template proven.
- (iii) Player-facing feedback: 4 new Roan lines that fire the moment
        any wolf-reducing quest ships (today: `pelt_for_lyra` drops
        pressure 0.5 → 0.4, < 0.5 trips the threshold). Kid-readable
        narrative cue ("Pippin's grazing past the fence again") that
        composes with the ⚡ agitation prefix already on surviving
        wolves AND the visible drop in wolf count from run 6. Owen's
        mastery hook: he can read THREE concurrent world-state signals
        on the SAME completion event.
- (iv)  Evaluation: parens/brackets/braces balance check passes
        (1076/1076, 56/56, 36/36). Double-quote parity even (768).
        NPCS entry count unchanged at 7. New `warm_faction_*` data
        keys validated against the existing `_make_npc()` reader at
        line ~1013 (no NPC.gd or _make_npc edits required — pure
        data extension on Roan's row).
- (v)   Future hooks (≥ 2):
        1. **Roan-issued wolf-bounty quest** — second `dire_wolves`
           reducer (-0.1). Trips the second wolf-spawn threshold
           (3 → 2 wolves) AND drops adaptive cooldown another step.
           One new quest entry + faction consequence payload. Now
           top-priority hook in WORLD_STATE.md. Composes with run 8.
        2. **Roan `warm_flag` tier (`first_bounty_done`)** — once the
           bounty quest ships, promote Roan to a fully 4-tier NPC by
           adding 4 `warm_lines` for personal warmth ("you brought the
           tally back") on top of the run-8 faction tier. Mirrors
           Mara's `good_customer` pattern.
        3. **Skeleton / Bandit faction-tier dialogue** — once those
           factions ship, any NPC can author 4 lines + 3 fields and
           speak the new state. Run 8 proves the data-only authoring
           path works. Crystal Caves placement (top remaining backlog
           item) unlocks both.
        4. **Bram and Hala faction-tier lines** — Roan was the
           lowest-effort NPC to wire because his role (stables,
           road-safety, mounts) thematically matches the wolf
           faction. Bram (innkeeper, road-traveler stories) and Hala
           (warrior-monk, "the world tests you") are the next two
           NPCs whose voice could sit on a faction scalar with no
           quest authoring required.

### Phase reached
Historian — feature shipped, all 5 ledgers updated, ready to commit.

### Next run should pick up
**Roan-issued wolf-bounty quest (-0.1 reducer for `dire_wolves`).**
Mirrors `ears_for_mara` as the second goblin reducer. Trips the
second wolf-spawn threshold (3 → 2) AND drops adaptive cooldown
another step — single quest, three visible world changes (Roan's
lines stay warm, fewer wolves, faster survivors). After that, Roan's
`warm_flag` tier on `first_bounty_done` promotes him to full 4-tier
parity with Maeve / Mara / Lyra.

## 2026-05-05 (autonomous run) — NPC re-source: Lyra, Roan, Hala upgraded after self-critique

### What changed
After the previous batch landed, comparing the eight NPC source thumbnails side-by-side made it obvious that three of the seven villagers didn't fit THEME §4 well. This run swaps those three to better-matched Sketchfab CC-BY pulls. Mara (mushroom-merchant) and Edda (worker_girl) stay as-is because no kid-safe upgrade was available — for Edda specifically, three female-warrior candidates were rejected mid-run (bikini-armor barbarian, sexualized amazon, and a sci-fi mech-knight) per THEME §7 child-safety rules and §1 no-modern/sci-fi.

### Swaps (in-game role → new GLB)
- **Herbalist Lyra**: `npcs/herbalist_lyra.glb` re-sourced from a chibi green druid → "Eadwien Elf Recruit" (slender female elf in green dress with leather accents). Now actually reads as the "slender healer with leaf-tangled hair" THEME describes
- **Stablemaster Roan**: `npcs/stablemaster_roan.glb` re-sourced from a quirky outlaw-creature → "Rogue Knight" (hooded grey-clad rogue with leather and a glowing accent). Reads as a lean ranger/scout
- **Trainer Hala**: now uses new `npcs/trainer_hala.glb` ("Monkey Warrior" — a chunky Sun-Wukong-style martial-artist creature, painterly stylized, 2 baked anims, ~24 MB). Replaces `warrior.glb` for this NPC role (warrior.glb stays in tree for a future guardsman or quest archetype)

### Wiring
- `WorldBuilder.gd::NPC_MODELS` "Trainer Hala" key changed from `warrior.glb` → `trainer_hala.glb`. The other two NPCs use the same paths as before — only the file contents changed, so no preload swap was needed
- New `npcs/trainer_hala.glb.import` Godot metadata
- The two replaced files keep the same UIDs in their existing `.glb.import` files; on next project open Godot will detect the binary change and re-import. No `.import` rewrites needed for those

### Theme citations
- THEME §1 — no modern, no sci-fi. The Female Knight Model (sci-fi mech), Sci-Fi Hunter (energy gun + breathing mask) were rejected on this gate
- THEME §7 — sexual content forbidden (audience age 9 and 11). The Warrior Maiden (bikini barbarian) and 3DRT Fantasy Amazon (bikini armor) were rejected on this gate. **Important for future agents:** Sketchfab "female warrior" results skew heavily toward sexualized armor — search "fantasy female knight" or "stylized woman peasant" or "shopkeeper" instead, and verify thumbnails before download
- THEME §4 — silhouette-distinct: the new lineup adds an elven robed silhouette (Lyra), a hooded grey rogue silhouette (Roan), and a hulking simian martial-artist silhouette (Hala). These are silhouette-distinct from each other and from the rest of the cast (granny, dwarf, generic worker, mushroom person, knight player)

### Files touched
- `eldoria-godot/assets/models/npcs/herbalist_lyra.glb` (REPLACED, 1.5 MB)
- `eldoria-godot/assets/models/npcs/stablemaster_roan.glb` (REPLACED, 1.6 MB)
- `eldoria-godot/assets/models/npcs/trainer_hala.glb` (NEW, 23.9 MB)
- `eldoria-godot/assets/models/npcs/trainer_hala.glb.import` (NEW)
- `eldoria-godot/scripts/WorldBuilder.gd` (one preload-path swap for Hala)
- `CREDITS.md` (3 lines updated)

### What still needs work (next run)
- **Mara the Merchant** still uses `mushroom_merchant.glb` — whimsical mushroom-person, child-friendly but doesn't match THEME's "plump trader in layered robes". Best candidate found this run was a 2-figure Chinese Merchant pack at 16 MB — too big and contains 2 characters in one file
- **Smith Edda** still uses `worker_girl.glb` — generic young woman in working clothes. Doesn't match THEME's "stocky soot-streaked smith with leather apron and hammer". CC-BY female-smith art is essentially nonexistent on Sketchfab; future runs may need to fall back to Meshy text-to-3D for this one
- The current Hala model at 23.9 MB is the largest character file in the project. If web export load times become a concern, future runs should look for a smaller alternative or trim textures

### Status
Pushed to `main` — GitHub Actions will rebuild the web export within 3-5 min.

---

## 2026-05-05 (autonomous run) — Player + all 7 villagers swapped to real fantasy GLBs

### What changed
The player hero and every villager in Briarwood were rendering as the same generic mannequin tinted differently per role. Specifically: the Player used `Hero.glb` ("Stylized Low poly Animated Character" — a generic animated mannequin), and every NPC in `WorldBuilder._make_npc` instanced `CesiumMan.glb` (a totally placeholder mannequin) and applied a per-NPC color tint as the only differentiator. So the seven villagers were silhouette-identical — a direct violation of THEME §4 ("each NPC should be silhouette-distinct — you should recognize them at 30m").

This run swaps the player and all 7 NPCs to per-character hand-curated GLBs, sourced as a mix of fresh Sketchfab CC-BY pulls and re-use of previously-orphaned npcs/ GLBs that earlier batches added but never wired in.

### New mapping (in-game role → source GLB)
| Role | GLB | Source / why this fits |
|---|---|---|
| **Player hero** | `hero_lange.glb` | "Lange - Half-Elf Knight" (CC-BY, 2 anims, ~21k faces) — dark teal tunic, leather armor, sash, dagger at hip, eyepatch. Reads as fantasy adventurer per THEME §4 |
| **Elder Maeve** | `npcs/elder_maeve.glb` | "Old Village Granny" (CC-BY, 1 anim) — gray-haired elderly woman in red-orange dress and apron. Literal grandmother |
| **Smith Edda** | `npcs/worker_girl.glb` (reused) | Generic working-clothes female from Char batch 2 — silhouette of a stocky working woman, fits THEME blacksmith |
| **Mara the Merchant** | `npcs/mushroom_merchant.glb` (reused) | Has bag, scroll, scarf (mesh names confirm) — perfect merchant silhouette |
| **Herbalist Lyra** | `npcs/herbalist_lyra.glb` | "Low Poly Forest Druid" (CC-BY) — chibi-stylized hooded green-themed druid; silhouette matches herbalist with leaf-tangled hair |
| **Innkeeper Bram** | `npcs/innkeeper_bram.glb` | "Stylized Hand Painted Dwarf" (CC-BY) — bald with orange handlebar mustache, green tunic, leather wraps. The trope incarnate |
| **Stablemaster Roan** | `npcs/stablemaster_roan.glb` | "Stylized Outlaw" (CC-BY) — lean, rangy figure with vest and gloves. Acceptable rough-around-the-edges ranger |
| **Trainer Hala** | `npcs/warrior.glb` (reused) | Sword + shield + warrior body — fits warrior-monk |

### Wiring
- **`Main.tscn`** — single `ext_resource` path swap from `Hero.glb` → `hero_lange.glb` for ID `8_hero`. Player node still instances `ExtResource("8_hero")` so the change is purely the asset binding.
- **`WorldBuilder.gd`** (+30 lines, additive)
  - New `const NPC_MODELS` dict keyed on `data.name` (matches `NPCS` const) → `PackedScene`
  - New `const NPC_SCALES` dict for per-NPC visual scale tuning (different sources have different native heights — first-pass values; future runs can refine)
  - `_make_npc()` now picks `NPC_MODELS.get(data.name, npc_scene)` and tracks `uses_real_model`. The flat tint modulate is applied **only** to the placeholder fallback — real models keep their painted textures
  - When a real model is used, `npc.call_deferred("_npc_play_idle_anim_if_any")` triggers an animation if the source GLB ships one
- **`NPC.gd`** (+22 lines) — added `_npc_play_idle_anim_if_any()` and `_find_first_anim_player(n)` recursive helpers. Tries common idle-animation spellings (`Idle` / `idle` / `IdleAnimation` / `ArmatureAction.001` / `Take 001` / `Scene`), then falls back to the first available

### Theme citations
- THEME §1 — no modern, no sci-fi: every chosen model is painterly stylized fantasy. Three sci-fi/modern candidates were rejected mid-run (a sci-fi female "Hunter" with energy gun, a modern grandma with a walking frame in jeans, and a modern peasant in fighting stance) before download became a commit
- THEME §4 — each villager is now silhouette-distinct: an old crone in a red dress, a stocky woman in working clothes, a robed merchant, a green druid, a bald dwarf, a lean outlaw, a sworded warrior, plus an adventurer with eyepatch + sash for the player. From 30m they read different
- THEME §10 rule 8 — every asset is source-credited (CC-BY) in CREDITS.md

### Files touched
- `eldoria-godot/assets/models/hero_lange.glb` (NEW, 12.7 MB)
- `eldoria-godot/assets/models/hero_lange.glb.import` (NEW)
- `eldoria-godot/assets/models/npcs/elder_maeve.glb` (NEW, 250 KB)
- `eldoria-godot/assets/models/npcs/elder_maeve.glb.import` (NEW)
- `eldoria-godot/assets/models/npcs/herbalist_lyra.glb` (NEW, 320 KB)
- `eldoria-godot/assets/models/npcs/herbalist_lyra.glb.import` (NEW)
- `eldoria-godot/assets/models/npcs/innkeeper_bram.glb` (NEW, 903 KB)
- `eldoria-godot/assets/models/npcs/innkeeper_bram.glb.import` (NEW)
- `eldoria-godot/assets/models/npcs/stablemaster_roan.glb` (NEW, 2.6 MB)
- `eldoria-godot/assets/models/npcs/stablemaster_roan.glb.import` (NEW)
- `eldoria-godot/assets/models/npcs/mushroom_merchant.glb.import` (NEW import for already-present GLB)
- `eldoria-godot/assets/models/npcs/warrior.glb.import` (NEW import for already-present GLB)
- `eldoria-godot/assets/models/npcs/worker_girl.glb.import` (NEW import for already-present GLB)
- `eldoria-godot/scenes/Main.tscn` (one ext_resource path swap)
- `eldoria-godot/scripts/WorldBuilder.gd` (NPC_MODELS, NPC_SCALES, `_make_npc` selector branch)
- `eldoria-godot/scripts/NPC.gd` (idle-anim helper)
- `CREDITS.md` (8 new credit lines)

### Validation
- Bracket / brace / paren balance: PASS for both edited GDScripts (`WorldBuilder.gd` 1125/1125, `NPC.gd` 68/68)
- Single definition of `NPC_MODELS`, `NPC_SCALES`, `_make_npc`, `_npc_play_idle_anim_if_any`, `_find_first_anim_player`
- All 7 NPCs in the `NPCS` const are keyed in `NPC_MODELS` — none fall through to placeholder
- No procedural primitives parented to character bodies — THEME §10 ban respected
- Soldier.glb still untouched as a visible character — BAN respected
- Old `Hero.glb` left in tree (still referenced by some import metadata); future cleanup can remove it once no other code references it

### Next run should pick up
- **Boss.glb wiring** — there's a 4.7 MB "Mountain Orge" GLB at `assets/models/Boss.glb` with 13 animations including Death/Ideal/Jump that's not wired anywhere. Add it to `Enemy.gd::KIND_MODELS` for `crystal_guardian` (or as `goblin_warlord` boss when that kind ships)
- **Wolf wiring** — `assets/models/enemies/wolf.glb` (real quadruped, 1 anim) is sitting unwired since Char batch 2. Add to `KIND_MODELS["wolf"]` and remove the `_model.rotation.x = -PI / 2` rotation hack once the model's forward axis is verified
- **Skeleton + Crystal Elemental** — both still using RobotExpressive in the Crystal Caves dungeon
- **Per-NPC scale tuning** — `NPC_SCALES` values are first-pass guesses. Once the build deploys, dial each NPC up/down so heights look right next to the player

### Status
Pushed to `main` — GitHub Actions will rebuild the web export within 3-5 min.

---

## Run 7 2026-05-04 (autonomous) — Adaptive enemy attack cooldown (3rd output on faction_pressure)

### Plan
WORLD_STATE.md's 🔥 top-priority hook called for the THIRD output on the
`World.faction_pressure(id)` scalar that already drives NPC.gd dialogue
tier 3 (run 4) and WorldBuilder spawn density (runs 5–6). One scalar,
three independent readers — narrative + density + pacing. Picked because
this is a pure recombination of existing primitives (Rule 1.a), keeps the
combat hot path untouched, and proves the *generalizability* of the
faction-pressure pattern past two consumers.

### Build
- `eldoria-godot/scripts/Enemy.gd` (+64 / -0):
  - New constants block under `KIND_MODELS`: `KIND_TO_FACTION` map (goblin
    → whisperwood_goblins, wolf → dire_wolves, skeleton/crystal_elemental/
    crystal_guardian → crystal_caves; bandit unmapped on purpose since no
    bandit faction exists yet); `ATTACK_COOLDOWN_BASELINE = 1.45` and
    `ATTACK_COOLDOWN_MIN = 1.05` (kid-tuned band endpoints; PLAYER_MODEL
    forbids widening without re-tuning); `AGITATED_COOLDOWN_THRESHOLD = 1.30`
    (where the visible ⚡ marker fires).
  - New `_resolve_adaptive_cooldown()` helper called once at the top of
    `_ready()` (after `hp = max_hp`, before label creation so the ⚡ prefix
    propagates into `_label.text`). Reads pressure via
    `world_node.faction_pressure(faction_id)` with the same fail-soft guards
    used in WorldBuilder spawn density: missing world group, missing
    accessor, OR unmapped kind ALL fall through to baseline 1.45.
  - `attack_cooldown` mutated in-place; `_do_attack()` is untouched.
- `WORLD_STATE.md`: top-priority hook marked Resolved (run 7); new
  top-priority promoted to Roan dialogue tier (which now has TWO partners:
  wolf spawn density + wolf cooldown agitation); new adjacent promoted to
  Roan-issued wolf-bounty quest. Faction-state table now lists cooldown as
  a 4th consumer of pressure on goblins, wolves, AND crystal_caves (wired
  prophylactically — fires the moment Crystal Caves ship). Player-impact
  ledger gains "Surviving enemy aggression" as the third *visible* axis.
- `SYSTEM_REGISTRY.md`: new "Enemy Cooldown Schema" section between Wolf
  Spawn Schema and World Flag Conventions, with: kind → faction map table,
  pressure → cooldown endpoint table at six points (1.0 / 0.85 / 0.65 /
  0.40 / 0.15 / 0.00), authoring rules (clamp + assert contract,
  fail-soft pattern, save-reload semantics matching spawn density), and
  the cosmetic-only ⚡ guarantee (loot tables and quest matching read
  `enemy_kind`, never `enemy_name`).
- `PLAYER_MODEL.md`: run-7 addendum spelling out per-kid impact (Alden's
  recovery valve preserved at fresh save, Owen's mastery rung scales
  through the same archetypes), output #4 + #5 candidates with the
  output-#5 PLAYER_MODEL.md gate (damage lerp risks Alden's HP economy;
  must be paired with symmetric `xp_reward` lerp), and the run-8
  difficulty-signal candidates (TTK delta on ⚡ vs baseline; deaths-per-
  quest in late game).
- `CHANGES.md`: this entry.

### Rule-2 outputs delivered
- (i)   World state: WORLD_STATE.md updated — Resolved entry, new top-priority,
        new adjacent, three faction-state rows updated to list cooldown
        as a consumer, player-impact ledger gains the third visible axis.
        Reads from `World.faction_pressure(id)` are now FOUR (NPC dialogue,
        goblin density, wolf density, enemy cooldown).
- (ii)  Queryable schema: `KIND_TO_FACTION` Dict + `_resolve_adaptive_cooldown()`
        helper documented in SYSTEM_REGISTRY.md "Enemy Cooldown Schema."
        Endpoint table at six pressure points + clamp/assert contract +
        fail-soft pattern + save-reload semantics. Schema mirror-shape with
        `_<kind>_pack_size(pressure)` helpers from runs 5–6 so the next
        engineer learns ONE pattern: "faction → reader."
- (iii) Player-facing feedback: visible `⚡ ` prefix on the floating name
        when the enemy's resolved cooldown < 1.30. Pairs with the spawn-
        density toasts (which announce *count* change) by surfacing
        *pacing* change at per-enemy granularity. Threshold corresponds
        to roughly pressure ≤ 0.625 — clearly past the first reducer.
- (iv)  Evaluation: parens/brackets/braces balance check passes (223/223,
        8/8, 2/2). All new `var` declarations carry explicit type
        annotations (`var faction_id: String`, `var world_node: Node`,
        `var pressure: float`, `var resolved: float`). Runtime assert
        enforces `resolved ∈ [1.05, 1.45]` — band contract. Fail-soft
        guards mirror WorldBuilder spawn density (missing world / missing
        accessor / unmapped kind → baseline, never crash).
- (v)   Future hooks (≥ 2):
        1. **Roan dialogue tier 3 on `dire_wolves`** — now has TWO partners
           in the wolf compound (density + cooldown agitation), so dialogue
           speaks state that the world ALREADY shows. Schema in place;
           only WorldBuilder edits to NPCS dictionary required.
        2. **Roan-issued wolf-bounty quest (-0.1 reducer)** — second
           reducer for `dire_wolves`, trips wolf-spawn 3 → 2 AND drops
           cooldown another step. ONE quest, TWO visible world changes.
        3. **Adaptive `chase_speed`** — output #4 on the same scalar
           (`lerp(4.6, 5.4, 1.0 - p)`). Tighter band so calmed enemies
           don't outrun mounted Owen.
        4. **Adaptive `damage` + symmetric `xp_reward`** — output #5,
           gated on PLAYER_MODEL.md tuning per the addendum: lerping damage
           up requires lerping XP up so the harder fight is more rewarding.
        5. **Skeleton + crystal_elemental + crystal_guardian** all
           pre-wired to `crystal_caves` cooldown — the moment Crystal Caves
           ship, dungeon enemies inherit the same pressure→pacing contract
           with zero new code.

### Phase reached
Historian — feature shipped, all 4 touched ledgers updated, ready to commit.

### Next run should pick up
**Roan (Stablemaster) → `dire_wolves` faction tier dialogue.** After run 7,
the wolf compound now has THREE consumers of `dire_wolves` pressure:
spawn density + cooldown agitation + (proposed) Roan dialogue. Roan smoke-
tests the 4-tier dialogue system on an NPC with NO `warm_flag` at all —
proves the faction-tier path stands alone. After Roan: a Roan-issued
-0.1 wolf-bounty quest (mirrors `ears_for_mara`) trips the second wolf
threshold AND drops cooldown another step, a single quest with two
visible world changes — the readability target for kid-aged co-op play.

## Integration 2026-05-04 (integrator) — Quest flags now warm NPC dialogue

### Gap (pattern A)
- The consequence resolver writes `npc_flags` (Maeve→`first_quest_done`, Lyra→`trusts_player`, Mara→`good_customer`) when their quests complete.
- WorldBuilder.NPCS just shipped 4 mood-dependent dialogue variants per NPC, picked by `World.time_of_day`.
- WORLD_STATE.md flagged this as 🔥 **top-priority next**: NPC.gd should consult `World.npc_has_flag()` and pick a different line when warmed.
- But `NPC.gd._on_interact()` ignored npc_flags entirely — flags were written and never consumed. Two systems, one missing wire.

### Bridge
- **NPC.gd** — added `warmed_flag: String` and `warmed_dialogue_variants: PackedStringArray` exports. In `_on_interact()`, if a `warmed_flag` is set AND `World.npc_has_flag(npc_name, warmed_flag)` returns true AND warmed variants exist, the same time-of-day bucket is pulled from the warmed array instead of the cold one. Falls back to existing behavior on every other axis (no warm fields → no change).
- **WorldBuilder.gd** — Maeve, Lyra, Mara each carry a `warm_flag` + 4-entry `warm_lines` array. `_make_npc()` wires them onto the NPC node alongside the existing dialogue_variants assignment.
- **WORLD_STATE.md** — top-priority hook marked resolved with the wiring detail.

### Effect
- Three NPCs × four time-of-day moods × cold-or-warmed = **24 reactive lines** unlocked from a single wiring change.
- No new functions, no balance change, no schema break for the four other NPCs (their `warm_*` fields are absent → array stays empty → variants fall through unchanged).
- The Crystal Caves faction (`pressure: 0.0`) is now ready to drive its own warm/cold dialogue once an NPC ties to it.

### Open TODOs
- `[INTEGRATOR-ASK]` — WORLD_STATE.md still lists Crystal Caves with STATUS "planned, not yet placed in world", but commit `bf4934d` actually placed the dungeon NW of village. The Architect agent should update the canon (geography + faction note + remove the entrance hook) on the next world-state pass.
- `[INTEGRATOR-ASK]` — Goblin spawn density should read `World.faction_pressure("whisperwood_goblins")` per the second 🔥 hook in WORLD_STATE.md. Single-read wiring change in the goblin spawner. Skipped this run to honor the one-integration-per-run rule.

---

## 2026-05-04 (autonomous run) — Fantasy hero makeover (Soldier → knight)

### What changed
The Soldier.glb is the Mixamo Vanguard — a sci-fi-looking trooper with a glowing visor that didn't fit the medieval-fantasy world. Inspected the GLB structure (68 nodes, 2 meshes: `vanguard_Mesh` body + `vanguard_visor`) and confirmed there's no separate rifle node, so the "soldier" feel comes entirely from the visor + tactical body texture. Approach: hide the visor and bolt on a full set of procedural fantasy gear so the player reads as a knight/adventurer.

### New systems in `Player.gd` (+170 lines, all appended)
- **`_apply_fantasy_makeover()`** — `call_deferred`d from `_ready()` so it runs after the GLB instance is fully spawned
- **`_hide_modern_bits(node)`** — recursively walks the Soldier scene tree; any MeshInstance3D whose name (case-insensitive) contains `visor`, `rifle`, `gun`, `barrel`, `magazine`, `scope`, `muzzle`, `ammo`, `bullet`, `pistol`, or `trigger` is set `visible = false`. The vanguard's visor is hidden by name; the helper is also future-proof for any other rigged weapon meshes that show up later
- **`_build_fantasy_gear()`** — builds a `FantasyGear` Node3D under the Player and populates it with procedural armor pieces using shared StandardMaterial3D instances (bronze, gold w/ subtle emission, crimson cloth, dark leather)

### Gear pieces (all rigid in player-space — placed on torso/head only so walk-cycle bone deformation doesn't make them pop)
- **Bronze knight's helm** — tapered cylinder cap covering head & visor (top_radius 0.16, bottom_radius 0.21, height 0.24)
- **Crown** — 5 gold prism spikes ringing the helm rim at radius 0.17
- **Gold forehead band** — flat cylinder, gold material, sits at the helm/face boundary
- **Crimson cape** — 0.60 × 1.05 × 0.04 box, slight 8° backward tilt, hangs at +Z (back of player)
- **Gold cape collar** — gold trim across the top of the cape
- **Bronze pauldrons** — hemispheres (radius 0.14) on both shoulders, each with a small gold rivet on top
- **Crimson tabard** — 0.34 × 0.72 chest panel at -Z (front) covering the tactical-looking torso
- **Gold tabard emblem** — prism-shaped diamond at chest center
- **Dark-leather belt** — 0.58 × 0.10 × 0.44 box around the waist
- **Gold belt buckle** — small gold square on the front of the belt

### Files changed
- `scripts/Player.gd` (+170 lines: `var fantasy_gear` declaration, two new `call_deferred` calls in `_ready()`, three new functions)

### Validation
- Bracket/brace/quote balance: PASS for all 12 GDScripts
- All new declarations use explicit types or `:=` against typed constructors (`StandardMaterial3D.new()`, `MeshInstance3D.new()` etc.) — no Variant strict-mode violations
- `for sx in sides:` iteration uses an `Array[float]` so `sx` is properly typed
- All new nodes are children of a single `FantasyGear` Node3D so the gear can be torn down or toggled cleanly later (e.g., for an "armor swap" feature)

### Notes for next run
- Gear is rigid in player-space. The torso barely moves during walk so this looks fine, but if the kids notice the cape "floats" on running, the next iteration could parent the gear to BoneAttachment3D nodes (Hips bone for belt, Spine2 for tabard, Head for helm) using the imported skeleton path `Soldier/Character/mixamorig:Hips`
- The body's skin texture still has tactical detailing under the tabard — fine for now, since the tabard + pauldrons cover most of the visible torso
- Did NOT touch Main.tscn — all changes are runtime so the scene file is unchanged
- Did NOT replace the Soldier.glb with a CC0 alternative — the procedural makeover gets us 80% of the way there with zero asset download/import overhead

### Status
✅ Pushed to `main` — GitHub Actions auto-builds within 3-5 min

### Next run should pick up
- **Backlog item 3: Better trees** — current cone+sphere stack looks placeholder-tier. Either source Kenney Nature Kit or rewrite `_make_tree` for irregular foliage with multiple jittered spheres + branching trunks, applying the existing bark PBR texture
- **Backlog item 4: Smith Edda forge UI** — buy/sell/upgrade weapons, enchant action that costs gold + Crystal Shards (we now have a steady source from the caves!)
- **Optional iteration on this run**: bone-attach the fantasy gear to the Mixamo skeleton so it animates with the body during walk/run/attack

---

## 2026-05-04 (autonomous run) — Crystal Caves dungeon (NW of village)

### New zone: Crystal Caves
- New `_build_crystal_caves(Vector3(-50, 0, -40))` in `WorldBuilder.gd` (~165 new lines, plus two helpers `_make_crystal_cluster` and `_make_stalagmite`)
- Cavern dome (inverted sphere shell, dark slate interior) caps the play area without blocking the camera
- Stone entrance arch facing the village: two tapered columns + capstone + a glowing blue beacon crystal that radiates omni light so the kids can spot the entrance from the Whisperwood
- Dim ambient blue OmniLight (energy 0.85, range 28m) for the main chamber + a deeper violet OmniLight (energy 1.6) seeded near the boss room
- Dark stone floor disc (22m radius)
- 9 procedural crystal clusters scattered around the cave — 3–6 emissive PrismMesh shards per cluster, pulsing OmniLight at the heart, alpha-blended translucent shards in three palettes (blue / teal / violet); the giant central crystal in the boss room is scale 2.2
- 18 floor stalagmites + 12 ceiling stalactites randomized in radius and height
- Stone arch separating the entry chamber from the boss room (two pillars at z=-10)
- Skull pile in front of the boss crystal — ominous flavor

### New enemies
- **Restless Skeleton** — 5 spawn around the cavern (HP 36, dmg 8, XP 24, gold 7, bone-white tint Color(0.95,0.95,0.92), move 2.4 / chase 4.4)
- **Crystal Elemental** — 3 spawn deeper in the cave (HP 70, dmg 14, XP 55, gold 14, glowing cyan, slower at 1.8/3.2 but hits hard)
- **Crystal Guardian** (boss) — 1 spawn in the back of the cave at (-50, 0, -56). HP 420, dmg 26, XP 480, gold 200. Uses `crystal_guardian` enemy_kind with scale 1.55 and crystal-blue tint.
- `Enemy.gd` updated with model scales for the new kinds (`skeleton`, `crystal_elemental`, `crystal_guardian`)

### Loot
- New legendary trinket `guardian_core` (Guardian's Core 💠) — +60 HP, +40 MP, +8% crit, value 1800
- New drop tables in `Items.gd`:
  - `skeleton` — crystal_shard / rusty_sword / iron_sword / chainmail / hp_potion_s / mp_potion / steel_blade
  - `crystal_elemental` — crystal_shard (60%) / mp_potion / hp_potion_l / ring_focus / frost_saber rare
  - `crystal_guardian` — guardian_core + 3-5 crystal_shards guaranteed-ish + frost_saber / steel_plate / emberforge / ring_focus / hp_potion_l + 2% dragonscale
- Reuses existing `crystal_shard` material drop as the cave's signature trash currency

### Files changed
- `scripts/WorldBuilder.gd` (+165 lines: `_build_crystal_caves` + 2 helpers, hooked into `_ready`)
- `scripts/Enemy.gd` (+6 lines: scale match cases for skeleton, crystal_elemental, crystal_guardian)
- `scripts/Items.gd` (+34 lines: guardian_core trinket + 3 drop tables)

### Validation
- Bracket/brace/quote balance: PASS for WorldBuilder.gd, Enemy.gd, Items.gd
- All new walrus declarations (`var x := Constructor.new()`) are on concrete types — no Variant strict-mode violations
- Enemy.gd has a `_:` fallback for unknown kinds, so existing goblin/wolf/bandit behavior unaffected

### Status
✅ Pushed to `main` — GitHub Actions should auto-build the Web export within 3-5 min

### Next run should pick up
- **Backlog item 2: Fantasy character replacement** — Soldier.glb is jarring in a fantasy world. Try Quaternius RPG Hero Polypack (CC0) or use CesiumMan + procedural cape/helmet, and at minimum hide the rifle.
- **Backlog item 3: Better trees** — current cone+sphere stack is placeholder-tier; either source Kenney Nature Kit or rewrite `_make_tree` for irregular foliage with multiple jittered spheres + branching trunks
- **Backlog item 4: Smith Edda forge UI** — buy/sell/upgrade weapons, enchant action that costs gold + Crystal Shards (we now have a steady source from the caves!)

---

---

## 2026-05-04 (latest run) — Goblin Warlord boss, audio engine, pet & mount system

### Goblin Warlord boss fight
- New `scripts/Boss.gd` (359 lines) — boss enemy with three attack patterns:
  - **Melee** — heavy hit + 5m knockback
  - **AoE Slam** — telegraphed red ring, 0.7s windup, 1.4× damage in a 5m radius, vertical knockback
  - **Charge** — telegraphed line, sprint forward at 18 m/s for 0.7s, 1.6× damage on contact
- Phases at 50% / 25% HP — summons 2 Warlord's Guard adds each phase with shouted dialogue ("RAAAGH! To me, my kin!")
- Gold crown, glowing red aura omni light, billboard name with ✦ markers
- Boss intro sting auto-plays when player enters 30m radius
- Boss arena built at (60, 0, 60): 8 stone monoliths, skull pile, green war banner pole
- Drops 3 rolls from `goblin_warlord` table — Frost Saber / Ember Axe / Shadow Dagger / Emberforge / Crit Amulet / Greater Potion stacks / **Dragonfang & Dragonscale at 2% each**
- Boss HP bar pinned top-center of screen with red fill while in combat

### Procedural CC0 audio engine
- 10 SFX generated as 16-bit WAV via Python (envelope + sine + noise synthesis): sword_swing, sword_hit, damage_taken, enemy_death, loot_pickup, level_up, quest_accept, chest_open, player_death, boss_intro
- 3 ambient music tracks (drone + pentatonic melody pattern): village_theme (C minor, 2 min loop), whisperwood_theme (low E, 2 min, darker), battle_theme (D, 1.5 min, faster tempo)
- AudioStreamPlayer nodes (MusicPlayer + SFXPlayer) added to Main.tscn
- World.gd: `play_music(zone)` / `play_sfx(name)` helpers, auto-switches zone music every 1.5s based on player position (village ↔ whisperwood ↔ battle near boss)
- SFX hooks wired in: Player attack, hit, take_damage, die, level_up; Enemy die + loot pickup; Chest open; World quest accept; Boss intro
- 15 MB total audio in `assets/audio/{music,sfx}/`

### Companion pet
- New `scripts/Pet.gd` (95 lines) — fox companion "Ember" 🦊 follows player using Fox.glb
- Distance-based speed (clamps 1.5–8.0 m/s), face-toward-player rotation, occasional "yip!" bark popup at nearby enemies
- Spawns next to player on game start

### Mount system
- World.gd: `toggle_mount` (M key) — must be near Stablemaster Roan to mount
- On mount: instantiates Horse.glb under Player, doubles walk_speed (5.5→9.5) and run_speed (9.0→14.0)
- On dismount: removes horse model, restores normal speed

### Wiring + cleanup
- Help label in HUD updated with full key reference: `WASD / Shift / Space / Right-drag / Wheel / E / Left-click / I / Q / M`
- Player.gd: `_on_inventory_changed` signal handler emits stats_changed to refresh HUD
- WorldBuilder.gd: removed duplicate `_build_chests()` call (linter integrated it into `_build_loot_chests`)
- All 12 GDScripts pass bracket/quote balance check (~4000 lines total)

### Files added/touched in this run
- ✨ NEW: `scripts/Boss.gd`
- ✨ NEW: `scripts/Pet.gd`
- ✨ NEW: `assets/audio/sfx/*.wav` (10 files)
- ✨ NEW: `assets/audio/music/*.wav` (3 files)
- `scripts/Player.gd` (SFX hooks, mount/quaff/inventory keys)
- `scripts/Enemy.gd` (SFX hooks for death + loot)
- `scripts/Chest.gd` (SFX hook on open)
- `scripts/World.gd` (audio engine, boss HP bar, mount system, ESC handler)
- `scripts/WorldBuilder.gd` (boss arena, pet spawn, BOSS_SCRIPT/PET_SCRIPT/CHEST_SCRIPT preloads)
- `scenes/Main.tscn` (Audio sub-tree, updated help text)

### Status
✅ Ready to deploy with `bash full-deploy.sh`

### Nightly autonomous builder
A scheduled task (`eldoria-nightly-builder`) runs every minute, picking from a rolling backlog. It reads CHANGES.md to avoid duplicate work and appends new entries here.

### Backlog queued for autonomous runs
1. **Crystal Caves dungeon** (Phase 2 item 4) — multi-level instanced zone NW of village with crystal formations + boss room
2. **Smith Edda forge UI** — buy/sell/upgrade weapons, gem socketing
3. **Achievements + title system** carry-over from HTML version
4. **Volumetric god-rays** through tree canopy
5. **Better character animations** from Mixamo CC0 library
6. **NPC schedules** — they walk between specific POIs at different times of day
7. **Visible armor swap** on Soldier model (currently only weapon swaps visibly)
8. **Better banner art** via Adobe Firefly / Stock once a quality source is found

---

## 2026-05-04 (later run) — Inventory UI, fetch quests, treasure chests & affix loot

### Inventory & Equipment UI (Phase 1 item 3 — DONE)
- Built full in-game inventory panel in `World.gd` (~260 new lines)
- Press **I** to toggle. Center-screen 720×480 panel with:
  - Paperdoll column (left): Weapon / Armor / Trinket equipment slots, recolored by rarity
  - Bag grid (right): 6×4 = 24 slots, each shows item icon + qty, recolored by rarity
  - Stats card: live damage / armor / max HP+bonus / max MP+bonus / crit % readout
  - Tooltip panel that follows the mouse and shows full item stats with rarity color
  - Close button (✕) and footer hint line
- Click bag slot → equips equipment / drinks consumable. Click paperdoll slot → unequips back to bag.
- `Inventory.gd` extended with `count_item`, `has_item`, `consume_item` for fetch-quest accounting
- HUD HP/MP bars now reflect equipment bonuses (max_hp + inventory.bonus_hp())

### Quest Engine v2 — fetch quests (Phase 1 item 2 — DONE)
- New `QUEST_CATALOG` in `World.gd` mapping NPC roles → quest dicts
- Quest now has `kind` field: `"kill"` (existing) | `"fetch"` (new)
- `Player.is_quest_ready_to_turn_in()` checks the right condition per kind
- Two new fetch quests live in the world:
  - **Herbalist Lyra** (alchemy) — "Pelts for the Salve": bring 4 Wolf Pelts, get +70 XP, +45 gold, **2 Greater Health Potions**
  - **Mara the Merchant** (shop) — "Bounty on Goblin Ears": bring 6 Goblin Ears, get +60 XP, +90 gold
- Player.gd auto-tracks fetch progress on every inventory change (signal hookup)
- Quest panel UI handles both kill and fetch progress (`5/4`, `3/6`, etc.)
- Turn-in routes by NPC name match against quest.giver (so Maeve only takes her own quest)
- Updated NPC dialogue lines for Lyra & Mara to advertise their quests

### Procedural Loot + Affix System (Phase 2 item 8 partial)
- New affix engine in `Items.gd`:
  - 7 prefixes (Gleaming, Sharpened, Sturdy, Fierce, Heroic, Mythic, Ancient) — modify damage/armor/HP/crit and bump rarity
  - 6 suffixes (of Frost, Embers, Bear, Swiftness, Dragon, Stars) — add icon overlay tints + side stats
  - `generate_affix_item(base_id, rng)` returns a runtime variant dict like "Gleaming Iron Sword of Frost: +12 dmg, +5% crit"
- Runtime registry: World scene stores affix variants under `@base#slug_stamp` ids; `Items.get_item("@…")` resolves via the registry
- 35% of equipment dropped by enemies now rolls as an affix variant
- New material drops: `wolf_pelt` (wolf), `goblin_ear` (goblin), `crystal_shard`, `warlord_horn`

### Treasure Chests (Phase 2 item 8 partial — NEW)
- New `Chest.gd` (~145 lines) — procedurally-built wooden chest with iron banding, gold lock, lid that animates open with a back-easing tween, omni-light glow that pulses while sealed and bursts on open
- Two loot pools in Items.gd: `chest_common`, `chest_rare` (new)
- `Items.roll_chest_loot(pool, rng, count)` rolls 2-4 items, 55% of equipment becomes affix variant
- 5 chests scattered around Whisperwood + village edge (3 common, 2 rare) wired in `WorldBuilder._build_chests()`
- "Press E to open" billboard hint, `interact_pressed` signal hookup, once-opened stays open

### Other
- `Main.tscn` — updated HelpLabel with new I / Q / M keys
- `World.gd` — added a stub `toggle_mount()` that toggles a 2× speed buff via Player.walk/run_speed; ready for Phase 2 item 6 mount model

### Files touched this session
- `eldoria-godot/scripts/World.gd` (full rewrite — ~640 lines, inventory UI + quest catalog + runtime registry)
- `eldoria-godot/scripts/Player.gd` (fetch quest API, inventory_changed hookup, is_quest_ready_to_turn_in)
- `eldoria-godot/scripts/Inventory.gd` (count_item, has_item, consume_item)
- `eldoria-godot/scripts/Items.gd` (materials + affix system + chest loot pools, ~120 new lines)
- `eldoria-godot/scripts/Enemy.gd` (affix variant rolling on death, registers with World registry)
- `eldoria-godot/scripts/WorldBuilder.gd` (NPC dialogue tweaks for Lyra/Mara, _build_chests with 5 spawn spots)
- `eldoria-godot/scripts/Chest.gd` ✨ NEW (procedural chest mesh + interaction + loot)
- `eldoria-godot/scenes/Main.tscn` (help text update)

### Status
✅ Ready to deploy with `bash full-deploy.sh`. Click-to-equip semantics chosen over drag-and-drop because it's friendlier for 9-year-old Alden — drag/drop can be a future refinement.

### Next run should pick up
1. **Audio engine** — wire up `_check_zone_music` + `play_sfx` (function stubs already exist in World.gd). Source CC0 audio from PolyHaven/AmbientCG into `assets/audio/{music,sfx}/`. Trigger SFX on attack/hit/loot/level-up.
2. **Mounts** — instantiate `Horse.glb` model on toggle_mount, attach as a child of Player, hide Soldier model, animate. Currently we only buff speed.
3. **Goblin Warlord boss** (Phase 2 item 5) — telegraphed AoE slam with red ground decal, charge, phase-2 minion summons. Drops `warlord_horn` (already in loot table).
4. **Crystal Caves dungeon** (Phase 2 item 4) — multi-level instanced zone with crystals + boss arena.
5. **Companion pets** (Phase 2 item 7) — Fox.glb follower AI.

---

## 2026-05-04 — Banner overhaul + Godot AAA visuals + combat scaffold

### Watchlist banner (top of family-watchlist.html)
- Replaced Canva-chromed banner with full-bleed inline SVG hero
- Cinzel Decorative + UnifrakturMaguntia fantasy fonts (Google Fonts @import)
- Painted sunset/dragon/knight/castle/forest, no purple
- Whole banner is `<a href="./eldoria/index.html">` — click anywhere → Godot game
- Glowing "⚔️ Enter the Realm" CTA in corner with hover bounce

### Godot world (eldoria-godot/)
- 19 PolyHaven CC0 PBR textures sourced into `assets/textures/{grass,wood,stone,thatch,bark,rock,snow}/` (12 MB)
- WorldBuilder.gd rewritten (1038 lines, 35 functions) with PBR materials, UV-tiled textures, _pbr_mat() cache
- Houses: stone foundation + wood plank walls + dark timber framing + shingled pyramid roofs + lit windows + chimneys
- Trees: bark-textured trunks + multi-tier rim-lit foliage with gentle wind sway
- Mountains: rock-face textures + snow caps (snow PBR), inner ring (36) + outer ring (28)
- Cobble path network between buildings
- New props: stone well, pond + reflective water + reeds, animated windmill with cloth sails, banner flags, **campfire with fire+smoke particles & flickering omni light**, fireflies (GPUParticles3D)
- Chimney smoke from each house
- 8 lanterns with flickering warm omni lights
- 7 NPCs spawn from WorldBuilder (removed duplicate hardcoded ones from Main.tscn)

### Main.tscn environment
- Sunset procedural sky (deep navy top, blazing orange horizon)
- Sun re-angled for golden-hour shadows, 4-cascade shadow mapping, energy 1.8
- MoonFill cool-blue rim DirectionalLight
- Volumetric fog tinted orange, density 0.006, height fog enabled
- ACES tonemap (mode 3), exposure 1.15, glow + bloom, SSAO 2.5, SSR enabled, color grading

### Combat (now LIVE)
- New `scripts/Enemy.gd` (293 lines) — CharacterBody3D enemy with idle-wander → chase → attack states, capsule collider, Area3D hit zone, billboard HP bar that hides at full HP, name label, attack cooldown, melee damage on player, knockback on hit, XP+gold drop on death, respawn after 35s
- New `scripts/DamageNumber.gd` — Label3D popup that drifts up + bobs + scale-punches + fades
- `scripts/Player.gd` rewritten — left-click melee attack with 110° forward arc, 2.6m range, 14+lvl base damage with 12% crit chance & 2x crit multiplier, level scaling, armor reduction (currently flat 15%), `take_damage`/`_die`/`_respawn_at_well` loop, `accept_quest`/`complete_quest_if_done` quest API, `on_enemy_killed` group hook, level-up popup
- `scripts/WorldBuilder.gd` — added `_build_enemies()` spawning **3 goblin camps** in the Whisperwood (each with 4 Goblin Scouts + 1 Goblin Brute around a glowing campfire) plus **4 Dire Wolves** wandering between them. 17 enemies total.
- `scripts/World.gd` rewritten — quest UI panel (top-right), gold label, death overlay (red tint + "You have fallen" message), dynamic Accept Quest / Turn In Quest buttons in dialogue panel, toast helper for quest completion, day/night cycle sped up to 6-min full cycle
- `scenes/Main.tscn` — added GoldLabel, QuestPanel + QuestTitle + QuestLabel, DeathOverlay + DeathLabel
- Maeve's "Whisperwood Cleansing" quest: slay 5 goblins → return to Maeve → +60 gold +80 XP

### Files touched this session
- `family-watchlist.html` (hero banner block)
- `eldoria-godot/scripts/WorldBuilder.gd` (full rewrite + enemies)
- `eldoria-godot/scripts/Player.gd` (combat + quest API)
- `eldoria-godot/scripts/Enemy.gd` ✨ NEW
- `eldoria-godot/scripts/DamageNumber.gd` ✨ NEW
- `eldoria-godot/scripts/World.gd` (quest UI + death overlay)
- `eldoria-godot/scenes/Main.tscn` (sunset env + UI panels)
- `eldoria-godot/assets/textures/**` (19 new PolyHaven CC0 files)

### Files touched
- `family-watchlist.html` (hero banner block)
- `eldoria-godot/scripts/WorldBuilder.gd` (full rewrite)
- `eldoria-godot/scenes/Main.tscn` (sunset env + sun + removed duplicate NPCs)
- `eldoria-godot/assets/textures/**` (19 new files)
- `deploy.sh` (copies eldoria-banner.png — banner now inline so this is harmless)

### Status
✅ Ready to deploy with `bash full-deploy.sh`

### Next run should pick up
1. Combat system — Enemy.gd Goblin/Wolf, player attack, damage numbers, death + XP
2. Quest system wired through Maeve
3. Inventory/equipment slots with visible gear swap on Soldier
4. Audio — CC0 ambient music + SFX

---

## 2026-05-04 — Auto run: Bootstrap world-engine ledgers

### What
Created the 5 architectural artifacts that replace the old "CHANGES.md alone"
governance model:
- `DESIGN_PHILOSOPHY.md` — operational distillation of the 6 rules
- `WORLD_STATE.md` — canon, NPC memory, faction state, player impact, hooks
- `SYSTEM_REGISTRY.md` — verbs, item schema, stat schema, drop tables, reserved schemas
- `QUEST_GRAMMAR.md` — single unified quest data model (current shipped + reserved)
- `PLAYER_MODEL.md` — Alden, Owen, co-op constraints, difficulty signals, open questions

### Why
Per DESIGN_PHILOSOPHY Rule 3, every run now reads these 5 files before
planning, and updates them as part of every commit. This is the pivot from
"ship features faster" to "compound the world engine."

### Files changed
- `DESIGN_PHILOSOPHY.md` ✨ NEW
- `WORLD_STATE.md` ✨ NEW
- `SYSTEM_REGISTRY.md` ✨ NEW
- `QUEST_GRAMMAR.md` ✨ NEW
- `PLAYER_MODEL.md` ✨ NEW
- `CHANGES.md` (this entry)

### Phase reached
Historian — bootstrap complete. No backlog feature shipped this run by design;
Rule 3 says ledgers must exist before any feature work compounds.

### Future hooks seeded
- `WORLD_STATE.md → Active Hooks` lists 5 concrete next-run anchors (Crystal
  Caves placement, reactive dialogue, faction scalar, housing plot, drop
  table reuse).
- `QUEST_GRAMMAR.md → Migration Notes` specifies the next quest-system
  refactor: a `consequence` resolver in World.gd. One change unlocks NPC
  memory, faction shifts, and reactive dialogue from a single entry point.
- `PLAYER_MODEL.md → Difficulty Signals` specifies the first telemetry
  primitive (`World.player_pressure_signal()`) and which knob to tune first
  (telegraph timing).

### Next run should pick up
Plan: read all 5 ledgers, then pick ONE of:
1. Reactive dialogue scaffold — adds `npc.lines` map keyed on world flags +
   3 example follow-up lines for Maeve, Lyra, Mara. Touches: WorldBuilder
   NPCS, NPC.gd, World.gd flag store. Compounds 7 NPCs × first quest events.
2. Consequence resolver — implements `consequence` in QUEST_GRAMMAR; backfill
   the 3 existing quests with `motivation`/`location`/`urgency` fields.
   Compounds: enables every future quest to mutate world state on completion.
3. Bandit pressure scalar — adds `World.factions["whisperwood_goblins"]
   .pressure: float` with decay/recovery + a single observable consequence
   (campfire visibility / patrol density). Compounds: enemy spawning, NPC
   dialogue, and adaptive difficulty all read this scalar.

Recommendation: option (2). It's the smallest change with the highest
downstream multiplier.

---

## 2026-05-04 — Auto run: Consequence resolver (run 2)

### What
Implemented the consequence resolver per QUEST_GRAMMAR.md migration notes.
Quests now mutate persistent world state on turn-in: faction pressure scalars,
world flags, NPC memory flags, and a player-facing toast — all from a single
`World.apply_consequence(Dictionary)` entry point. Backfilled the 3 existing
quests with the full grammar (`actor`, `motivation`, `location`, `urgency`,
`world_trigger`, `consequence`).

### Why (Rule 1 — compounds, doesn't sprawl)
This adds exactly ONE new primitive (the consequence resolver) and integrates
with at least three existing systems:
1. **Quest grammar** — `complete_quest_if_done()` → `apply_consequence()` is
   now a closed loop. Every quest is now a *world event*, not just a reward
   grant.
2. **Faction state** — promoted from doc-only proposal to live runtime data.
   Cleansing & ear-bounty quests reduce `whisperwood_goblins.pressure`; pelt
   quest reduces `dire_wolves.pressure`.
3. **NPC schema** — `npc_flags[npc] -> Array[String]` is now real data with
   read accessor (`npc_has_flag`). Reactive dialogue can branch on this.

### Files changed
- `eldoria-godot/scripts/World.gd` — runtime state vars (factions, world_flags,
  npc_flags), `apply_consequence()`, three read accessors, QUEST_CATALOG
  backfill, `_on_turn_in_quest` wiring.
- `QUEST_GRAMMAR.md` — Migration Notes flipped from "future work" to "shipped".
- `WORLD_STATE.md` — Faction State + NPC Memory tables now reflect live data;
  new "World Flags (Active)" section; Active Hooks updated.
- `SYSTEM_REGISTRY.md` — Faction Schema flipped to shipped; new "Consequence
  Schema" + "World Flag Conventions" sections.
- `PLAYER_MODEL.md` — Difficulty Signals notes the faction-pressure feedback
  loop and how it composes with `player_pressure_signal()`.
- `CHANGES.md` — this entry.

### Rule-2 outputs delivered
- (i)   World state: `World.factions`, `World.world_flags`, `World.npc_flags`
        — three persistent stores added and populated by quest completions.
- (ii)  Queryable schema: `faction_pressure(id)`, `has_world_flag(name)`,
        `npc_has_flag(npc, flag)` — documented in SYSTEM_REGISTRY.md.
- (iii) Player-facing feedback: per-quest toast strings (e.g. "🌿 The
        Whisperwood feels a little safer.") fire after the reward toast.
- (iv)  Evaluation: parens/quotes balance check passes; explicit type
        annotations on every Variant-derived `var`; runtime guard
        `if consequence.is_empty(): return`; clamp on pressure values.
- (v)   Future hooks (≥ 2):
        1. NPC.gd reactive dialogue can now branch on `npc_has_flag(...)`
           — Maeve, Lyra, Mara already have flags ready to consume.
        2. Goblin spawner can read `faction_pressure("whisperwood_goblins")`
           to scale patrol density without any further plumbing.
        3. Smith Edda forge UI can gate enchant tier on `world_flags`.

### Phase reached
Historian — feature shipped, all 5 ledgers updated, ready to commit.

### Next run should pick up
Recommendation: **Reactive dialogue** — wire NPC.gd to read
`World.npc_has_flag(npc_name, flag)` and pick a different greeting/quest
prompt when the flag is set. Three NPCs × 2 states = 6 unique conversational
moments unlocked from one wiring change. This compounds *immediately* off
this run.

Adjacent option: spawn density tied to `faction_pressure` — a single line in
the goblin spawner that reduces pack size as pressure decays. Lower payoff
than dialogue but lower risk.



## 2026-05-04 — Auto run: Reactive dialogue follow-up — world-flag tier (run 3 follow-up)

### Context
The integrator commit (`8380282 — Integrate: pattern A`) shipped the NPC-flag
warmed dialogue layer ahead of this run, using a `warmed_flag: String` /
`warmed_dialogue_variants: PackedStringArray` schema. This run was about to
land a parallel Dictionary-based version of the same feature. Per Rule 1
("compound, don't sprawl") I dropped that commit completely and instead
layered ONE genuinely new tier on top of pattern A's schema.

### What
Added a SECOND warmed tier to NPC.gd, keyed on a *world* flag rather than an
NPC flag. It uses pattern A's exact array shape — singular `warmed_world_flag:
String` and `warmed_world_dialogue_variants: PackedStringArray` — so the two
tiers compose naturally instead of competing. Lookup precedence in
`_on_interact()`:
  1. NPC-flag warmed line (integrator) — "you helped *me* personally"
  2. World-flag warmed line (this run)  — "you helped the world / our cause"
  3. Time-of-day variant (run 2 polish) — ambient personality
  4. Single fallback `dialogue` line

Lyra picks up 4 new lines on the new tier, gated by `lyra_potion_brew` (a
world flag set by `pelt_for_lyra`'s `consequence`). Result: even before a
specific player has personally pelted, if any prior save unlocked the recipe
for the village, Lyra's lines reflect it.

### Why (Rule 1 — compounds, doesn't sprawl)
ONE new primitive (world-flag-keyed warmed lines) wired into TWO existing
systems:
1. **Integrator's warmed dialogue** (just-shipped) — same export shape
   (`String` flag name + 4-bucket `PackedStringArray`), same time-of-day
   bucket math, same `_make_npc()` plumbing pattern.
2. **`World.world_flags` store** (run 2) — a map that has been written by
   3 quests but had ZERO consumers until this run. Pattern A reads
   `npc_flags`; this tier reads `world_flags`. Together they consume both
   stores the consequence resolver writes.

This satisfies Rule 5 (endlessness from memory + reaction, not new tiles):
the world now contains a fact ("the salve recipe is loose") that surfaces
through dialogue independently of any individual player's history.

### Files changed
- `eldoria-godot/scripts/NPC.gd` — added `warmed_world_flag` /
  `warmed_world_dialogue_variants` exports; in `_on_interact()`, inserted
  the world-flag check between the NPC-flag check and the variant render,
  guarded by `variants == dialogue_variants` so tier 1 always wins when both
  fire. Runtime guards on `has_method("has_world_flag")` keep older saves /
  older `World` autoloads from crashing.
- `eldoria-godot/scripts/WorldBuilder.gd` — Lyra's `NPCS` entry gains
  `warm_world_flag` + 4 `warm_world_lines`. `_make_npc()` copies the new
  fields onto the NPC node (mirrors the integrator's existing two lines).
- `WORLD_STATE.md` — NPC Memory table now shows Lyra's two reactive layers;
  Active Hooks reset (faction-pressure dialogue is now top-priority).
- `SYSTEM_REGISTRY.md` — NPC Schema rewritten to document the full 4-tier
  precedence (was still marked "Reserved for reactive dialogue" before).
- `PLAYER_MODEL.md` — polish note: world-flag tier serves Alden by making
  the village feel like it remembers events even on first-time interactions.
- `CHANGES.md` — this entry.

### Rule-2 outputs delivered
- (i)   World state: no new writes; new READ of `world_flags` finally
        consumes a store that has been writable since run 2 with no readers.
        WORLD_STATE.md updated to reflect the new consumer.
- (ii)  Queryable schema: `NPC.warmed_world_flag: String` +
        `NPC.warmed_world_dialogue_variants: PackedStringArray` —
        documented in SYSTEM_REGISTRY.md "NPC Schema" alongside pattern A's
        fields, with full 4-tier precedence rules.
- (iii) Player-facing feedback: 4 new dialogue strings (Lyra × 4 buckets)
        surfaced through the existing `World.show_dialogue` panel; total
        warmed strings in production = 16 (integrator's 12 + this run's 4).
- (iv)  Evaluation: parens/quotes balance check passes for both touched
        files; runtime `has_method("has_world_flag")` guard so an older
        World autoload still falls through cleanly to tier 3; the
        `variants == dialogue_variants` short-circuit guarantees tier 1 is
        never demoted by tier 2.
- (v)   Future hooks (≥ 2):
        1. Faction-pressure dialogue: NPC.gd already has the World node
           reference and the tier-stacking pattern. A new tier between
           "world-flag warm" and "time-of-day variant" reading
           `World.faction_pressure(...)` would close the consequence loop
           — factions become *spoken* by NPCs, not just data.
        2. Smith Edda forge UI (backlog #4) can now branch its enchant menu
           greeting on a future `edda_forge_open` world flag using the same
           `warm_world_flag` field. No NPC.gd changes needed.
        3. The 4 still-neutral NPCs (Edda, Bram, Roan, Hala) get reactive
           dialogue automatically the moment they get quests — schema is
           in place, code path is exercised, only WorldBuilder edits left.

### Phase reached
Historian — feature shipped, all 5 ledgers updated, ready to commit.

### Next run should pick up
**Faction-pressure dialogue** — see WORLD_STATE.md top-priority hook. The
runway is shorter than ever: NPC.gd already touches the World node, already
walks tiers, already short-circuits. One read of `World.faction_pressure()`,
one new tier slot, and the consequence resolver loop is fully closed.

Adjacent option: faction pressure → spawn density. Lower payoff than
dialogue (player feels it less directly than a line of speech) but lower
risk and would close the same unread-output gap.

## 2026-05-04 (run 4) — Faction-pressure dialogue tier (closes the consequence-resolver loop)

### What
Added a THIRD warmed dialogue tier in `NPC.gd`, slotted between the world-flag
warm tier (run-3 follow-up) and the time-of-day variants. NPCs can now react
to the *shape* of the world by reading `World.faction_pressure(id)` directly —
no flag intermediary required. Maeve picks up 4 new lines on the new tier,
gated by `whisperwood_goblins` pressure dropping below 0.9.

### Why (Rule 1 — compounds, doesn't sprawl)
ONE new primitive (faction-pressure threshold check) wired into THREE existing
systems:
1. **NPC.gd's tier walker** — same `variants == dialogue_variants` short-circuit
   pattern that runs 3 and 3-follow-up established. Pure extension, zero
   re-architecture.
2. **`World.faction_pressure(id)` accessor** — declared in run 2, written by 3
   quests, READ BY NOTHING UNTIL NOW. This run gives it its first reader.
3. **`WorldBuilder._make_npc()` plumbing** — same `data.get("warm_*", default)`
   copy pattern, same shape onto the NPC node.

This satisfies Rule 5 (endlessness from memory + reaction): the world contains
a fact ("the Whisperwood is forgetting the goblins") that surfaces through
dialogue without any per-NPC bookkeeping. Faction pressure was a write-only
store for two runs; now it speaks.

### Authoring lesson learned during VERIFY phase
First seed targeted Maeve with threshold 0.7. Caught during verification: the
faction tier only fires when warm_flag is NOT set, but cleansing (the quest
that sets Maeve's `first_quest_done` flag) is also the quest that reduces
goblin pressure by -0.2. With cleansing done, tier-1 wins; without cleansing,
the only goblin reducer is `ears_for_mara` (-0.15) bringing pressure to 0.85,
which never crosses 0.7. Threshold raised to 0.9, and the tier now fires on
the "ears-before-cleansing" path — a real emergent moment where Maeve notices
goblin retreat caused by Mara's bounty before the player has spoken to Maeve
about her own quest. This authoring trap (faction reduction and warm_flag
issuance bound to the same quest) is documented in SYSTEM_REGISTRY.md so
future runs avoid it.

### Files changed
- `eldoria-godot/scripts/NPC.gd` — added `warmed_faction_id: String`,
  `warmed_faction_below: float`, `warmed_faction_dialogue_variants:
  PackedStringArray` exports; in `_on_interact()`, inserted the faction-tier
  check between the world-flag block and the time-of-day variant render,
  guarded by `variants == dialogue_variants` so tiers 1 and 2 always win when
  they fire. Runtime guard on `has_method("faction_pressure")` keeps older
  saves / older `World` autoloads from crashing.
- `eldoria-godot/scripts/WorldBuilder.gd` — Maeve's `NPCS` entry gains
  `warm_faction_id`, `warm_faction_below`, and 4 `warm_faction_lines`.
  `_make_npc()` copies the new fields onto the NPC node (mirrors the
  integrator's pattern-A and the run-3 world-flag plumbing).
- `WORLD_STATE.md` — Faction State table now shows the consumer; Active Hooks
  promotes goblin spawn density (now the next adjacent compound).
- `SYSTEM_REGISTRY.md` — NPC Schema rewritten to document the full 4-tier
  precedence (added Tier 3: faction-pressure). Added an "Authoring traps"
  callout warning against pairing a faction reducer with the same quest that
  issues the NPC's warm_flag.
- `PLAYER_MODEL.md` — polish note: faction tier serves Alden by making the
  village respond to the *aggregate* of his work, not just the individual
  quests he completed; serves Owen by giving the consequence ladder one more
  visible rung to climb.
- `CHANGES.md` — this entry.

### Rule-2 outputs delivered
- (i)   World state: no new writes; new READ of `factions[id].pressure` finally
        consumes a store written by 3 quests since run 2 with no readers.
        WORLD_STATE.md updated to reflect the new consumer.
- (ii)  Queryable schema: `NPC.warmed_faction_id: String`,
        `NPC.warmed_faction_below: float`,
        `NPC.warmed_faction_dialogue_variants: PackedStringArray` —
        documented in SYSTEM_REGISTRY.md "NPC Schema" alongside tiers 1+2,
        with full 4-tier precedence rules and the authoring-traps callout.
- (iii) Player-facing feedback: 4 new dialogue strings (Maeve × 4 buckets)
        surfaced through the existing `World.show_dialogue` panel; total
        warmed strings in production = 20 (16 prior + this run's 4).
- (iv)  Evaluation: parens/quotes balance check passes for both touched
        files; runtime `has_method("faction_pressure")` guard so an older
        World autoload still falls through cleanly to tier 4; the
        `variants == dialogue_variants` short-circuit guarantees tiers 1 + 2
        are never demoted by tier 3; explicit type annotation
        `var fp: float = float(...)` keeps Godot 4.6 strict mode happy.
- (v)   Future hooks (≥ 2):
        1. **Goblin spawn density** — the most direct compound: enemy spawns
           in Whisperwood camps could read `World.faction_pressure("whisperwood
           _goblins")` and scale count / respawn-time. Single read, big
           behavior delta. Now top-priority hook in WORLD_STATE.md.
        2. Roan (Stablemaster) → `dire_wolves` faction tier — schema is in
           place, only WorldBuilder edits needed. Wolves spook horses;
           pressure < 0.5 (after one pelt quest) and Roan speaks.
        3. The 4 still-faction-quiet NPCs (Edda, Bram, Roan, Hala) get
           reactive dialogue automatically the moment they get faction lines
           — no NPC.gd or WorldBuilder structural changes required.
        4. Difficulty knob (PLAYER_MODEL adaptive proposal): `Enemy.gd
           attack_cooldown` could `lerp(1.45, 1.05, 1.0 - faction_pressure)`
           — calm-faction enemies hit harder/faster, stressed-faction enemies
           recover more — turning the same scalar into both narrative and
           pacing.

### Phase reached
Historian — feature shipped, all 5 ledgers updated, ready to commit.

### Next run should pick up
**Goblin spawn density driven by `faction_pressure("whisperwood_goblins")`.**
This is the matching write→read pair on the spawn side: dialogue speaks the
faction state, spawning *enacts* it. Single read in the goblin spawn loop
(WorldBuilder spawns or World's enemy roster), scale count / respawn-time
inversely with pressure. Every quest the player completes against goblins
will then make the wood quieter to walk through AND Maeve will narrate it.
That's the consequence-resolver loop closed on both ends.

Adjacent option: Roan + dire_wolves dialogue (smallest-possible follow-up,
zero new code paths, only WorldBuilder edits). Lower payoff (one NPC, one
faction) but useful as a smoke-test that the 4-tier system handles the
"NPC with no warm_flag at all" path cleanly.

## 2026-05-04 (run 5) — Goblin spawn density driven by faction pressure

Closes the consequence-resolver loop on the spawning side. Run 4 made the
NPC dialogue tier 3 SPEAK the faction state ("Maeve narrates a calmer wood
when `whisperwood_goblins` pressure drops below 0.9"). Run 5 makes the
spawn system ENACT it: per-camp goblin population now derives from
`World.faction_pressure("whisperwood_goblins")` via a new helper
`_goblin_camp_size(pressure: float) -> Dictionary` in `WorldBuilder.gd`,
returning `{"scouts": int, "brutes": int}`.

At fresh-save pressure 1.0 the population is identical to pre-run-5 (4
scouts + 1 brute per camp, 3 camps = 15 goblins total). At pressure 0.85
(the value `ears_for_mara` alone produces) each camp drops to 3 + 1.
At 0.65 (Mara + Maeve cleansing) each camp drops to 2 + 1. Brute is
suppressed below 0.4. Sole scout below 0.15. The empty camp prop
(campfire + huts) persists at all levels, so a calmed wood reads as
"they used to be here" — a memorial, not a forgotten zone.

`World.faction_pressure()` now has TWO consumers (NPC.gd dialogue tier 3,
WorldBuilder spawn density). The same scalar drives both narrative and
pacing — exactly the compound mandate from Rule 1.

### Files changed
- `eldoria-godot/scripts/WorldBuilder.gd` — `_build_enemies()` reads
  `goblin_pressure` from `get_parent()` (the World node, fail-soft on
  `has_method("faction_pressure")`), derives `scout_count` / `brute_count`
  via `_goblin_camp_size()`, and uses those to drive both the per-camp
  scout loop and the per-camp brute spawn. Adds asserts on the
  count contracts (`[0,4]`, `[0,1]`). Adds a deferred world-build toast
  ("🌿 You sense fewer goblins in the wood.") that fires only when
  `scout_count<4` OR `brute_count<1` — i.e. the wood IS visibly calmer.
  New helper `_goblin_camp_size(pressure: float) -> Dictionary` lives
  directly above `_spawn_enemy()` with documented threshold table.
  Total diff: +55 / -5 lines.
- `WORLD_STATE.md` — top hook (goblin spawn density) marked Resolved;
  promoted wolf spawn density as new top-priority next; faction-state
  table row for Whisperwood Goblins now lists BOTH consumers; player
  impact ledger gains a "goblins spawned per world load" entry.
- `SYSTEM_REGISTRY.md` — new "Goblin Spawn Schema" section between
  Consequence Schema and World Flag Conventions, with threshold table,
  authoring rules, and the runtime-guard pattern. Faction-pressure
  accessor now documented as having TWO consumers.
- `PLAYER_MODEL.md` — polish note: run 5 serves Alden by visually
  quieting the wood as he progresses, and serves Owen by giving him
  a second mastery-rung on the same scalar he climbs through dialogue.
  Adaptive proposal for run 6: same scalar drives Enemy.gd
  attack_cooldown for the THIRD output coupling.
- `CHANGES.md` — this entry.

### Rule-2 outputs delivered
- (i)   World state: no new writes; new READ of `factions[id].pressure`
        adds spawn density as the SECOND consumer of the scalar (run 4
        added dialogue as the first). WORLD_STATE.md updated to surface
        the new consumer in the faction-state table and player-impact
        ledger.
- (ii)  Queryable schema: `_goblin_camp_size(pressure: float) -> Dictionary`
        with `{"scouts": int, "brutes": int}` shape; thresholds
        9 / 7 / 4 / 15 (×0.1) documented in SYSTEM_REGISTRY.md
        "Goblin Spawn Schema" with full table and authoring rules.
- (iii) Player-facing feedback: visible spawn-count delta on every world
        load after a goblin-reducing quest (3 camps × scout drop +
        possibly the brute), PLUS a deferred one-shot toast
        "🌿 You sense fewer goblins in the wood." that fires only when
        the wood actually IS calmer than baseline. Pairs with the
        per-quest `apply_consequence` toasts so the player gets BOTH
        the change-moment announcement AND the persistent-state
        announcement on subsequent loads.
- (iv)  Evaluation: parens/brackets/braces balance check passes
        (991/991, 53/53, 33/33). All 8 new `var` declarations carry
        explicit type annotations (`var goblin_pressure: float`,
        `var world_node: Node`, `var camp_size: Dictionary`, etc.) —
        no walrus on Variant. Two runtime asserts enforce the
        scout_count ∈ [0,4] and brute_count ∈ [0,1] contracts.
        Runtime guard on `has_method("faction_pressure")` keeps an
        older World autoload fail-soft to baseline behavior.
- (v)   Future hooks (≥ 2):
        1. **Wolf spawn density** — identical pattern. Read
           `World.faction_pressure("dire_wolves")`, mirror helper
           `_wolf_pack_size(pressure)`. `pelt_for_lyra` already
           reduces by 0.1 from baseline 0.5, so a single completion
           takes the wood from 4 wolves to 3, and a second from 3 to 2.
           Same compound shape: dialogue tier 3 (Roan, when wired) +
           density. Now top-priority hook in WORLD_STATE.md.
        2. **Adaptive Enemy.gd attack_cooldown** — same goblin
           pressure scalar, THIRD output. `lerp(1.45, 1.05, 1.0 -
           pressure)` so a calmed-wood goblin hits faster (Owen's
           harder fight) while a fresh-save goblin hits slower (Alden's
           recovery valve). Single line edit on `_physics_process` or
           in spawn config; uses a scalar already on World.
        3. **Per-frame faction decay from kills_by_kind** — bypasses
           quest gating so per-kill impact routes back through the
           same channel. Long-term hook: keeps the loop closed even
           when the player is just hunting, not questing.
        4. **Skeleton / bandit enemy kinds (backlog #6)** — once those
           ship, Crystal Caves and a future bandit camp can each
           reuse `_<kind>_pack_size(pressure)`. Schema is documented
           as authoring rule under "Goblin Spawn Schema."

### Phase reached
Historian — feature shipped, all 5 ledgers updated, ready to commit.

### Next run should pick up
**Wolf spawn density driven by `faction_pressure("dire_wolves")`.** Identical
shape to run 5 — single helper `_wolf_pack_size(pressure)` with thresholds
co-firing with a future Roan dialogue tier 3. Lower payoff per-population
than goblins (4 wolves vs 15 goblins) but higher *systems* payoff: it
proves the run-5 pattern generalizes and unblocks the same compound for
every other faction. After wolves, the next compound is the THIRD output
on the same scalar — Enemy.gd `attack_cooldown` lerped on faction pressure,
making one number drive narrative + density + pacing.


## 2026-05-04 (run 6) — Wolf spawn density driven by `faction_pressure("dire_wolves")`

### Plan
- 5 ledgers consulted. Top-priority hook from WORLD_STATE was wolf spawn
  density, mirror of the run-5 goblin pattern. Single read, single helper,
  proves the run-5 PATTERN generalizes to a second faction.
- Rule 1 (compound, don't sprawl): no new primitive — recombines existing
  primitives (faction pressure scalar × spawn count). Adds the SECOND
  consumer of the `dire_wolves` faction key after pelt_for_lyra wrote it.
- Rule 5 (endless ≠ infinite map): the wood feels different on EVERY save
  reload after one quest, without any new geometry, biomes, or maps.

### Build
- `eldoria-godot/scripts/WorldBuilder.gd` (+33 / -3):
  - `_build_enemies()`: replaces the hard-coded 4-element wolf loop with a
    `faction_pressure("dire_wolves")` read + `_wolf_pack_size(pressure)`
    derivation + assert + bounded loop. Same fail-soft contract as goblins.
  - `_wolf_pack_size(pressure: float) -> Dictionary` helper inserted
    directly under `_goblin_camp_size`, with documented threshold table.
  - One-shot ambient toast `🐺 The wolf packs feel thinner.` at world
    build when `wolf_count < 4`. Distinct from the goblin toast so the
    kids can read WHICH faction shrank.
- `WORLD_STATE.md`: top-priority hook (wolf spawn density) marked Resolved;
  promoted "third output on goblin scalar" (adaptive Enemy.gd cooldown) as
  the new top-priority. Faction-state table row for Dire Wolves now lists
  density as a consumer. Adjacent-next note for Roan dialogue updated to
  reflect that spawn density already speaks the state; dialogue would be
  the third leg, not the second.
- `SYSTEM_REGISTRY.md`: new "Wolf Spawn Schema" section between Goblin
  Spawn Schema and World Flag Conventions, with threshold table, authoring
  rules (positional stability!), and the runtime-guard pattern.
- `PLAYER_MODEL.md`: addendum noting run-6 dual-axis quieting (goblins +
  wolves) for Alden, and the proof-of-pattern-generalization for Owen's
  mastery-rung budget. Run-7 adaptive proposal: same goblin scalar drives
  a THIRD output (Enemy.gd attack_cooldown).
- `CHANGES.md`: this entry.

### Rule-2 outputs delivered
- (i)   World state: no new writes; new READ of `factions["dire_wolves"].pressure`
        adds spawn density as the SECOND consumer of that key. WORLD_STATE.md
        updated with the consumer in the faction-state table and player-impact
        ledger ("Wolves spawned per world load").
- (ii)  Queryable schema: `_wolf_pack_size(pressure: float) -> Dictionary`
        with `{"count": int}` shape; thresholds 0.5 / 0.3 / 0.15 documented
        in SYSTEM_REGISTRY.md "Wolf Spawn Schema" with full table and
        authoring rules. Mirror-shape of `_goblin_camp_size` so callers
        learn one helper pattern per faction.
- (iii) Player-facing feedback: visible wolf-count delta on every world
        load after a wolf-reducing quest (4 → 3 from pelt_for_lyra alone),
        PLUS a deferred one-shot toast "🐺 The wolf packs feel thinner."
        that fires only when wolves are below baseline. Pairs with
        `apply_consequence` per-quest toasts (announces *change-moment*)
        and the run-5 goblin toast (announces *persistent state*).
- (iv)  Evaluation: parens/brackets/braces balance check passes
        (1014/1014, 55/55, 34/34). All new `var` declarations carry
        explicit type annotations (`var wolf_pressure: float`,
        `var pack_size: Dictionary`, `var wolf_count: int`,
        `var wolf_spots: Array`, `var w: Vector3`, `var p: float`,
        `var count: int`). One runtime assert enforces `wolf_count ∈ [0,4]`.
        Same fail-soft guard `world_node.has_method("faction_pressure")`
        as the goblin path.
- (v)   Future hooks (≥ 2):
        1. **Adaptive `Enemy.gd.attack_cooldown`** — third output on the
           goblin scalar. `lerp(1.45, 1.05, 1.0 - pressure)`. Single line
           edit. Single scalar then drives dialogue + density + pacing.
           Now top-priority hook in WORLD_STATE.md.
        2. **Roan dialogue tier 3 on `dire_wolves`** — completes the
           three-output compound for the wolf faction (dialogue + density
           + future pacing). Schema is in place; only WorldBuilder edits
           to NPCS dictionary required.
        3. **Roan-issued wolf-bounty quest (-0.1 reducer)** — second
           reducer for `dire_wolves` taking pressure 0.4 → 0.3 (next
           threshold trip, 3 → 2 wolves). Mirrors the way `ears_for_mara`
           is a second reducer for goblins after `whisperwood_cleansing`.
        4. **`_<kind>_pack_size` for skeleton + bandit** — once those
           ship, Crystal Caves and a future bandit camp each reuse the
           pattern. Authoring rule documented under "Wolf Spawn Schema."

### Phase reached
Historian — feature shipped, all 5 ledgers updated, ready to commit.

### Next run should pick up
**Adaptive `Enemy.gd.attack_cooldown` driven by `faction_pressure`.** Same
goblin scalar that already drives dialogue tier 3 (run 4) + spawn density
(run 5). Third output on a single scalar = mastery threshold for the
"compound, don't sprawl" rule. Keep the lerp tight (1.45 → 1.05) so a
fresh-save goblin still telegraphs at child-readable speed. After that,
Roan's `dire_wolves` faction-tier dialogue (4 lines, mirrors Maeve) +
a Roan-issued -0.1 wolf-bounty quest, both of which compose with run-6.
---

### Art run — sky HDRI swap (2026-05-04)

#### What
Replaced `ProceduralSkyMaterial` in `eldoria-godot/scenes/Main.tscn` with
`PanoramaSkyMaterial` referencing the existing
`assets/skies/eldoria_sunset_sky_2k.jpg` (PolyHaven CC0, "The Sky Is On Fire"
by Greg Zaal — 2048×1024 equirectangular sunset panorama). `radiance_size`
bumped to 4 (512×512) for richer ambient reflections.

#### Why
`ATTRIBUTION.md` flagged the panorama as ready-to-wire, but no scene was
actually using it — `WorldEnvironment.environment.sky` was still procedural,
which produces flat, gradient-only skies. THEME §3 calls for a warm sunset
palette as the dominant 70% of frame; a hand-painted HDRI delivers that for
free, plus the `ambient_light_source = AMBIENT_SOURCE_SKY` already configured
in the Environment now picks up the panorama's warm orange/crimson IBL,
washing the whole scene in canon palette without any per-light tuning.

#### Theme compliance
- §3 palette: panorama is dominantly burnt-orange / sunset-gold / crimson — exact §3 primaries.
- §1 painterly: HDRI is a hand-photographed real sunset, but at 2k panorama scale and through Godot's tonemap (mode 3 / Filmic, exposure 0.85) it reads as painterly, not photoreal.
- §10.8 license: PolyHaven CC0, no attribution required (we credit anyway in `assets/skies/ATTRIBUTION.md`).

#### Files
- `eldoria-godot/scenes/Main.tscn` — swapped 2 sub_resources, added 1 ext_resource, bumped `load_steps` 15→16.

#### Branch
`auto/art` (push discipline §14).

---

### Integrator run — 2026-05-04 (merge batch)

Merged 5 worker branches into `main`:
- `auto/builder` (1 commit)  → Roan dire_wolves faction-tier dialogue (run 8)
- `auto/polisher` (1 commit) → Enemy.chase_speed lerp on faction_pressure (run 8 output #4) — **resolved WORLD_STATE.md conflict by keeping BOTH run-8 narratives** (Roan dialogue + adaptive chase). Both legitimately landed in the same run from different agents; faction table rows merged row-by-row to keep every `(run-N)` annotation.
- `auto/art` (2 commits) → sky HDRI swap + Items.gd `icon_path` fields
- `auto/lore` (1 commit) → Elder Maeve dialogue JSON + lore .md
- `auto/qa` (1 commit) → split-pck.py for >100MB index.pck — **resolved build-eldoria.yml conflict by keeping BOTH** the qa "Split index.pck" step AND main's existing rebase-retry commit step name. Both improvements compose; qa's split runs before main's commit.

Branches not present this run: `auto/character`, `auto/environment`, `auto/audio` (no work landed).

[INTEGRATOR-GAP] **Lore dialogue JSONs are NOT loaded by NPC.gd.** `eldoria-godot/data/dialogue/elder_maeve.json` and `smith_edda.json` shipped from `auto/lore` with mood-keyed trees (default/morning/midday/evening/night/after_first_quest_complete/low_health_player/boss_alive/boss_slain/high_renown/stranger/longnight_vigil/honeysong_eve/spring_first_warm_day) plus voice_rules and consequence_hooks metadata. NPC.gd reads `dialogue_variants` / `warmed_dialogue_variants` / `warmed_world_dialogue_variants` / `warmed_faction_dialogue_variants` exported PackedStringArrays populated by WorldBuilder — there is no JSON loader. The JSONs even self-describe as "for the Builder/Polisher's NPC.gd reader" but no reader exists. Next builder/lore run should add a JSON-driven dialogue path in NPC.gd (or have WorldBuilder ingest the JSONs at startup) so these files become live. Until then, the .json + .md content is canon-only — informational, not in-game.

[INTEGRATOR-GAP] **Items.gd `icon_path` fields are not consumed yet.** The art branch added `icon_path` to every entry in `ITEMS = {...}` pointing to real PNGs in `assets/icons/` — files exist on disk. But no UI code reads either `icon` or `icon_path` keys (grep across `scripts/` is empty). Inventory rendering still uses whatever path it had before. Forward-looking — when an inventory UI lands, the data is already there to wire.

Next run TODO:
1. Builder or Lore: add JSON dialogue loader in NPC.gd (or WorldBuilder.NPCS ingest at `_ready`). Without it, lore-keeper output sits dormant.
2. Builder: surface `icon_path` in inventory UI (Inventory.gd has no icon read path today).
3. Builder per existing top-priority hook: Roan-issued wolf-bounty quest (-0.1 dire_wolves reducer), now that Roan's faction-tier dialogue is live and the bounty has compounding effects (dialogue stays warm, second wolf-spawn threshold trips, adaptive cooldown drops another step).

## 2026-05-04 (run 8) — Roan (Stablemaster) `dire_wolves` faction-tier dialogue

### Plan
- 5 ledgers consulted. Top-priority hook from WORLD_STATE was the Roan
  faction tier — it had been queued as the natural next step after runs
  6 + 7 wired wolf spawn density and adaptive cooldown to the same
  `dire_wolves` scalar. Roan's lines complete the FOURTH leg of that
  compound (dialogue + density + cooldown + visual ⚡ marker).
- Rule 1 (compound, don't sprawl): no new primitive, no new schema, no
  new tier. Reuses the run-4 `warm_faction_id` / `warm_faction_below` /
  `warm_faction_lines` schema verbatim. Adds Roan as the SECOND author
  of the schema after Maeve, and the FIRST author whose ONLY warm tier
  is the faction read (Maeve also carries `warm_flag:first_quest_done`).
- Rule 2 (5 outputs): see explicit checklist below.
- Rule 5 (endless ≠ infinite map): Briarwood feels different on a save
  reload after `pelt_for_lyra` ships — Roan now narrates the change at
  every time-of-day bucket, no new geometry.

### Build
- `eldoria-godot/scripts/WorldBuilder.gd` (+24 / 0):
  - NPCS Roan dict gains `warm_faction_id`, `warm_faction_below`, and a
    4-line `warm_faction_lines` array (morning / midday / evening / night),
    inserted directly under his existing `lines` array. Threshold 0.5
    matches the run-6 wolf-spawn first-trip threshold so dialogue and
    density flip together on the same -0.1 quest.
  - 12-line block comment above the new fields documents the smoke-test
    intent (no `warm_flag` → only warm tier is the faction read), the
    threshold rationale, and the four-leg compound it completes.
- `WORLD_STATE.md`:
  - Top-priority Roan-dialogue hook marked Resolved (run 8).
  - Promoted Roan-issued wolf-bounty quest to new top-priority. New
    adjacent-next: Bram or Hala faction-tier as the second proof of the
    no-`warm_flag` pattern.
  - NPC Memory table: Roan row flips from "neutral / ❌ no quest" to
    "warms when wolves thin / ✅ 4 (faction, run 8)" with the
    `dire_wolves < 0.5` flag-consumed call-out.
  - Faction State table: Dire Wolves row appends "Roan speaks at <0.5
    (run-8 dialogue tier 3)" alongside the existing density + cooldown
    annotations.
- `CHANGES.md`: this entry.

### Rule-2 outputs delivered
- (i)   World state: no new writes; new READ of `World.faction_pressure(
        "dire_wolves")` from NPC.gd's existing tier-3 path. The scalar
        had two readers entering the run (wolf spawn density, attack
        cooldown); it now has THREE (Roan dialogue), and the 4-tier
        dialogue stack now has TWO faction authors instead of one.
- (ii)  Queryable schema: no new schema. Proves the run-4
        `warm_faction_*` schema reuses cleanly across NPCs without a
        `warm_flag`. Authoring template captured in the in-file block
        comment above the new fields.
- (iii) Player-facing feedback: 4 new dialogue lines fire when the player
        approaches Roan after `pelt_for_lyra` has dropped `dire_wolves`
        below 0.5. Each of the 4 time-of-day buckets has its own line so
        the change is visible at any hour the player chooses to talk.
        Composes with run-6's "thinner wolves" toast (announces *moment*)
        and run-7's per-enemy ⚡ prefix (announces *pacing change*).
- (iv)  Evaluation: parens / brackets / braces balance check passes
        (1079/1079, 56/56, 36/36 in WorldBuilder.gd). New dictionary
        keys all use the existing `.get(..., default)` loader path, so
        every other NPC continues to load with empty defaults. No new
        `var` declarations introduced (pure dict-literal data).
- (v)   Future hooks (≥ 2):
        1. **Roan-issued wolf-bounty quest (-0.1 reducer for `dire_wolves`)**
           — now the canonical NPC↔quest pairing because Roan's dialogue
           already speaks the state. Trips the second wolf-spawn threshold
           (0.4 → 0.3, 3 → 2 wolves) AND drops attack cooldown another step
           AND keeps Roan's faction-tier lines firing. Single quest, three
           visible world changes. Promoted to new top-priority hook.
        2. **Bram (Innkeeper) faction-tier on `whisperwood_goblins` < 0.4**
           — second proof of the no-`warm_flag` pattern Roan just
           established. Bram has a different vibe (warm hearth, gossip
           radius) so his lines should narrate "the travelers feel
           safer" rather than "I sleep easier".
        3. **Hala (Trainer) faction-tier on `dire_wolves` < 0.3** — a
           low-threshold author who only fires when the wolves are nearly
           extinct. Rare-but-rich payoff. Trains the kids to keep
           pursuing the hook even when the obvious ones (Roan, Maeve)
           have already paid out.
        4. **Lower-threshold Roan tier (`dire_wolves` < 0.15)** — same
           NPC, second tier on the same scalar. Currently the schema
           supports one threshold per NPC; either bump the schema OR
           wait for the wolf-extinction lines to land in a sibling NPC.

## 2026-05-05 (run 9) — JSON dialogue trees made live (closes integrator gap)

### Plan
- 5 ledgers consulted. Top-priority TODO from the 2026-05-04 integrator merge
  was **explicit**: "add JSON dialogue loader in NPC.gd (or WorldBuilder.NPCS
  ingest at `_ready`). Without it, lore-keeper output sits dormant." The
  `data/dialogue/elder_maeve.json` and `smith_edda.json` files have shipped
  rich mood-keyed trees with low-HP / boss / festival / time-of-day branches,
  but no reader existed. This run is the reader.
- Rule 1 (compound, don't sprawl): no new primitive. The lore JSONs already
  exist on disk (`auto/lore` shipped them 2026-05-04). This run is a single
  loader + a single predicate resolver + a single-line opt-in flag per NPC.
- Rule 5 (endless ≠ infinite map): the SAME NPCs the player has known since
  bootstrap now react to HP, boss state, festival days, and quest history.
  Briarwood feels lived-in without any new geometry, NPCs, or quests.

### Build
- `eldoria-godot/scripts/DialogueDB.gd` (NEW, +189 lines): `class_name
  DialogueDB extends RefCounted` with static methods `load_for(npc_name) ->
  Dictionary` and `choose_line(npc_name, ctx) -> String`. JSON load uses
  `FileAccess.file_exists` + `FileAccess.open` + `JSON.parse_string`,
  cached forever per slug (negative cache for misses). Predicate priority
  (highest first):
    1. `low_health_player`           — `Player.hp / Player.max_hp < 0.30`
    2. `boss_slain`                  — `World.has_world_flag("warlord_dead")`
    3. `boss_alive`                  — `World.has_world_flag("seen_warlord")` *
    4. `high_renown`                 — `World.player_renown >= 100` *
    5. `stranger`                    — `World.npc_seen[name] != true` *
    6. festival key                  — `World.current_festival == key` *
    7. `after_first_quest_complete`  — npc_has_flag(warmed_flag) OR
                                       has_world_flag("first_quest_done")
    8. mood bucket (tod)             — morning / midday / evening / night
    9. `default`                     — fallback
  ( * = fail-soft: World doesn't carry these fields yet; the predicate just
  doesn't fire today. The day a future Builder adds the field, the existing
  lines in the JSONs LIGHT UP automatically — no DialogueDB or JSON edit
  required. Five lines per NPC become live "free" the moment the field
  lands.)
- `eldoria-godot/scripts/NPC.gd` (+30 / -2): new `@export var
  use_dialogue_json: bool = false`. Cached `_player_ref: Player` populated
  on body_entered, cleared on body_exited (so DialogueDB can read accurate
  hp_ratio without a fresh group lookup at interact time). At the top of
  `_on_interact()`, if `use_dialogue_json` is true, builds ctx (world, tod,
  hp_ratio, warmed_flag), calls `DialogueDB.choose_line(npc_name, ctx)`. If
  non-empty, emits via `show_dialogue` and returns. Otherwise falls through
  to the existing 4-tier variants/warmed_* pipeline UNCHANGED.
- `eldoria-godot/scripts/WorldBuilder.gd` (+15 / -2): added
  `"use_json_dialogue": true` to the Maeve and Edda dicts in `NPCS`.
  `_make_npc()` copies `bool(data.get("use_json_dialogue", false))` onto
  `npc.use_dialogue_json`. Defaults false → all 5 other NPCs unchanged.
- `SYSTEM_REGISTRY.md`: new top-level section "JSON Dialogue Tree Schema"
  added between "NPC Schema" and "Time Schema". Documents slug convention,
  tree shape (9 supported keys), predicate priority, wiring, authoring
  rules, composition diagram with the existing 4 tiers, authoring traps,
  and 5 future hooks.
- `WORLD_STATE.md`: new "Resolved 2026-05-04 (run 9)" entry added before
  the existing top-priority lines. New top-priority promoted: ship JSON
  dialogue trees for the other 5 NPCs (Mara, Lyra, Bram, Roan, Hala) —
  pure data work, zero code change.
- `CHANGES.md`: this entry.

### Rule-2 outputs delivered
- (i)   World state: NO new World writes. New READ paths added:
        `World.has_world_flag("warlord_dead")`, `World.has_world_flag(
        "seen_warlord")`, `World.player_renown` (fail-soft), `World.npc_seen`
        (fail-soft), `World.current_festival` (fail-soft),
        `World.has_world_flag("first_quest_done")`, `World.npc_has_flag(name,
        warmed_flag)`. Six READ-only consumers added across DialogueDB.
        WORLD_STATE.md updated with a Resolved entry plus a NEW top-priority
        hook (5 more NPCs, data-only).
- (ii)  Queryable schema: `DialogueDB.load_for(npc_name) -> Dictionary` and
        `DialogueDB.choose_line(npc_name, ctx: Dictionary) -> String`.
        Documented in SYSTEM_REGISTRY.md "JSON Dialogue Tree Schema" with
        the 9-key tree shape table, predicate-priority listing, slug
        convention, and authoring traps. The `ctx` Dictionary is a stable
        public contract: 6 fields (world, tod, hp_ratio, warmed_flag,
        renown_threshold, low_hp_below) — all optional with safe defaults.
- (iii) Player-facing feedback: Maeve and Edda now react to player HP at
        every interaction (drop below 30% — both deliver mentor warmth).
        After the first quest turn-in, both warm to a "Whisperwood / Brigid"
        beat with stronger character voice than the existing 4-line warm
        cycles. Time-of-day mood lines for Maeve and Edda are now sourced
        from the rich JSON authorship (proverbs, hammer-clangs) instead of
        the terser `lines: []` fallback. Five additional lines per NPC are
        fail-soft and will light up THE DAY a future Builder adds a renown,
        festival, npc-seen, or seen-warlord tracker — no further dialogue
        edits required.
- (iv)  Evaluation:
        - DialogueDB.gd: parens 89/89, brackets 15/15, braces 9/9. ✓
        - NPC.gd: parens 79/79, brackets 3/3, braces 1/1. ✓
        - WorldBuilder.gd: parens 1084/1084, brackets 56/56, braces 36/36. ✓
        - All new `var` declarations carry explicit type annotations
          (`var key: String`, `var f: FileAccess`, `var raw: String`,
          `var parsed: Variant`, `var tree: Dictionary`, `var world_node:
          Node`, `var tod: float`, `var hp_ratio: float`, `var warmed_flag:
          String`, `var renown_threshold: int`, `var low_hp_below: float`,
          `var first_quest_warm: bool`, `var festival: String`,
          `var seen: Dictionary`, `var renown: int`, `var mood: String`,
          `var json_line: String`, `var ctx: Dictionary`, `var path: String`).
          No walrus on Variant.
        - JSON load is fail-soft: missing file, parse error, non-Dictionary
          root, and missing predicate keys all degrade to "" and the legacy
          variants pipeline takes over. No exceptions, no panics.
        - Negative cache means misses are O(1) on repeat — won't hammer
          FileAccess every interact for the 5 not-yet-JSON NPCs.
- (v)   Future hooks (≥ 2):
        1. **Ship JSON dialogue trees for Mara / Lyra / Bram / Roan / Hala**
           — pure data work. Author a `data/dialogue/<slug>.json` per the
           schema and flip `"use_json_dialogue": true`. Each NPC inherits
           the full 9-tier predicate space with no GDScript edit. Now the
           top-priority hook in WORLD_STATE.md.
        2. **`World.player_renown: int`** — when added, `high_renown` keys
           for Maeve + Edda fire automatically (their JSONs already author
           the lines). Single int + a setter from quest XP. Lights up
           multiple NPCs the moment the field exists.
        3. **`World.current_festival: String`** — when a calendar/festival
           system lands, the seasonal keys (`longnight_vigil`,
           `honeysong_eve`, `spring_first_warm_day`) become live without
           any JSON edit. Maeve already authors all 3; Edda authors 2.
           This is the cheapest path to "the village feels different on
           Halsa-day" gameplay.
        4. **`World.npc_seen: Dictionary`** — first-interaction tracker.
           When added, every JSON-tree NPC's `stranger` key fires for the
           first encounter and only then. Compounds with renown for a
           2-axis "rookie ↔ legend" arc.
        5. **`World.has_world_flag("seen_warlord")`** — set by an Enemy or
           the Boss script the first time the player gets within sight
           range of the Goblin Warlord. Lights up Maeve + Edda's
           `boss_alive` lines (currently dormant). One-line write in
           Boss.gd or a sight-detect Area3D in Whisperwood.
        6. **Per-line portrait / voice-clip extension:** `choose_line()`
           could return a Dictionary (line + portrait_path + voice_clip) if
           any future JSON adds those fields. Tree schema is already
           extensible (unknown keys are ignored), so additions are
           non-breaking.

### Phase reached
Historian — feature shipped, all 5 ledgers updated, ready to commit.

### Next run should pick up
**Roan-issued wolf-bounty quest (-0.1 reducer for `dire_wolves`).** Mirror
of `ears_for_mara` for the wolf faction. Trips the second wolf-spawn
threshold (0.4 → 0.3, 3 → 2 wolves), drops attack cooldown another step,
and KEEPS Roan's faction-tier lines firing — they remain valid because
the threshold is `< 0.5`. Single quest, three readable world changes.
Authoring is just a Quest entry in QuestRegistry plus a ConsequenceMap
row; no new schemas. After that, Bram or Hala faction-tier lines are
the next-cheapest second proof of the no-`warm_flag` pattern.

---

## Run 9 — Builder — 2026-05-04 — Achievements + Title system

**Theme citation:** §1 (warm + lived-in) + §3 (palette: burnt-gold modulate
on title Label3D, black outline) + §12 (motion-and-life: title bobs, never
static). Mood-board panel: N/A (no mood-boards/ directory committed yet).

**I'm building:** Achievements + Title system off backlog item #6 ("build
together"). Five achievements ship at run 9, with auto-equipped titles
above the player's head. ZERO new world primitives — every predicate reads
existing `factions` / `world_flags` / `npc_flags` state.

### Build
- `eldoria-godot/scripts/Achievements.gd` (NEW, 207 lines): const
  `ACHIEVEMENTS: Dictionary` + composable predicate language
  (`world_flag`, `faction_below`, `faction_above`, `all_npc_flags`,
  `all_of`, `any_of`) + pure `evaluate(world) -> Array` + stable
  `best_title(unlocked_ids) -> String`. Same fail-soft duck-type contract
  as the spawn-density helpers — missing world / missing accessors → empty
  array, never crashes.
- `eldoria-godot/scripts/World.gd` (+88 / -2):
  - `unlocked_achievements: Dictionary` + `current_title: String` runtime
    state, declared right under `npc_flags`.
  - `_check_achievements()` invoked at the END of `apply_consequence(...)`
    and once at `_ready()` (deferred so Player exists). Diffs against
    `unlocked_achievements`; toasts each newly-unlocked achievement
    (`🏆 <icon> <name> — <desc>`); 0.6s stagger if multiple unlock at
    once so kids can READ each one.
  - Auto-equipper: `Achievements.best_title()` picks the highest-priority
    unlocked title; on change, toast `✨ Title equipped: <title>` 0.3s
    after the unlock toast and pushes the title down via
    `_apply_title_to_player()`.
  - Public read accessor `has_achievement(id) -> bool` for future panels.
- `eldoria-godot/scripts/Player.gd` (+30 / -0):
  - `title_label: Label3D` declared near `weapon_visual` (palette §3
    burnt gold, black outline 8px).
  - `_ready()` builds the Label3D, hidden until World assigns one.
    Anchored at `position = Vector3(0, 2.4, 0)` above feet; billboarded;
    `pixel_size = 0.0035`. THEME §12 looping `create_tween()` bobs
    `position:y` between 2.40 and 2.46 every 1.5s so the label breathes.
  - Public `set_title(t: String) -> void` setter; empty string hides.
- `SYSTEM_REGISTRY.md` (+78 lines): new "Achievement & Title Schema"
  section between "World Flag Conventions" and EOF. Field table,
  predicate-language table, authoring rules, title-priority ladder,
  and the run-9 authoring trap (predicate evaluation runs AFTER all
  consequence steps — tier-4 unlocks fire on the same frame as their
  last input quest's toast; the 0.6s stagger is what protects them).
- `WORLD_STATE.md` (+27 lines): run-9 ✅ Resolved entry under Active
  Hooks; new Player Impact Ledger row for "Achievements unlocked".
  Wolf-bounty + Roan warm_flag still 🔥-flagged as next, just demoted
  one slot.
- `CHANGES.md`: this entry.

### Rule-2 outputs delivered (i–v)
- (i)   World state: ZERO new writes; new READ of three primitive
        accessors (`faction_pressure`, `has_world_flag`, `npc_has_flag`).
        `World.unlocked_achievements` and `World.current_title` are NEW
        runtime state but mutated only by the achievement evaluator
        itself — they don't expand the world-state surface area for
        downstream systems.
- (ii)  Queryable schema: `Achievements.evaluate(world) -> Array` and
        `Achievements.best_title(unlocked_ids) -> String` documented
        in SYSTEM_REGISTRY.md with the predicate-language table. Five
        achievements documented with their predicate shapes; the
        title-priority ladder (10 / 30 / 40 / 50 / 100) is published
        so future runs can slot new titles between existing tiers
        without reshuffling.
- (iii) Player-facing feedback: 🏆 toast on unlock with icon + name +
        desc; 0.6s stagger if multiple unlock simultaneously; 0.3s
        delayed ✨ "Title equipped" toast on title change; floating
        gold Label3D above the player's head, billboarded so it reads
        from any orbit angle, with a §12 Y-bob so it breathes.
- (iv)  Evaluation: parens / brackets / braces balance check passes
        on Achievements.gd (clean), World.gd (420/420, 59/59, 29/29),
        Player.gd (347/347, 20/20, 11/11). All new `var` declarations
        carry explicit type annotations
        (`var unlocked_now: Array`, `var newly_unlocked: Array[String]`,
        `var stagger: float`, `var entry: Dictionary`,
        `var icon: String`, `var aname: String`, `var adesc: String`,
        `var msg: String`, `var new_title: String`, plus all locals
        in `_eval_predicate`'s `match` arms). Same fail-soft duck-type
        guard pattern as `_goblin_camp_size` — `Achievements.evaluate`
        no-ops on a malformed world rather than crashing.
- (v)   Future hooks (≥ 2):
        1. **Achievements panel UI** — keybind (e.g. `J`) opens a panel
           listing all `ACHIEVEMENTS` with locked/unlocked state, a
           "current title" header, and (future) a manual title-equip
           button. `World.has_achievement(id)` already in place. Polisher
           or Builder lane.
        2. **Save/load achievements + title** — currently per-session.
           When persistence ships for `factions` / `world_flags` /
           `npc_flags`, `unlocked_achievements` should ride along on
           the same blob. The `_check_achievements()` call from
           `_ready()` already covers re-derivation if the predicates
           are in a satisfied state at load time.
        3. **Combat-derived achievements** — once `Player.kills_by_kind`
           is exposed via a `World.kill_count(kind: String) -> int`
           accessor, add `kill_count_at_least` predicate and unlock
           IDs like `goblin_slayer_25` or `wolf_hunter_10`. NEW reader
           of an existing primitive — same compound pattern.
        4. **Title-locked dialogue** — NPC.gd Tier 0 (above warm_flag)
           reads `World.current_title` and prefers a `title_dialogue`
           variant. E.g. "Warden of Eldoria, the road is yours." Ships
           on top of the existing 4-tier dialogue stack with one new
           field per NPC dict.
        5. **Roan + wolf-bounty quest** — still the immediate-next from
           run 8. With `pack_thinner` already wired against
           `dire_wolves < 0.5`, a Roan-issued -0.1 reducer would BOTH
           trip the second wolf-spawn cliff AND keep `pack_thinner`
           unlocked, with no special-case logic.

### Phase reached
Builder — feature shipped, 5/5 ledgers updated (Achievements.gd,
World.gd, Player.gd, SYSTEM_REGISTRY.md, WORLD_STATE.md, CHANGES.md),
ready to commit.

### Next run should pick up
**Roan-issued wolf-bounty quest** (still adjacent-next from run 8 —
trips `pack_thinner` → keeps `pack_thinner` AND drops a second wolf
spawn cliff AND drops surviving-wolf cooldown one more step). The
achievement-as-reward layer means the bounty quest now compounds with
SEVEN downstream consumers of its consequence: Roan dialogue (warm),
Roan dialogue (faction), goblin pressure (irrelevant for wolf bounty),
wolf spawn density, enemy cooldown, achievement evaluator, and (after
the panel UI ships) achievement panel state. Single quest, seven
visible world changes.

---

### Integrator run — 2026-05-05 (merge batch)

Merged 3 worker branches into `main`:
- `auto/builder` (2 commits) → Achievements + Title system (new `Achievements.gd`, wired into `World.gd` evaluator + Label3D float-text in `Player.gd`) AND Roan dire_wolves faction-tier dialogue retry. **Resolved 3-way conflict on CHANGES.md / WORLD_STATE.md / WorldBuilder.gd**: kept HEAD on WORLD_STATE + WorldBuilder (HEAD already had the prior integrator's run-8 narrative + adaptive chase_speed extension and the FIVE-consumers framing — builder's variant was a parallel re-author of work already merged); kept BOTH on CHANGES.md (changelog is append-only — builder's run-8 entry is genuinely new content). Builder's Achievements.gd diff applied cleanly.
- `auto/polisher` (1 commit) → Main.tscn env tuned to THEME §1/§3 sunset canon (run 9) + PLAYER_MODEL.md notes. Clean merge.
- `auto/lore` (1 commit) → Innkeeper Bram backstory `.md` (250 lines) + `innkeeper_bram.json` dialogue tree + WORLD_STATE.md lore appendix. Clean merge.

Branches not present this run: `auto/character`, `auto/environment`, `auto/audio` (no work landed). `auto/art` and `auto/qa` are 0 ahead — nothing to merge.

[INTEGRATOR-GAP] **Lore dialogue JSONs are STILL not loaded by NPC.gd.** Now THREE JSONs sit dormant: `elder_maeve.json`, `smith_edda.json`, `innkeeper_bram.json` (added this run). NPC.gd only reads exported PackedStringArrays populated by WorldBuilder; no `JSON.parse_string` or `FileAccess` of these files anywhere in `scripts/` (the only JSON loader in the codebase is Player.gd's save-state I/O on `user://eldoria_save.json`). The Bram JSON adds rich mood-keyed dialogue trees (default/morning/evening/etc.) plus voice_rules — all content-only, not in-game. **Same gap flagged in the 2026-05-04 integrator run; still no loader has shipped.** Forward-looking: builder or lore should add a JSON-driven dialogue path to NPC.gd, or have WorldBuilder ingest the JSONs at `_ready` and merge them into the existing `*_dialogue_variants` arrays.

[INTEGRATOR-GAP] **Items.gd `icon_path` fields are STILL unconsumed.** Every Items.gd entry carries `icon_path` pointing to real PNGs in `assets/icons/`, but no UI code reads either `icon` or `icon_path` (grep across `scripts/` is empty for both keys outside of Items.gd itself). Inventory rendering today uses neither. **Same gap flagged in the 2026-05-04 integrator run.** When inventory UI lands, the data is ready to wire — single line per item slot to swap text-glyph for `Texture2D` from `load(icon_path)`.

[INTEGRATOR-NEW] **Bram lore .md (250 lines) is canon-only.** Same shape as `elder_maeve.md`: rich narrative backstory living alongside its JSON sibling, neither consumed by the runtime today. The lore corpus is now 3 NPCs deep — these files are valuable as context for future authoring runs (worker agents read them before writing new lines), but they don't reach the player.

[INTEGRATOR-NOTE] **Achievements + Title system landed cleanly.** `Achievements.gd` is properly wired — `class_name Achievements`, called from `World.gd` (`Achievements.evaluate(self)`, `Achievements.best_title(...)`), unlocks toast in Player.gd, Label3D title floats above player. FIFTH reader of `faction_pressure()` plus first multi-NPC `npc_flags` reader. No integration gap here — builder's Achievements work is a self-contained, fully-wired feature on landing.

Next run TODO:
1. **Builder or Lore (HIGH):** Add JSON dialogue loader to NPC.gd (or WorldBuilder ingest at `_ready`). Without it, three lore-keeper JSONs sit dormant and the lore agent's authoring work isn't reaching players. Two integrator runs in a row have flagged this.
2. **Builder (MED):** Surface `icon_path` in inventory UI. Two integrator runs have flagged this. Single line change once inventory texture rendering is added.
3. **Builder (per WORLD_STATE top-priority):** Roan-issued wolf-bounty quest (-0.1 dire_wolves reducer). Compounds with Roan's run-8 dialogue, run-6 spawn density, run-7+8 adaptive cooldown/chase — one quest, four readable world changes.
4. **Lore (MED):** Author Bram's faction-tier dialogue (e.g. `whisperwood_goblins < 0.4`) so his .md backstory and JSON tree start to flow into game lines via WorldBuilder NPCS — this would be a second proof of the no-`warm_flag` pattern Roan established in run 8, on a low-threshold "the wood is almost ours" moment.
**Ship JSON trees for the 5 remaining NPCs** (data work, but high impact —
proves the schema with five distinct character voices). After that, the
next compounding move is a `World.player_renown: int` (single field) which
LIGHTS UP every `high_renown` line in every JSON tree at once.


---

## 2026-05-05 — INTEGRATOR run

### Branches merged (in stable order)
- `auto/builder` (1 commit) — JSON dialogue loader: DialogueDB.gd + NPC.gd integration; Maeve & Edda opted in
- `auto/polisher` (1 commit) — Player swing feel polish (range/arc/crit/timing/flash)
- `auto/character` (1 commit) — wolf.glb wired into Enemy.gd; §13 ground-contact lift
- `auto/art` (1 commit) — 5 PBR roughness maps (bark/rock/snow/roof/shingle)

`auto/lore` and `auto/qa` were 0 ahead — nothing to merge. `auto/environment` and `auto/audio` branches don't exist yet.

### Conflicts resolved
- `CHANGES.md` had two overlapping additions (HEAD's run-8 Roan + integrator notes vs. branch's run-9 JSON loader entry). Resolved by keeping BOTH chronologically — both runs happened, both deserve their entries. SYSTEM_REGISTRY.md and WORLD_STATE.md auto-merged cleanly. WorldBuilder.gd auto-merged cleanly.

### Integration gaps spotted

[INTEGRATOR-NOTE] **JSON dialogue loader gap CLOSED.** Builder's run 9 added `DialogueDB.gd` and wired `NPC.gd` to call `DialogueDB.choose_line(npc_name, ctx)` for opted-in NPCs. Two integrator runs in a row had flagged this gap; it's now resolved. `data/dialogue/` ships 3 JSONs (Maeve, Edda, Bram). Maeve and Edda are opted in via `use_json_dialogue: true` in WorldBuilder NPCS.

[INTEGRATOR-GAP] **Bram JSON is shipped but Bram is NOT opted into the loader.** Only 2 of the 3 dialogue JSONs are reaching players (`grep -c "use_json_dialogue.*true" WorldBuilder.gd` = 2). `innkeeper_bram.json` sits dormant despite the loader now existing. Single-line fix in WorldBuilder NPCS — flip Bram's entry to add `"use_json_dialogue": true`. **Recommended for next builder run.**

[INTEGRATOR-GAP] **PBR roughness textures are unconsumed.** Art shipped 5 .jpg roughness maps to `assets/textures/{bark,rock,snow,thatch}/` with `.import` files, but **zero .gd or .tscn references them** (`grep -r "bark_rough|rock_rough|snow_rough|roof_rough|shingle_rough" --include='*.gd' --include='*.tscn'` is empty). The textures are loaded by Godot's importer but no `StandardMaterial3D.roughness_texture` or shader uniform reads them. **Recommended for next builder run:** wire each rough map into the matching surface material in WorldBuilder where the bark/rock/snow/thatch albedo is set.

[INTEGRATOR-NOTE] **wolf.glb wiring landed cleanly.** Character agent's work is fully reachable — `Enemy.gd` preloads `res://assets/models/enemies/wolf.glb` in the model dict and skips the auto-rescale sweep for it (real quadruped, not the giant-head capsule fallback). No gap.

[INTEGRATOR-GAP] **`icon_path` STILL unconsumed (third integrator run flagging).** Items.gd carries `icon_path` for every weapon/armor entry pointing to real PNGs in `assets/icons/`, but no UI code reads either `icon` or `icon_path` outside of Items.gd itself. Single-line fix once inventory texture rendering ships.

### Branch reset
All 6 existing worker branches (`builder`, `polisher`, `character`, `art`, `lore`, `qa`) fast-forwarded to the new `main` head (9ea78ef). Next agent runs start from a clean slate.

### Next run TODO
1. **Builder (LOW, single-line):** Add `"use_json_dialogue": true` to Bram's entry in `WorldBuilder.gd` NPCS so his shipped JSON tree actually reaches players. Closes a brand-new gap with one keystroke.
2. **Builder or Art (MED):** Wire the 5 PBR roughness maps into surface materials in `WorldBuilder.gd` so the textures Art shipped this run are visible in-game. Today they're loaded by Godot but never referenced.
3. **Builder (per WORLD_STATE top-priority):** Roan-issued wolf-bounty quest (-0.1 dire_wolves reducer). Compounds with run-8 Roan dialogue, run-6 spawn density, run-7+8 adaptive cooldown — one quest, four readable world changes.
4. **Builder (MED):** Surface `icon_path` in inventory UI. Three integrator runs have flagged this. Single line once inventory texture rendering exists.
5. **Lore (MED):** Author Bram's faction-tier dialogue (`whisperwood_goblins < 0.4`) so his backstory and JSON tree start reaching game lines via WorldBuilder NPCS — second proof of the no-`warm_flag` pattern Roan established in run 8.


---

## 2026-05-05 — INTEGRATOR run (later same day)

### Branches merged (in stable order)
- `auto/polisher` (1 commit) — Main.tscn post-processing pass: glow + SSAO + tonemap white + adjustments + sun godrays; 11 env knobs retuned, no new nodes/resources/scripts.
- `auto/art` (1 commit) — 8 procedural parchment/wood UI panels (`assets/ui/*.png`) + generator script `scripts/art/make_ui_frames.py`.
- `auto/lore` (1 commit) — Herbalist Lyra full backstory (`lore/npcs/herbalist_lyra.md`), mood-keyed dialogue tree (`data/dialogue/herbalist_lyra.json`), and WORLD_STATE.md update.

`auto/builder`, `auto/character`, `auto/qa` were 0 ahead — nothing to merge. `auto/environment` and `auto/audio` branches still don't exist.

### Conflicts resolved
None this run — all three merges were clean fast-forward-style merges (--no-ff).

### Integration gaps spotted

[INTEGRATOR-GAP] **Herbalist Lyra dialogue JSON is shipped but Lyra is NOT opted into the loader.** Same pattern as Bram in the previous run. WorldBuilder NPCS entry for Lyra lacks `"use_json_dialogue": true`, so her rich mood-keyed JSON tree (`data/dialogue/herbalist_lyra.json`) sits dormant despite her being spawned and modeled. **Single-line fix**: add `"use_json_dialogue":true` to her NPCS entry. Counter is now `grep -c "use_json_dialogue.*true" WorldBuilder.gd` = 2 (Maeve, Edda) but THREE JSONs ship (Maeve, Edda, Bram, Lyra → 4 actually). Lore is outpacing builder integration. **Recommended for next builder run** (combine with Bram's flip — two-line fix).

[INTEGRATOR-GAP] **8 new UI panels are unreferenced.** Art shipped `parchment_panel.png`, `parchment_panel_small.png`, `wood_panel.png`, `scroll_banner.png`, `divider_ornate.png`, and `button_{normal,hover,pressed}.png` to `assets/ui/`, but `grep -r --include='*.gd' --include='*.tscn' --include='*.tres' "<panel_name>"` returns 0 references for every single one. None are wired into a Theme resource, StyleBoxTexture, or Control node. The Generator script and PNGs exist; the Theme/StyleBox plumbing does not. **Recommended for next builder/UI run:** create `assets/ui/eldoria_theme.tres` with StyleBoxTexture-backed panels referencing these PNGs, then assign as the project default theme in `project.godot` or apply to existing CanvasLayer/Control roots.

[INTEGRATOR-NOTE] **Lore→model→spawn chain for Lyra is otherwise intact.** WorldBuilder.gd preloads `herbalist_lyra.glb`, scales her at 1.30, spawns her in NPCS at (-3, 0, -5) with role "alchemy" and a wolf-pelt-for-salve quest hook. Only the JSON-loader opt-in is missing. Two changes away from full integration of this run's lore work.

[INTEGRATOR-GAP] **Polisher's Main.tscn post-processing applies to the original scene.** No gap per se — Main.tscn is the loaded scene — but worth noting that any future agents adding scenes (BriarwoodScene, dungeons) will not inherit these env settings unless they instance/reference Main.tscn's WorldEnvironment node or the env values are extracted into a shared `world_environment.tres`. **Watch item, not blocker.**

### Carried-over gaps from previous integrator runs (unchanged)
- **Bram JSON unconsumed** (`use_json_dialogue` flag missing in WorldBuilder NPCS).
- **5 PBR roughness textures unconsumed** (`bark/rock/snow/roof/shingle_rough` — no material references).
- **`icon_path` on Items.gd entries unconsumed** by inventory UI.

### Branch reset
All 6 existing worker branches (`auto/builder`, `auto/polisher`, `auto/character`, `auto/art`, `auto/lore`, `auto/qa`) fast-forwarded to the new `main` head. Next agent runs start clean.

### Next run TODO
1. **Builder (LOW, two-line):** Flip `"use_json_dialogue":true` on **both** Bram and Lyra in WorldBuilder NPCS. Closes two gaps in one keystroke. Quadruples the player-reachable JSON dialogue corpus (2→4).
2. **Builder/UI (MED):** Build `assets/ui/eldoria_theme.tres` from the 8 new parchment/wood panels and assign it as the project default theme. Connects this run's Art work.
3. **Builder/Art (MED, carried):** Wire the 5 PBR roughness maps into surface materials in WorldBuilder so the textures Art shipped two runs ago become visible.
4. **Builder (per WORLD_STATE top-priority, carried):** Roan-issued wolf-bounty quest as the first `-0.1` dire_wolves reducer. Lyra's pelt quest is *also* a `-0.1` reducer (already wired) — Roan would compound it.
5. **Lore (MED, carried):** Bram faction-tier dialogue (`whisperwood_goblins < 0.4`) — second proof of the no-warm-flag predicate pattern.

---

## 2026-05-05 (integrator run 3) — Builder + Polisher merged; 4 carried gaps

### Branches merged this run
- `auto/builder` (1 commit) — `728a217` Boss world-flag wire (`seen_warlord` on intro, `warlord_dead` on death) + Bram opted into JSON dialogue. New `World.set_world_flag(name, value=true)` public API. +289 / −1 across 6 files (CHANGES.md, SYSTEM_REGISTRY.md, WORLD_STATE.md, Boss.gd, World.gd, WorldBuilder.gd).
- `auto/polisher` (1 commit) — `ddc423e` Drop-table balance pass (skeleton, crystal_elemental, chest_common, chest_rare) + affix odds 60/25/15 → 56/24/20 + affix value 2.5 → 2.75 + chest affix chance 0.55 → 0.58 + hp_potion_l 120 → 130 + mp_potion 40 → 45. +122 / −29 across 2 files (PLAYER_MODEL.md, Items.gd).

### Branches unchanged (0 ahead of main)
- `auto/character` — pinned at last integration
- `auto/art` — pinned at last integration
- `auto/lore` — pinned at last integration
- `auto/qa` — pinned at last integration

### Branches missing (do not exist on remote)
- `auto/environment` — no branch exists (per registry; no env worker has run yet)
- `auto/audio` — no branch exists (per registry; no audio worker has run yet)

### No conflicts. Linear merge order: builder → polisher. Both fast-forwarded clean off `5ba54e7`.

### Branch reset
All 6 existing worker branches (`builder`, `polisher`, `character`, `art`, `lore`, `qa`) fast-forwarded back to `main` HEAD (`5ba54e7`). Next agent runs start clean.

### Integration status this run
- ✅ **Boss → DialogueDB loop is now CLOSED.** Builder's run-10 wire writes `seen_warlord` / `warlord_dead`; the existing JSON-tree loader (DialogueDB.gd from run 9) already reads them via `boss_alive` / `boss_slain` predicates. Three opted-in NPCs (Maeve, Edda, Bram) now speak distinct boss-state lines on the same tick the player crosses 30m of the Warlord and on the tick the Warlord dies. **No gap.**
- ✅ **Bram JSON opt-in landed cleanly.** Last run's flagged gap is closed — `WorldBuilder.gd` now has `"use_json_dialogue":true` on Maeve, Edda, **and Bram**. Counter `grep -c "use_json_dialogue.*true" WorldBuilder.gd` = 3.

### Carried-over gaps (still open, no work this run)
- [INTEGRATOR-GAP] **Herbalist Lyra dialogue JSON is shipped but Lyra is NOT opted-in.** `data/dialogue/herbalist_lyra.json` has been on disk for two runs. WorldBuilder.gd NPCS entry for Lyra (line 199) lacks `"use_json_dialogue":true`. The other three NPCs with JSONs are all opted in. **Single-line fix** — add `"use_json_dialogue":true` to her entry. Builder lane next run.
- [INTEGRATOR-GAP] **Items.gd `icon_path` STILL unconsumed (4th run flagging).** Every weapon/armor entry in `Items.gd ITEMS = {...}` carries `icon_path` pointing to real PNGs in `assets/icons/` (chainmail.png, frost_saber.png, dragonfang.png, etc.). `grep "icon_path" eldoria-godot/scripts/*.gd` returns ONLY Items.gd itself; no UI consumer. Inventory UI swap-in is one line per slot once it lands.
- [INTEGRATOR-GAP] **PBR roughness textures STILL unconsumed (3rd run flagging).** 5 .jpg roughness maps under `assets/textures/{bark,rock,snow,thatch,wood,stone}/*_rough.jpg` with .import siblings. `grep -rE "bark_rough|rock_rough|snow_rough|roof_rough|shingle_rough|stone_rough|wood_rough" eldoria-godot/scripts/ eldoria-godot/scenes/` is empty. No `StandardMaterial3D.roughness_texture` assignment, no shader uniform read. Builder lane: wire each rough map into the matching surface material in WorldBuilder where the bark/rock/snow/thatch/wood/stone albedo is set.
- [INTEGRATOR-GAP] **8 UI panel PNGs STILL unreferenced (2nd run flagging).** `assets/ui/{parchment_panel,parchment_panel_small,wood_panel,scroll_banner,divider_ornate,button_normal,button_hover,button_pressed}.png` exist with ATTRIBUTION.md. Zero references in `*.gd / *.tscn / *.tres`. No `eldoria_theme.tres` exists. Builder/UI lane: create `assets/ui/eldoria_theme.tres` with StyleBoxTexture-backed panels, assign as project default theme in `project.godot` or apply to existing CanvasLayer/Control roots.

### Next-run TODO (priority order for worker agents)
1. **Builder** — Lyra `use_json_dialogue` flip (1 line). Lights up `data/dialogue/herbalist_lyra.json`'s mood-keyed tree (default/morning/midday/evening/night/low_health_player/boss_alive/boss_slain plus warmed-tier hooks). Highest-leverage single-line fix in the queue.
2. **Builder** — `World.player_renown: int` (or alias `unlocked_achievements.size()` as read-only computed). DialogueDB's `high_renown` predicate is wired but the field is missing — fail-soft today, would light up another 4–6 dormant authored lines across the three opted-in NPCs.
3. **Builder/UI** — `eldoria_theme.tres` with StyleBoxTexture from the 8 shipped UI panels, then apply to the project default theme.
4. **Builder/Material** — Roughness-texture wire-in across bark/rock/snow/thatch/wood/stone WorldBuilder materials.
5. **Builder/UI** — Inventory icon read path: `load(item_data.icon_path)` → `Texture2D` → slot icon. Single-line per slot once Inventory.gd renders textures instead of glyphs.
6. **Lore** — Author Mara / Roan / Hala JSONs. Mara highest-leverage (only NPC who trades; `low_health_player` reads as "she comps a potion").
7. **Character / Art / Audio** — No new gaps; continue per existing backlog.


---

## 2026-05-05 — BUILDER run 11 (player_renown system + Lyra JSON opt-in)

### What I'm building
**`World.player_renown: int` + `gain_renown()` + HUD RenownLabel** —
the single missing link in the dialogue-predicate chain. DialogueDB has
been reading `"player_renown" in world_node` since run 9 with a
fail-soft fallback; the field landed today. Compounded with the Lyra
JSON opt-in flip the integrator has been begging for since run 9, so
the `high_renown` predicate now resolves against authored lines on
all four opted-in NPCs (Maeve, Edda, Bram, Lyra).

### THEME compliance
- **§3 palette** — RenownLabel uses `Color(1, 0.78, 0.32)`, a slightly
  cooler burnt-gold than GoldLabel's `Color(1, 0.85, 0.40)`. Both inside
  the §3 primary palette range. Outline matches the existing HUD grammar.
- **§12 MOTION & LIFE** — the renown HUD label scale-pulses
  1.0 → 1.18 → 1.0 over 0.45s on every gain. Same back-then-sine grammar
  as DamageNumber.gd. No static "should-pulse" element.
- **§14 PUSH DISCIPLINE** — pushing to `auto/builder` only. Not main.

### Files changed
1. `eldoria-godot/scripts/World.gd`
   - `+@onready var renown_label: Label = $UI/HUD/RenownLabel` (line 20)
   - `+var player_renown: int = 0` with full schema docblock (after `current_title`)
   - `+func gain_renown(amount: int, source: String) -> void` — public mutator,
     clamps min 0, toasts positive delta, scale-pulses HUD label, re-evaluates
     achievements at the end (matches every other state mutator).
   - `+func _recompute_renown_from_achievements() -> void` — idempotent rebuild
     from `unlocked_achievements`. Save-safe for future persistence work.
   - `_check_achievements()`: each newly-unlocked achievement now schedules a
     `gain_renown(title_priority, "<icon> <name>")` 0.6s after its toast so
     kids parse the achievement first, then see the number rise.
   - `_refresh_hud()`: writes RenownLabel text alongside GoldLabel.
2. `eldoria-godot/scenes/Main.tscn`
   - `+[node name="RenownLabel" type="Label" parent="UI/HUD"]` directly below
     GoldLabel (offset_top 158 vs Gold's 130, same x range, same font size 18).
3. `eldoria-godot/scripts/WorldBuilder.gd`
   - Lyra NPCS entry: `+"use_json_dialogue":true` (compound run-9-and-10 gap
     the integrator has flagged in two consecutive reports). Counter
     `grep -c "use_json_dialogue.*true" WorldBuilder.gd` = 4 (was 3).
4. `SYSTEM_REGISTRY.md` — Renown Schema section (API, ladder, authoring rules, HUD readout).
5. `WORLD_STATE.md` — note the renown integer is now a strict function of `unlocked_achievements`.
6. `CHANGES.md` — this entry.

### 5-output check (Builder rule)
- (i) **integration** — `gain_renown` is callable from `apply_consequence`
  payload extension (future), `_check_achievements` is the wired source
  today, `DialogueDB.choose_line` reads via the existing fail-soft path.
- (ii) **schema** — SYSTEM_REGISTRY Renown section names the public API,
  the renown ladder (10/30/40/50/100 = title_priority), authoring rules,
  HUD readout. `_recompute_renown_from_achievements` is the save-safe
  idempotent rebuild.
- (iii) **feedback** — toast (`✨ +N Renown — 🐺 Pack Thinner`), HUD label
  (gold palette, sub-Gold position), scale-pulse 1.0→1.18→1.0 (THEME §12),
  achievement-toast staggered 0.6s before renown-toast for kid-readability.
- (iv) **eval** — `_recompute_renown_from_achievements()` is pure; can be
  called any time without drift. `gain_renown` calls `_check_achievements()`
  at the end so future renown-gated achievements unlock on the same tick
  the threshold is crossed (same idempotent contract as every other state
  mutator — `_check_achievements` diffs against `unlocked_achievements`,
  no double-grant).
- (v) **2+ hooks** — (1) DialogueDB `high_renown` predicate (lights up four
  authored JSON lines instantly), (2) HUD RenownLabel readout, (3)
  `_check_achievements` automatic credit chain (achievement unlock →
  renown gain → optional future achievement-on-renown unlock), (4) Lyra's
  newly-opted-in JSON tree (5th hook — direct compound from same run).

### Player-reachable JSON dialogue lines this run
- **Before run 11:** `grep -c "use_json_dialogue.*true" WorldBuilder.gd` = 3
  (Maeve, Edda, Bram). `high_renown` predicate fail-soft on missing field —
  zero authored renown lines reached players.
- **After run 11:** counter = 4 (Lyra opted in). `player_renown` field exists,
  `high_renown` predicate resolves. **Four** authored renown lines
  (elder_maeve, smith_edda, innkeeper_bram, herbalist_lyra) become reachable
  the moment the player crosses 100 renown — which the Warden tier achievement
  alone trips (priority 100 → +100 renown on unlock).

### What next run picks up
1. **Builder/UI (carried, MED):** `assets/ui/eldoria_theme.tres` from the 8 shipped
   parchment/wood UI panels — three integrator runs flagging.
2. **Builder/Material (carried, MED):** Roughness-texture wire-in across
   bark/rock/snow/thatch/wood/stone WorldBuilder materials — three integrator
   runs flagging.
3. **Builder/UI (carried, MED):** Inventory icon read path (`load(item_data.icon_path)`
   → Texture2D → slot icon). Four integrator runs flagging.
4. **Builder (NEW, LOW):** Renown-gated achievement (e.g. "Renowned" at 100,
   "Legend of Eldoria" at 250) — exercises the `_check_achievements()` call
   inside `gain_renown` that's wired but unproven this run.
5. **Lore:** Author Mara / Roan / Hala JSONs with `high_renown` keys to fill
   out the renown-line corpus from 4 to 7. Mara highest-leverage (only NPC
   who trades — `high_renown` reads as "she comps a potion").
6. **Crystal Caves dungeon** (backlog #1) — still untouched. Highest-leverage
   NEW system in the queue once the integration debt clears.

### Branch pushed: `auto/builder`


---

## 2026-05-05 — BUILDER run 11 (NPC schedules)

### Branch: `auto/builder` — rebased on integrator's run-4 HEAD
This run's first push lost the lane race to a parallel Builder agent
shipping `World.player_renown` + Lyra JSON opt-in. The integrator's
run-4 cycle merged that work into main. This commit rebases the
SCHEDULE-only deliverable onto the new clean `auto/builder` (off run-4
integrator HEAD) — duplicates dropped, schedules added.

### Theme gate
- THEME §12 cited (MOTION & LIFE — every visible thing must move): NPCs
  were stationary outside their idle-anim loop; this run gives all 7
  villagers positional motion across the day so their ambient role-
  behavior plays at the *right place* at the *right time*.
- THEME §13 cited (GROUND CONTACT): schedule walker preserves spawn-time
  `y` (`_spawn_y` cached in `_ready`); xz-only motion; no anchor can
  sink or float an NPC even if a future author writes a nonzero anchor y.
- Mood-board panel: Briarwood village dawn — Maeve at the well, Edda
  fanning forge, Bram unlocking inn shutters, Lyra returning from herb-
  foraging at the treeline.

### Feature shipped
**NPC SCHEDULES** (backlog item #3). Each visible villager moves between
role-specific anchor positions over a 24-h in-game day (~6 real-min
period at the existing `time_of_day` advance rate of `delta * 24/360`).
Buckets reuse the canonical 4-tier mood-bucket cliffs (5/11/17/21) so a
schedule transition coincides exactly with a dialogue-tier transition.
Smooth lerp at 0.8 m/s with 0.5m arrival-radius snap. Halts during
dialogue range so the player can converse without chasing.

### Files changed (2 .gd + 3 .md)
- `eldoria-godot/scripts/NPC.gd` — 3 new exports (`schedule_anchors`,
  `schedule_speed`, `schedule_arrival_radius`), 2 new internal vars
  (`_spawn_y`, `_last_bucket`), `_process` calls `_tick_schedule(delta)`
  when anchors non-empty AND player not in range, new `_tick_schedule()`
  walker + `_bucket_for_tod()` helper. ~70 LOC added; legacy NPCs (no
  anchors set) untouched.
- `eldoria-godot/scripts/WorldBuilder.gd`:
  - `schedule` Vector3-array key authored on all 7 NPCs in `NPCS` const
    (Maeve, Edda, Mara, Lyra, Bram, Roan, Hala — see WORLD_STATE table).
  - `_make_npc()` reads `data.get("schedule", null)` and, if Array of
    Vector3, copies into `npc.schedule_anchors`.
- `CHANGES.md` — this run log.
- `SYSTEM_REGISTRY.md` — registered `NPC.schedule_anchors` schema +
  bucket boundaries + author rules + smoke-test checklist.
- `WORLD_STATE.md` — Briarwood-mobility table (7 NPCs × 4 buckets) +
  high-leverage observables.

### Compounds with parallel-builder run 11 (player_renown)
- The schedule walker reuses the same `World.time_of_day` 4-bucket
  cliffs that DialogueDB reads for time-of-day mood keys. Since the
  parallel run shipped `player_renown` + Lyra JSON opt-in, ALL FOUR
  opted-in NPCs (Maeve, Edda, Bram, Lyra) now have:
    1. JSON-tree dialogue resolution (run 9 + 10 + 11 lore work)
    2. `high_renown` predicate that actually fires (parallel run 11)
    3. Spatial-position truth matching dialogue truth (THIS run)
- Lyra's morning JSON line about "marshmint at the forest edge" now
  plays AT the forest edge (anchor at -7.5,-7.5) where the dialogue
  said she was. Spatial truth ↔ dialogue truth.

### 5-output check
i.   **INTEGRATION** ✓ — schedule walker reads `World.time_of_day` (run-1
     primitive); buckets match the canonical 5/11/17/21 cliffs reused by
     `dialogue_variants`, `warmed_*`, and DialogueDB time-of-day keys.
ii.  **SCHEMA** ✓ — new `schedule` key in NPCS dict (Array[Vector3], up
     to 4 entries, clamped). Registered in SYSTEM_REGISTRY.
iii. **FEEDBACK** ✓ — visible motion at 0.8m/s with face-direction yaw;
     0.5m arrival radius snap. Idle anim keeps playing throughout walk
     (walk-anim swap is a documented Polisher hook).
iv.  **EVAL** ✓ — paren/bracket/brace balance verified on both .gd files.
     No `:= variant` patterns. Tab indentation consistent. Spawn-y
     cache locks ground contact; `look_at` guarded against zero-direction
     degeneracy.
v.   **HOOKS COMPOUND** ✓ —
     1. NPC physical position now matches what the dialogue *says*.
     2. Mara → inn at night puts her in earshot of Bram's evening line.
     3. Lyra → treeline at dawn matches her morning JSON line about
        marshmint at the forest edge.
     4. Future quest predicate `npc_at(name, location)` becomes trivial
        once schedule anchors are public.
     5. Festival staging (Longnight Vigil quartet) gains a *spatial*
        dimension — quartet members can converge on the well at vigil
        time, not just speak in the same JSON key.

### What next run picks up
1. **Builder/UI** (carried 4th run) — `assets/ui/eldoria_theme.tres`
   StyleBoxTexture wrapper for the 8 shipped panel PNGs.
2. **Builder/Material** (carried 5th run) — wire the 5 PBR roughness
   maps in WorldBuilder where bark/rock/snow/thatch/wood/stone albedo
   is set.
3. **Builder** — Crystal Caves dungeon (entrance NW, Vector3(-50, 0, -40)).
   Highest-leverage backlog item now that motion + dialogue + faction +
   achievement + renown stacks all compound.
4. **Lore** — Mara JSON (`data/dialogue/mara_the_merchant.json`) — only
   un-JSONed villager with a high-leverage `low_health_player` hook.
   Schedule anchor lands her at the inn at night where Bram's JSON
   has dialogue about her.
5. **Polisher** — walk anim swap-in for NPCs in motion. Detect
   `velocity.length() > 0.05` (or position delta) and play "Walk"
   animation if the GLB ships one; else keep current Idle.
6. **QA** — smoke-test the schedule walker. Set `time_of_day = 6.0` /
   `13.0` / `19.0` / `22.0` in turn and verify each villager arrives
   at the registered anchor.

---

## 2026-05-05 — Integrator run

**Merged into main this run:** auto/builder (1 commit), auto/character (2 commits), auto/art (1 commit), auto/lore (1 commit). Skipped: none — auto/polisher and auto/qa had nothing ahead of main; auto/environment and auto/audio branches do not exist yet.

**One conflict, manually resolved:** `WORLD_STATE.md` — auto/builder appended a "Briarwood NPCs become mobile (Builder run 11)" section and auto/lore appended a "Run: Lore Keeper — Stablemaster Roan backstory" section, both at the same anchor. Both are purely additive log entries; combined in chronological order (Builder section first, then Lore section). No content discarded.

[INTEGRATOR-GAP] **Achievement crests are authored but the toast UI does not consume them.** Art shipped 5 painterly 128×128 PNGs at `assets/icons/achievements/{first_steps,pack_thinner,goblin_bane,trusted_three,realm_warden}.png` and added `icon_path` to every `Achievements.ACHIEVEMENTS` entry. But `World.gd:282` still pulls `entry.get("icon", "🏆")` — the text glyph — when composing the unlock toast (`"🏆 %s %s — %s"`). The 128×128 crest never reaches a `Texture2D` slot. Single-line forward-fix: add a TextureRect to the toast scene and `load(entry.get("icon_path", ""))` alongside the existing string. **Recommended for next builder/UI run.** Note this echoes the long-standing Items.gd `icon_path` gap — same shape, same one-liner fix once a UI lands.

[INTEGRATOR-GAP] **Stablemaster Roan dialogue JSON is NOT shipped.** Lore canonized Roan's backstory (606-line markdown) and Builder added Roan to the schedule walker (stable in morning/midday, leading the team in the evening, lantern at night). But `data/dialogue/stablemaster_roan.json` does not exist — the four JSON-opted NPCs are still Maeve / Edda / Bram / Lyra. Roan's spoken lines are still the static "wolves bolder this season"-tier strings inlined in WorldBuilder. The backstory exists in canon but does not reach the player through dialogue. **Recommended:** lore drafts `stablemaster_roan.json` next run with the mood-keyed tree (default/morning/midday/evening/night plus low_health, boss_alive, boss_slain, high_renown — and Roan's distinctive longnight_vigil hook since he's the one who lights the stable lantern), then builder flips `"use_json_dialogue":true` on his NPCS entry.

[INTEGRATOR-GAP] **Lore .md backstory files (npcs/*.md) remain canon-only.** Roan's 606-line file joins Maeve / Edda / Bram / Lyra / Mara as static reference markdown — no code path loads `eldoria-godot/lore/npcs/*.md` at runtime. This is by design (the .md is for the writer; the .json is for the engine), but worth flagging since the lore folder has now grown to 6 files (5 NPCs + world.md) and a player encountering Roan in-game will hear nothing of Briar's Run, Tael, Eithne, the Long Mound, or the *thirre*-stone. Bridging this is intentionally JSON's job — see the previous gap.

**Branch reset:** all worker `auto/*` branches fast-forwarded to main after merge so next agent runs start from a clean tip.
---

## 2026-05-05 — BUILDER run 12 (Smith Edda forge — Crystal Caves loop closure)

### What I'm building
**Smith Edda's anvil — a per-weapon reforge upgrade ladder that consumes
Crystal Shards.** The Crystal Caves dropped shards from runs 5–11 with no
village-side sink; this run wires Smith Edda's dialogue panel with a 🔨
Reforge button that bumps the equipped weapon's `forge_tier` (1..3),
adding +2/+4/+6 flat damage and stamping a "+N" suffix on the display
name. The cave→village gameplay loop closes for the first time.

### THEME compliance cited
- **§1-9 visual canon** — no new visual content this run; the dialogue
  button is text-only inside the existing parchment-style DialoguePanel.
  Bronze/brass/cyan tier-color palette (`Items.REFORGE_TIER_COLORS`)
  reserved for future paperdoll polish stays inside §3 primary palette.
- **§7 dialogue tone** — "Edda hammers the steel — Iron Sword +1 sings"
  toast, "Already +3 — Edda nods. \"This is as far as steel goes.\""
  on max-tier press. Warm gravitas, no modern register, child-safe.
- **§12 motion-and-life** — toast scale-fades (existing _show_toast
  grammar), `play_sfx("sword_hit")` fires on success, and the run-11
  renown-label pulse triggers on the same tick (achievement → +25 renown
  chain). Three-layer feedback beat with no new tween code.
- **§13 ground contact** — N/A (no new 3D geometry placed).
- **§14 push discipline** — pushing to `auto/builder` only.

### Mood board panel
N/A — text-only UI compound; no new visual asset required.

### Files changed
1. `eldoria-godot/scripts/Items.gd`
   - `+const REFORGE_MAX_TIER: int = 3`
   - `+const REFORGE_COSTS: Array[int] = [5, 10, 18]`
   - `+const REFORGE_DAMAGE_BONUS: Array[int] = [2, 4, 6]`
   - `+const REFORGE_SUFFIXES: Array[String] = ["+1", "+2", "+3"]`
   - `+const REFORGE_TIER_COLORS: Array[Color]` (THEME §3 palette band)
   - `+static func forged_name(base_id, tier) -> String` — display helper
   - `+static func forge_damage_bonus(tier) -> int` — additive helper
   - `+static func forge_next_tier_cost(tier) -> int` — cap-aware cost
2. `eldoria-godot/scripts/Inventory.gd`
   - `+var forge_tiers: Dictionary = {}` — per-weapon-id tier state
   - `+func weapon_forge_tier(weapon_id="") -> int`
   - `+func weapon_display_name(weapon_id="") -> String`
   - `+func attempt_reforge(world: Object) -> Dictionary` — validates
     cost / tier cap, consumes shards, mutates tier, sets world flag,
     emits both inventory + equipment signals; returns a structured
     `{ok, ...}` Dict so the caller pretty-prints success and each
     failure mode without re-validating
   - `bonus_damage()` updated to ADD `Items.forge_damage_bonus(tier)`
     on top of base — pre-run-12 values unchanged when `forge_tiers`
     is empty (the default).
3. `eldoria-godot/scripts/World.gd`
   - `_setup_dialogue_actions()` — appends a `ReforgeBtn` Button below
     `TurnInQuestBtn`, wired to `_on_reforge_pressed`.
   - `show_dialogue()` — calls `_refresh_reforge_button(btn, role,
     player)` so the button label + enabled state reflect the player's
     current weapon and shard count every time the panel opens.
   - `+func _refresh_reforge_button(btn, role, player)` — pure read of
     inventory state. Visibility = (role == "smithy"). Disabled with
     reason-string label when no weapon, max tier, or insufficient
     shards. The button itself teaches the system.
   - `+func _on_reforge_pressed()` — calls
     `Inventory.attempt_reforge(self)`; on success toasts the new
     forged name + damage and replays `sword_hit` SFX, then refreshes
     the button so a back-to-back reforge reads correctly without
     closing & reopening dialogue. On failure toasts the reason from
     the structured result Dict.
4. `eldoria-godot/scripts/Achievements.gd`
   - `+"first_forge"` entry, slotted between `first_steps` (priority 10)
     and `pack_thinner` (priority 30) at priority 25. Title "the
     Forged". Predicate `{"kind": "world_flag", "flag":
     "first_reforge_done"}` — uses the existing predicate kind, no new
     evaluator surface.
5. `SYSTEM_REGISTRY.md` — Forge Schema section: API tables, ladder,
   authoring rules, hooks consumed / produced.
6. `WORLD_STATE.md` — Forge state subsection: world_flag, forge_tiers
   shape, cave-loop closure note.
7. `CHANGES.md` — this entry.

### 5-output check (Builder rule)
- (i) **integration** — Smith Edda's role was already wired in
  `WorldBuilder.NPCS` ("Smith Edda" / role "smithy"). The reforge button
  hangs off the existing DialoguePanel actions HBoxContainer; no new
  scene node, no new Main.tscn change. `Inventory` was the natural site
  for state because the equipped weapon and the bag (where shards live)
  are already its responsibility.
- (ii) **schema** — `forge_tiers: Dictionary[String, int]` keyed on
  weapon base id is the ONLY new state primitive. `Items.REFORGE_*`
  constants make the cost/damage curve a flat catalog edit. The
  `attempt_reforge` return shape is documented in code + registered in
  SYSTEM_REGISTRY for future readers.
- (iii) **feedback** — three layers fire on success:
  (1) `_show_toast("🔨 Edda hammers the steel — <name> sings (<dmg>)")`,
  (2) `play_sfx("sword_hit")`,
  (3) `player.stats_changed.emit()` → `_refresh_hud()` repaints the
  damage bonus, which compounds with the run-11 renown-label scale-pulse
  the moment the "first_forge" achievement unlocks (+25 renown). The
  button itself is the fourth layer of feedback when the action can't
  proceed (reason-string label).
- (iv) **eval** — `Items.forged_name`, `Items.forge_damage_bonus`,
  `Items.forge_next_tier_cost` are pure static helpers — callable any
  time, no side effects. `Inventory.attempt_reforge` is idempotent
  *given the same shard inventory* (a second call with the same shards
  would correctly fail with `not_enough_shards`); idempotency under the
  cap `tier == REFORGE_MAX_TIER` is explicit (returns `max_tier`
  failure, no mutation).
- (v) **2+ hooks** — (1) DialoguePanel ReforgeBtn (visibility +
  enabled state + label), (2) HUD damage readout (`bonus_damage()` now
  composes the tier bonus), (3) world_flags["first_reforge_done"] (new
  quest-trigger surface via existing world_flag predicate kind), (4)
  Achievements "first_forge" → renown +25 (run-11 ladder) → DialogueDB
  `high_renown` corpus (run-9 readers), (5) future
  `Inventory.weapon_display_name` HUD substitution.

### Player-reachable state this run
- **Crystal-shard sink** — before run 12: zero (caves drop, bag fills
  forever). After: 33 shards fully reforges any weapon (~3 cave runs at
  the run-11 drop-table tuning).
- **New achievement** — "First Forge" / title "the Forged", priority 25.
  Sits between "the Apprentice" (10) and "Wolf-Friend" (30) so a player
  who reforges before slaying any wolves gets briefly titled "the
  Forged" before the wolves humble enough to upgrade them. Pleasant
  pacing.
- **DialogueDB high_renown corpus** — unchanged in word count, but the
  threshold (default 100) is now reachable one achievement faster: a
  player who completes a starter quest (10 renown), reforges (25), and
  bears down on the goblins (40) sits at 75 — one step closer to the
  "Warden of Eldoria" tier.

### What next run picks up
1. **Builder/UI (carried, MED):** `assets/ui/eldoria_theme.tres` from the
   8 shipped parchment/wood UI panels — four integrator runs flagging.
2. **Builder/Material (carried, MED):** Roughness-texture wire-in across
   bark/rock/snow/thatch/wood/stone WorldBuilder materials — four
   integrator runs flagging.
3. **Builder/UI (carried, MED):** Inventory icon read path
   (`load(item_data.icon_path)` → Texture2D → slot icon) — five
   integrator runs flagging.
4. **Builder (NEW, LOW):** Renown-gated achievement at 100/250 — still
   unproven this run, the `_check_achievements` call inside `gain_renown`
   exists but no predicate consumes it.
5. **Builder/Forge polish:** Inventory paperdoll + bag tooltip should
   show "+N" on forged weapons. Today the dialogue button and HUD damage
   readout are the only visible surface; the bag still shows the base
   name. Quick win.
6. **Lore:** Smith Edda JSON could gain a `forge_tier_at_least` warmed
   key — "*looks at your blade and nods*" when she sees her own work
   come back. Predicate would need adding to DialogueDB; see hook (v).
7. **NPC schedules** (backlog #3) — still untouched. Highest-leverage
   NEW system in the queue once the integration debt (carried 1-3)
   clears.
8. **Better enemy variety — Skeleton, Bandit GLBs** (backlog #4). The
   skeleton kind exists in Enemy.gd KIND_TO_FACTION + spawning, but no
   GLB. Sourcing a CC0/CC-BY skeleton is the wire-up.

### Branch pushed: `auto/builder`

---

## 2026-05-05 — Integrator run (run 5)

**Merged into main this run:** auto/builder (1 commit — Smith Edda forge / reforge tier ladder), auto/polisher (1 commit — third-person camera retune), auto/art (1 commit — 8 enemy bestiary portraits), auto/lore (1 commit — Trainer Hala backstory). Skipped: none. Branches with nothing ahead: auto/character, auto/qa. Branches that don't exist yet: auto/environment, auto/audio.

**Three additive markdown conflicts, manually resolved:**
- `CHANGES.md` — auto/builder appended a "BUILDER run 12 (Smith Edda forge)" section while HEAD held the prior integrator run-4 notes. Both kept in chronological order; no content discarded.
- `SYSTEM_REGISTRY.md` — auto/builder added a "Forge Schema" section while HEAD held the run-4 schedule-walker registry entries. Both kept; the registry now documents both NPC schedules and per-weapon forge tiers.
- `WORLD_STATE.md` — auto/builder added "Forge state" subsection AND auto/lore added "Trainer Hala backstory" subsection at the same trailing anchor. All three (HEAD, builder, lore) kept in append order. No content discarded.

[INTEGRATOR-GAP] **Enemy bestiary portraits ship as orphaned assets.** Art shipped 8 painterly 128×128 enemy portraits (`assets/portraits/{goblin_grunt,goblin_brute,goblin_warlord,dire_wolf,skeleton_warrior,crystal_elemental,crystal_guardian,bandit_hooded}.png`) plus an ENEMIES_ATTRIBUTION.md. But `grep -rn portraits/ eldoria-godot/scripts/` returns ZERO matches — no Enemy.gd field, no DialoguePanel slot, no bestiary-UI scene loads any of them. The same gap exists for the 13 NPC portraits (mara, roan, hala, smith_edda, etc.) — they've sat unconsumed since Art's earlier town-manifest run. Single-line forward-fix when a UI lands: add a `var portrait_path: String` export to Enemy.gd / NPC.gd, populate from each entry, and `load(portrait_path)` into a TextureRect on damage-flash/dialogue-open. **Recommended for next builder/UI run** — this is the same integration debt as the achievement-icon and item-icon gaps. One unified "icon_path → TextureRect" pattern would close all three gaps in one builder pass.

[INTEGRATOR-GAP] **Trainer Hala dialogue JSON is NOT shipped — same shape as last run's Roan gap.** Lore canonized Hala's backstory (506-line markdown at `lore/npcs/trainer_hala.md`) and Builder's run-11 already added Hala to the schedule walker (field watch / training-yard / patrol). But `data/dialogue/trainer_hala.json` does not exist — the four JSON-opted NPCs are still Maeve / Edda / Bram / Lyra. Hala's spoken lines remain inline static strings in WorldBuilder. Two NPCs now have full backstories and zero JSON dialogue surface (Roan from run-4, Hala this run). **Recommended:** lore drafts `trainer_hala.json` next run with the mood-keyed tree (default/morning/midday/evening/night plus low_health, boss_alive, boss_slain, high_renown, plus a Hala-distinctive `recent_kill` / `wolf_count` hook since she's the trainer who watches the player's combat record), then builder flips `"use_json_dialogue":true` on her NPCS entry. Same forward-fix shape as the Roan recommendation from run-4.

[INTEGRATOR-GAP] **Skeleton and bandit portraits anticipate enemy kinds that have no dedicated GLB.** Art shipped `skeleton_warrior.png` and `bandit_hooded.png`. The skeleton kind exists in `Items.gd:DROP_TABLES` and `Enemy.gd:KIND_TO_FACTION`, but `Enemy.gd:KIND_TO_GLB` maps both `crystal_elemental` and `crystal_guardian` (and presumably skeleton/bandit if added) to `warrior.glb` — the generic stub. The portraits are *forward-staged* art that will pay off only once Builder/Asset shipping lands a real skeleton GLB (already on the backlog as item #4 from run-12). Not a regression — flagging because this is the cleanest example of art arriving ahead of the model pipeline. **Recommended:** Builder/Asset agent picks up CC0 skeleton + bandit GLBs as the next enemy-variety pass.

[INTEGRATOR-GAP] **Smith Edda forge button has no Inventory paperdoll surface.** Builder's run-12 reforge ladder writes `Inventory.forge_tiers[weapon_id]` and `Items.forged_name()` returns the "+N" suffixed display name. The dialogue toast on reforge AND the HUD damage readout both reflect the upgrade. But the Inventory paperdoll / bag tooltip path was not updated — bag still shows the base weapon name. Builder flagged this in their own "what next run picks up" so this is a known carry, not a discovered gap. Mentioned here for the ledger.

**Polisher's camera retune is self-contained.** auto/polisher only touched `CameraController.gd` and `PLAYER_MODEL.md` — no Player.gd changes this run, so the retune drops in cleanly without compounding with Character agent's prior bone-attach / weapon-visual work.

**Branch reset:** all worker `auto/*` branches will be fast-forwarded to main after push so next agent runs start from a clean tip.

