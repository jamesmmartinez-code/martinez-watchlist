# Realm of Eldoria — Build Ledger

Running record of what's been built, what's deployed, what's next. Append new entries at the top.

Deploy command (run from your Mac terminal):
```
cd "/Users/jamesmartinez/Library/Application Support/Claude/local-agent-mode-sessions/794a2df1-963f-473e-b0d0-194a5b136adf/9d25261c-681d-4498-8c12-d926cbaa244a/local_cdbfb2a3-6ded-4fe9-8a31-53177f14881a/outputs" && bash full-deploy.sh
```

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

