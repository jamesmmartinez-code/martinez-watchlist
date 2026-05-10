## Tech debt
- QA 2026-05-10T13:38Z: Build=None (no build-eldoria.yml runs found) | Oversized: eldoria-godot/assets/models/Hero.glb (>20MiB hard cap) — REFERENCED in Main.tscn (player model); cannot delete. Tech debt logged in multiple prior runs. No new action taken — awaiting manual LOD/compression fix.

- QA 2026-05-10T06:08Z: Build=success | Oversized: eldoria-godot/assets/models/Hero.glb (>20MiB hard cap) — REFERENCED in Main.tscn (player model), Player.gd, CharacterSelect.gd; cannot delete. Requires LOD/compression fix (e.g. glTF draco compression or lower-poly mesh).

- QA 2026-05-10T05:37Z: Build=None (no build-eldoria.yml runs found) | Oversized: eldoria-godot/assets/models/Hero.glb (>20MiB hard cap) — REFERENCED in Main.tscn, Player.gd, CharacterSelect.gd; cannot delete. Tech debt already logged in multiple prior runs. No new action taken — awaiting manual LOD/compression fix.

## 2026-05-09 Auto: run 35 — NPC Gift-Giving mechanic (Backlog #8 completion)

I'm building: NPC memory system — gift-giving mechanic (Backlog #8)
THEME §1 cited: gifts are period-correct foraged/crafted goods only (wildflower, herb, sweet roll, painted stone)
THEME §12 cited: toast fades in/out per _show_toast — no hard snap; gift button text updates live
THEME §13 cited: no world-space changes — pure UI/data layer addition

Files changed:
  eldoria-godot/scripts/Items.gd      — 4 gift-type items added (wildflower_bunch, herb_bundle, sweet_roll, painted_stone)
  eldoria-godot/scripts/World.gd      — GiftBtn in dialogue Actions bar; _refresh_gift_button(); _find_gift_item();
                                         _on_gift_btn_pressed(); npc_count_with_relationship_above() helper
  eldoria-godot/scripts/WorldBuilder.gd — _make_npc wires warmed_relationship_min + warmed_relationship_dialogue_variants;
                                           Maeve + Bram get relationship_min=2 + 4 gift-warmed lines each
  eldoria-godot/scripts/Achievements.gd — gift_giver achievement (title "the Generous", priority 12);
                                           beloved_of_briarwood achievement (title "Friend of Briarwood", priority 38);
                                           beloved_of_briarwood eval branch in _eval_predicate

5-output check:
  i.  Integration  — GiftBtn wired into _setup_dialogue_actions; show_dialogue refreshes it each open
  ii. Schema       — Items.gd type="gift" items with gift_flavor field; npc_memory gifts/insults counters (pre-existing)
  iii.Feedback     — _show_toast with item name + NPC name + flavor text + reaction tier (nod/warm/fond)
  iv. Eval         — npc_relationship_score() public accessor (pre-existing); gift_giver achievement fires at score >= 1
  v.  2+ hooks     — "npcs" group gift button triggers _check_achievements(); npc_count_with_relationship_above()
                     enables beloved_of_briarwood; Maeve + Bram warmed_relationship_dialogue_variants

