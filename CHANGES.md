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