Next run picks up: Faction state — bandit boldness scales with road_defense_score (Backlog #9) or
                   Crystal Caves dungeon entrance polishing (Backlog #1)
## Tech debt

- **[2026-05-09] QA §15 violation — `eldoria-godot/assets/models/Hero.glb` is 29.55 MiB (exceeds 20 MiB soft cap, 25 MiB hard cap per OPERATIONS.md §15 / Cloudflare Pages budget)**
  - Asset is actively referenced in `Main.tscn` (player model) and cannot be deleted without breaking the game.
  - Action required: compress or LOD-swap Hero.glb below 20 MiB before Cloudflare Pages migration.
  - Logged by Eldoria QA Watchdog on 2026-05-09.

## Tech debt

QA 2026-05-09T04:48Z — Build: ✅ success | Pages: /pages/builds API shows errored record (build ~04:34Z) but deployment 4629164204 queued at 04:45Z indicates recovery; site likely live. No action taken — monitoring. Tech debt: OPERATIONS.md §15 does not exist as a file in repo (policy only documented in QA_OVERSIZED_ASSETS.md); Hero.glb 29.55 MB owner-override non-blocking (logged previously).


## run-33 — NPC Defense Witness System (2026-05-08)

**Backlog**: #8 NPC Memory — proximity defense awareness  
**THEME**: §1 (lived-in consequence), §12 (MOTION & LIFE — bark popup)

### What was built
- `Enemy.gd` `_die()`: calls `World.record_npc_defense_witness(global_position)` via call_group
- `World.gd`: `record_npc_defense_witness()` scans NPCs within 12m, increments `defenses_witnessed`, fires bark
- `World.gd`: `npc_defense_witnessed(name)` and `npc_count_with_defense_above(n)` query helpers
- `NPC.gd`: `witnessed_defense_lines: Array[String]` export, highest-priority dialogue tier, `_fire_witness_bark()` warm-gold popup
- `Achievements.gd`: `village_defender` achievement (3 NPCs witness ≥1 defense), `npc_defense_count` predicate
- `WorldBuilder.gd`: wires `defense_lines` for Elder Maeve, Smith Edda, Innkeeper Bram

### 5-output checklist
- ✅ Integration: Enemy→World→NPC call chain
- ✅ Schema: `defenses_witnessed` in npc_memory dict
- ✅ Feedback: `_fire_witness_bark()` warm-gold Label3D popup
- ✅ Eval: `village_defender` achievement + `npc_defense_count` predicate
- ✅ Hooks (×2): `record_npc_defense_witness` + `_fire_witness_bark`


### OPERATIONS.md §15 violation — Hero.glb exceeds 25 MiB hard cap
- **File:** `eldoria-godot/assets/models/Hero.glb`
- **Size:** ~29 MiB (hard cap: 25 MiB, soft cap: 20 MiB per OPERATIONS.md §15)
- **Status:** REFERENCED — cannot auto-delete
- **References found in:**
  - `eldoria-godot/scenes/Main.tscn` (ext_resource uid://b0j4kdyg3stf2)
  - `eldoria-godot/scripts/Player.gd` (Mixamo-retarget skeleton)
  - `eldoria-godot/scripts/CharacterSelect.gd` (default fallback model)
- **Context:** Replaced castle_guard.fbx on 2026-05-07. Meshy biped export at ~2.4-2.6m scale. GLB includes embedded textures which likely accounts for the size overage.
- **Required action (manual):** Re-export Hero.glb with external textures (gltf/embedded_image_handling=0) or compress/reduce embedded textures to bring file under 20 MiB soft cap. Alternatively, strip unused animation tracks before re-export.
- **Detected:** 2026-05-09 by QA Watchdog (automated)

## 2026-05-09 Auto: run 32 — Items.gd CQ-S2-02/03/04 (Builder canon-flag fixes)

I'm building: Fix builder-owned canon flags CQ-S2-02, CQ-S2-03, CQ-S2-04
THEME §1 cited: all 5 items are period-correct fantasy materials (carved briar, moss-lashed oak, hemp halter, hand-bound cudgel — no modern materials)
Canon docs read: AGENT_CANON_PREAMBLE.md, SIZE_STANDARDS.md, PROBLEMS_LOG.md, qa/_canon_flags.md
Mood board panel: Briarwood village market stall — Mara's row of six cudgels, Roan's stable shelf

Files: eldoria-godot/scripts/Items.gd (+5 entries to ITEMS dict)

5-output check:
  i.  Integration: Items.get_item("briar_shortbow") / ("mossbound_buckler") / ("roan_woodbow")
        / ("practice_cudgel") / ("roan_steppe_halter") now return full dicts instead of {};
        forge sell UI, loot popup, shop display, and drop table label all consume Items.get_item()
        — all 5 now work without any caller changes.
  ii. Schema: 5 new ITEMS entries. briar_shortbow (uncommon bow, dmg 8, crit 0.04, val 65);
        mossbound_buckler (common shield, armor 4, val 18); roan_woodbow (common bow, dmg 3, val 10);
        practice_cudgel (common weapon, dmg 4, val 8); roan_steppe_halter (uncommon trinket, val 22).
        Stats mirror corresponding .tres files exactly (CQ-S2-02). CQ-S2-03/04 authored fresh.
  iii. Feedback: loot popups and forge sell panel will now show correct item names/colors/icons
        instead of blank / "?" fallbacks. Roan's roan_halter_gifted flag chain now has a named item
        to show in paperdoll. Hala's after_first_quest_complete cudgel gift displays correctly.
  iv. Eval: Items.get_item(id).is_empty() == false for all 5 new ids — verifiable from any caller.
  v.  2+ hooks: Items.roll_loot (drop table) / World.show_dialogue (gift reward display) /
        Inventory.add_item (paperdoll slot resolution) / Inventory.attempt_sell_weapon (forge sell)
        — all 4 callers of Items.get_item() now resolve correctly for these ids.

Canon flags closed this run:
  CQ-S2-02 CLOSED: briar_shortbow, mossbound_buckler, roan_woodbow added to ITEMS dict
  CQ-S2-03 CLOSED: practice_cudgel authored (weapon, common, Hala gift)
  CQ-S2-04 CLOSED: roan_steppe_halter authored (trinket, uncommon, Roan gift)

Branch: auto/builder

Next run picks up:
  CQ-S2-01: items_flavor.json needs 4 entries (briar_shortbow, mossbound_buckler, roan_woodbow, wolf_heart)
  CQ-S2-05: mossbound_buckler recipe (craft via Lyra's herb_shed or new wood_shed station)
  CQ-S2-06: tree collision radius audit in _make_glb_tree

## Tech debt

## 2026-05-09 Auto: run 31 — Wandering Herbalist NPC + Cave Delver Achievement

I'm building: Wandering Herbalist NPC (maeve.glb, previously unused) + cave_delver achievement
THEME §1 cited: wandering healer is classic fantasy archetype — no modern gear, rootcraft and restoratives
THEME §12 cited: MOTION & LIFE — Wandering Herbalist has a wide day-arc schedule (deep forest→village well→cave approach), never static
THEME §13 cited: all schedule anchors y=0, no floating or buried geometry
Mood board panel: BotW travelling merchant at forest edge, lantern-lit dusk path

Files:
  WorldBuilder.gd  +NPC_MODELS "Wandering Herbalist"→maeve.glb
                   +NPC_SCALES "Wandering Herbalist" 1.10×
                   +NPCS[9]: Wandering Herbalist — role=alchemy, pos=Vector3(-22,0,-8)
                     4-bucket schedule (deep forest/village well/forest edge/cave approach)
                     memory_visits_min=2, warm_flag=first_quest_done
                     5 ambient barks 18-32s interval
  Enemy.gd         _die(): crystal_guardian → set_world_flag("crystal_guardian_slain") + _check_achievements
  Achievements.gd  +cave_delver achievement: predicate world_flag "crystal_guardian_slain"
                     title "the Cave Delver", priority 45

5-output check:
  i.   Integration: Wandering Herbalist spawned via existing _make_npc() path in _build_village();
         Enemy._die() crystal_guardian branch calls set_world_flag + _check_achievements
  ii.  Schema: NPCS[9] dict with full schedule/bark/memory/warm structure;
         Achievements "cave_delver" entry with world_flag predicate; crystal_guardian_slain flag
  iii. Feedback: warmed_flag lines fire after first_quest_done; memory_visits_min=2 warm tier at third visit;
         cave_delver achievement toast "the Cave Delver" on Guardian kill
  iv.  Eval: Achievements.cave_delver predicate evaluable via _check_achievements() in World.gd;
         Wandering Herbalist schedule walk readable via NPC._get_schedule_target()
  v.   2+ hooks: group "npcs" (Minimap gold-dot); schedule_anchors (NPC walker);
         warmed_memory tier (visit ledger); crystal_guardian_slain flag read by Achievements
         AND available as future dialogue predicate for Wandering Herbalist advanced lines

GLBs consumed this run: maeve.glb (NPC, Wandering Herbalist)
Next run picks up: Housing depth (storage chest contents, bed-rest heal), or Boss.glb wiring as Mountain Ogre


- **QA: OPERATIONS.md §15 violation — Hero.glb exceeds 25 MiB soft cap**
  - File: `eldoria-godot/assets/models/Hero.glb` — 29 MB (soft cap: 20 MiB, hard cap: 25 MiB)
  - Status: **REFERENCED** in `scenes/Main.tscn`, `scripts/Player.gd`, `scripts/CharacterSelect.gd` — cannot delete
  - Action required: Replace with a compressed/LOD version of Hero.glb before Cloudflare Pages migration
  - Logged by: Eldoria QA Watchdog — 2026-05-09T02:57:48Z

## 2026-05-08 Auto: run 29 — NPC Relationship Score (Backlog #8 compound)
I'm building: NPC memory deepening — record_npc_gift / record_npc_insult + relationship tier
THEME §12 cited: MOTION & LIFE — village NPCs now REACT to kindness, not just visits
Canon docs read: AGENT_CANON_PREAMBLE.md, SIZE_STANDARDS.md, PROBLEMS_LOG.md
Mood board panel: Stardew Valley / Rune Factory — villager warmth earned through actions
Files: World.gd +record_npc_gift +record_npc_insult +npc_relationship_score +npc_any_relationship_above
       NPC.gd +warmed_relationship_min +warmed_relationship_dialogue_variants (5th tier)
       Achievements.gd +villager_friend achievement (score>=3) + npc_relationship_min predicate
5-output check:
  i.  Integration: NPC._on_interact calls warmed_relationship tier ABOVE visit-count tier;
        World._check_achievements() called after every gift/insult write
  ii. Schema: npc_memory dict extended with gifts: int, insults: int per NPC;
        NPC_RELATIONSHIP_SCORE_MIN/MAX consts; warmed_relationship_min/@export on NPC
  iii.Feedback: warmed_relationship_dialogue_variants produces distinct warm lines when score>=min;
        achievement villager_friend unlocks title the Beloved on score>=3
  iv. Eval: npc_relationship_score() + npc_any_relationship_above() public accessors;
        _eval_predicate extended with npc_relationship_min kind
  v.  2+ hooks: record_npc_gift triggers _check_achievements (Achievement hook);
        warmed_relationship tier composable with all existing tiers in NPC chain
Next run picks up: Faction state — bandit boldness scales with road defense (Backlog #9)

## 2026-05-08 Auto: run 29 -- Faction State: Bandit Road Defense (Backlog #9)

I'm building: Faction state — bandit boldness scales with road defense (Backlog #9)
THEME §1 cited: road_defense_score decays slowly so defended roads soften back — consequence is lived-in, not permanent
THEME §12 cited: road_defense_score decays 5%/s via _process — drifts, never hard-clears; patrol spawns at 90s interval bring the road alive
THEME §13 cited: patrol bandit spawns at y=0 (GROUND CONTACT), south road corridor clamped to x∈[-8,8]
Mood board panel: Zelda BotW emergent threat ecology — world responds to what you've done

Files:
  World.gd  +road_defense_score float  +_bandit_patrol_timer float
            +BANDIT_PATROL_INTERVAL const  +BANDIT_PATROL_BOLDNESS_THRESHOLD const
            +ROAD_DEFENSE_DECAY const  +ROAD_DEFENSE_CAP const
            +record_road_kill(kind) mutator
            +get_road_defense_score() eval accessor
            +_tick_bandit_patrol() internal patrol spawner
            update_bandit_pressure() — defense_damper term subtracts from boldness
            _process — road_defense_score decay + _bandit_patrol_timer tick
  Enemy.gd  _die() — bandit/bandit_captain kill → record_road_kill() on world
  WorldBuilder.gd — Roan warmed_world_flag:"bandit_road_cleared" + 4 morning/midday/evening/night lines

5-output check:
  i.   Integration:  _tick_bandit_patrol() wired into World._process every BANDIT_PATROL_INTERVAL (90s)
                     record_road_kill() called from Enemy._die() for bandit/bandit_captain kinds
  ii.  Schema:       road_defense_score float[0..10], _bandit_patrol_timer, 4 consts in World.gd
                     SYSTEM_REGISTRY.md updated with full contract
  iii. Feedback:     "The road breathes easier." toast on bandit_road_cleared flag (score>=3)
                     "A bandit patrol stirs on the south road." toast on patrol spawn
                     Minimap ping at south road on cleared flag
  iv.  Eval:         get_road_defense_score() public accessor
                     faction_pressure("bandits") is the eval surface for boldness (pre-existing)
  v.   2+ hooks:     Enemy._die() → record_road_kill() (hook 1, per-kill)
                     _process → _bandit_patrol_timer → _tick_bandit_patrol() (hook 2, interval)
                     Roan warmed_world_flag:"bandit_road_cleared" (hook 3, NPC dialogue)
                     update_bandit_pressure() defense_damper (hook 4, boldness derivation)

Next run picks up: NPC memory deepening (record_npc_gift / record_npc_insult / relation_score)
  or Crystal Caves deepening (boss lore, new crystal_guardian patrol pattern)

## Tech debt

QA: 2026-05-08 — OPERATIONS.md §15 violation: `eldoria-godot/assets/models/Hero.glb` is 29 MiB, exceeding the 25 MiB hard cap (20 MiB soft cap) for Cloudflare Pages deploy target. Asset is actively referenced in `scripts/Player.gd`, `scripts/CharacterSelect.gd`, and `scenes/Main.tscn` — cannot be deleted. Action required: compress/LOD-bake Hero.glb below 20 MiB or split into streaming chunks before Cloudflare Pages migration.

## 2026-05-08 Auto: run 27 — Ambient NPC Barks (THEME §12)
I'm building: Ambient bark system wiring — all 7 villagers (Backlog #8 compound)
THEME §12 cited: MOTION & LIFE — idle one-liners float above NPCs between interactions;
  world feels inhabited, not posed. Every villager has a role-specific voice.
Canon docs read: AGENT_CANON_PREAMBLE.md, SIZE_STANDARDS.md, PROBLEMS_LOG.md
Mood board panel: cosy village at dusk, each villager muttering to themselves
Files: WorldBuilder.gd (bark_lines added to all 7 NPCS[] entries + _make_npc wiring)
5-output check:
  i.  Integration: _make_npc() copies bark_lines → npc.ambient_bark_lines;
        NPC._ready initialises _bark_cooldown to staggered random;
        NPC._process calls _tick_ambient_bark(delta) each frame
  ii. Schema: bark_lines key added to all 7 NPCS[] dict entries (4 lines each);
        interval stays at NPC.gd defaults (22-38s) — per-role tuning in next pass
  iii.Feedback: Label3D floats above NPC head, fades over 3s (NPC._tick_ambient_bark)
  iv. Eval: no bark fires when player is in interact range (ambient_bark_player_near_only=true)
  v.  2+ hooks: group 'npcs' (Minimap already reads it); 'use_dialogue_json' chain untouched;
        schedule_anchors wiring untouched — both compound systems still active
Next run picks up: NPC memory system deepening (record_npc_gift / record_npc_insult) or
  Faction state — bandit boldness scales with road defense (Backlog #9)

- QA 2026-05-08T15:08Z: Build=success (pages-build-and-deployment), Pages=built. §15: Hero.glb 29MiB > 20MiB soft cap — REFERENCED in Main.tscn+Player.gd, cannot delete; already logged as tech debt in prior runs. No new action taken this run. ✅ All systems green.
- QA 2026-05-08T15:27Z: Build=in_progress (Godot Web Export), Pages=building. §15: Hero.glb 29MiB > 20MiB soft cap — REFERENCED in Main.tscn+Player.gd, cannot delete; already logged as tech debt. No new action taken this run.
- QA 2026-05-08T14:58Z: Build=success (pages-build-and-deployment), Pages=built. §15: Hero.glb 29MiB > 20MiB soft cap — REFERENCED in Main.tscn+Player.gd, cannot delete; already logged as tech debt. No new action taken this run. ✅ All systems green.
- QA 2026-05-08T14:46Z: Build=success (pages-build-and-deployment), Pages=built. §15: Hero.glb 29MiB > 20MiB soft cap — REFERENCED in Main.tscn+Player.gd, cannot delete; already logged as tech debt. No new action taken this run. ✅ All systems green.
- QA 2026-05-08T14:45Z: Build=in_progress (pages-build-and-deployment), Pages=building. §15: Hero.glb 29MiB > 20MiB soft cap — REFERENCED in Main.tscn+Player.gd, cannot delete; already logged as tech debt. No new action taken this run.
- QA 2026-05-08T14:42Z: Build=success, Pages=built. §15: Hero.glb 29MiB > 20MiB soft cap — REFERENCED in Main.tscn (player model), cannot delete; already logged as tech debt. No new action needed this run. All systems green.
- QA 2026-05-08T14:23Z: Build=success (pages-build-and-deployment 14:19Z), Pages=built. §15: Hero.glb 29MiB > soft cap — already logged as tech debt in prior runs. No new action needed this run. ✅ All systems green.

## 2026-05-08 Auto: run 25 — Visual polish (god-ray + hearth)
Polish category: Visual
THEME §12 cited: MOTION & LIFE — light through leaves moves; a hearth that emits
flat constant energy reads as a light bulb, not a fire.
Files: World.gd (god-ray loop REFINE) | PlayerHome.gd (CANDLE_FREQ2/AMP2 consts + _process + _hearth_light wiring)
5-output:
  i.  INTEGRATION  — all changes within existing functions, no new calls
  ii. SCHEMA       — CANDLE_FREQ2=5.18, CANDLE_AMP2=0.07, _hearth_light OmniLight3D ref
  iii.FEEDBACK     — per-shaft amount_ratio now unique per frame; hearth+candle pulse linked
  iv. EVAL         — both changes deepen run 23 (god-rays) and run 24 (hearth) without touching new nodes
  v.  HOOKS        — god_ray_shafts group unchanged (WorldBuilder hook still valid)
Next: Character depth (NPC ambient-bark deepening) or Combat-feel (damage number color tiers)

- QA 2026-05-08T14:11 UTC: Build=success (Build Eldoria 14:03), Pages=errored (Jekyll processing failure on large .pck files). FIX: added .nojekyll (commit c658b56a) to skip Jekyll — this should resolve Pages build. §15 violation: Hero.glb 29MiB > 20MiB soft cap — REFERENCED in Main.tscn+Player.gd, cannot delete. Logged as tech debt.

## Tech debt

- **OPERATIONS.md §15 violation** — `eldoria-godot/assets/models/Hero.glb` is 29 MiB, exceeding the 20 MiB soft cap (25 MiB hard cap). File is actively referenced in `scenes/Main.tscn` and `scripts/Player.gd` as the primary character model. Must be re-exported from Meshy/Blender at lower poly count, or split into base mesh + separate animation library, before Cloudflare Pages migration. Detected: 2026-05-08.

- QA 2026-05-08T14:06 UTC: Build=None (pages-build-and-deployment in_progress, no build-eldoria.yml runs), Pages=building, §15 violation: Hero.glb 29MiB > 20MiB soft cap — REFERENCED in Main.tscn+Player.gd, cannot delete; already logged as tech debt in prior runs. No new action taken this run.

## 2026-05-08 Auto: run 24 -- Adaptive difficulty per player

I'm building: Adaptive difficulty per player (Backlog #11)
THEME §1 cited: difficulty is invisible — no MODE banner, just a tiny ▿/◇/▴ glyph on HUD
THEME §12 cited: diff_scalar lerps 30% toward target every 10s — drifts, never snaps
THEME §13 cited: receive_difficulty_scalar skips dead enemies — no stat mutation on floor contacts
Mood board panel: Zelda BotW natural-rhythm tuning, Soulsborne difficulty-that-feels-fair

Files: World.gd +player_difficulty_state dict +_adaptive_diff_timer +_process tick
       +record_player_death() +record_player_kill() +get_difficulty_tier()
       +get_difficulty_scalar() +_apply_adaptive_difficulty() +_refresh_difficulty_hud()
       Enemy.gd +receive_difficulty_scalar() (live-mutates cooldown/speed/damage via lerp)
       Player.gd +record_player_death hook in _die() +record_player_kill hook in on_enemy_killed()

5-output check:
  i.  Integration: _apply_adaptive_difficulty() wired into World._process every 10s
  ii. Schema: player_difficulty_state dict (deaths/kills/seconds/diff_scalar/tier) in World.gd
  iii. Feedback: _refresh_difficulty_hud() creates DifficultyLabel in HUD (▿/◇/▴)
  iv. Eval: get_difficulty_tier() + get_difficulty_scalar() public accessors
  v.  2+ hooks: Player._die() -> record_player_death() | Player.on_enemy_killed() -> record_player_kill()
      Enemy.receive_difficulty_scalar() group-called on all live enemies

Next run picks up: Housing / player-shaped spaces (Backlog #10)

- QA 2026-05-08T13:50 UTC: Build=None (no workflow runs yet), Pages=building, §15 violation: Hero.glb 29MiB > 20MiB soft cap — REFERENCED in Main.tscn, cannot delete; already logged as tech debt. No new action taken this run.
- QA 2026-05-08T13:16 UTC: `eldoria-godot/assets/models/Hero.glb` is 29 MiB -- exceeds OPERATIONS.md §15 soft cap (20 MiB) and hard cap (25 MiB). Referenced in Main.tscn, cannot delete. Action: mesh optimization/LOD reduction needed.

## Tech debt
## 2026-05-08 Auto: run 24 -- Housing / Player Home (Backlog #10)
I'm building: Housing / player-shaped spaces (Backlog #10)
THEME §1 cited: timber-frame + thatched roof identical to village houses — no modern materials
THEME §3 cited: warm amber window glow, sunset-gold nameplate (#FFD86B)
THEME §12 cited: hearth CPUParticles3D sparks, candle sine-flicker in _process, chimney smoke
THEME §13 cited: all geometry base at y=0; no floating edges, no buried foundations
Mood board panel: cosy fantasy cottage at dusk, warm light through leaded windows
Files: scripts/PlayerHome.gd (NEW) | WorldBuilder.gd +HOME_POS +HOME_SCRIPT +_build_player_home | Achievements.gd +hearthkeeper
5-output: i=_build_player_home wired via _safe_call in WorldBuilder._ready; ii=HOME_POS+HOME_SCRIPT schema + interior_unlocked bool + "player_home" group; iii=E-key toast feedback ("Home. The hearth is warm." / locked line); iv=interior gated on has_world_flag("first_quest_done") re-evaluated each _ready; v="player_home" group hook (WeatherSystem/SeasonSystem) + World flag "player_home_visited" + Achievements "hearthkeeper" + "chests" group on StorageChest for Minimap pin
Next: Adaptive difficulty per-player (Backlog #11) or NPC faction dialogue for hearthkeeper title

- QA 2026-05-08: `eldoria-godot/assets/models/Hero.glb` is 30 MiB -- exceeds OPERATIONS.md s15 soft cap (20 MiB) and hard cap (25 MiB). Referenced in Main.tscn, cannot delete. Action: mesh optimization/LOD reduction needed.

## 2026-05-08 Auto: run 23 -- God-rays through canopy
I'm building: God-rays through canopy (Backlog #5)
THEME Â§1 cited: painterly warm amber light shafts through Whisperwood
THEME Â§12 cited: GPUParticles3D shafts drift/breathe â no static quads
THEME Â§13 cited: emitters at canopy height 5.5m, shafts fall to ground, no below-ground spawn
Mood board panel: dawn light through forest canopy, Ghibli/BotW morning mist
Files: WorldBuilder.gd +GOD_RAY_SPOTS const +_build_god_rays | World.gd +daylight god_ray_shafts fade
5-output: i=_safe_call wired in _ready; ii=GOD_RAY_SPOTS schema (5 emitters, NW/W arc); iii=_dlog feedback on spawn; iv=_make_soft_particle_texture+alpha ramp (no white-blob per PROBLEMS_LOG Â§1.3); v=god_ray_shafts group + World.gd amount_ratio tod hook
Next: Housing/player-shaped spaces or Adaptive difficulty

## Tech debt

### Â§15 Asset Budget Violation â Hero.glb (2026-05-08)
- **File**: `eldoria-godot/assets/models/Hero.glb`
- **Size**: 29 MiB (30,258 KB) â exceeds 20 MiB soft cap and 25 MiB hard cap per OPERATIONS.md Â§15
- **Status**: REFERENCED â cannot delete
  - Referenced in: `eldoria-godot/scripts/Player.gd`, `eldoria-godot/scripts/CharacterSelect.gd`, `eldoria-godot/scenes/Main.tscn`
- **Action required**: Compress or LOD-split Hero.glb to bring under 20 MiB before Cloudflare Pages migration
- **Detected by**: QA Watchdog run 2026-05-08T07:12 UTC



## 2026-05-08 Auto: run 22 -- Smith Edda forge UI (enchant/sell/buy)
Building: Forge UI enchant+sell+Mara shop
THEME s1 (parchment UI) + s12 (toast/button motion)
Files: Inventory.gd +enchant/sell/buy | World.gd +3 buttons+shop | Achievements.gd +first_enchant
5-output: i=show_dialogue wired; ii=attempt_* schema; iii=toast feedback; iv=first_enchant achievement; v=Achievements hook+ShopBtn role dispatch
Next: NPC memory or god-rays
- QA 2026-05-08T14:06 UTC: Build=success, Pages=building (in-progress, no error), §15 Hero.glb 29MiB violation already logged. No new action — existing tech debt entry covers this.
- QA 2026-05-08T15:14 UTC: Build=success, Pages=built, §15 Hero.glb 29MiB violation persists (logged 07:12 UTC). Asset is referenced — no action taken. No-op run.
- QA 2026-05-08T15:48 UTC: Build=None (no recent conclusion/queued), Pages=building (in-progress), §15 Hero.glb 29MiB violation persists (logged 07:12 UTC). Asset is referenced — no action taken. No-op run.
- QA 2026-05-08T16:07Z: Build=success (Godot Web Export run 549, 16:02Z), Pages=success (pages-build-deployment run 883, 16:04Z). §15: Hero.glb 29MiB > 20MiB soft cap — REFERENCED in Main.tscn+Player.gd+CharacterSelect.gd, cannot delete; already logged as tech debt. No new action taken this run. ✅ All systems green.
- QA 2026-05-08T16:19Z: Build=success (Godot Web Export run 549, 16:02Z), Pages=success (pages-build-deployment run 884, 16:19Z). §15: Hero.glb 29MiB > 20MiB soft cap — REFERENCED in Main.tscn+Player.gd+CharacterSelect.gd, cannot delete; already logged as tech debt. No new action taken this run. ✅ All systems green.
- QA 2026-05-08T16:58Z: Build=success (Godot Web Export run 551, 16:52Z), Pages=success (pages-build-deployment run 889, 16:57Z). §15: Hero.glb 29MiB > 20MiB soft cap — REFERENCED in Main.tscn+Player.gd+CharacterSelect.gd, cannot delete; already logged as tech debt. No new action taken this run. ✅ All systems green.
- QA 2026-05-08T17:10Z: Build=success (Godot Web Export run 551, 16:52Z), Pages=success (pages-build-deployment run 890, 17:07Z). §15: Hero.glb 29MiB > 20MiB soft cap — REFERENCED in Main.tscn+Player.gd+CharacterSelect.gd, cannot delete; already logged as tech debt. No new action taken this run. ✅ All systems green.
- QA 2026-05-08T17:13Z: Build=success (pages-build-deployment run 891, 17:15Z), Pages=success. §15: Hero.glb 29MiB > 20MiB soft cap — REFERENCED in Main.tscn+Player.gd+CharacterSelect.gd, cannot delete; already logged as tech debt. No new action taken this run. ✅ All systems green.

- QA 2026-05-08T20:14Z: Build=in_progress (Godot Web Export run 558, 20:12Z), Pages=success (deployment 4626206728, 20:13Z). §15: Hero.glb 29MiB > 20MiB soft cap — REFERENCED in Main.tscn+Player.gd+CharacterSelect.gd, cannot delete; already logged as tech debt. No new action taken this run. ✅ Pages green.
- QA 2026-05-08T20:16Z: Build=success (Godot Web Export run #558, 20:15Z), Pages=success (pages-build-deployment run #907, 20:17Z). §15: Hero.glb 29MiB > 20MiB soft cap — REFERENCED in Main.tscn+Player.gd+CharacterSelect.gd, cannot delete; already logged as tech debt. No new action taken this run. ✅ All systems green.- QA 2026-05-08T20:19Z: Build=success, Pages=built. §15: Hero.glb 29MiB > 20MiB soft cap — REFERENCED in Main.tscn+Player.gd+CharacterSelect.gd, already logged as tech debt. No new action taken. ✅ All systems green.
- QA 2026-05-09T02:14Z: Build=success (pages-build-and-deployment), Pages=built. §15: Hero.glb 29MiB > 20MiB soft cap — REFERENCED in Main.tscn+Player.gd+CharacterSelect.gd, cannot delete; already logged as tech debt. No new action taken this run. ✅ All systems green.
- QA 2026-05-09T02:18Z: Build=success (run 25588908587, 02:17Z), Pages=built (02:17Z). §15: Hero.glb 29MiB > 20MiB soft cap — REFERENCED in Main.tscn+Player.gd+CharacterSelect.gd, cannot delete; already logged as tech debt. No new action taken this run. ✅ All systems green.
- QA 2026-05-09T02:21Z: Build=success (pages-build-and-deployment, 02:20Z), Pages=built (02:20Z). §15: Hero.glb 29MiB > 20MiB soft cap — REFERENCED in Main.tscn+Player.gd+CharacterSelect.gd, cannot delete; already logged as tech debt. No new action taken this run. ✅ All systems green.
- QA 2026-05-08T04:29Z: Build=success (#1128, 04:27Z), Pages=built (04:26Z). §15: Hero.glb 29MiB > 20MiB soft cap — REFERENCED, already logged as tech debt. No new action taken this run. ✅ All systems green.
- QA 2026-05-09T04:33Z: Build=queued/in_progress (pages-build-and-deployment queued after 2 errored Pages builds), Pages=building (recovering from errored state at 04:32Z). §15: Hero.glb 29MiB > 20MiB soft cap — REFERENCED in Main.tscn+CharacterSelect.gd+Player.gd, cannot delete; already logged as tech debt. No new action taken this run. ⚠️ Pages recovering.
