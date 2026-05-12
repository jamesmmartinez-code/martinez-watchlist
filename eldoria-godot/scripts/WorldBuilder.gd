extends Node3D
class_name WorldBuilder
# Procedurally builds Briarwood Village with REAL PBR textures (PolyHaven CC0).
# Houses, timber-framed walls, thatched/tiled roofs, bark trees, mountain rock
# faces with snow caps, cobble paths, market stalls, lanterns, banners, NPCs.

@export var npc_scene: PackedScene = preload("res://assets/models/CesiumMan.glb")
# THEME §4 — silhouette-distinct NPC models. Each villager gets a hand-crafted
# (or hand-curated) GLB that reads as the right archetype from 30m. NPCs whose
# `name` is missing here fall through to `npc_scene` (CesiumMan placeholder),
# so wiring is additive and safe.
# WorldBuilder hardening 2026-05-06: switched const+preload() → var+load()
# so a missing or 0-byte GLB no longer takes the entire script offline. Empty
# world reports trace back to preload-of-missing-file aborting script compile.
var NPC_MODELS: Dictionary = {}  # populated in _ready

func _safe_load_glb(path: String) -> PackedScene:
	if not ResourceLoader.exists(path):
		push_warning("[WorldBuilder] missing GLB: " + path)
		return null
	var res: Resource = load(path)
	if res is PackedScene:
		return res as PackedScene
	push_warning("[WorldBuilder] not a scene: " + path)
	return null

func _populate_npc_models() -> void:
	NPC_MODELS = {
		"Elder Maeve":         _safe_load_glb("res://assets/models/npcs/elder_maeve.glb"),
		"Smith Edda":          _safe_load_glb("res://assets/models/npcs/smith_edda.glb"),
		"Mara the Merchant":   _safe_load_glb("res://assets/models/npcs/mushroom_merchant.glb"),
		"Herbalist Lyra":      _safe_load_glb("res://assets/models/npcs/herbalist_lyra.glb"),
		"Innkeeper Bram":      _safe_load_glb("res://assets/models/npcs/innkeeper_bram.glb"),
		"Stablemaster Roan":   _safe_load_glb("res://assets/models/npcs/stablemaster_roan.glb"),
		"Trainer Hala":        _safe_load_glb("res://assets/models/npcs/trainer_hala.glb"),
		"Village Guard":        _safe_load_glb("res://assets/models/npcs/warrior.glb"),
		"Farm Worker":          _safe_load_glb("res://assets/models/npcs/worker_girl.glb"),
		"Wandering Herbalist":  _safe_load_glb("res://assets/models/npcs/maeve.glb"),
	}
# Per-NPC scale tweak — different sources have different native heights.
const NPC_SCALES := {
	"Elder Maeve":         Vector3(1.10, 1.10, 1.10),
	"Smith Edda":          Vector3(1.05, 1.05, 1.05),
	"Mara the Merchant":   Vector3(1.10, 1.10, 1.10),
	"Herbalist Lyra":      Vector3(1.30, 1.30, 1.30),
	"Innkeeper Bram":      Vector3(1.20, 1.20, 1.20),
	"Stablemaster Roan":   Vector3(1.05, 1.05, 1.05),
	"Trainer Hala":        Vector3(1.10, 1.10, 1.10),
	"Village Guard":        Vector3(1.05, 1.05, 1.05),
	"Farm Worker":          Vector3(1.00, 1.00, 1.00),
	"Wandering Herbalist":  Vector3(1.10, 1.10, 1.10),
}
@export var npc_script: Script = preload("res://scripts/NPC.gd")

# Phase 26 — Chunked async world build (web-perf: stops 86s main-thread block)
signal build_progress(phase: String, pct: float)
signal build_complete()
@export var chunk_build_enabled: bool = true

var _buildings_built: bool = false
var _briarwood_root: Node3D = null
var _qb_layer: CanvasLayer = null
var _qb_panel: Panel = null
var _qb_player: Node3D = null
var _qb_list_root: VBoxContainer = null
var _qb_detail: RichTextLabel = null
var _qb_selected_id: String = ""

var _quest_marker_timer: Timer = null
var _quest_markers: Dictionary = {}

var _qh_layer: CanvasLayer = null
var _qh_panel: Panel = null
var _qh_label: RichTextLabel = null

var _bw_life_root: Node3D = null
var _bw_life_timer: Timer = null
var _bw_life_npcs: Array = []

var _shop_layer: CanvasLayer = null
var _shop_panel: Panel = null
var _shop_player: Node3D = null
var _shop_kind: String = ""
var _shop_gold_label: Label = null
var _shop_shop_list: VBoxContainer = null
var _shop_inv_list: VBoxContainer = null
var _shop_detail: RichTextLabel = null

var _craft_layer: CanvasLayer = null
var _craft_panel: Panel = null
var _craft_player: Node3D = null
var _craft_list: VBoxContainer = null
var _craft_detail: RichTextLabel = null

var _interior_root: Node3D = null
var _interior_kind: String = ""
var _exterior_return_pos: Vector3 = Vector3.ZERO

var _schedule_timer: Timer = null
var _last_night_state: bool = false
var _town_time: float = 0.35

var _dlg_layer: CanvasLayer = null
var _dlg_panel: Panel = null
var _dlg_player: Node3D = null
var _dlg_title: Label = null
var _dlg_text: RichTextLabel = null
var _dlg_choices: VBoxContainer = null

var _fade_layer: CanvasLayer = null
var _fade_rect: ColorRect = null
var _fade_tween: Tween = null

var _music_player: AudioStreamPlayer = null
var _current_music_id: String = ""

var _tutorial_step: int = 0
var _tutorial_done: bool = false
var _mayor_intro_ran: bool = false   # Phase 21 — mayor intro fires exactly once

# Phase 22 — tutorial polish
var _tutorial_last_progress_time: float = 0.0
var _tutorial_tick_timer: Timer = null
var _arrow_root: Node3D = null
var _arrow_label: Label3D = null
var _arrow_mesh: MeshInstance3D = null
var _arrow_target: Node3D = null
var _bark_cd: Dictionary = {}   # "bark|<key>" -> next_allowed_time (secs)
# Phase 24 — cached MultiMesh-ready meshes (lazy-init via getters)
var _bw_fence_post_mesh: CylinderMesh = null
var _bw_bench_mesh: BoxMesh = null
var _bw_crate_mesh: BoxMesh = null
var _bw_barrel_mesh: CylinderMesh = null
var _bw_woodpile_mesh: BoxMesh = null
var _trail_root: Node3D = null
var _trail_last_update: float = 0.0

# ─── THEME §1, §11, §12 — Whisperwood asset wire-up ──────────────────────────
# Sketchfab CC-BY tree GLBs (oak / pine / bush / dead) replacing the procedural
# blob trees that previously made every tree look like the same lumpy sphere
# stack. Variants are picked by weight per scatter pass; if `load()` returns
# null (asset not importable yet, missing on disk, etc.) `_make_glb_tree`
# returns false and `_make_tree` falls through to the legacy procedural path
# so the world NEVER spawns empty.
const TREE_VARIANTS: Array = [
	{"path": "res://assets/models/trees/oak_tree.glb",  "weight": 0.45,
		"scale_min": 0.55, "scale_max": 0.95, "kind": "oak"},
	{"path": "res://assets/models/trees/pine_tree.glb", "weight": 0.30,
		"scale_min": 0.60, "scale_max": 1.05, "kind": "pine"},
	{"path": "res://assets/models/trees/bush.glb",      "weight": 0.20,
		"scale_min": 0.55, "scale_max": 0.95, "kind": "bush"},
	{"path": "res://assets/models/trees/dead_tree.glb", "weight": 0.05,
		"scale_min": 0.50, "scale_max": 0.85, "kind": "dead"},
]
# Sketchfab CC-BY boulder GLB used by `_scatter_rocks` in place of the lumpy
# sphere primitives. Same fallback contract as TREE_VARIANTS above.
const BOULDER_GLB_PATH: String = "res://assets/models/props/boulder.glb"

# ─── THEME §12 — Whisperwood undergrowth + village dressing GLBs ────────────
# Three currently-unused CC-BY GLBs that bring the world from "open lawn with
# trees" to "lived-in fantasy forest". Loaded the same way as TREE_VARIANTS:
# any missing asset is silently skipped so the world never crashes.
const FERN_GLB_PATH: String     = "res://assets/models/props/fern.glb"
const MUSHROOM_GLB_PATH: String = "res://assets/models/props/mushroom_red.glb"
const BARREL_GLB_PATH: String   = "res://assets/models/props/wooden_barrel.glb"
# Phase 26 fix: lantern.glb was a mis-placed witch-hat model — disabled until
# a real lantern GLB is imported. Empty string → procedural fallback always fires.
const LANTERN_GLB_PATH: String  = ""  # was "res://assets/models/props/lantern.glb"
# Env: 2026-05-06 — wire up two more CC-BY GLBs that were sitting unused on
# disk. Same fallback contract: if the asset isn't loadable the legacy
# procedural primitive path runs, so the village never spawns without a
# hearth or well. (THEME §1, §11)
const CAMPFIRE_GLB_PATH: String = "res://assets/models/props/campfire.glb"
const WELL_GLB_PATH: String     = "res://assets/models/props/stone_well.glb"
# Env: 2026-05-06 — wire the last unused prop GLB. The procedural
# windmill (cone-stack tower + box blades) reads as a primitive next
# to the new GLB-bodied campfire/well/lantern. Same fallback contract:
# any missing asset silently falls through to the procedural primitive
# path so the village always has its mill. (THEME §1, §11, §12)
const WINDMILL_GLB_PATH: String = "res://assets/models/props/windmill.glb"

# ─── PBR material cache ──────────────────────────────────────────────────────
var _mat_cache: Dictionary = {}
var _sub_cache: Dictionary = {}  # Substance .tres material cache

func _pbr_mat(albedo_path: String, normal_path: String = "", rough_path: String = "",
		uv_scale: Vector3 = Vector3(1, 1, 1), tint: Color = Color(1, 1, 1)) -> StandardMaterial3D:
	var key := albedo_path + "|" + normal_path + "|" + rough_path + "|" + str(uv_scale) + "|" + str(tint)
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := StandardMaterial3D.new()
	if ResourceLoader.exists(albedo_path):
		m.albedo_texture = load(albedo_path)
	m.albedo_color = tint
	if normal_path != "" and ResourceLoader.exists(normal_path):
		m.normal_enabled = true
		m.normal_texture = load(normal_path)
		m.normal_scale = 1.0
	if rough_path != "" and ResourceLoader.exists(rough_path):
		m.roughness_texture = load(rough_path)
	else:
		m.roughness = 0.85
	m.uv1_scale = uv_scale
	m.metallic = 0.0
	m.metallic_specular = 0.4
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_mat_cache[key] = m
	return m

# Loads a Substance .tres StandardMaterial3D, duplicates it, and applies the
# requested UV scale. Falls back to null so callers can chain _pbr_mat().
func _sub_mat(tres_path: String, uv: float = 2.0) -> StandardMaterial3D:
	var key := tres_path + "|" + str(uv)
	if _sub_cache.has(key):
		return _sub_cache[key]
	if not ResourceLoader.exists(tres_path):
		push_warning("[WorldBuilder] _sub_mat: missing " + tres_path)
		return null
	var base = ResourceLoader.load(tres_path, "StandardMaterial3D")
	if not (base is StandardMaterial3D):
		push_warning("[WorldBuilder] _sub_mat: not StandardMaterial3D at " + tres_path)
		return null
	var m: StandardMaterial3D = base.duplicate()
	# Guard: albedo_texture null means images aren't in the .pck yet
	# (missing .import sidecars) — fall back to _pbr_mat() instead of
	# serving a textureless white material.
	if m.albedo_texture == null:
		push_warning("[WorldBuilder] _sub_mat: albedo null (images not imported?) at " + tres_path)
		return null
	m.uv1_scale = Vector3(uv, uv, 1.0)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_sub_cache[key] = m
	return m

# Convenience accessors
func MAT_GRASS(uv := 30.0) -> StandardMaterial3D:
	var m = _sub_mat("res://assets/textures/terrain/plateau_grass/plateau_grass.tres", uv)
	if m: return m
	return _pbr_mat("res://assets/textures/grass/grass_diff.jpg",
		"res://assets/textures/grass/grass_norm.jpg",
		"res://assets/textures/grass/grass_rough.jpg",
		Vector3(uv, uv, 1))

func MAT_WOOD(uv := 1.5) -> StandardMaterial3D:
	var m = _sub_mat("res://assets/textures/arch/wood_beam/wood_beam.tres", uv)
	if m: return m
	return _pbr_mat("res://assets/textures/wood/wood_diff.jpg",
		"res://assets/textures/wood/wood_norm.jpg",
		"res://assets/textures/wood/wood_rough.jpg",
		Vector3(uv, uv, 1), Color(0.85, 0.66, 0.45))

func MAT_DARK_WOOD(uv := 1.5) -> StandardMaterial3D:
	var m = _sub_mat("res://assets/textures/arch/wood_flooring/wood_flooring.tres", uv)
	if m: return m
	return _pbr_mat("res://assets/textures/wood/wood_diff.jpg",
		"res://assets/textures/wood/wood_norm.jpg",
		"res://assets/textures/wood/wood_rough.jpg",
		Vector3(uv, uv, 1), Color(0.35, 0.22, 0.13))

func MAT_ROOF(uv := 2.5) -> StandardMaterial3D:
	var m = _sub_mat("res://assets/textures/arch/roof_moss_tiles/roof_moss_tiles.tres", uv)
	if m: return m
	return _pbr_mat("res://assets/textures/thatch/shingle_diff.jpg",
		"res://assets/textures/thatch/shingle_norm.jpg",
		"",
		Vector3(uv, uv, 1), Color(0.7, 0.42, 0.32))

func MAT_STONE(uv := 2.0) -> StandardMaterial3D:
	var m = _sub_mat("res://assets/textures/arch/curtain_wall_stone/curtain_wall_stone.tres", uv)
	if m: return m
	return _pbr_mat("res://assets/textures/stone/stone_diff.jpg",
		"res://assets/textures/stone/stone_norm.jpg",
		"res://assets/textures/stone/stone_rough.jpg",
		Vector3(uv, uv, 1))

func MAT_PATH(uv := 4.0) -> StandardMaterial3D:
	var m = _sub_mat("res://assets/textures/terrain/briarwood_path/briarwood_path.tres", uv)
	if m: return m
	return _pbr_mat("res://assets/textures/stone/stone_diff.jpg",
		"res://assets/textures/stone/stone_norm.jpg",
		"res://assets/textures/stone/stone_rough.jpg",
		Vector3(uv, uv, 1), Color(0.72, 0.68, 0.62))

func MAT_FOUNDATION(uv := 2.0) -> StandardMaterial3D:
	var m = _sub_mat("res://assets/textures/arch/house_foundation/house_foundation.tres", uv)
	if m: return m
	return _pbr_mat("res://assets/textures/stone/stone_diff.jpg",
		"res://assets/textures/stone/stone_norm.jpg",
		"res://assets/textures/stone/stone_rough.jpg",
		Vector3(uv, uv, 1))

func MAT_PLASTER(uv := 3.0) -> StandardMaterial3D:
	# Whitewashed plaster for building wall surfaces — half-timbered look
	# when combined with MAT_DARK_WOOD corner beams.
	var m = _sub_mat("res://assets/textures/arch/whitewashed_plaster/whitewashed_plaster.tres", uv)
	if m: return m
	return _pbr_mat("res://assets/textures/stone/stone_diff.jpg",
		"res://assets/textures/stone/stone_norm.jpg",
		"",
		Vector3(uv, uv, 1), Color(0.94, 0.91, 0.84))

func MAT_BARK(uv := 2.0) -> StandardMaterial3D:
	return _pbr_mat("res://assets/textures/bark/bark_diff.jpg",
		"res://assets/textures/bark/bark_norm.jpg",
		"",
		Vector3(uv, uv, 1))

func MAT_ROCK(uv := 1.0) -> StandardMaterial3D:
	return _pbr_mat("res://assets/textures/rock/rock_diff.jpg",
		"res://assets/textures/rock/rock_norm.jpg",
		"",
		Vector3(uv, uv, 1))

func MAT_SNOW(uv := 1.0) -> StandardMaterial3D:
	return _pbr_mat("res://assets/textures/snow/snow_diff.jpg",
		"res://assets/textures/snow/snow_norm.jpg",
		"",
		Vector3(uv, uv, 1), Color(0.95, 0.96, 1.0))

func MAT_LEAF(tint: Color) -> StandardMaterial3D:
	# Stylized leaves — slight subsurface look
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	m.roughness = 0.78
	m.metallic = 0.0
	# Simulate sub-surface scattering with rim emission
	m.rim_enabled = true
	m.rim = 0.4
	m.rim_tint = 0.6
	return m

# ─── Village NPCs ────────────────────────────────────────────────────────────
# REFINE: each NPC now carries 4 mood-dependent dialogue variants
# (morning / midday / evening / night). The single `line` is kept as a
# fallback for systems that haven't been taught the variant lookup yet.
# Personality details: Maeve fears the wolves, Edda wishes the dew lasted,
# Mara grudges miscounters, Lyra remembers her mother's garden, Bram has a
# catchphrase about three valleys, Roan trusts horses over men, Hala says
# strength is loud and mastery is quiet.
const NPCS = [
	{"name":"Elder Maeve",       "role":"quest",   "pos":Vector3(  6,  0,  3), "tint":Color(0.6,0.4,0.85),
		"line":"Trouble brews in the Whisperwood. Seek out the Goblin Warlord.",
		"lines":[
		"Ah, traveler. Trouble brews in the Whisperwood — seek out the Goblin Warlord.",
		"You smell of pine. Good. Goblins do not. Mind the Warlord.",
		"I sleep poorly when wolves howl. I hope your blade keeps mine quiet.",
		"You should be inside. Even my whispers travel further after dark.",
		],
		"warm_flag":"first_quest_done",
		"warm_lines":[
		"You came back. The forest sleeps lighter for it. Tea by the hearth?",
		"Goblins still scratch our edges, but with you about, they keep their distance.",
		"My old bones thank you — I sleep deeper since you cleared the wood.",
		"Walk safe — though even the wolves walk softer since your last errand.",
		],
		# COMPOUND (run 4): faction-pressure tier. Maeve gave the cleansing quest
		# and feels the Whisperwood as a fellow inhabitant. The faction tier only
		# fires when warm_flag (first_quest_done) is NOT set — i.e. the player
		# tackled Mara's bounty BEFORE Maeve's cleansing. In that path, ears for
		# Mara has already dropped goblin pressure to 0.85 and Maeve notices
		# (threshold 0.9 → triggers on any goblin-reduction quest pre-cleansing).
		# Once cleansing is done, warm_flag tier wins and personal warmth narrates.
		"warm_faction_id":"whisperwood_goblins",
		"warm_faction_below":0.9,
		"warm_faction_lines":[
		"The Whisperwood breathes easier this dawn. Even the crows fly bolder.",
		"You hear that midday hush? That's a forest with fewer wicked things in it.",
		"The light slants through the trees and not a goblin lantern in sight — beautiful.",
		"Owls again at last — they only sing when the wood is theirs again. Sleep well.",
		],
		# COMPOUND (run 9 — JSON dialogue tree): opt Maeve into the JSON-tree
		# resolver. NPC.gd consults `data/dialogue/elder_maeve.json` first; on
		# miss (no matching predicate) it falls back to the variants above.
		# Lights up `low_health_player`, `boss_slain`, `after_first_quest_complete`,
		# plus seasonal hooks (`longnight_vigil`, `honeysong_eve`) the day a
		# festival/calendar system lands. Lines above are kept as fallback so
		# nothing regresses if the JSON ever fails to load.
		# COMPOUND (run 11 — schedule): morning at the well, midday at her hut,
		# evening at the hearth telling stories, night back at the hut door.
		"schedule":[Vector3( 0.6, 0,  5.0), Vector3( 6.0, 0,  3.0), Vector3( 0.8, 0, -1.6), Vector3( 6.0, 0,  3.0)],
		# COMPOUND (run 16 — Builder): visit-memory tier. After three quiet
		# hellos with no specific deed completed, Maeve speaks like she knows
		# you. Threshold 3 fires on the third visit (run 16 wiring includes
		# the triggering visit in the count). The four-bucket time-of-day
		# shape carries through; only the language shifts toward familiarity.
		# Note this tier sits below faction-pressure: if the Whisperwood
		# pressure has dropped, the faction-tier line wins (the world-state
		# lines are louder than the relationship cadence).
		"memory_visits_min":3,
		"memory_lines":[
		"Three mornings now you've come by — I count. The kettle's on, dear.",
		"You sit a while, hm? Even old Maeve enjoys company at midday.",
		"You've a way of finding my doorstep at dusk. Sit — the bread's still warm.",
		"Late again? My door knows your knock by now. Come in from the cold.",
		],
		# REFINE: character — ambient barks THEME §12 MOTION & LIFE. Maeve mutters
		# to her herb bundles and the Whisperwood. Interval 28–42s: she speaks slowly.
		"bark_lines":[
		"Whisperwood's listening today. Can you hear it?",
		"These roots remember older names than ours.",
		"A good healer knows when to let the wound breathe.",
		"The crow flew north twice this morning. Mark that.",
		"Mmm. Wolf-sage is blooming. Strange for this season.",
		],
		"bark_min":28.0, "bark_max":42.0,
	# run-35: relationship tier lines (score >= 2).
	"relationship_min":2,
	"relationship_lines":[
   "You've a generous heart. The Whisperwood remembers kindness.",
   "Gifts freely given — that's the oldest magic there is.",
   "Come for the company, stay for the herbs. Always welcome.",
   "I've watched folk give and take. You're the giving kind. Rare.",
	],
		"defense_lines": [
		"Your blade rings true, child.",
		"The spirits guided your arm.",
		"Eldoria thanks you.",
		],
		"use_json_dialogue":true},
	{"name":"Smith Edda",        "role":"smithy",  "pos":Vector3( -6,  0,  3), "tint":Color(0.7,0.25,0.18),
		"line":"Bring me ore and I'll forge you a blade.",
		"lines":[
		"Bring me ore. I forge best when the dew's still on the iron.",
		"*hammer-clang* — Steel won't shape itself. Got ore, or just standing there?",
		"Forge cools by sundown. Last orders, friend.",
		"Coals are banked. Come back when you've slept.",
		],
		# COMPOUND (run 9 — JSON dialogue tree): opt Edda into the JSON-tree
		# resolver. NPC.gd consults `data/dialogue/smith_edda.json` first; on
		# miss falls back to the four lines above. Lights up `low_health_player`,
		# `boss_alive`, `boss_slain`, `after_first_quest_complete`, plus seasonal
		# hooks (`longnight_vigil`, `spring_first_warm_day`).
		# COMPOUND (run 11 — schedule): tiny shifts around the forge — Edda is
		# the smithy and never strays far. Quenching trough at night.
		"schedule":[Vector3(-5.4, 0,  3.0), Vector3(-6.0, 0,  3.0), Vector3(-6.0, 0,  2.4), Vector3(-6.4, 0,  3.4)],
		# REFINE: character — ambient barks THEME §12 MOTION & LIFE. Edda grumbles
		# at the forge and talks to her work. Interval 20–32s: she's industrious.
		"bark_lines":[
		"Iron remembers every strike. So does Edda.",
		"Bellows need air — just like good steel needs time.",
		"This blade'll hold. Unlike the last apprentice.",
		"Sparks mean it's working. No sparks, start over.",
		"Morning dew cooled my tongs. Nature's temper. I respect it.",
		"A dull blade is just a heavy stick. Don't bring me heavy sticks.",
		],
		"bark_min":20.0, "bark_max":32.0,
		"defense_lines": [
		"Strong arm! My forge respects that.",
		"I'll sharpen your blade free of charge.",
		"Didn't think you had it in you.",
		],
		"use_json_dialogue":true},
	{"name":"Mara the Merchant", "role":"shop",    "pos":Vector3(  3,  0, -5), "tint":Color(0.7,0.5,0.25),
		"line":"There's a bounty on goblin raiders — bring me proof of six and I'll pay handsome.",
		"lines":[
		"Six goblin ears, that's the bounty. I keep tally; I never miscount. Never.",
		"Trade me proof of six raiders and you'll walk out richer than you walked in.",
		"Hurry — I count my coin twice before bed and I dislike being interrupted.",
		"Shop's shut. Knock again at sunrise unless your purse has wings.",
		],
		"warm_flag":"good_customer",
		"warm_lines":[
		"Word's out: Mara pays well. You set my ledger humming. Welcome back.",
		"Six ears as promised — coin's heavy in your pouch and in mine. Trade well.",
		"I'd shutter for the day, but for you I'll uncross my arms a moment longer.",
		"Late again, eh? For my favorite buyer, the till's not quite shut.",
		],
		# COMPOUND (run 11 — schedule): market stall during the day, drinks at
		# the inn at night. Closes the believable-merchant loop with Bram.
		"schedule":[Vector3( 2.5, 0,  0.0), Vector3( 2.5, 0,  0.0), Vector3( 3.0, 0, -5.0), Vector3( 8.6, 0, -2.0)],
		# REFINE: character — ambient barks THEME §12 MOTION & LIFE. Mara counts
		# stock and mutters about coin. Interval 18–30s: a merchant never stops.
		"bark_lines":[
		"Four potions, three salves, two satchels. Good. Good.",
		"Someone always wants more and pays less. Someone named Everyone.",
		"I did not carry this stock three valleys for BROWSING.",
		"Hmm. Crystal shards are moving faster this week.",
		"Counts right. Mara's counts always right.",
		"If it gleams, it sells. If it stinks, it heals. Mara knows both.",
		],
		"bark_min":18.0, "bark_max":30.0},
	{"name":"Herbalist Lyra",    "role":"alchemy", "pos":Vector3( -3,  0, -5), "tint":Color(0.4,0.7,0.35),
		"line":"I need 4 wolf pelts for a healing salve. Bring them, and the salve is yours.",
		"lines":[
		"Four wolf pelts for a healing salve — wolves are bolder at dawn, mind.",
		"Smell that? Marshmint. Brings me back to my mother's garden — long lost now.",
		"Bring me pelts before the moss closes. It only opens by daylight.",
		"Owls are louder than wolves tonight. Bad sign. Travel close to lanterns.",
		],
		"warm_flag":"trusts_player",
		"warm_lines":[
		"Your pelts cured well — I owe you the salve, and a stronger one besides.",
		"Ask if you need a greater potion. For you, the moss opens a little longer.",
		"The garden in my memory has one more bloom now. Yours, friend.",
		"Owls still cry, but you've made my shelves richer. Sleep well.",
		],
		# COMPOUND (run 3 follow-up): world-flag warmed tier. Fires when the
		# village knows the recipe (`lyra_potion_brew`) even if the player
		# personally hasn't pelted yet. Lower priority than `warm_flag` above.
		"warm_world_flag":"lyra_potion_brew",
		"warm_world_lines":[
		"The greater salve is brewing — come back at dusk for the first batch.",
		"Word of the salve has reached two villages. I'll need more pelts soon.",
		"Lanterns are lit late. The mortar is loud. Good problems, these.",
		"Even at this hour the kettle bubbles. Try a sip, on the house.",
		],
		# COMPOUND (run 11): Lyra joins Maeve / Edda / Bram on the JSON-tree
		# resolver — fourth opt-in. `data/dialogue/herbalist_lyra.json` carries
		# default + tod x4 + low_health_player + boss_alive + boss_slain +
		# high_renown + warmed-tier hooks. With this flip plus the new
		# `World.player_renown` field landing in the same run, her `high_renown`
		# line ("Mara mentioned a name on her last circuit. So did Roan…")
		# becomes the FIRST renown-gated line to actually fire in-game. The
		# legacy `lines` / `warm_lines` / `warm_world_lines` arrays above stay
		# as the no-tree fallback so absolutely nothing regresses.
		# COMPOUND (run 11 — schedule): forages at the treeline at dawn (the
		# marshmint she eulogizes in her morning line is at the forest edge),
		# then back to her hut for the rest of the day.
		"schedule":[Vector3(-7.5, 0, -7.5), Vector3(-3.0, 0, -5.0), Vector3(-3.0, 0, -4.4), Vector3(-3.0, 0, -5.0)],
		# REFINE: character — ambient barks THEME §12 MOTION & LIFE. Lyra hums and
		# talks to her plants. Interval 25–40s: she's contemplative.
		"bark_lines":[
		"Feverfew dries best on the east wall. Mother was right.",
		"Hmm. This batch smells of the deep wood. Strong.",
		"Three pinches, not two. Always three.",
		"The meadow iris is early this year. Rain's coming.",
		"These roots won't grind themselves… actually, let me check.",
		"Poultice, poultice, tincture, poultice. Busy season.",
		],
		"bark_min":25.0, "bark_max":40.0,
		"use_json_dialogue":true},
	{"name":"Innkeeper Bram",    "role":"inn",     "pos":Vector3( 10,  0, -2), "tint":Color(0.8,0.55,0.30),
		# COMPOUND (run 19 — Builder): swap the legacy "pull up a stool" line for
		# the Bram-issued bounty pitch. Bram's role `inn` was QUEST-BLANK in
		# WorldBuilder runs 1-18 — the Accept Quest button never appeared on his
		# dialogue panel because `_quest_for_role("inn")` returned `{}`. With
		# World.QUEST_CATALOG run-19 entry `wolf_heart_for_bram`, the resolver
		# now hits, and `line` is the offer text shown when the player opens
		# dialogue. Pattern matches Mara's ear bounty, Lyra's pelt fetch, Roan's
		# fang bounty, and Hala's wolf-form drill. Old "pull up a stool" line
		# preserved as `lines[0]` so it still cycles in the time-of-day pool.
		"line":"Wolves spoil the bards' songs. Bring me 3 wolf hearts and the deep barrel's yours.",
		"lines":[
		"*polishes a mug* — Stew's on. Pull up a stool, rest your bones.",
		"Bards lie about half their songs. The other half are mine.",
		"Best ale in three valleys. The other two valleys have no ale, mind.",
		"Bed's warm. Fire's banked. Stay if you've nowhere safer.",
		],
		# COMPOUND (run 19 — Builder): Bram's `warm_flag` tier — Tier 2 in
		# NPC.gd's dialogue stack, fires above his existing memory tier (Tier
		# 5, run 16). `nights_quiet` is set as the npc_flag on the
		# wolf_heart_for_bram consequence, so these lines unlock the moment
		# that quest turns in. Promotes Bram from a memory-only NPC (run 16)
		# to a full warm_flag + memory NPC — same dialogue depth as Maeve.
		# Bram's village role is the rumor exchange: when the wolves quiet,
		# he hears the SONG come back to the road first. Lines lean on the
		# bards-and-mead motif from his existing `lines` (THEME §7 "voice:
		# warm gravitas") so the warm tier reads as the SAME Bram, just
		# warmer — not a different character. Tier 2 (warm_flag) ranks above
		# tier 5 (memory) so once the quest is in, returning patrons read the
		# warm lines first; on warm_flag miss the memory tier still fires for
		# the cold-rep loop.
		"warm_flag":"nights_quiet",
		"warm_lines":[
		"Three hearts to the hearth — and the bards finished their set last night, first time in months.",
		"My deep barrel's yours, friend. Pour heavy; the howls won't drown the lute now.",
		"Fire's high and the door's open later these evenings. Your work — sit.",
		"Even past midnight the singing carries to the road. Quiet enough now. Stay safe out there.",
		],
		# COMPOUND (run 10 — third JSON opt-in): Bram joins Maeve & Edda on the
		# JSON-tree resolver. `data/dialogue/innkeeper_bram.json` carries 15 keys
		# including all four boss-state lines (the Long Lantern is the village's
		# rumor exchange; he learns of the Warlord before Edda sometimes), the
		# warmest `low_health_player` line in the village ("Sit. SIT. *guides you
		# to the bench* — No coin tonight"), and the `honeysong_eve` festival
		# hook. With Boss.gd's run-10 wire of `seen_warlord` / `warlord_dead`,
		# all THREE opted-in NPCs now speak distinct boss_alive AND boss_slain
		# lines on the same world tick — Maeve grieves the Whisperwood, Edda
		# grieves the saber she forged, Bram pours without being asked. The
		# variants above stay as the legacy fallback so nothing regresses.
		# COMPOUND (run 11 — schedule): sweeps the doorstep at dawn, peak
		# service in the evening when Mara joins him for a drink.
		"schedule":[Vector3( 9.4, 0, -1.0), Vector3(10.0, 0, -2.0), Vector3( 9.0, 0, -2.0), Vector3(10.0, 0, -2.5)],
		# REFINE: character — ambient barks THEME §12 MOTION & LIFE. Bram talks to
		# himself about the inn, ale, and gossip. Interval 22–35s: publican rhythm.
		"bark_lines":[
		"Mug's clean. Mug's always clean. That's the standard.",
		"Three valleys, three ales, one Bram. That's the legend.",
		"Fire needs a log. Fire always needs a log.",
		"Roan looked worried this morning. I'll pull him an extra.",
		"Trade's good when the road's safe. Road's been good lately.",
		"Maeve ordered chamomile again. Worried woman drinks chamomile.",
		],
		"bark_min":22.0, "bark_max":35.0,
	# run-35: relationship tier lines (score >= 2).
	"relationship_min":2,
	"relationship_lines":[
   "The generous one! Your coin spends well but gifts linger longer.",
   "You bring gifts and drink both? I keep a chair warm for you.",
   "Bram never forgets a kind gesture. Nor do his prices.",
   "A kind hand opens more doors than a full purse. You've both.",
	],
		# COMPOUND (run 16 — Builder): visit-memory tier. Bram is the village
		# rumor-exchange — by the third pull-up he's calling you a regular.
		# Threshold 3 mirrors Maeve so cross-NPC pacing matches; tune individual
		# NPCs up or down as authored relationships tighten or loosen.
		"memory_visits_min":3,
		"memory_lines":[
		"Same stool by the window again? Mug's already on its way, friend.",
		"You're a regular now. I keep the second-best chair clear at midday.",
		"Sundown brings my favorite drinker back. Stew's better tonight — try it.",
		"Fire's low, but I'd never bank it before YOU walked in. Sit, sit.",
		],
		"defense_lines": [
		"Drinks are on me tonight!",
		"I've never seen fighting like that.",
		"The whole inn saw what you did.",
		],
		"use_json_dialogue":true},
	{"name":"Stablemaster Roan", "role":"stable",  "pos":Vector3(-10,  0, -2), "tint":Color(0.55,0.45,0.25),
		# COMPOUND (run 17): `line` becomes the bounty pitch now that Roan is a
		# questgiver (`wolf_fang_for_roan`, role `stable`). Pattern matches Mara's
		# ear bounty and Lyra's pelt fetch — `line` is the offer text shown when
		# the player accepts; `lines` remain the time-of-day greetings the player
		# hears between accepting and turning in.
		"line":"Wolves nip my mares again. Bring me 5 wolf fangs and the road's safer.",
		"lines":[
		"Faster mounts, fewer ambushes. Pick your steed before sun's up.",
		"I trust my horses more than most men. They've never lied to me.",
		"Sun's down — saddle up only if your errand can't wait.",
		"Riding by moonlight? Bold. Or fool. Or both. Take the gray mare.",
		],
		# COMPOUND (run 17): Roan's `warm_flag` tier — Tier 2 in NPC.gd's
		# dialogue stack, fires above his existing run-8 faction-tier (Tier 4).
		# `first_bounty_done` is set as the npc_flag on the wolf_fang_for_roan
		# consequence, so these lines unlock the moment that quest turns in.
		# Promotes Roan from a faction-only NPC (run 8) to a full faction +
		# warm_flag NPC — same dialogue depth as Mara (`good_customer`) and
		# Lyra (`trusts_player`). Composes with run-6 wolf spawn density
		# (3 → 2 wolves) and run-7/8 adaptive pacing on the surviving pack.
		"warm_flag":"first_bounty_done",
		"warm_lines":[
		"Five fangs as promised — that bounty's coin is yours, and the road thanks you.",
		"You proved you can ride hard and fight harder. Pick any saddle on the rack.",
		"Pippin nuzzled me at sunset — first time since spring. Your work, friend.",
		"The mares slept clean through the night. I owed you a tip; here's two.",
		],
		# COMPOUND (run 21 — Builder): warm_world_flag tier (Tier 3 in NPC.gd's
		# dialogue stack, between Tier 2 warm_flag and Tier 4 warm_faction).
		# Reads `bandits_emergent` — the world flag set by World.update_bandit_
		# pressure() when the inverse-derived bandit boldness crosses 0.40.
		# Roan is the natural narrator for this tier: he's the road-traveler
		# who saddles the player every visit, and his existing Tier 4 already
		# speaks "fewer howls means fewer flinches on the road" — so when those
		# flinches drop AND opportunistic bandits creep in, Roan's voice is
		# what tells the player the road's NEW shape. Composes with the
		# existing 4-tier stack: warm_flag (first_bounty_done) wins on Roan's
		# first wolf bounty turn-in; warm_world_flag (bandits_emergent) wins
		# when the player has tamed enough of the woods that bandits surface;
		# warm_faction_id (dire_wolves < 0.5) wins as the wolves recede; legacy
		# `lines` time-of-day greetings run as default. Note these lines speak
		# to a threat that's EMERGING — they precede actual bandit enemies on
		# the map (the road-spawn pattern is the next Builder run's hook).
		# That ordering is intentional: dialogue plants the seed BEFORE the
		# first bandit ambush, so the player has narrative permission to
		# expect the encounter rather than being blindsided.
		"warm_world_flag":"bandits_emergent",
		"warm_world_lines":[
		"Mares are calm — too calm. Heard a saddle-bell on the south road last night that wasn't ours.",
		"Three travelers came in light. Said they paid a 'toll' to a hooded fellow at the crossroads. We don't keep tollkeepers here, friend.",
		"Quiet woods bring quieter trouble. Keep one eye on the brush when you ride out at dusk.",
		"Wolves used to chase off the wrong sort. Now? Watch the leather-cloaked ones. They smell coin where coin used to be safe.",
		],
		# COMPOUND (run 29 — Builder, Backlog #9): road-defense cleared tier.
		# warmed_world_flag fires ONLY when warm_world_flag (bandits_emergent)
		# is NOT active — so these lines play precisely when the road has been
		# actively defended (score >= 3 kills → bandit_road_cleared flag) but
		# bandits have NOT yet emerged at boldness >= 0.40. The player has
		# pre-empted the threat. THEME §1 consequence: Roan notices.
		# Four time-of-day bucket lines (morning/midday/evening/night) so
		# each visit gets a fresh voice. THEME §12: Roan's gratitude shifts
		# with the light — morning relief, midday confidence, evening hope,
		# night rest.
		"warmed_world_flag":"bandit_road_cleared",
		"warmed_world_lines":[
		"South road's been clean since you patrolled it. Pippin's been past the gate twice this morning.",
		"Heard you put down more than a few on the road. The merchants ride easier. So do I.",
		"The hooded ones haven't shown in days. That's your work, isn't it. Good work.",
		"Quietest night in a fortnight. Mares slept straight through. Whatever you did on that road — keep it up.",
		],
		# COMPOUND (run 8): faction-pressure tier on `dire_wolves`. Originally
		# this comment claimed Roan had "no warm_flag and no warm_world_flag"
		# — that was true through run 16. Run 17 added warm_flag, run 21 added
		# warm_world_flag. Roan is now a 4-TIER NPC (memory + warm_flag +
		# warm_world_flag + faction-pressure) — the densest dialogue stack in
		# the village. The faction-pressure tier still smoke-tests the
		# 4-tier dialogue stack as the LOWEST-priority warm channel. Threshold 0.5 mirrors the run-6 wolf-spawn first
		# cliff (`pelt_for_lyra` drops `dire_wolves` 0.5 → 0.4 on completion),
		# so Roan starts speaking the moment any wolf-reducing quest ships.
		# Pairs with run-6 spawn density and run-7 adaptive cooldown — the
		# same scalar now drives Roan dialogue + wolf count + wolf pacing,
		# closing the FIVE-consumer compound on `dire_wolves` (NPC.gd reads
		# it twice — Maeve via `whisperwood_goblins`, Roan via this — and
		# WorldBuilder + Enemy.gd each read it once).
		"warm_faction_id":"dire_wolves",
		"warm_faction_below":0.5,
		"warm_faction_lines":[
		"The mares slept through the night, friend. First time in a season — that's your doing.",
		"Look — Pippin's grazing past the fence again. He only does that when the woods are kind.",
		"Saddle's lighter at dusk these days. Fewer howls means fewer flinches on the road.",
		"Quiet enough to hear the owls now. The wolves used to drown them out. Ride safe.",
		],
		# COMPOUND (run 11 — schedule): brushes a horse outside the stable in
		# the morning, leads the team in for the evening.
		"schedule":[Vector3(-9.0, 0, -1.0), Vector3(-10.0, 0, -2.0), Vector3(-10.0, 0, -3.0), Vector3(-10.0, 0, -2.0)],
		# REFINE: character — ambient barks THEME §12 MOTION & LIFE. Roan talks to
		# his horses and the road. Interval 20–34s: stable work is constant.
		"bark_lines":[
		"Easy, Pippin. Easy. Road's still quiet.",
		"Good mare. Good. You heard the wolves last night too, hm?",
		"South road's dry. That'll be mud by sundown — felt the air.",
		"Saddle this side, brush that side. Order matters.",
		"Three travelers came through smelling of fear. I said nothing.",
		"Horses know. Before men know, horses know.",
		],
		"bark_min":20.0, "bark_max":34.0,
		"use_json_dialogue":true},
	{"name":"Trainer Hala",      "role":"trainer", "pos":Vector3(  0,  0, -10), "tint":Color(1.0,0.65,0.20),
		# COMPOUND (run 18 — Builder): swap the legacy "spirit" koan for the
		# Hala-issued bounty pitch. Same role used to query World.QUEST_CATALOG
		# via `_quest_for_role("trainer")` → `wolf_form_with_hala`, so the
		# bounty drops onto the talk-line the moment the player opens dialogue.
		# Old spirit line preserved as `lines[0]` so it still cycles in the
		# generic-talk pool.
		"line":"Wolves still circle the road. Take down 4 — you'll learn the form by doing.",
		"lines":[
		"Each level, your spirit grows. Pour it into what you trust.",
		"Strength is loud. Mastery is quiet. Choose.",
		"Tired? Train tired. The road won't ask if you slept.",
		"Even shadow needs practice. Feet on the boards, breathe.",
		],
		# COMPOUND (run 18 — Builder): warm_flag tier. After 4 wolves fall and
		# `wolf_form_taught` is set, Hala's tone shifts from "prove yourself"
		# to "I saw it in you" — the rarest flavor for a teacher who never
		# gushes. Tier 2 (warm_flag) ranks above tier 5 (memory) so once the
		# quest is in, returning trains read the warm lines first; on warm_flag
		# miss the memory tier still fires for the cold-rep loop.
		"warm_flag":"wolf_form_taught",
		"warm_lines":[
		"Form held. Few I've taught hold it under teeth. Few.",
		"You moved like the trees today. Wolves can't read trees. Good.",
		"Old Hala saw a hero today. Don't make me write it down.",
		"Walk lighter, you. The forest hears it. Ride safe.",
		],
		# COMPOUND (run 11 — schedule): never leaves the training field. Slight
		# position shifts at evening (lantern-side practice) and night (watch).
		"schedule":[Vector3( 0.0, 0, -10.0), Vector3( 0.0, 0, -10.0), Vector3(-1.0, 0, -10.0), Vector3( 1.0, 0,  -9.6)],
		# REFINE: character — ambient barks THEME §12 MOTION & LIFE. Hala barks
		# drill counts and koans at the air. Interval 15–26s: a trainer never rests.
		"bark_lines":[
		"One. Two. Three. HOLD. Again.",
		"Footwork is thinking. Slow feet, slow mind.",
		"You breathe out on the strike. Always out. Always.",
		"Pivot on the ball. Never the heel. Ball.",
		"A wolf doesn't telegraph. Neither should you.",
		"AGAIN. From the hip, not the shoulder. AGAIN.",
		],
		"bark_min":15.0, "bark_max":26.0,
		# COMPOUND (run 16 — Builder): visit-memory tier. Hala is THE skill
		# mentor — by the third session her tone shifts from generic koan to
		# named-student attention. Threshold 3, same as the others, so all
		# three memory-aware NPCs warm in the same visit cadence (a player
		# making the village rounds three times unlocks all three at once).
		"memory_visits_min":3,
		"memory_lines":[
		"Back already, eh? Good. Drills don't care if you're tired — show me.",
		"You've been here enough to know the form. Today: PRESSURE. Faster.",
		"Last light's the best teacher. You came back for a reason — show it.",
		"Past curfew, training under stars. I knew you for the type. Begin.",
		],
		"use_json_dialogue":true},
	# THEME §4 — warrior.glb (CC-BY): armoured guard silhouette reads from 30m.
	# North gate placement — first NPC the player sees. THEME §12: gate patrol schedule.
	{"name":"Village Guard",    "role":"guard",   "pos":Vector3(  0,  0,  18), "tint":Color(0.55,0.55,0.65),
		"line":"Stay close to the village walls — the forest has ears tonight.",
		"lines":[
		"Stay close to the village walls — the forest has ears tonight.",
		"Gate's held since dawn. Your road look clear?",
		"I count my rounds by lantern-lights. Seven lanterns, seven rounds.",
		"Rest well, friend. I'll keep watch.",
		],
		"warm_flag":"first_quest_done",
		"warm_lines":[
		"The wood's quieter since your errand. Makes my rounds easier. Thank you.",
		"Fewer shadows at the treeline tonight. Word travels — so does gratitude.",
		"You made the night shorter for all of us. Gate's yours to pass, always.",
		"Seven lanterns, and none of them flickered last night. First time in weeks.",
		],
		"schedule":[
		Vector3( 0.0, 0,  18.0),  # morning: north gate post
		Vector3( 0.0, 0,  16.0),  # midday: patrol south
		Vector3( 0.0, 0,  17.0),  # evening: mid-gate
		Vector3( 0.0, 0,  18.5),  # night: outer gate
		],
		"bark_lines":[
		"All clear on the north. For now.",
		"Seven rounds since midnight. Still counting.",
		"Wind's picking up from the Whisperwood. Watch the treeline.",
		"Gate holds. Village sleeps. Guard stands. Order of things.",
		"You hear that? … No. Good. That's the sound of a quiet night.",
		],
		"bark_min":25.0, "bark_max":40.0},
	# THEME §4 — worker_girl.glb (CC-BY): farmer silhouette reads from 30m.
	# East fields placement. THEME §12: field→market→home schedule. memory_visits_min=2.
	{"name":"Farm Worker",      "role":"villager","pos":Vector3( 18,  0,  5), "tint":Color(0.6,0.5,0.30),
		"line":"The harvest's thin when the goblins raid our stores. Stay sharp.",
		"lines":[
		"The harvest's thin when the goblins raid our stores. Stay sharp.",
		"Soil's good this season, if I can keep the pests away. Two-legged ones, mostly.",
		"Evening already? The rows still need another pass.",
		"No rest for the fields. They grow at night whether I watch or not.",
		],
		"warm_flag":"first_quest_done",
		"warm_lines":[
		"I slept without nightmares last night. First time in months. Thank you.",
		"The stores are fuller since you drove them off. We'll eat well this winter.",
		"Children played past the fence today. They didn't used to do that.",
		"Even the birds are louder now. Field feels alive again.",
		],
		"memory_visits_min":2,
		"memory_lines":[
		"You pass this way often. The field thanks you for the company.",
		"Back again? I'll save you the corner root — it's the sweetest.",
		"Three visits now? Most folks don't notice the farmer. You do. Appreciated.",
		"Come every day and I'll teach you which rows need turning. Honest work.",
		],
		"schedule":[
		Vector3( 20.0, 0,  6.0),  # morning: east field work
		Vector3( 14.0, 0,  2.0),  # midday: market
		Vector3( 18.0, 0,  5.0),  # evening: field last check
		Vector3( 16.0, 0,  3.0),  # night: home
		],
		"bark_lines":[
		"These rows don't turn themselves.",
		"Good soil is quiet soil. This soil's been too quiet lately.",
		"Root vegetables first, then the greens. Always.",
		"Rain's overdue. I've started counting clouds.",
		"Harvest comes whether you're ready or not. I'm always ready.",
		],
		"bark_min":20.0, "bark_max":35.0},
	# run-31 (Builder) — Wandering Herbalist uses maeve.glb (CC-BY, previously unused).
	# THEME §12 MOTION & LIFE: she never stays in one spot — wide day-arc from
	# the Whisperwood fringe at morning to the village well at midday and back.
	# THEME §1: a wandering healer is a classic fantasy archetype — no modern gear.
	# THEME §13 GROUND CONTACT: all schedule anchors at y=0.
	# Compounds: NPC memory (memory_visits_min=2), relationship tier, ambient barks,
	# and the cave_delver achievement (she's the one who tells you to go to the caves).
	{"name":"Wandering Herbalist", "role":"alchemy", "pos":Vector3(-22, 0, -8),
		"tint":Color(0.55, 0.75, 0.45),
		"line":"The forest gives freely if you know how to listen. Most folk don't.",
		"lines":[
		"The forest gives freely if you know how to listen. Most folk don't.",
		"I've walked this edge since before the gate was built. It remembers me.",
		"The Crystal Caves hum differently at dawn. Something is awake in there.",
		"I trade in roots and restoratives. Not weapons. Never weapons.",
		],
		"warm_flag":"first_quest_done",
		"warm_lines":[
		"Word travels fast in a small forest. They say you've been busy.",
		"The wolves are quieter east of the stone. You did that, didn't you.",
		"Here — a tincture of ironleaf. For the road ahead.",
		"I've seen a dozen young wanderers pass through. You feel different.",
		],
		"use_json_dialogue":false,
		"memory_visits_min":2,
		"memory_lines":[
		"You seek me out. The forest likes you for that.",
		"Third time we've met on this path. Fate or habit — both are good signs.",
		"You come often. Take this dried moonsprig — it won't keep past full moon.",
		"I've started leaving a mark on the birch when I've spoken with you.",
		],
		"schedule":[
			Vector3(-30.0, 0, -18.0),  # morning: deep Whisperwood fringe
			Vector3(-14.0, 0,  -4.0),  # midday: near village well
			Vector3(-22.0, 0,  -8.0),  # evening: forest edge camp
			Vector3(-18.0, 0, -12.0),  # night: dark path near cave approach
		],
		"bark_lines":[
		"Roots before bark. Always roots first.",
		"The cave breathes differently today. Mind your step.",
		"Moonsprig grows best where the light doesn't quite reach.",
		"I count five wolf-paths through here. Down from twelve last month.",
		"Speak quietly near the crystal formations. They carry sound.",
		],
		"bark_min":18.0, "bark_max":32.0},
]

# ── Briarwood Hub exports (Briarwood Hub Builder v1) ─────────────────────────
@export var briarwood_hub_enabled: bool = true
@export var briarwood_origin: Vector3 = Vector3(0, 0, 0)

@export var bw_plaza_offset: Vector3     = Vector3(0,   0, 14)
@export var bw_gate_offset: Vector3      = Vector3(0,   0, -6)
@export var bw_market_offset: Vector3    = Vector3(8,   0, 18)
@export var bw_craft_offset: Vector3     = Vector3(-12, 0, 18)
@export var bw_shrine_offset: Vector3    = Vector3(-6,  0, 10)
@export var bw_townhall_offset: Vector3  = Vector3(0,   0, 22)

@export var bw_house_count: int = 28
@export var bw_market_stall_count: int = 14
@export var bw_npc_count: int = 16
@export var bw_prop_density: float = 1.0

@export var briarwood_npc_scene: PackedScene       # optional; null = no crowd spawns
@export var briarwood_questboard_enabled: bool = true
@export var briarwood_quest_refresh_sec: float = 0.0  # 0 = static list
@export var quest_marker_enabled: bool = true
@export var quest_marker_tick: float = 0.5
@export var quest_hud_enabled: bool = true
@export var quest_hud_corner: Vector2 = Vector2(18, 18)
@export var briarwood_life_enabled: bool = true
@export var briarwood_life_tick: float = 1.8
@export var briarwood_atmosphere_enabled: bool = true
@export var sfx_bw_birds_loop: AudioStream
@export var sfx_bw_wind_loop: AudioStream
@export var sfx_bw_tavern_loop: AudioStream
@export var sfx_bw_hammer_loop: AudioStream
@export var sfx_bw_forge_loop: AudioStream
@export var bw_smoke_enabled: bool = true
@export var bw_flag_enabled: bool = true
@export var bw_lantern_sway_enabled: bool = true
# Phase 23 — Briarwood visual style pass
@export var bw_style_enabled: bool = true
@export var bw_window_energy_day: float = 0.35
@export var bw_window_energy_night: float = 1.7
@export var bw_roof_pitch_min: float = 22.0
@export var bw_roof_pitch_max: float = 34.0
@export var bw_roof_overhang: float = 0.45
@export var bw_chimney_enabled: bool = true
@export var bw_porch_enabled: bool = true
# Phase 24 — Street dressing
@export var bw_dressing_enabled: bool = true
@export var bw_dressing_density: float = 1.0
@export var bw_multimesh_enabled: bool = true
@export var bw_mm_fences: bool = true
@export var bw_mm_benches: bool = true
@export var bw_mm_clutter: bool = true
# Phase 24 — Real village layout
@export var bw_real_village_enabled: bool = true
@export var bw_palisade_radius_x: float = 52.0
@export var bw_palisade_radius_z: float = 44.0
@export var bw_gate_width: float = 9.0
@export var bw_inner_loop_scale: float = 0.70
@export var bw_house_setback: float = 6.5
@export var bw_yard_depth: float = 6.0
@export var bw_farm_enabled: bool = true
# Phase 24 — House type weights
@export var bw_house_small_weight: float = 0.55
@export var bw_house_medium_weight: float = 0.30
@export var bw_house_large_weight: float = 0.10
@export var bw_house_corner_weight: float = 0.05
@export var bw_shopfront_weight_market: float = 0.35
# Phase 25 — Street alignment + auto yards
@export var bw_align_enabled: bool = true
@export var bw_setback_small: float = 6.0
@export var bw_setback_medium: float = 7.0
@export var bw_setback_large: float = 8.5
@export var bw_setback_shop: float = 5.2
@export var bw_setback_corner: float = 6.8
@export var bw_yard_fence_enabled: bool = true
@export var bw_yard_width_min: float = 6.0
@export var bw_yard_width_max: float = 10.0
@export var bw_shops_enabled: bool = true
@export var shop_stock_rotation_enabled: bool = true
@export var shop_day_length_real_seconds: float = 0.0
@export var shop_global_seed: int = 7331
@export var town_schedule_enabled: bool = true
@export var day_length_seconds: float = 420.0
@export var night_start: float = 0.72
@export var night_end: float = 0.20
@export var briarwood_inn_interior: PackedScene
@export var briarwood_shop_interior: PackedScene
@export var briarwood_smith_interior: PackedScene
@export var festival_enabled: bool = true
@export var festival_day_mod: int = 7
@export var interior_fallback_builders_enabled: bool = true
@export var transitions_enabled: bool = true
@export var transition_fade_time: float = 0.25
@export var interior_audio_enabled: bool = true
@export var music_inn: AudioStream
@export var music_shop: AudioStream
@export var music_smith: AudioStream
@export var music_outside: AudioStream
@export var minimap_markers_enabled: bool = true
@export var tutorial_enabled: bool = true
@export var tutorial_gating_enabled: bool = true   # Phase 21 — lock boat/upgrade behind tutorial steps
@export var mayor_intro_enabled: bool = true       # Phase 21 — Mayor greeting on first load
@export var mayor_intro_delay: float = 0.8         # Phase 21 — seconds after spawn before intro fires
@export var tutorial_arrow_enabled: bool = true    # Phase 22 — floating objective arrow
@export var tutorial_barks_enabled: bool = true    # Phase 22 — NPC proximity one-liners
@export var tutorial_failsafe_enabled: bool = true # Phase 22 — hint + auto-help if stuck
@export var tutorial_hint_after_sec: float = 120.0 # Phase 22 — seconds idle before hint
@export var tutorial_autofix_after_sec: float = 300.0 # Phase 22 — seconds idle before auto-help
@export var tutorial_trail_enabled: bool = true      # Phase 22B — sparkle breadcrumb trail
@export var tutorial_trail_step: float = 1.6         # metres between sparkle pips
@export var tutorial_trail_count: int = 9            # pips placed ahead of player
@export var tutorial_trail_update_sec: float = 0.6   # seconds between trail rebuilds
@export var tutorial_trail_height: float = 0.06      # metres above ground

const BRIARWOOD_QUESTS := [
	{
		"id": "bw_kill_goblins",
		"title": "Goblin Trouble",
		"desc": "Clear goblins near the treeline.",
		"quest": {"kind":"kill","target":"goblin","needed":6,"giver":"Briarwood Board","gold_reward":45,"xp_reward":80},
	},
	{
		"id": "bw_kill_wolves",
		"title": "Wolves at the Fence",
		"desc": "Drive off wolves prowling the palisade.",
		"quest": {"kind":"kill","target":"wolf","needed":4,"giver":"Briarwood Board","gold_reward":55,"xp_reward":95},
	},
	{
		"id": "bw_fetch_herbs",
		"title": "Herbal Remedy",
		"desc": "Bring herbs to the healer.",
		"quest": {"kind":"fetch","item":"herb","needed":3,"giver":"Healer","gold_reward":35,"xp_reward":70},
	},
	{
		"id": "bw_fetch_wood",
		"title": "Wood for Repairs",
		"desc": "Deliver wood to the carpenter.",
		"quest": {"kind":"fetch","item":"wood","needed":5,"giver":"Carpenter","gold_reward":40,"xp_reward":75},
	},
	{
		"id": "bw_training_combo",
		"title": "Training: 3-hit Combo",
		"desc": "Practice your Slash combo at the training dummy.",
		"quest": {"kind":"kill","target":"training_dummy","needed":3,"giver":"Guard Captain","gold_reward":20,"xp_reward":50},
	},
	{
		"id": "bw_deliver_crate_nordic",
		"title": "Crate Delivery",
		"desc": "Bring a supply crate to the Harbor Master at the Nordic docks.",
		"quest": {"kind":"fetch","item":"supply_crate","needed":1,"giver":"Mayor","gold_reward":80,"xp_reward":120,"turn_in":"harbor_master"},
	},
]

const BUILDINGS = [
	Vector3( 6, 0,  6), Vector3(-6, 0,  6),
	Vector3(10, 0,  0), Vector3(-10, 0,  0),
	Vector3( 6, 0, -8), Vector3(-6, 0, -8),
]
# Builder run 24 — Player Home (Backlog #10). North of the plaza, clear of all
# existing buildings and the path network terminus at z=12. THEME §13: y=0.
const HOME_POS: Vector3 = Vector3(0.0, 0.0, 14.0)
const HOME_SCRIPT: Script = preload("res://scripts/PlayerHome.gd")

# ── Phase 14: Shop catalogs ───────────────────────────────────────────────────
const SHOP_ITEMS := {
	"merchant": [
		{"id":"hp_potion_s","name":"Health Potion (S)","price":18,"sell":9},
		{"id":"hp_potion_l","name":"Health Potion (L)","price":45,"sell":22},
		{"id":"mp_potion_s","name":"Mana Potion (S)",  "price":22,"sell":11},
		{"id":"herb",       "name":"Herb Bundle",      "price":10,"sell":5},
		{"id":"wood",       "name":"Wood Bundle",      "price":8, "sell":4},
		{"id":"rope",       "name":"Rope Coil",        "price":12,"sell":6},
		{"id":"torch",      "name":"Torch",            "price":6, "sell":3},
	],
	"smith": [
		{"id":"iron_ingot","name":"Iron Ingot",      "price":25, "sell":12},
		{"id":"leather",   "name":"Leather Roll",    "price":18, "sell":9},
		{"id":"sword_1",   "name":"Iron Sword",      "price":120,"sell":60},
		{"id":"axe_1",     "name":"Iron Axe",        "price":110,"sell":55},
		{"id":"helm_1",    "name":"Iron Helm",       "price":90, "sell":45},
		{"id":"chest_1",   "name":"Iron Chestpiece", "price":160,"sell":80},
	],
}

# ── Phase 15: Display database (icons + names + slots) ───────────────────────
const ITEM_DB := {
	"hp_potion_s": {"icon":"🧪","name":"Health Potion (S)","type":"consumable"},
	"hp_potion_l": {"icon":"🧪","name":"Health Potion (L)","type":"consumable"},
	"mp_potion_s": {"icon":"✨","name":"Mana Potion (S)",  "type":"consumable"},
	"herb":        {"icon":"🌿","name":"Herb Bundle",      "type":"material"},
	"wood":        {"icon":"🪵","name":"Wood Bundle",      "type":"material"},
	"rope":        {"icon":"🪢","name":"Rope Coil",        "type":"material"},
	"torch":       {"icon":"🔥","name":"Torch",            "type":"tool"},
	"iron_ingot":  {"icon":"⛓️","name":"Iron Ingot",       "type":"material"},
	"leather":     {"icon":"🟤","name":"Leather Roll",     "type":"material"},
	"sword_1":     {"icon":"🗡️","name":"Iron Sword",       "type":"weapon","slot":"weapon"},
	"axe_1":       {"icon":"🪓","name":"Iron Axe",         "type":"weapon","slot":"weapon"},
	"helm_1":      {"icon":"🪖","name":"Iron Helm",        "type":"armor", "slot":"helm"},
	"chest_1":     {"icon":"🛡️","name":"Iron Chestpiece",  "type":"armor", "slot":"chest"},
	"supply_crate":{"icon":"📦","name":"Supply Crate",     "type":"quest"},
}

# ── Phase 16: Stock pools + craft recipes ────────────────────────────────────
const SHOP_POOLS := {
	"merchant": ["hp_potion_s","mp_potion_s","torch","rope","herb","wood","hp_potion_l"],
	"smith":    ["iron_ingot","leather","sword_1","axe_1","helm_1","chest_1"],
}

const CRAFT_RECIPES := [
	{"id":"craft_hp_potion_s","name":"Brew Health Potion (S)",
		"inputs":[{"id":"herb","qty":2}],"outputs":[{"id":"hp_potion_s","qty":1}]},
	{"id":"craft_mp_potion_s","name":"Brew Mana Potion (S)",
		"inputs":[{"id":"herb","qty":1},{"id":"rope","qty":1}],"outputs":[{"id":"mp_potion_s","qty":1}]},
	{"id":"craft_iron_bundle","name":"Forge Iron Ingot",
		"inputs":[{"id":"wood","qty":2}],"outputs":[{"id":"iron_ingot","qty":1}]},
]

func _ready() -> void:
	if _buildings_built: return
	_buildings_built = true
	_dlog("_ready START")
	_populate_npc_models()
	_dlog("NPC_MODELS=%d" % NPC_MODELS.size())
	# Phase 26: chunked async path lets the browser breathe between heavy phases,
	# eliminating the single 86 s "Script Evaluation" block on the main thread.
	# Set chunk_build_enabled = false in the inspector to revert to sync (editor use).
	if chunk_build_enabled:
		_build_world_async.call_deferred()
	else:
		_build_world_sync()


# ── Sync build (editor / non-web fallback) ───────────────────────────────────
# Original _ready body. Each _safe_call defers to next frame but they all
# flush in one batch — fine for desktop, brutal on the web main thread.
func _build_world_sync() -> void:
	_safe_call("_build_ground_overlay")
	_safe_call("_build_path_network")
	if briarwood_hub_enabled:
		_safe_call("_build_briarwood_hub")  # Briarwood Hub Builder v1
	else:
		_safe_call("_build_village")        # legacy 6-house fallback
	_safe_call("_scatter_trees", [140])
	_safe_call("_scatter_rocks", [36])
	_safe_call("_scatter_ferns", [48])
	_safe_call("_scatter_mushrooms", [24])
	_safe_call("_build_village_barrels")
	_safe_call("_build_mountain_ring")
	_safe_call("_build_market_stalls")
	_safe_call("_build_windmill")
	_safe_call("_build_lanterns")
	_safe_call("_build_banners")
	_safe_call("_build_npcs")
	_safe_call("_build_grass_tufts", [220])
	_safe_call("_build_well")
	_safe_call("_build_pond")
	_safe_call("_build_firefly_particles")
	_safe_call("_build_falling_leaves")
	_safe_call("_build_butterflies")
	_safe_call("_build_bird_flocks")
	_safe_call("_build_god_rays")
	_safe_call("_build_smoke_chimneys")
	_safe_call("_build_campfire")
	_safe_call("_build_enemies")
	_safe_call("_build_pet")
	_safe_call("_build_stable_horse")
	_safe_call("_build_loot_chests")
	call_deferred("_global_scale_sweep")
	_safe_call("_build_player_home")
	_safe_call("_build_weather")
	_safe_call("_build_crystal_caves", [Vector3(-50, 0, -40)])
	_safe_call("_build_nordic_fishing_village")
	_safe_call("_build_nordic_road")
	_safe_call("_build_nordic_ambient_audio")
	if nordic_dock_life_enabled:
		_safe_call("_build_nordic_dock_life")
	if district_streaming_enabled:
		_safe_call("_init_district_streaming")
	if quest_marker_enabled:
		_safe_call("_init_quest_markers")
	if town_schedule_enabled:
		_safe_call("_init_town_schedule")
	if tutorial_enabled:
		_safe_call("_tutorial_start_if_needed")
	if mayor_intro_enabled:
		get_tree().create_timer(mayor_intro_delay).timeout.connect(
			func(): _run_mayor_intro(), CONNECT_ONE_SHOT
		)
	if tutorial_enabled:
		_safe_call("_init_tutorial_polish")
	build_progress.emit("Done", 1.0)
	build_complete.emit()
	_dlog("sync build DONE — children=%d" % get_child_count())


# ── Async chunked build (web / production) ───────────────────────────────────
# Each await gives the engine one full rendered frame + lets the browser event
# loop breathe. Phases are grouped so each chunk runs in ~2–8 ms, keeping the
# tab responsive. Progress signal drives the LoadingScene overlay.
func _build_world_async() -> void:
	_dlog("async build START")

	# ── Ground ────────────────────────────────────────────────────────────────
	build_progress.emit("Ground", 0.00)
	await get_tree().process_frame
	_safe_call_now("_build_ground_overlay", [])
	_safe_call_now("_build_path_network",   [])

	# ── Briarwood hub (heaviest single chunk) ─────────────────────────────────
	build_progress.emit("Briarwood", 0.05)
	await get_tree().process_frame
	if briarwood_hub_enabled:
		_safe_call_now("_build_briarwood_hub", [])
	else:
		_safe_call_now("_build_village",       [])

	# ── Trees + rocks ─────────────────────────────────────────────────────────
	build_progress.emit("Trees & Rocks", 0.22)
	await get_tree().process_frame
	_safe_call_now("_scatter_trees", [140])
	_safe_call_now("_scatter_rocks", [36])

	# ── Ground cover ──────────────────────────────────────────────────────────
	build_progress.emit("Ground Cover", 0.30)
	await get_tree().process_frame
	_safe_call_now("_scatter_ferns",     [48])
	_safe_call_now("_scatter_mushrooms", [24])

	# ── Village props ─────────────────────────────────────────────────────────
	build_progress.emit("Village Props", 0.36)
	await get_tree().process_frame
	_safe_call_now("_build_village_barrels", [])
	_safe_call_now("_build_mountain_ring",   [])
	_safe_call_now("_build_market_stalls",   [])
	_safe_call_now("_build_windmill",        [])
	_safe_call_now("_build_lanterns",        [])
	_safe_call_now("_build_banners",         [])

	# ── NPCs + grass ──────────────────────────────────────────────────────────
	build_progress.emit("Characters", 0.46)
	await get_tree().process_frame
	_safe_call_now("_build_npcs",        [])
	_safe_call_now("_build_grass_tufts", [220])

	# ── Water, particles, atmosphere ──────────────────────────────────────────
	build_progress.emit("Water & FX", 0.54)
	await get_tree().process_frame
	_safe_call_now("_build_well",              [])
	_safe_call_now("_build_pond",              [])
	_safe_call_now("_build_firefly_particles", [])
	_safe_call_now("_build_falling_leaves",    [])
	_safe_call_now("_build_butterflies",       [])
	_safe_call_now("_build_bird_flocks",       [])
	_safe_call_now("_build_god_rays",          [])
	_safe_call_now("_build_smoke_chimneys",    [])
	_safe_call_now("_build_campfire",          [])

	# ── Creatures, loot, scale pass ───────────────────────────────────────────
	build_progress.emit("Creatures & Loot", 0.64)
	await get_tree().process_frame
	_safe_call_now("_build_enemies",      [])
	_safe_call_now("_build_pet",          [])
	_safe_call_now("_build_stable_horse", [])
	_safe_call_now("_build_loot_chests",  [])
	call_deferred("_global_scale_sweep")

	# ── Home, weather, caves ──────────────────────────────────────────────────
	build_progress.emit("Home & Weather", 0.72)
	await get_tree().process_frame
	_safe_call_now("_build_player_home",    [])
	_safe_call_now("_build_weather",        [])
	_safe_call_now("_build_crystal_caves",  [Vector3(-50, 0, -40)])

	# ── Nordic district (second-heaviest chunk) ───────────────────────────────
	build_progress.emit("Nordic District", 0.80)
	await get_tree().process_frame
	_safe_call_now("_build_nordic_fishing_village", [])
	_safe_call_now("_build_nordic_road",            [])
	_safe_call_now("_build_nordic_ambient_audio",   [])
	if nordic_dock_life_enabled:
		_safe_call_now("_build_nordic_dock_life", [])

	# ── Game systems ──────────────────────────────────────────────────────────
	build_progress.emit("Systems", 0.90)
	await get_tree().process_frame
	if district_streaming_enabled:
		_safe_call_now("_init_district_streaming", [])
	if quest_marker_enabled:
		_safe_call_now("_init_quest_markers", [])
	if town_schedule_enabled:
		_safe_call_now("_init_town_schedule", [])
	if tutorial_enabled:
		_safe_call_now("_tutorial_start_if_needed", [])
	if mayor_intro_enabled:
		get_tree().create_timer(mayor_intro_delay).timeout.connect(
			func(): _run_mayor_intro(), CONNECT_ONE_SHOT
		)
	if tutorial_enabled:
		_safe_call_now("_init_tutorial_polish", [])

	# ── Done ──────────────────────────────────────────────────────────────────
	build_progress.emit("Done", 1.0)
	build_complete.emit()
	_dlog("async build DONE — children=%d" % get_child_count())

# _ready bisect helper. Logs entry/exit for each spawn call. If a call halts
# the script (runtime error), we'll see [WB] -> X without a matching [WB] OK X.
# Godot's print() goes to stdout which the Web export pipes to console.log.
func _safe_call(method_name: String, args: Array = []) -> void:
	# 2026-05-06: Each spawn call runs deferred (next frame) so a runtime
	# error in one method (null asset, bad index, etc.) doesn't halt the
	# rest of _ready. Without this, one bad call leaves the player on a
	# bare ground plane with no village. Deferred calls log entry/exit
	# from the deferred handler so the bisect output stays intact.
	if not has_method(method_name):
		_dlog("MISSING " + method_name)
		return
	call_deferred("_safe_call_now", method_name, args)

func _safe_call_now(method_name: String, args: Array) -> void:
	_dlog("-> " + method_name)
	callv(method_name, args)
	_dlog("OK  " + method_name)

# _dlog: write to print() AND document.title AND window.WB_LOG so the
# bisect output is reachable without DevTools (just take an OS screenshot
# of the Chrome tab strip — the last spawn call appears in the title bar).
var _wb_log_lines: Array[String] = []
func _dlog(msg: String) -> void:
	print("[WB] " + msg)
	_wb_log_lines.append(msg)
	if _wb_log_lines.size() > 24:
		_wb_log_lines.pop_front()
	if Engine.has_singleton("JavaScriptBridge"):
		var js = Engine.get_singleton("JavaScriptBridge")
		var joined: String = " | ".join(_wb_log_lines)
		# Tab title shows last spawn call — visible in any browser screenshot.
		js.eval("document.title='⚙ ' + " + JSON.stringify(joined) + ".slice(-280);")
		js.eval("window.WB_LOG=(window.WB_LOG||[]); window.WB_LOG.push(" + JSON.stringify(msg) + ");")

# ============================================================================
# A textured ground patch is added on TOP of the existing flat ground so the
# Main.tscn ground stays as a collider while we get a real PBR look.
# ============================================================================
func _build_ground_overlay() -> void:
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(220, 220)
	pm.subdivide_width = 80
	pm.subdivide_depth = 80
	ground.mesh = pm
	ground.material_override = MAT_GRASS(40)
	ground.position.y = 0.01  # avoid z-fighting with the existing ground
	ground.name = "GroundPBR"
	ground.custom_aabb = AABB(Vector3(-150, -2, -150), Vector3(300, 4, 300))
	add_child(ground)

# ============================================================================
# Cobble paths between buildings — a few intersecting plane strips
# ============================================================================
func _build_path_network() -> void:
	var paths = [
		{"from": Vector3(-12, 0, 0),  "to": Vector3(12, 0, 0),  "w": 1.6},
		{"from": Vector3(0, 0, -12),  "to": Vector3(0, 0, 12),  "w": 1.6},
		{"from": Vector3(-9, 0, -8),  "to": Vector3(9, 0, -8),  "w": 1.2},
		{"from": Vector3(-9, 0,  8),  "to": Vector3(9, 0,  8),  "w": 1.2},
	]
	for p in paths:
		var dir = p.to - p.from
		var length = dir.length()
		var center = (p.from + p.to) * 0.5
		var path := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(p.w, length)
		path.mesh = pm
		path.material_override = MAT_PATH(length / 2)
		path.position = center + Vector3(0, 0.02, 0)
		path.rotation.y = atan2(dir.x, dir.z)
		path.name = "Path"
		path.custom_aabb = AABB(Vector3(-200, -1, -200), Vector3(400, 2, 400))
		add_child(path)

# ============================================================================
# Buildings — timber-framed wood walls, shingled roof, lit window, chimney
# ============================================================================
func _build_village() -> void:
	for pos in BUILDINGS:
		_make_building(pos)

func _make_building(pos: Vector3) -> void:
	var house := Node3D.new()
	house.position = pos
	house.add_to_group("buildings")
	add_child(house)

	# Stone foundation (1m tall around the base)
	var foundation := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(4.0, 0.5, 4.0)
	foundation.mesh = fm
	foundation.material_override = MAT_FOUNDATION(2)
	foundation.position.y = 0.25
	house.add_child(foundation)

	# Walls (whitewashed plaster — half-timbered look with dark wood corner beams)
	var wall := MeshInstance3D.new()
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(3.6, 2.6, 3.6)
	wall.mesh = wall_mesh
	wall.material_override = MAT_PLASTER(3)
	wall.position.y = 1.3 + 0.5
	house.add_child(wall)

	# Wall collision — covers foundation + walls up to eave.
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.6, 3.4, 3.6)
	col.shape = box
	col.position.y = 1.7
	body.add_child(col)
	house.add_child(body)

	# Corner timber beams (dark wood)
	for dx in [-1.7, 1.7]:
		for dz in [-1.7, 1.7]:
			var beam := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.22, 2.6, 0.22)
			beam.mesh = bm
			beam.material_override = MAT_DARK_WOOD(0.5)
			beam.position = Vector3(dx, 1.3 + 0.5, dz)
			house.add_child(beam)
	# Horizontal cross beams
	for dy in [0.5 + 0.6, 0.5 + 1.6, 0.5 + 2.5]:
		for dx in [0.0]:
			for dz in [-1.81, 1.81]:
				var crossbeam := MeshInstance3D.new()
				var bm := BoxMesh.new()
				bm.size = Vector3(3.6, 0.16, 0.16)
				crossbeam.mesh = bm
				crossbeam.material_override = MAT_DARK_WOOD(0.5)
				crossbeam.position = Vector3(dx, dy, dz)
				house.add_child(crossbeam)

	# Eave
	var eave := MeshInstance3D.new()
	var em := BoxMesh.new()
	em.size = Vector3(4.0, 0.18, 4.0)
	eave.mesh = em
	eave.material_override = MAT_DARK_WOOD(0.5)
	eave.position.y = 3.18
	house.add_child(eave)

	# Roof — pyramid (tiled shingle)
	var roof := MeshInstance3D.new()
	var pyr := PrismMesh.new()
	pyr.left_to_right = 0.5
	pyr.size = Vector3(4.4, 1.9, 4.4)
	roof.mesh = pyr
	roof.material_override = MAT_ROOF(2.0)
	roof.position.y = 4.13
	house.add_child(roof)
	# Walkable roof collision — trimesh from the actual mesh so the slope is
	# a proper surface. Player can land here and walk around; floor_max_angle
	# is 65° so the ~41° pitch is fully walkable without sliding off.
	var roof_body := StaticBody3D.new()
	var roof_col  := CollisionShape3D.new()
	roof_col.shape = pyr.create_trimesh_shape()
	roof_body.add_child(roof_col)
	roof.add_child(roof_body)

	# Window with warm light
	var win_mat := StandardMaterial3D.new()
	win_mat.albedo_color = Color(0.95, 0.6, 0.25)
	win_mat.emission_enabled = true
	win_mat.emission = Color(1.0, 0.7, 0.3)
	win_mat.emission_energy_multiplier = 1.2
	win_mat.metallic = 0.0
	win_mat.roughness = 0.4
	var win := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.7, 0.6)
	win.mesh = qm
	win.material_override = win_mat
	win.position = Vector3(0, 2.1, 1.81)
	house.add_child(win)

	# Window frame
	var fr_mat := MAT_DARK_WOOD(0.4)
	for off in [Vector2(-0.4, 0), Vector2(0.4, 0), Vector2(0, 0.35), Vector2(0, -0.35)]:
		var f := MeshInstance3D.new()
		var fm2 := BoxMesh.new()
		if abs(off.x) > 0:
			fm2.size = Vector3(0.06, 0.7, 0.05)
		else:
			fm2.size = Vector3(0.85, 0.06, 0.05)
		f.mesh = fm2
		f.material_override = fr_mat
		f.position = Vector3(off.x, 2.1 + off.y, 1.83)
		house.add_child(f)

	# Door
	var door := MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(0.9, 1.6, 0.08)
	door.mesh = dm
	door.material_override = MAT_DARK_WOOD(0.6)
	door.position = Vector3(-1.0, 1.3, 1.85)
	house.add_child(door)

	# Chimney
	var chim := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(0.5, 1.5, 0.5)
	chim.mesh = cm
	chim.material_override = MAT_STONE(1)
	chim.position = Vector3(1.2, 4.6, 1.0)
	chim.name = "Chimney"
	house.add_child(chim)

# ============================================================================
# Trees — bark-textured trunk + multi-tier stylized foliage with rim lighting
# ============================================================================
func _scatter_trees(count: int) -> void:
	# Env: 2026-05-06 — trees RE-ENABLED. Whisperwood was bare because the
	# previous emergency shutoff ("big-trees-stupid") never lifted, but the
	# 4.5m AABB clamp added to `_clamp_tree_at_spawn` already caps every GLB
	# below player-occluding height. THEME §1 / §11 / §12 require a forest:
	# the village without it reads as "lawn with houses". Reduced count and
	# bumped the inner radius so trees ring the plaza without clipping the
	# building cluster.
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var spawn_count: int = mini(count, 100)  # cap to 100 — the playfield is ~70m wide
	for i in spawn_count:
		var ang: float = rng.randf() * TAU
		# Inner ring (40%) — village-edge trees at 24-40m. Outer ring (60%) —
		# Whisperwood proper at 40-72m. The bias gives a sense of the forest
		# pressing in without crowding the central plaza.
		var dist: float
		if rng.randf() < 0.4:
			dist = rng.randf_range(24.0, 40.0)
		else:
			dist = rng.randf_range(40.0, 72.0)
		var pos: Vector3 = Vector3(cos(ang) * dist, 0, sin(ang) * dist)
		# THEME §13 — keep trunks clear of the cobble path network and the
		# building footprints. The path network radiates from origin out to
		# the village edge, so a small jitter prevents perfect alignment.
		pos += Vector3(rng.randf_range(-0.6, 0.6), 0.0, rng.randf_range(-0.6, 0.6))
		_make_tree(pos, rng)

func _make_tree(pos: Vector3, rng: RandomNumberGenerator) -> void:
	# THEME §1, §11, §12 — every tree is now a real CC-BY GLB instance from
	# `assets/models/trees/{oak,pine,bush,dead}.glb`. The procedural sphere-stack
	# fallback that used to live here has been REMOVED per the environment-spec
	# brief ("NO procedural cone-stack trees"). All four GLBs are committed in
	# the repo, so `_make_glb_tree` should never return false at runtime; if it
	# ever does (asset import broken), we log via `_dlog` and skip the spawn so
	# we don't fall back to ugly primitives.
	if _make_glb_tree(pos, rng):
		return
	_dlog("Env: _make_tree skipped — _make_glb_tree returned false at " + str(pos))

# ============================================================================
# Rocks — stone-textured with random rotation
# ============================================================================
func _scatter_rocks(count: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in count:
		var ang: float = rng.randf() * TAU
		var dist: float = rng.randf_range(20, 70)
		var pos: Vector3 = Vector3(cos(ang) * dist, 0, sin(ang) * dist)
		# THEME §1 — try the Sketchfab CC-BY boulder GLB first; fall through to
		# the legacy sphere-primitive path if the asset isn't loadable.
		if _make_glb_boulder(pos, rng):
			continue
		# ─── Procedural fallback (legacy primitive path) ─────────────────────
		var size: float = rng.randf_range(0.7, 1.8)
		var rock := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = size; sm.height = size * 1.4
		sm.radial_segments = 8
		sm.rings = 5
		rock.mesh = sm
		rock.material_override = MAT_ROCK(0.6)
		rock.position = pos + Vector3(0, size * 0.5, 0)
		rock.rotation = Vector3(rng.randf() * 0.4, rng.randf() * TAU, rng.randf() * 0.4)
		rock.scale = Vector3(1.0, 0.6, 1.0)
		add_child(rock)

# ============================================================================
# Mountain ring with rock texture + snow caps (snow texture)
# ============================================================================
func _build_mountain_ring() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	# Inner ring
	for i in 36:
		var ang: float = (float(i) / 36.0) * TAU + rng.randf_range(-0.05, 0.05)
		var r: float = 220.0 + rng.randf_range(-15, 15)  # 2026-05-06 [CANON-APPROVED: SIZE_STANDARDS.md §6 — was 90m, mountain ring must be 200m+]
		var pos: Vector3 = Vector3(cos(ang) * r, 0, sin(ang) * r)
		var h: float = rng.randf_range(20, 40)
		var base_r: float = rng.randf_range(8, 14)
		var mt := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = base_r
		cm.height = h
		cm.radial_segments = 8
		mt.mesh = cm
		mt.material_override = MAT_ROCK(2.0)
		mt.position = pos + Vector3(0, h/2 - 2, 0)
		mt.rotation.y = rng.randf() * TAU
		add_child(mt)
		# Snow cap
		if rng.randf() < 0.7:
			var cap := MeshInstance3D.new()
			var ccm := CylinderMesh.new()
			ccm.top_radius = 0.0
			ccm.bottom_radius = base_r * 0.55
			ccm.height = h * 0.32
			ccm.radial_segments = 8
			cap.mesh = ccm
			cap.material_override = MAT_SNOW(1.0)
			cap.position = pos + Vector3(0, h - h*0.16 - 2, 0)
			cap.rotation.y = mt.rotation.y
			add_child(cap)
	# Outer ring (taller, further)
	for i in 28:
		var ang: float = (float(i) / 28.0) * TAU + rng.randf_range(-0.1, 0.1)
		var r: float = 320.0 + rng.randf_range(-25, 25)  # 2026-05-06 [CANON-APPROVED: outer ring pushed back from 160m to 320m so it reads as horizon]
		var pos: Vector3 = Vector3(cos(ang) * r, 0, sin(ang) * r)
		var h: float = rng.randf_range(45, 80)
		var base_r: float = rng.randf_range(15, 25)
		var mt := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = base_r
		cm.height = h
		cm.radial_segments = 7
		mt.mesh = cm
		mt.material_override = MAT_ROCK(3.5)
		mt.position = pos + Vector3(0, h/2 - 5, 0)
		mt.rotation.y = rng.randf() * TAU
		add_child(mt)
		# Snow cap on outer ring (always)
		var cap := MeshInstance3D.new()
		var ccm := CylinderMesh.new()
		ccm.top_radius = 0.0
		ccm.bottom_radius = base_r * 0.6
		ccm.height = h * 0.42
		ccm.radial_segments = 7
		cap.mesh = ccm
		cap.material_override = MAT_SNOW(1.5)
		cap.position = pos + Vector3(0, h - h*0.21 - 5, 0)
		cap.rotation.y = mt.rotation.y
		add_child(cap)

# ============================================================================
# Market stalls
# ============================================================================
func _build_market_stalls() -> void:
	var spots = [Vector3(4.0, 0, -8.0), Vector3(-4.0, 0, -8.0)]
	for spot in spots:
		_make_stall(spot)

func _make_stall(pos: Vector3) -> void:
	var stall := Node3D.new()
	stall.position = pos
	add_child(stall)
	var counter := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.8, 0.8, 0.8)
	counter.mesh = bm
	counter.material_override = MAT_DARK_WOOD(1.5)
	counter.position.y = 0.4
	stall.add_child(counter)
	for dx in [-0.8, 0.8]:
		var post := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 0.05; pm.bottom_radius = 0.05; pm.height = 1.6
		post.mesh = pm
		post.material_override = MAT_DARK_WOOD(0.5)
		post.position = Vector3(dx, 1.2, -0.3)
		stall.add_child(post)
	# Awning (red striped cloth) — THEME §12: cloth must FLAP.
	# Env: 2026-05-06 — was a static angled box. Wrap in a pivot Node3D at
	# the back-post line and join group "stall_awnings" so _process() can
	# pitch the cloth around X (front lip lifting/falling in wind) plus a
	# small Z-sway. Per-stall phase metadata keeps adjacent stalls from
	# flapping in unison. Base pitch (0.4 rad) preserved as set_meta so the
	# canopy keeps its painted-stylized downward slope between flaps.
	var awn_pivot := Node3D.new()
	awn_pivot.position = Vector3(0, 1.95, -0.3)  # top of back posts
	awn_pivot.set_meta("phase", randf() * TAU)
	awn_pivot.set_meta("base_pitch", 0.4)
	awn_pivot.add_to_group("stall_awnings")
	stall.add_child(awn_pivot)
	var awn_mat := StandardMaterial3D.new()
	awn_mat.albedo_color = Color(0.78, 0.22, 0.18)
	awn_mat.roughness = 0.7
	awn_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var awn := MeshInstance3D.new()
	var am := BoxMesh.new()
	am.size = Vector3(2.2, 0.05, 1.2)
	awn.mesh = am
	awn.material_override = awn_mat
	# Cloth offset forward of the pivot — pivot lives at the back edge so
	# rotation.x reads as the front lip lifting in the breeze.
	awn.position = Vector3(0, 0.05, 0.4)
	awn_pivot.add_child(awn)
	# Wares (potions)
	var rng := RandomNumberGenerator.new(); rng.randomize()
	var ware_colors = [Color(0.95, 0.3, 0.25), Color(0.95, 0.85, 0.3), Color(0.3, 0.75, 0.4), Color(0.65, 0.3, 0.85)]
	for i in 4:
		var ware_mat := StandardMaterial3D.new()
		ware_mat.albedo_color = ware_colors[i]
		ware_mat.roughness = 0.25
		ware_mat.metallic = 0.1
		ware_mat.emission_enabled = true
		ware_mat.emission = ware_colors[i]
		ware_mat.emission_energy_multiplier = 0.25
		var w := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.10
		w.mesh = sm
		w.material_override = ware_mat
		w.position = Vector3(-0.65 + i * 0.4, 0.92, 0)
		stall.add_child(w)

# ============================================================================
# Windmill
# ============================================================================
func _build_windmill() -> void:
	var pos: Vector3 = Vector3(0, 0, 12)
	var mill := Node3D.new()
	mill.position = pos
	mill.add_to_group("windmills")
	add_child(mill)

	# THEME §1, §11 — try the Sketchfab CC-BY windmill GLB first. Fall through
	# to the procedural cone-tower + box-blade path if the asset isn't loadable
	# so the village never loses its mill. The "Blades" pivot stays attached
	# to `mill` regardless of which path renders, and joins group
	# "windmill_blades" so THEME §12 rotation in _process always plays.
	var mill_packed: PackedScene = _load_glb_safe(WINDMILL_GLB_PATH)
	var mill_used_glb: bool = false
	# Hub Y for procedural blade overlay. The procedural fallback fixes this
	# to 4.0 (matching the legacy tower) — the GLB path overrides it after
	# AABB measurement to sit just below the roof apex.
	var hub_y: float = 4.0
	# Default forward offset of the blade hub from the tower centerline (so
	# blades sit on the front face of the windmill, not inside it).
	var hub_z: float = 1.0
	if mill_packed != null:
		var mill_inst: Node = mill_packed.instantiate()
		if mill_inst != null:
			mill.add_child(mill_inst)
			if mill_inst is Node3D:
				# Most stylized Sketchfab windmills export at ~3-6m tall.
				# 1.55x matches the procedural ~8.8m total — settle + spawn
				# clamp tame any leftover floor/ceiling drift.
				(mill_inst as Node3D).scale = Vector3(1.55, 1.55, 1.55)
			mill_used_glb = true
			# Coarse cylindrical collider so the player can lean on the
			# tower but not walk through it. Radius 1.1 matches the visual
			# stone-tower base; previously 1.4 which extended to Z=10.6 and
			# nearly touched SAFE_SPAWN (0,0,3) was the old (0,0,10) —
			# physics engine was launching the player upward onto the cylinder top.
			var mill_body: StaticBody3D = StaticBody3D.new()
			var mill_col: CollisionShape3D = CollisionShape3D.new()
			var mill_cyl: CylinderShape3D = CylinderShape3D.new()
			mill_cyl.radius = 1.1
			mill_cyl.height = 5.0
			mill_col.shape = mill_cyl
			mill_col.position.y = 2.5
			mill_body.add_child(mill_col)
			mill.add_child(mill_body)
			# 2026-05-08: Use hardcoded hub_y for GLB path instead of deferred AABB.
			# The windmill GLB at scale 1.55 is ~8.5m tall; hub at 85% = 7.2m.
			# Deferred AABB fires too early (GLB not yet rendered) → blades at y=4.0.
			hub_y = 7.2
			hub_z = 1.5
			# Hide baked blades via a one-shot timer (0.1s) so GLB is fully rendered.
			var _t := get_tree().create_timer(0.1)
			_t.timeout.connect(func(): _hide_baked_blades(mill_inst))

	if not mill_used_glb:
		# scale-eng 2026-05-05: measured roof-tip 5.7m, canon windmill floor 8m
		# (target 12m, cap 18m). Sweep clamps DOWN over-cap but cannot grow UP —
		# under-floor windmills must be fixed at source. Uniform 1.55x → ~8.8m.
		mill.scale = Vector3(1.55, 1.55, 1.55)
		# Stone tower base
		var base := MeshInstance3D.new()
		var bcm := CylinderMesh.new()
		bcm.top_radius = 0.85; bcm.bottom_radius = 1.1
		bcm.height = 2.0
		base.mesh = bcm
		base.material_override = MAT_STONE(1.5)
		base.position.y = 1.0
		mill.add_child(base)
		# Wood upper tower
		var tower := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.7; cm.bottom_radius = 0.85
		cm.height = 2.5
		tower.mesh = cm
		tower.material_override = MAT_WOOD(2)
		tower.position.y = 3.25
		mill.add_child(tower)
		# Roof
		var roof := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0; cone.bottom_radius = 0.85
		cone.height = 1.2
		roof.mesh = cone
		roof.material_override = MAT_ROOF(1.5)
		roof.position.y = 5.1
		mill.add_child(roof)
		# Collision for procedural path (matches visual base radius, local scale 1.55 applied)
		# Using pre-scaled values: radius 0.85/1.55=0.548 → 0.9 at local (un-scaled) for a
		# comfortable fit. The node scale 1.55 makes this 0.9*1.55=1.395 → ~1.4m world radius.
		var proc_body := StaticBody3D.new()
		var proc_col  := CollisionShape3D.new()
		var proc_cyl  := CylinderShape3D.new()
		proc_cyl.radius = 0.9    # * mill.scale 1.55 ≈ 1.4m world radius
		proc_cyl.height = 3.0    # * mill.scale 1.55 ≈ 4.65m world height
		proc_col.shape  = proc_cyl
		proc_col.position.y = 1.5  # * 1.55 ≈ 2.3m world — centre of base+tower
		proc_body.add_child(proc_col)
		mill.add_child(proc_body)

	# ── Blade hub (overlay on both paths so THEME §12 rotation is consistent)
	# Procedural blades + sail cloth ride on a pivot Node3D rotated by
	# _process via group "windmill_blades". For the GLB path, baked blades
	# (if any) are hidden by _hide_baked_blades so they don't double up.
	var blades := Node3D.new()
	blades.name = "Blades"
	blades.position = Vector3(0, hub_y, hub_z)
	mill.add_child(blades)
	for i in 4:
		var b := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.18, 2.6, 0.5)
		b.mesh = bm
		b.material_override = MAT_DARK_WOOD(0.4)
		var ang := (float(i) / 4.0) * TAU
		b.rotation.z = ang
		b.position = Vector3(cos(ang + PI/2) * 1.3, sin(ang + PI/2) * 1.3, 0)
		blades.add_child(b)
		# Sail cloth
		var cloth_mat := StandardMaterial3D.new()
		cloth_mat.albedo_color = Color(0.92, 0.88, 0.78)
		cloth_mat.roughness = 0.85
		cloth_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		var cloth := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(0.85, 2.4)
		cloth.mesh = qm
		cloth.material_override = cloth_mat
		cloth.rotation.z = ang
		cloth.position = Vector3(cos(ang + PI/2) * 1.3, sin(ang + PI/2) * 1.3, 0.05)
		blades.add_child(cloth)
	blades.add_to_group("windmill_blades")

# Env: 2026-05-06 — windmill GLB helpers. Called via call_deferred so the
# AABB is valid (sub-resources finish loading on the next frame).
#
# Lifts the procedural blade pivot so it sits ~85% up the GLB-bodied
# windmill rather than at the legacy-procedural Y=4.0. Without this the
# blades read as floating mid-tower on tall stylized windmill exports.
func _position_windmill_blades_after_settle(mill: Node3D) -> void:
	if not is_instance_valid(mill):
		return
	var pivot: Node = mill.get_node_or_null("Blades")
	if pivot == null:
		return
	var aabb: AABB = _measure_aabb(mill)
	if aabb.size == Vector3.ZERO:
		return
	# Convert global AABB to local-space delta from the mill's origin.
	var top_global: float = aabb.position.y + aabb.size.y
	var pivot_y_global: float = mill.global_transform.origin.y + (top_global - mill.global_transform.origin.y) * 0.85
	(pivot as Node3D).global_position.y = pivot_y_global
	# Push the hub forward to sit on the front face of the tower (radius
	# ~half the AABB's X-size feels right for a windmill silhouette).
	var hub_z: float = aabb.size.x * 0.5 + 0.15
	(pivot as Node3D).position.z = hub_z

# Hides any node inside the windmill GLB whose name suggests baked blade /
# sail / wing geometry. Without this, the rotating procedural overlay
# reads as duplicate blades next to the static GLB ones.
# Match is case-insensitive, substring-based, and only touches direct
# VisualInstance3D children — no risk to skeletons or root pivots.
func _hide_baked_blades(root: Node) -> void:
	if not is_instance_valid(root):
		return
	var keywords: Array = ["blade", "sail", "wing", "vane", "rotor", "fan"]
	var visuals: Array = root.find_children("*", "VisualInstance3D", true, false)
	for v in visuals:
		var nm: String = String(v.name).to_lower()
		for kw in keywords:
			if nm.find(kw) != -1:
				(v as Node3D).visible = false
				break

# ============================================================================
# Lanterns
# ============================================================================
func _build_lanterns() -> void:
	var positions = [Vector3(8, 0, 8), Vector3(-8, 0, 8), Vector3(8, 0, -8), Vector3(-8, 0, -8),
						Vector3(12, 0, 0), Vector3(-12, 0, 0), Vector3(0, 0, 12), Vector3(0, 0, -12)]
	for p in positions:
		_make_lantern(p)

func _make_lantern(pos: Vector3) -> void:
	var lan := Node3D.new()
	lan.position = pos
	lan.add_to_group("lanterns")
	add_child(lan)
	# THEME §1, §11 — try the Sketchfab CC-BY lantern GLB first; fall through to
	# the legacy procedural path so the village never goes dark.
	var packed: PackedScene = _load_glb_safe(LANTERN_GLB_PATH)
	if packed != null:
		var inst: Node = packed.instantiate()
		if inst != null:
			lan.add_child(inst)
			if inst is Node3D:
				(inst as Node3D).scale = Vector3(1.0, 1.0, 1.0)
			# Warm omni light at fixture height. Name MUST stay "OmniLight3D"
			# so the flicker loop in _process keeps finding it.
			var glb_light := OmniLight3D.new()
			glb_light.light_color = Color(1.0, 0.62, 0.28)
			glb_light.light_energy = 1.6
			glb_light.omni_range = 8.0
			glb_light.position.y = 1.9
			glb_light.shadow_enabled = false
			lan.add_child(glb_light)
			call_deferred("_settle_to_ground", lan)
			return
	# ─── Procedural fallback (legacy primitive path) ─────────────────────────
	var post := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	# scale-eng 2026-05-05: post 2.4m -> 2.2m. Measured lantern top at
	# spawn = 2.71m (post 2.4 + box top 2.5+0.21). Canon lantern cap = 2.5m.
	# Sweep would clamp every spawn; better to spawn in spec.
	cm.top_radius = 0.05; cm.bottom_radius = 0.07; cm.height = 2.2
	post.mesh = cm
	post.material_override = MAT_DARK_WOOD(0.4)
	post.position.y = 1.1
	lan.add_child(post)
	var box := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.32, 0.42, 0.32)
	box.mesh = bm
	box.material_override = MAT_DARK_WOOD(0.3)
	box.position.y = 2.25  # scale-eng 2026-05-05: -0.25 -> top 2.46m (under canon cap 2.5m)
	lan.add_child(box)
	# Glowing glass
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(1.0, 0.65, 0.20)
	glass_mat.emission_enabled = true
	glass_mat.emission = Color(1.0, 0.55, 0.18)
	glass_mat.emission_energy_multiplier = 1.8
	glass_mat.metallic = 0.0
	glass_mat.roughness = 0.2
	var glass := MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(0.22, 0.30, 0.22)
	glass.mesh = gm
	glass.material_override = glass_mat
	glass.position.y = 2.25  # scale-eng 2026-05-05
	glass.name = "Glow"
	lan.add_child(glass)
	# Light
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.62, 0.28)
	light.light_energy = 1.6
	light.omni_range = 8.0
	light.position.y = 2.25  # scale-eng 2026-05-05
	light.shadow_enabled = false
	lan.add_child(light)

# ============================================================================
# Banner flags
# ============================================================================
# THEME §12 — banners must FLAP. Each banner is built with a pivot Node3D
# at the top of the pole; the cloth hangs to one side of that pivot, so a
# small Y-rotation on the pivot reads as wind catching the banner. The pivot
# is added to the "banner_cloths" group so `_process` can sway it.
const BANNER_COLORS: Array[Color] = [
	Color(0.78, 0.22, 0.18),  # Eldoria crimson — see THEME §3
	Color(0.62, 0.18, 0.14),  # deeper wine
	Color(0.55, 0.34, 0.12),  # bronze-tabard
]

func _build_banners() -> void:
	# THEME §8 — Briarwood banner poles ring the central plaza. Doubled count
	# from 2 → 6 so the village reads as inhabited rather than half-built.
	var spots: Array = [
		Vector3(-14, 0,   0),
		Vector3( 14, 0,   0),
		Vector3(  0, 0,  14),
		Vector3(  0, 0, -14),
		Vector3( 10, 0,  10),
		Vector3(-10, 0, -10),
	]
	var rng := RandomNumberGenerator.new(); rng.randomize()
	for i in spots.size():
		var p: Vector3 = spots[i]
		var pole := Node3D.new()
		pole.position = p
		pole.rotation.y = rng.randf() * TAU  # random facing so flap directions differ
		pole.add_to_group("banner_poles")
		add_child(pole)
		var post := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.06; cm.bottom_radius = 0.06; cm.height = 4.5
		post.mesh = cm
		post.material_override = MAT_DARK_WOOD(0.3)
		post.position.y = 2.25
		pole.add_child(post)
		# Crossbar at top — gives the banner something to hang from visually
		var bar := MeshInstance3D.new()
		var bcm := CylinderMesh.new()
		bcm.top_radius = 0.04; bcm.bottom_radius = 0.04; bcm.height = 1.6
		bar.mesh = bcm
		bar.material_override = MAT_DARK_WOOD(0.3)
		bar.rotation.z = PI * 0.5
		bar.position = Vector3(0.7, 4.35, 0)
		pole.add_child(bar)
		# Pivot Node3D at top of pole — rotated by `_process` to flap the cloth.
		# Cloth is offset along +X from pivot, so Y-rotation sweeps it through
		# the wind and Z-rotation gives a subtle billow.
		var pivot := Node3D.new()
		pivot.position = Vector3(0, 4.35, 0)
		pivot.add_to_group("banner_cloths")
		pivot.set_meta("phase", rng.randf() * TAU)
		pole.add_child(pivot)
		var ban_mat := StandardMaterial3D.new()
		ban_mat.albedo_color = BANNER_COLORS[i % BANNER_COLORS.size()]
		ban_mat.roughness = 0.85
		ban_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		var ban := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(1.4, 0.85)
		ban.mesh = qm
		ban.material_override = ban_mat
		# Cloth pivots from its TOP edge so it hangs naturally
		ban.position = Vector3(0.7, -0.45, 0)
		pivot.add_child(ban)

# ============================================================================
# Stone well
# ============================================================================
func _build_well() -> void:
	var well := Node3D.new()
	well.position = Vector3(0, 0, 6)
	add_child(well)

	# THEME §1, §11 — try the Sketchfab CC-BY stone_well GLB first. Fall
	# through to the procedural stone-cylinder-with-posts-and-beam path if
	# the asset isn't loadable, so the village always has its well. The
	# water plane below is always added regardless of which path runs so
	# THEME §12 ripple animation (driven by group "water_planes") still
	# plays on the GLB version.
	var well_packed: PackedScene = _load_glb_safe(WELL_GLB_PATH)
	var well_used_glb: bool = false
	if well_packed != null:
		var well_inst: Node = well_packed.instantiate()
		if well_inst != null:
			well.add_child(well_inst)
			if well_inst is Node3D:
				# Most stylized stone-well exports sit ~2m tall; nudge to
				# match the procedural ~1.0m ring + 1.8m posts (≈2.8m total).
				(well_inst as Node3D).scale = Vector3(1.15, 1.15, 1.15)
			well_used_glb = true
			# Trunk-ring collider so the player can lean against the well
			# but not fall into the water plane through the sides.
			var well_body: StaticBody3D = StaticBody3D.new()
			var well_col: CollisionShape3D = CollisionShape3D.new()
			var well_cyl: CylinderShape3D = CylinderShape3D.new()
			well_cyl.radius = 1.25
			well_cyl.height = 1.0
			well_col.shape = well_cyl
			well_col.position.y = 0.5
			well_body.add_child(well_col)
			well.add_child(well_body)
			# THEME §13 — settle to ground so the rim doesn't half-sink.
			call_deferred("_settle_to_ground", well)

	if not well_used_glb:
		# ─── Procedural fallback (legacy primitive path) ─────────────────────
		# Base ring
		var ring := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 1.1; cm.bottom_radius = 1.2
		cm.height = 1.0
		ring.mesh = cm
		ring.material_override = MAT_STONE(1.5)
		ring.position.y = 0.5
		well.add_child(ring)
	# Water
	var water_mat := StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.05, 0.18, 0.28)
	water_mat.metallic = 0.3
	water_mat.roughness = 0.2
	water_mat.emission_enabled = true
	water_mat.emission = Color(0.1, 0.3, 0.5)
	water_mat.emission_energy_multiplier = 0.15
	var water := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(2.0, 2.0)
	water.mesh = pm
	water.material_override = water_mat
	water.position.y = 0.85
	water.add_to_group("water_planes")  # THEME §12 — animated by _process
	water.set_meta("rest_y", 0.85)
	water.set_meta("ripple_amp", 0.018)
	water.set_meta("ripple_freq", 1.4)
	well.add_child(water)
	# Posts + crossbeam (the rope and bucket frame) — only when the GLB
	# didn't render its own. The campfire/lantern/tree paths follow the
	# same fallback contract.
	if not well_used_glb:
		for dx in [-1.0, 1.0]:
			var p := MeshInstance3D.new()
			var pcm := CylinderMesh.new()
			pcm.top_radius = 0.08; pcm.bottom_radius = 0.08; pcm.height = 1.8
			p.mesh = pcm
			p.material_override = MAT_DARK_WOOD(0.4)
			p.position = Vector3(dx, 1.9, 0)
			well.add_child(p)
		var beam := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(2.4, 0.16, 0.16)
		beam.mesh = bm
		beam.material_override = MAT_DARK_WOOD(0.5)
		beam.position.y = 2.85
		well.add_child(beam)

# ============================================================================
# Pond — small reflective water plane
# ============================================================================
func _build_pond() -> void:
	var pond := Node3D.new()
	pond.position = Vector3(-18, 0, 14)
	add_child(pond)
	var water_mat := StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.08, 0.22, 0.30)
	water_mat.metallic = 0.65
	water_mat.roughness = 0.08
	water_mat.emission_enabled = true
	water_mat.emission = Color(0.15, 0.40, 0.55)
	water_mat.emission_energy_multiplier = 0.18
	var w := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(8.0, 6.0)
	w.mesh = pm
	w.material_override = water_mat
	w.position.y = 0.04
	w.add_to_group("water_planes")  # THEME §12 — animated by _process
	w.set_meta("rest_y", 0.04)
	w.set_meta("ripple_amp", 0.035)
	w.set_meta("ripple_freq", 0.9)
	pond.add_child(w)
	# Reeds along edge
	var rng := RandomNumberGenerator.new(); rng.randomize()
	for i in 24:
		var ang: float = rng.randf() * TAU
		var rx: float = cos(ang) * (3.5 + rng.randf() * 0.5)
		var rz: float = sin(ang) * (2.5 + rng.randf() * 0.5)
		var reed := MeshInstance3D.new()
		var rcm := CylinderMesh.new()
		rcm.top_radius = 0.0; rcm.bottom_radius = 0.04
		rcm.height = 0.6 + rng.randf() * 0.4
		reed.mesh = rcm
		var rm := StandardMaterial3D.new()
		rm.albedo_color = Color(0.35, 0.5, 0.18)
		rm.roughness = 0.85
		reed.material_override = rm
		reed.position = Vector3(rx, 0.3, rz)
		# Env: 2026-05-06 — reeds were static; added to "reeds" group with a
		# per-reed phase so _process() can sway them like the ferns/grass tufts
		# (THEME §12 — every visible thing must move).
		reed.add_to_group("reeds")
		reed.set_meta("phase", rng.randf() * TAU)
		pond.add_child(reed)

# ============================================================================
# Floating fireflies — GPUParticles3D
# ============================================================================
func _build_firefly_particles() -> void:
	# Env: 2026-05-06 — re-enabled with soft radial alpha (THEME §12)
	var spots = [Vector3(0, 0, 0), Vector3(15, 0, 12), Vector3(-15, 0, -12), Vector3(0, 0, 18)]
	for s in spots:
		var p := GPUParticles3D.new()
		p.position = s + Vector3(0, 1.5, 0)
		p.amount = 18  # 2026-05-08: 60→18 (too many caused white speck carpet)
		p.lifetime = 4.0
		p.preprocess = 2.0
		p.visibility_aabb = AABB(Vector3(-12, -2, -12), Vector3(24, 6, 24))
		var pm := ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pm.emission_box_extents = Vector3(8, 1.5, 8)
		pm.gravity = Vector3(0, 0.05, 0)
		pm.initial_velocity_min = 0.1
		pm.initial_velocity_max = 0.6
		pm.scale_min = 0.4  # 2026-05-08: reduced
		pm.scale_max = 0.7
		pm.color = Color(1.0, 0.85, 0.35)
		p.process_material = pm
		var qm := QuadMesh.new()
		qm.size = Vector2(0.06, 0.06)
		var dm := StandardMaterial3D.new()
		dm.albedo_color = Color(1.0, 0.9, 0.5)
		dm.emission_enabled = true
		dm.emission = Color(1.0, 0.75, 0.25)
		dm.emission_energy_multiplier = 1.2  # 2026-05-08: 4.0→1.2 (was causing white HDR blowout)
		dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
		dm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		dm.albedo_texture = _make_soft_particle_texture()
		qm.material = dm
		p.draw_pass_1 = qm
		add_child(p)

# ============================================================================
# Butterflies — daytime ambient life
# THEME §12 lists "butterflies, fireflies at night, birds in V-formations,
# falling leaves" as ambient life that brings the world alive. Fireflies
# (night) and falling leaves were already wired by prior environment runs;
# butterflies (day) are the missing third pillar. Five GPUParticles3D
# emitters across the meadow + village edge push pale-wing quads upward
# with a horizontal tangential wander so they read as fluttering rather
# than rising smoke. Wing colors pull from the §3 sunset palette accent
# tier (soft yellow, pale orange, alabaster) so they catch the painterly
# light without going neon.
# Per THEME §13 the emission boxes sit slightly above ground (y=0.6) so
# butterflies never spawn inside the dirt; lifetime keeps them alive long
# enough to drift through ~3m of vertical sunbeam before fading.
# Each emitter joins group "butterflies" so future _process tweaks can
# vary speed by time-of-day if a day/night cycle ships.
# ============================================================================
const BUTTERFLY_SPOTS: Array = [
	Vector3( 12.0, 0.6,  20.0),  # meadow east — sunny clearing
	Vector3(-18.0, 0.6,  10.0),  # west pasture by pond
	Vector3(  8.0, 0.6, -22.0),  # forest fringe south
	Vector3(-22.0, 0.6, -18.0),  # whisperwood edge
	Vector3(  0.0, 0.6,  30.0),  # village far approach
]
const BUTTERFLY_PALETTE: Array = [
	Color(1.00, 0.92, 0.55),  # pale lemon — Old World swallowtail
	Color(1.00, 0.65, 0.28),  # painterly orange — fritillary
	Color(0.94, 0.88, 0.78),  # alabaster — cabbage white tinted warm
	Color(0.85, 0.55, 0.18),  # bronze accent (THEME §3 secondary)
	Color(0.62, 0.74, 0.42),  # moss-pale — common brimstone
]

func _build_butterflies() -> void:
	# Env: 2026-05-06 — daytime ambient life (THEME §12). No emission/glow:
	# unlike fireflies, butterflies catch ambient sun rather than emit it.
	for i in BUTTERFLY_SPOTS.size():
		var spot: Vector3 = BUTTERFLY_SPOTS[i]
		var wing_color: Color = BUTTERFLY_PALETTE[i % BUTTERFLY_PALETTE.size()]
		var p := GPUParticles3D.new()
		p.position = spot
		p.amount = 14
		p.lifetime = 5.5
		p.preprocess = 3.0
		# Butterflies wander in a low cylinder ~6m wide, 2m tall above the spot.
		p.visibility_aabb = AABB(Vector3(-7, -1, -7), Vector3(14, 4, 14))
		var pm := ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pm.emission_box_extents = Vector3(3.0, 0.4, 3.0)
		# Drift gently upward — opposite of falling leaves.
		pm.direction = Vector3(0, 1, 0)
		pm.spread = 55.0
		pm.gravity = Vector3(0, 0.05, 0)
		pm.initial_velocity_min = 0.20
		pm.initial_velocity_max = 0.55
		# Horizontal wander reads as fluttering wings catching the breeze.
		pm.tangential_accel_min = 0.6
		pm.tangential_accel_max = 1.6
		pm.angular_velocity_min = -180.0
		pm.angular_velocity_max =  180.0
		pm.scale_min = 0.55
		pm.scale_max = 1.15
		pm.color = wing_color
		# Fade in + out so the wings appear to flit into and out of sunbeams
		# rather than popping at spawn or clipping the ground (§13).
		var ramp := Gradient.new()
		# 4-point fade so wings flit IN and OUT of sunbeams. Setting offsets +
		# colors as packed arrays sidesteps the add_point() index-drift trap
		# that bites when you mix set_color(1,…) with add_point() calls.
		ramp.offsets = PackedFloat32Array([0.0, 0.15, 0.85, 1.0])
		ramp.colors = PackedColorArray([
			Color(1, 1, 1, 0),
			Color(1, 1, 1, 1),
			Color(1, 1, 1, 1),
			Color(1, 1, 1, 0),
		])
		var ramp_tex := GradientTexture1D.new()
		ramp_tex.gradient = ramp
		pm.color_ramp = ramp_tex
		p.process_material = pm
		# Tiny pair-of-wings quad. Cull disabled so it reads from both sides.
		var qm := QuadMesh.new()
		qm.size = Vector2(0.14, 0.10)
		var dm := StandardMaterial3D.new()
		dm.albedo_color = wing_color
		dm.albedo_texture = _make_soft_particle_texture()
		dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		dm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		dm.cull_mode = BaseMaterial3D.CULL_DISABLED
		dm.vertex_color_use_as_albedo = true
		# A whisper of warm emission so they catch the eye in shaded canopy
		# without going neon (THEME §3 bans fluorescent palette).
		dm.emission_enabled = true
		dm.emission = wing_color
		dm.emission_energy_multiplier = 0.25
		qm.material = dm
		p.draw_pass_1 = qm
		p.add_to_group("butterflies")
		add_child(p)


# ============================================================================
# Chimney smoke from each building
# ============================================================================
# ============================================================================
# Falling leaves — drifting autumn leaves through the Whisperwood canopy
# THEME §1 painterly fantasy aesthetic, §11 Studio Ghibli watercolor reference,
# §12 motion mandate (no static "should-move" props), §3 warm sunset palette.
# Five GPUParticles3D emitters at canopy height (~7m) push small leaf-quads
# downward with tangential tumble + horizontal sway. Each emitter takes a
# different palette color so the meadow ripples with golds, oranges, russets,
# and the occasional moss-green. Leaves fade out via color_ramp before the
# ground plane (THEME §13 ground contact — no leaves clipping below y=0).
# Emission boxes are wide (16x16) so the effect catches dense canopy regions
# without needing exact tree positions.
# ============================================================================
const FALLING_LEAF_SPOTS: Array = [
	Vector3( 22.0, 7.0, -18.0),
	Vector3(-26.0, 7.0, -10.0),
	Vector3(-12.0, 7.0,  28.0),
	Vector3( 30.0, 7.0,  14.0),
	Vector3( -4.0, 7.0, -34.0),
]
const LEAF_PALETTE: Array = [
	Color(1.00, 0.85, 0.42),  # sunset gold (THEME §3 primary)
	Color(1.00, 0.50, 0.20),  # burnt orange
	Color(0.55, 0.27, 0.10),  # autumn russet
	Color(0.29, 0.44, 0.22),  # forest moss
	Color(0.85, 0.55, 0.18),  # hammered bronze accent (THEME §3 secondary)
]

func _build_falling_leaves() -> void:
	# Env: 2026-05-06 — re-enabled with soft radial alpha (THEME §12)
	for i in FALLING_LEAF_SPOTS.size():
		var spot: Vector3 = FALLING_LEAF_SPOTS[i]
		var leaf_color: Color = LEAF_PALETTE[i % LEAF_PALETTE.size()]
		var p := GPUParticles3D.new()
		p.position = spot
		p.amount = 28
		p.lifetime = 6.5
		p.preprocess = 4.0
		p.visibility_aabb = AABB(Vector3(-10, -8, -10), Vector3(20, 16, 20))
		var pm := ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pm.emission_box_extents = Vector3(8.0, 0.5, 8.0)
		pm.direction = Vector3(0, -1, 0)
		pm.spread = 35.0
		pm.gravity = Vector3(0, -0.55, 0)
		pm.initial_velocity_min = 0.15
		pm.initial_velocity_max = 0.45
		pm.angular_velocity_min = -90.0
		pm.angular_velocity_max =  90.0
		pm.tangential_accel_min = 0.4
		pm.tangential_accel_max = 1.1
		pm.scale_min = 0.55
		pm.scale_max = 1.30
		pm.color = leaf_color
		# Fade alpha over lifetime so leaves don't pop at ground (§13 contact)
		var ramp := Gradient.new()
		ramp.set_color(0, Color(1, 1, 1, 1))
		ramp.set_color(1, Color(1, 1, 1, 0))
		var ramp_tex := GradientTexture1D.new()
		ramp_tex.gradient = ramp
		pm.color_ramp = ramp_tex
		p.process_material = pm
		var qm := QuadMesh.new()
		qm.size = Vector2(0.18, 0.10)
		var dm := StandardMaterial3D.new()
		dm.albedo_color = leaf_color
		dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		dm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		dm.cull_mode = BaseMaterial3D.CULL_DISABLED
		dm.vertex_color_use_as_albedo = true
		dm.albedo_texture = _make_soft_particle_texture()
		qm.material = dm
		p.draw_pass_1 = qm
		p.add_to_group("falling_leaves")
		add_child(p)


# ============================================================================
# Env: 2026-05-06 — Bird V-formation flocks (THEME §12)
# THEME §12 explicitly lists "birds in V-formations" as required ambient life.
# A previous comment on _build_butterflies acknowledged the gap. This adds
# 3 small flocks of stylized bird silhouettes that drift across the sky in
# tight V wedges, with each bird wing-bobbing on its own phase. No emission
# or glow (THEME §3 — birds are silhouettes against sky, not lanterns).
#
# Birds are tiny dark BoxMesh slivers (0.30 x 0.04 x 0.10) with a faint
# painterly tint (charcoal-warm from THEME §3). Cull-disabled so they read
# from any angle. The flock parent Node3D drifts at ~6 m/s on a heading
# stored in meta; once a flock crosses the world bounds it teleports to the
# opposite side, which is invisible at 40m altitude with the Mountain Ring
# silhouette breaking up the horizon.
#
# Group: "bird_flocks" — driven by _process for translation & yaw.
# Per-bird group: "bird_wings" — driven by _process for wing-bob.
# ============================================================================
const BIRD_FLOCK_COUNT: int = 3
const BIRD_PER_FLOCK: int = 7
const BIRD_FLOCK_ALTITUDE_MIN: float = 38.0
const BIRD_FLOCK_ALTITUDE_MAX: float = 52.0
# World half-extent for wrap-around. Chosen to match the Mountain Ring (220m)
# so flocks loop behind silhouette rather than popping in mid-frame.
const BIRD_WORLD_BOUND: float = 240.0
# Charcoal-warm silhouette (THEME §3 ink black + a touch of warmth so it
# doesn't read as pure black against the sunset palette).
const BIRD_BODY_COLOR: Color = Color(0.10, 0.085, 0.080)

func _build_bird_flocks() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for f in BIRD_FLOCK_COUNT:
		var flock := Node3D.new()
		flock.name = "BirdFlock%d" % f
		# Spread flocks around the village so they don't all read at once.
		var ang: float = rng.randf() * TAU
		var dist: float = 80.0 + rng.randf() * 120.0
		var alt: float = lerp(BIRD_FLOCK_ALTITUDE_MIN, BIRD_FLOCK_ALTITUDE_MAX, rng.randf())
		flock.position = Vector3(cos(ang) * dist, alt, sin(ang) * dist)
		# Heading vector — direction the V points and travels in. Re-used
		# in _process for both translation and yaw alignment.
		var heading_ang: float = rng.randf() * TAU
		var heading: Vector3 = Vector3(cos(heading_ang), 0, sin(heading_ang))
		flock.set_meta("heading", heading)
		# Speed scales gently per flock so the sky reads as multi-layered.
		flock.set_meta("speed", 5.0 + rng.randf() * 2.5)
		# Per-flock phase so wing-bobs across flocks don't lock-step.
		flock.set_meta("phase", rng.randf() * TAU)
		flock.add_to_group("bird_flocks")
		add_child(flock)
		# Build the V — lead bird at index 0, two trailing wings spreading
		# back on each side. Spacing is 1.6m back-and-out per row.
		var spacing: float = 1.6
		for i in BIRD_PER_FLOCK:
			var bird := Node3D.new()
			bird.name = "Bird%d" % i
			# Row 0 = lead, row 1 = (-1, +1), row 2 = (-2, +2), row 3 = (-3, +3)…
			var row: int = (i + 1) / 2
			var side: int = 1 if (i % 2 == 0) else -1
			# Index 0 is the lead — clamp to centerline.
			if i == 0:
				row = 0; side = 0
			# Local frame: heading points along +X (rotated by flock); birds
			# trail along -X and fan out along Z.
			bird.position = Vector3(-row * spacing, 0, side * row * spacing * 0.85)
			# Per-bird phase keeps the V from beating in unison.
			bird.set_meta("phase", rng.randf() * TAU)
			bird.set_meta("base_y", bird.position.y)
			bird.add_to_group("bird_wings")
			# Body — small flat sliver of dark mesh.
			var body := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.30, 0.04, 0.10)
			body.mesh = bm
			var mat := StandardMaterial3D.new()
			mat.albedo_color = BIRD_BODY_COLOR
			mat.roughness = 0.95
			mat.metallic = 0.0
			# Slight vertex-color allowance so future tints don't fight us.
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			body.material_override = mat
			bird.add_child(body)
			# Two wing quads, hinged at the body, that fold up and down on
			# the wing-bob phase in _process. Quads are billboard-disabled so
			# they read as actual wings, not flat sprites.
			for wside in [-1, 1]:
				var wing := MeshInstance3D.new()
				var qm := QuadMesh.new()
				qm.size = Vector2(0.32, 0.10)
				wing.mesh = qm
				var wmat := StandardMaterial3D.new()
				wmat.albedo_color = BIRD_BODY_COLOR
				wmat.roughness = 0.92
				wmat.metallic = 0.0
				wmat.cull_mode = BaseMaterial3D.CULL_DISABLED
				wing.material_override = wmat
				# Hinge wing out from body centerline. Local +Z is "out", so
				# rotation Z controls flap (up = positive Z bend).
				wing.position = Vector3(0, 0.0, wside * 0.20)
				# Wings face up by default — quad is XY-aligned in Godot.
				wing.rotation = Vector3(0, 0, 0)
				wing.name = "Wing%s" % ("R" if wside == 1 else "L")
				bird.add_child(wing)
			# Yaw the bird so its body points along the flock heading.
			bird.rotation.y = heading_ang
			flock.add_child(bird)


func _build_smoke_chimneys() -> void:
	# Env: 2026-05-06 — re-enabled with soft radial alpha (THEME §12)
	for b in get_tree().get_nodes_in_group("buildings"):
		var chim = b.get_node_or_null("Chimney")
		if not chim: continue
		var smoke := GPUParticles3D.new()
		smoke.position = chim.position + Vector3(0, 0.9, 0)
		smoke.amount = 24
		smoke.lifetime = 5.0
		smoke.preprocess = 3.0
		var pm := ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = 0.12
		pm.gravity = Vector3(0.05, 0.4, 0)
		pm.initial_velocity_min = 0.2
		pm.initial_velocity_max = 0.4
		pm.scale_min = 0.4
		pm.scale_max = 1.6
		pm.color = Color(0.7, 0.65, 0.6, 0.4)
		smoke.process_material = pm
		var qm := QuadMesh.new()
		qm.size = Vector2(0.5, 0.5)
		var dm := StandardMaterial3D.new()
		dm.albedo_color = Color(0.85, 0.8, 0.75, 0.45)
		dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		dm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		dm.no_depth_test = false
		dm.albedo_texture = _make_soft_particle_texture()
		qm.material = dm
		smoke.draw_pass_1 = qm
		b.add_child(smoke)

# ============================================================================
# NPCs
# ============================================================================
func _build_npcs() -> void:
	for n in NPCS:
		_make_npc(n)

func _make_npc(data: Dictionary) -> void:
	var npc := StaticBody3D.new()
	npc.position = data.pos + Vector3(0, 0.0, 0)  # sit on ground; model handles its own pivot
	npc.set_script(npc_script)
	# Builder run 14 (mini-map) — NPCs join the "npcs" group so the
	# new Minimap.gd / WorldMap.gd can plot gold dots without needing
	# any direct references. Pure additive: nothing else queries this
	# group yet, but it is the first cross-cutting NPC index in the
	# repo and a natural hook for future schedule/memory readers.
	npc.add_to_group("npcs")
	npc.npc_name = data.name
	npc.npc_role = data.role
	# Wire activity animation profile for NPCs with physical roles (farming/craft/stable).
	# "npc" maps to humanoid_npc.tres (Farming_Pack) — graceful no-op if not yet built.
	var _farming_roles: PackedStringArray = PackedStringArray(["farmer", "gardener", "herbalist",
		"stablemaster", "stable_hand", "worker", "labourer", "blacksmith", "smith"])
	if data.role in _farming_roles:
		npc.anim_profile = "npc"
	npc.dialogue = data.line
	# REFINE: feed mood-dependent variants if this NPC has them defined.
	npc.dialogue_variants = PackedStringArray(data.get("lines", []))
	# INTEGRATE (pattern A): if this NPC carries a quest-warmed dialogue set,
	# wire the flag name + warm variants so NPC.gd can consult World.npc_has_flag().
	npc.warmed_flag = String(data.get("warm_flag", ""))
	npc.warmed_dialogue_variants = PackedStringArray(data.get("warm_lines", []))
	# COMPOUND (run 3 follow-up): also wire the lower-priority world-flag tier
	# so an NPC can react to global story beats (`World.world_flags`) when the
	# player hasn't personally earned a memory yet.
	npc.warmed_world_flag = String(data.get("warm_world_flag", ""))
	npc.warmed_world_dialogue_variants = PackedStringArray(data.get("warm_world_lines", []))
	# COMPOUND (run 4): wire the faction-pressure tier so an NPC can sense the
	# SHAPE of the world (e.g. Maeve → whisperwood_goblins pressure). Closes
	# the consequence-resolver loop: faction_pressure() is written by 3 quests
	# since run 2 and now has its first reader.
	npc.warmed_faction_id = String(data.get("warm_faction_id", ""))
	npc.warmed_faction_below = float(data.get("warm_faction_below", 1.0))
	npc.warmed_faction_dialogue_variants = PackedStringArray(data.get("warm_faction_lines", []))
	# COMPOUND (run 16 — Builder): wire the visit-memory tier. Both fields
	# default to off (visits_min=0, empty variants) so NPCs without authored
	# memory lines keep their existing 4-tier behavior. Maeve, Bram, and Hala
	# carry authored variants in this run; future NPCs opt in by adding
	# `memory_visits_min` + `memory_lines` to their NPCS dict entry.
	npc.warmed_memory_visits_min = int(data.get("memory_visits_min", 0))
	npc.warmed_memory_dialogue_variants = PackedStringArray(data.get("memory_lines", []))
	# run-35: wire relationship score tier (gift/insult warmed dialogue).
	npc.warmed_relationship_min = int(data.get("relationship_min", 0))
	npc.warmed_relationship_dialogue_variants = PackedStringArray(data.get("relationship_lines", []))
	# run-33: wire witnessed_defense_lines
	if "witnessed_defense_lines" in npc and data.has("defense_lines"):
		for _dl: String in data["defense_lines"]:
			npc.witnessed_defense_lines.append(_dl)
	# COMPOUND (run 9 — JSON dialogue tree): opt-in flag for JSON-tree
	# resolution via DialogueDB. Defaults false so legacy NPCs are untouched.
	npc.use_dialogue_json = bool(data.get("use_json_dialogue", false))
	# COMPOUND (run 11 — NPC schedules): pass the per-NPC schedule anchor
	# array straight through. Empty / absent = legacy stationary behavior.
	# We copy into a typed Array so Godot's strict typed-export check is
	# happy regardless of whether the literal in NPCS was inferred as
	# Array[Vector3] or untyped Array.
	var sched = data.get("schedule", null)
	if sched is Array and (sched as Array).size() > 0:
		var anchors: Array = []
		for v in (sched as Array):
			if v is Vector3:
				anchors.append(v)
		npc.schedule_anchors = anchors
	# REFINE: character — ambient bark wiring. THEME §12 MOTION & LIFE: the bark
	# system was defined in NPC.gd (run 26) but no NPC had lines authored in
	# WorldBuilder. Now each NPC's dict may carry "bark_lines", "bark_min",
	# "bark_max"; absent keys default to silent (empty array, 22-38s defaults).
	var bark_lines_raw = data.get("bark_lines", [])
	if bark_lines_raw is Array and (bark_lines_raw as Array).size() > 0:
		npc.ambient_bark_lines = Array(bark_lines_raw, TYPE_STRING, "", null)
	npc.ambient_bark_interval_min = float(data.get("bark_min", 22.0))
	npc.ambient_bark_interval_max = float(data.get("bark_max", 38.0))

	var col := CollisionShape3D.new()
	var caps := CapsuleShape3D.new()
	caps.radius = 0.4; caps.height = 1.8
	col.shape = caps
	col.position.y = 0.9
	npc.add_child(col)

	# THEME §4: prefer the per-name hand-crafted GLB; fall back to CesiumMan only
	# for NPCs we haven't sourced yet. The flat tint is applied ONLY to the
	# placeholder — real models carry their own painted textures.
	var src: PackedScene = NPC_MODELS.get(data.name, npc_scene)
	if src == null:
		src = npc_scene  # fallback to CesiumMan placeholder if GLB missing
	var uses_real_model: bool = src != npc_scene
	var model := src.instantiate()
	# Auto-normalize to ~1.8m tall (handles any authored size — supersedes the
	# hardcoded NPC_SCALES dict; the dict is left in place as a manual override
	# fallback if a future run wants to bias a specific NPC up or down).
	model.scale = NPC_SCALES.get(data.name, Vector3(1.0, 1.0, 1.0))
	call_deferred("_normalize_npc_scale", model)
	npc.add_child(model)
	if not uses_real_model:
		model.call_deferred("propagate_call", "set", ["modulate", data.tint])
	else:
		# Auto-play any embedded idle animation if the source GLB ships one.
		npc.call_deferred("_npc_play_idle_anim_if_any")

	var label := Label3D.new()
	label.text = data.name
	# REFINE: character — nameplate font_size 28 → 30 so the kids can read 'Stablemaster Roan' at the back of the screen. Pet.gd's Ember nameplate already lives at 20pt; villager labels deserve a bit more weight.
	label.font_size = 30
	# REFINE: character — outline_size 6 → 7 so the nameplate stays legible when a villager stands against the bright sunset HDRI sky-band (THEME §3 — palette is sunset-warm; black outline must hold its own).
	label.outline_size = 7
	label.outline_modulate = Color(0, 0, 0)
	# REFINE: character — nameplate tint (1, 0.85, 0.4) → (1.0, 0.86, 0.46). Slight shift toward THEME §3 sunset-gold (#FFD86B family) — same direction the Chest.gd glow_color was warmed in the previous polish run. Reads as 'lit by the sun' not 'painted yellow'.
	label.modulate = Color(1.0, 0.86, 0.46)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	# REFINE: character — nameplate y 2.4 → 2.55. At 2.4 the label sat ON the hood of taller villagers (Hala in particular); 2.55 floats it cleanly above every villager silhouette without feeling detached.
	label.position = Vector3(0, 2.55, 0)
	label.name = "Label3D"
	npc.add_child(label)

	var area := Area3D.new()
	area.name = "InteractArea"
	area.monitoring = true           # must be true for body_entered to fire
	area.collision_mask = 2          # layer 2 = player (collision_layer set in Player._ready)
	npc.add_child(area)
	var acol := CollisionShape3D.new()
	var ashape := SphereShape3D.new()
	# REFINE: character — InteractArea radius 2.5 → 2.7 m. Alden's low-friction-interaction affinity: a slightly wider 'within talking distance' bubble means he doesn't have to plant himself directly on top of a villager to trigger the prompt. Owen still walks past at speed without spurious triggers (the player_in_range gate clears on body_exit).
	ashape.radius = 2.7
	acol.shape = ashape
	# REFINE: character — InteractArea y 1.0 → 1.1. Centers the sphere around the villager's chest rather than waist, so a player approaching from a slope still trips the area on the chest line (THEME §13 ground-contact spirit — geometry follows where bodies actually meet).
	acol.position.y = 1.1
	area.add_child(acol)

	# PHYSICS FIX 2026-05-08: add_child(npc) moved here from early in _make_npc().
	# In Godot 4, @onready and _ready() fire when a node enters the scene tree
	# (i.e. at add_child time). The original code called add_child(npc) before
	# $Label3D and $InteractArea were added, so both @onready vars resolved to
	# null — NPC nameplates were invisible and E-key dialogue never connected.
	add_child(npc)

# ============================================================================
# Grass tufts — plane cards (cull_mode disabled, lit)
# ============================================================================
func _build_grass_tufts(count: int) -> void:
	var rng := RandomNumberGenerator.new(); rng.randomize()
	var grass_mat := StandardMaterial3D.new()
	grass_mat.albedo_color = Color(0.42, 0.62, 0.22)
	grass_mat.roughness = 0.85
	grass_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	grass_mat.rim_enabled = true
	grass_mat.rim = 0.5
	for i in count:
		var pos: Vector3 = Vector3(rng.randf_range(-60, 60), 0, rng.randf_range(-60, 60))
		if pos.length() < 4: continue
		var tuft := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0; cm.bottom_radius = 0.08
		cm.height = 0.5 + rng.randf() * 0.3
		cm.radial_segments = 4
		tuft.mesh = cm
		tuft.material_override = grass_mat
		tuft.position = pos + Vector3(0, cm.height / 2, 0)
		tuft.add_to_group("grass")
		add_child(tuft)

# ============================================================================
# Enemies — Whisperwood goblin camps + scattered wolves
# ============================================================================
const ENEMY_SCRIPT = preload("res://scripts/Enemy.gd")
const BOSS_SCRIPT  = preload("res://scripts/Boss.gd")
const PET_SCRIPT   = preload("res://scripts/Pet.gd")
const CHEST_SCRIPT = preload("res://scripts/Chest.gd")

func _build_enemies() -> void:
	var rng := RandomNumberGenerator.new(); rng.randomize()

	# REFINE: world-engine — goblin spawn density reads faction pressure.
	# Closes the consequence-resolver loop: dialogue tier 3 (run 4) SPEAKS
	# the faction state; spawning now ENACTS it. Single read of
	# World.faction_pressure("whisperwood_goblins"); see SYSTEM_REGISTRY.md
	# "Faction Schema" + "Goblin Spawn Schema". Fail-soft: missing/older
	# World autoload → baseline (4 scouts + 1 brute, pre-run-5 behavior).
	var goblin_pressure: float = 1.0
	var world_node: Node = get_parent()
	if world_node and world_node.has_method("faction_pressure"):
		goblin_pressure = float(world_node.faction_pressure("whisperwood_goblins"))
	var camp_size: Dictionary = _goblin_camp_size(goblin_pressure)
	var scout_count: int = int(camp_size.get("scouts", 4))
	var brute_count: int = int(camp_size.get("brutes", 1))
	assert(scout_count >= 0 and scout_count <= 4, "scout_count out of contract")
	assert(brute_count >= 0 and brute_count <= 1, "brute_count out of contract")

	# Three goblin camps in the Whisperwood (outside the village)
	var camp_centers = [
		Vector3(35, 0, 35),
		Vector3(-40, 0, 30),
		Vector3(20, 0, -45),
	]
	for camp in camp_centers:
		# Per-camp scout count is faction-pressure-driven (was hard-coded 4)
		_make_goblin_camp(camp)
		for i in scout_count:
			var ang: float = rng.randf() * TAU
			var r: float = rng.randf_range(2.5, 6.0)
			var pos: Vector3 = camp + Vector3(cos(ang) * r, 0, sin(ang) * r)
			_spawn_enemy("goblin", pos, "Goblin Scout", 28, 6, 18, 4)

	# A Goblin Brute per camp, suppressed entirely once pressure drops below 0.4
	for camp in camp_centers:
		for j in brute_count:
			# REFINE: balance — Goblin Brute hp 56→95, damage 11→13. PX difficulty_targets.md
			# §TTK-band: Brute is "Tough" tier, target 4–7s. At L2 iron_sword (eff DPS 27.3):
			# 56 HP = ~2 swings ≈ 2.1s realistic — outside band (reads as trash). 95 HP =
			# 3–4 swings ≈ 3.5–5.0s realistic — center of Tough band. Damage 11→13 preserves
			# threat shape (Brute hits harder than Scout) while staying in damage-taken budget.
			# Cited: pacing/difficulty_targets.md PX rec #1.
			_spawn_enemy("goblin", camp + Vector3(2, 0, 0), "Goblin Brute", 95, 13, 36, 9,
				Color(0.30, 0.55, 0.20), 0.95, 1.0)

	# Player-facing feedback (Rule 2 iii): one-shot ambient toast at world
	# build if the wood is *visibly* calmer than baseline. Pairs with the
	# quest-completion toasts already in apply_consequence() — those announce
	# the change at the moment of action; this one announces the persistent
	# state on every load thereafter. Deferred to next tick so the HUD exists.
	if (scout_count < 4 or brute_count < 1) and world_node and world_node.has_method("_show_toast"):
		world_node.call_deferred("_show_toast", "🌿 You sense fewer goblins in the wood.")

	# REFINE: world-engine (run 6) — wolf pack density mirrors goblin pattern.
	# Read World.faction_pressure("dire_wolves") (baseline 0.5 from Faction
	# Schema). pelt_for_lyra is a -0.1 reducer → first completion takes the
	# wood from 4 wolves to 3. Same fail-soft contract as goblins: missing
	# accessor → baseline. See SYSTEM_REGISTRY.md "Wolf Spawn Schema".
	var wolf_pressure: float = 0.5
	if world_node and world_node.has_method("faction_pressure"):
		wolf_pressure = float(world_node.faction_pressure("dire_wolves"))
	var pack_size: Dictionary = _wolf_pack_size(wolf_pressure)
	var wolf_count: int = int(pack_size.get("count", 4))
	assert(wolf_count >= 0 and wolf_count <= 4, "wolf_count out of contract")

	# Stable position list — fewer wolves means we drop the LAST entries first
	# so positions 0..wolf_count remain consistent across saves. Empty patches
	# of forest where a wolf used to roam read as "they used to be here."
	var wolf_spots: Array = [
		Vector3(15, 0, 25), Vector3(-25, 0, -25), Vector3(50, 0, -10), Vector3(-15, 0, 50)
	]
	for i in wolf_count:
		var w: Vector3 = wolf_spots[i]
		# REFINE: balance — Dire Wolf hp 40→52. PX difficulty_targets.md §TTK-band:
		# Wolf is "Standard" tier, target 2.5–4.5s. At L2 iron_sword (eff DPS 27.3):
		# 40 HP = ~2 swings ≈ 1.5s realistic — outside band (too fast). 52 HP =
		# ~2 swings ≈ 1.9–2.8s realistic — base of Standard band. XP/gold unchanged.
		# Cited: pacing/difficulty_targets.md §L2 audit, Dire Wolf row.
		_spawn_enemy("wolf", w, "Dire Wolf", 52, 9, 28, 6,
			Color(0.55, 0.50, 0.45), 0.8, 1.05)

	# Player-facing feedback (Rule 2 iii): one-shot toast at world build if
	# the wolf packs are thinner than baseline. Messaged separately from the
	# goblin toast so kids can tell which faction shrank. Deferred so HUD exists.
	if wolf_count < 4 and world_node and world_node.has_method("_show_toast"):
		world_node.call_deferred("_show_toast", "🐺 The wolf packs feel thinner.")

	# REFINE: world-engine (run 22) — bandit camp on the south road. Reads
	# World.faction_pressure("bandits") (INVERTED semantics: high = BOLD,
	# more bandits; low = dormant, empty camp). Same fail-soft contract as
	# goblin/wolf pressure reads: missing world / accessor → baseline
	# (pressure 0.0, dormant — fresh-save behavior). The "bandits" faction
	# pressure is derived by World.update_bandit_pressure() each time a
	# consequence resolves; bandits surface AFTER the player has tamed
	# enough goblins+wolves that the woods feel safe. See SYSTEM_REGISTRY.md
	# "Bandit Spawn Schema" — thresholds 0.20/0.40/0.55/0.70 → 0/1/2/3/4.
	# At fresh save (bandits pressure approx 0.05) the camp is EMPTY but the
	# camp prop spawns anyway as foreshadowing — the cold ash log + plank
	# tells the player "someone's been camping here."
	var bandit_pressure: float = 0.0
	if world_node and world_node.has_method("faction_pressure"):
		bandit_pressure = float(world_node.faction_pressure("bandits"))
	var bandit_pop: Dictionary = _bandit_camp_size(bandit_pressure)
	var bandit_count: int = int(bandit_pop.get("count", 0))
	assert(bandit_count >= 0 and bandit_count <= 4, "bandit_count out of contract")

	# South road bandit camp — past the path-network terminus at z=-12, far
	# enough south that the silhouette of the camp doesn't bleed into the
	# village skyline. x=2 keeps it just off the central road axis so the
	# player walks INTO the camp when traveling south, not past it. THEME
	# §13 ground contact: y=0 for the camp prop; _spawn_enemy lifts bandits
	# +1.0 m to keep feet on the path (same lift goblins/wolves use).
	var bandit_camp: Vector3 = Vector3(2, 0, -55)
	_make_bandit_camp(bandit_camp)
	for i in bandit_count:
		var ang: float = rng.randf() * TAU
		var r: float = rng.randf_range(2.0, 5.5)
		var pos: Vector3 = bandit_camp + Vector3(cos(ang) * r, 0, sin(ang) * r)
		# Stat profile: between Goblin Scout and Goblin Brute. Bandits are
		# armed humans with looted gear — readable as "harder than a scout,
		# softer than a brute." HP 42, dmg 9, xp 24, gold 8.
		# Tint: dark weathered leather (THEME §3 charcoal-leather palette,
		# §4 hooded silhouette). Movespd matches Goblin Scout (2.6/4.6) but
		# chase 4.8 — road-ambushers are slightly more committed once seen.
		_spawn_enemy("bandit", pos, "Bandit Ambusher", 42, 9, 24, 8,
			Color(0.30, 0.22, 0.18), 2.6, 4.8)

	# Player-facing feedback (Rule 2 iii): one-shot toast at world build
	# whenever the bandit camp is populated. Mirrors the goblin/wolf toast
	# pattern with INVERTED phrasing — bandits APPEARING reads as a fresh
	# threat, not a calmer wood. Composes with Roan's `bandits_emergent`
	# warm_world_flag dialogue (run 21) so the village voice and the
	# road state agree at every load. Deferred so the HUD exists.
	if bandit_count > 0 and world_node and world_node.has_method("_show_toast"):
		world_node.call_deferred("_show_toast", "Hooded figures stalk the south road.")

	# COMPOUND (run 23 — Builder): Bandit Captain mini-boss. Spawns ONLY at
	# the extreme-tame pressure rung (≥0.70 → bandit_count == 4) where the
	# south-road camp is fully populated. _bandit_captain_should_spawn
	# returns true at that single threshold so the captain is RARE — Owen-
	# tier mastery beat after the player has visibly tamed both goblins
	# AND wolves enough that bandits feel safe in numbers. THEME §13:
	# captain rides 0.6m closer to the camp pit so the silhouette reads
	# as "the one giving orders," and the +1.0m Y lift in _spawn_enemy
	# keeps feet on the path. Tag bandit_count fed forward — the captain
	# does NOT increment bandit_count; the assert above (≤4) holds.
	if _bandit_captain_should_spawn(bandit_pressure):
		var captain_pos: Vector3 = bandit_camp + Vector3(0, 0, -0.6)
		# Stat profile: ~3.0× HP of regular bandit (42 → 130), +60% damage
		# (9 → 15), ~5× xp (24 → 120), ~6× gold (8 → 50). Sits between
		# Goblin Brute (90 hp) and Goblin Warlord (~600 hp) — a true
		# mini-boss. Tint deepened to bruise-purple leather so the captain
		# reads as a tier above the dark-charcoal regulars at 30m. Move
		# speed matches regular bandits; chase speed up 0.2 ("commits
		# harder"). All other adaptive bands (cooldown/chase/damage/xp)
		# already light up via the bandits-faction mapping in Enemy.gd.
		_spawn_enemy("bandit_captain", captain_pos, "Bandit Captain", 130, 15, 120, 50,
			Color(0.32, 0.18, 0.30), 2.6, 5.0)
		# Capoeira fighter — rare enforcer guarding the bandit camp
		var cap_fighter_pos: Vector3 = captain_pos + Vector3(4.0, 0, -3.0)
		_spawn_enemy("capoeira_fighter", cap_fighter_pos, "Capoeira Enforcer", 90, 16, 85, 30,
			Color(0.80, 0.60, 0.25), 3.0, 5.5)
		# Player-facing feedback (Rule 2 iii): captain-arrival toast lands
		# AFTER the regular hooded-figures toast so the kids hear the
		# escalation as two beats. Distinct emoji (🗡️) and phrasing so
		# Alden's HUD log reads the captain as a separate event in the
		# scrollback.
		if world_node and world_node.has_method("_show_toast"):
			world_node.call_deferred("_show_toast", "🗡️ A Captain leads the south-road camp.")

	# Goblin Warlord — boss in the deepest part of the Whisperwood
	_build_boss_arena(Vector3(60, 0, 60))

# Goblin Spawn Schema (run 5) — derive per-camp population from faction
# pressure. Read accessor: World.faction_pressure("whisperwood_goblins")
# in [0.0, 1.0]. Thresholds co-fire with NPC.gd's tier-3 dialogue:
#   - <0.9 (after one reducer quest)  → 3 scouts + 1 brute  (Maeve speaks)
#   - <0.7 (noticeably safer)         → 2 scouts + 1 brute
#   - <0.4 (halfway tamed)            → 2 scouts + 0 brute
#   - <0.15 (definitively tamed)      → 1 scout  + 0 brute
# At pressure 1.0 (fresh save): baseline 4 scouts + 1 brute — identical to
# pre-run-5 behavior. Empty camp prop (campfire / huts) persists below
# threshold as a "they used to be here" memorial.
func _goblin_camp_size(pressure: float) -> Dictionary:
	var p: float = clamp(pressure, 0.0, 1.0)
	var scouts: int = 4
	var brutes: int = 1
	if p < 0.9:
		scouts = 3
	if p < 0.7:
		scouts = 2
	if p < 0.4:
		brutes = 0
	if p < 0.15:
		scouts = 1
	return {"scouts": scouts, "brutes": brutes}

# Wolf Spawn Schema (run 6) — same shape as goblin spawn schema. Read accessor:
# World.faction_pressure("dire_wolves") in [0.0, 1.0], baseline 0.5.
# Thresholds were chosen so a SINGLE pelt_for_lyra completion (-0.1 → 0.4)
# is visible (4 wolves → 3) while still allowing future reducers to taper:
#   >= 0.5 → 4 wolves (baseline / fresh save)
#   < 0.5  → 3 wolves (one reducer applied)
#   < 0.3  → 2 wolves (two further reducers)
#   < 0.15 → 1 wolf   (definitively tamed Whisperwood)
# pelt_for_lyra is the single reducer today; future runs will likely add a
# Roan-issued wolf-bounty to take the path 0.4 → 0.3 → 0.2 in two more steps.
func _wolf_pack_size(pressure: float) -> Dictionary:
	var p: float = clamp(pressure, 0.0, 1.0)
	var count: int = 4
	if p < 0.5:
		count = 3
	if p < 0.3:
		count = 2
	if p < 0.15:
		count = 1
	return {"count": count}

# Bandit Spawn Schema (run 22) — INVERTED-pressure derivation. Where goblin
# and wolf factions use "high pressure = many enemies, threat unresolved",
# the bandits faction uses "high pressure = bandits feel SAFE enough to come
# out". Read accessor: World.faction_pressure("bandits") in [0.0, 0.80]
# (capped by update_bandit_pressure's 0.20 buffer). Thresholds align with
# the bandits_emergent world flag (fires at p >= 0.40, drives Roan's tier-3
# dialogue):
#   p < 0.20 -> 0 bandits  (camp prop is COLD ASH; foreshadowing only)
#   p < 0.40 -> 1 bandit   (lone scout — sign before the flag fires)
#   p < 0.55 -> 2 bandits  (camp populated; bandits_emergent ON)
#   p < 0.70 -> 3 bandits
#   p >= 0.70 -> 4 bandits  (only reachable in extreme-tame state where
#                            BOTH goblins and wolves are deeply quieted)
# At fresh save (factions: goblin 1.0 + wolf 0.5 -> bandits ~0.05) the
# count is 0 — IDENTICAL load-time silhouette to runs 1–21 except for the
# new bandit camp PROP, which is intentionally visible as a "what's that?"
# breadcrumb. The empty camp prop persists across pressure changes the
# same way empty goblin camps do (run 5 memorial pattern).
func _bandit_camp_size(pressure: float) -> Dictionary:
	var p: float = clamp(pressure, 0.0, 1.0)
	var count: int = 0
	if p >= 0.20:
		count = 1
	if p >= 0.40:
		count = 2
	if p >= 0.55:
		count = 3
	if p >= 0.70:
		count = 4
	return {"count": count}

# COMPOUND (run 23 — Builder): Bandit Captain spawn predicate. Single-threshold
# Boolean: captain spawns ONLY at bandit pressure ≥ 0.70 — the same threshold
# that maxes _bandit_camp_size to 4 regulars. The threshold is hard-coded
# rather than derived from the camp-size dict to make the contract explicit:
# "captain only with a full camp." If a future run rebalances the camp-size
# bands, this helper must be revisited in the same edit (caught by SYSTEM_
# REGISTRY.md "Bandit Spawn Schema" doc-test pairing).
#
# At fresh save (bandits pressure ≈ 0.05) the captain stays dormant alongside
# his crew — the camp prop alone (cold ash + leaning plank) is the only
# south-road silhouette. The captain's first appearance is roughly the moment
# Roan's `bandits_emergent` warm_world dialogue tier has been resonating for
# enough screens that the player has started LOOKING for the source — and
# now the player has both the prereq quest unlocked (run 23 quest schema)
# AND the boss to chase.
func _bandit_captain_should_spawn(pressure: float) -> bool:
	return pressure >= 0.70

func _spawn_enemy(kind: String, pos: Vector3, ename: String, hp: int, dmg: int,
		xp: int, gold: int, tint: Color = Color(0.45, 0.85, 0.30),
		movespd: float = 2.6, chasespd: float = 4.6) -> void:
	var e := CharacterBody3D.new()
	e.set_script(ENEMY_SCRIPT)
	e.position = pos + Vector3(0, 1.0, 0)
	e.enemy_kind = kind
	e.enemy_name = ename
	e.max_hp = hp
	e.damage = dmg
	e.xp_reward = xp
	e.gold_reward = gold
	e.tint = tint
	e.move_speed = movespd
	e.chase_speed = chasespd
	add_child(e)

func _build_pet() -> void:
	# Spawn the player's fox companion next to the spawn point
	var pet := CharacterBody3D.new()
	pet.set_script(PET_SCRIPT)
	pet.position = Vector3(2, 1.0, 2)
	add_child(pet)

# ============================================================================
# Stable horse — wires Horse.glb (previously unused on disk). Stands in the
# yard south-west of Stablemaster Roan's anchor, named "Pippin" after the
# mare in Roan's dialogue ("Look — Pippin's grazing past the fence again").
# THEME §4 silhouette: a real horse next to the stablemaster. THEME §12
# motion: Horse.glb ships a `horse_A_` morph-target weights animation that
# auto-plays — quiet breathing/grazing, no T-pose. THEME §13 ground contact:
# horse spawned at y=0 and the source GLB has its origin near the feet
# (POSITION accessor min.y ≈ 0.8 at native units → ~0.0075 m at chosen
# scale 1/110 — well under the 0.05 m ground-contact tolerance).
# Marked as "scenery" so the global scale sweep skips it (its expected
# height is not a character standard).
# ============================================================================
const HORSE_GLB: PackedScene = preload("res://assets/models/Horse.glb")

func _build_stable_horse() -> void:
	var horse_root := Node3D.new()
	horse_root.name = "Pippin"
	horse_root.add_to_group("scenery")
	horse_root.add_to_group("stable_horses")
	# Position: south-west of the stable building (-10, 0, 0) and Roan's
	# anchor (-10, 0, -2). (-12.5, 0, -3.5) sits in the open yard; rotation
	# faces north-east so the horse looks toward Roan.
	horse_root.position = Vector3(-12.5, 0.0, -3.5)
	horse_root.rotation.y = deg_to_rad(40)
	add_child(horse_root)

	var horse_model := HORSE_GLB.instantiate()
	# Horse.glb is a Three.js export at native units (POSITION min/max y
	# spans ~182 units). Scale 1/110 puts withers at ~1.65 m — believable
	# riding-horse height; head at ~2.0 m. Keep uniform.
	var s: float = 1.0 / 110.0
	horse_model.scale = Vector3(s, s, s)
	horse_root.add_child(horse_model)

	# Auto-play whatever idle-flavored animation the GLB ships. Horse.glb's
	# only animation is `horse_A_` (morph-target weights — quiet breathing).
	# Defer one frame so the AnimationPlayer is fully wired by the importer.
	horse_root.call_deferred("set_meta", "_horse_anim_pending", true)
	call_deferred("_play_horse_idle_anim", horse_root)

	# Floating nameplate, same shape as villager Label3D (THEME §3 sunset-gold).
	var label := Label3D.new()
	label.text = "Pippin"
	label.font_size = 24
	label.outline_size = 6
	label.outline_modulate = Color(0, 0, 0)
	label.modulate = Color(1.0, 0.86, 0.46)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 2.2, 0)
	label.no_depth_test = false
	horse_root.add_child(label)

func _play_horse_idle_anim(horse_root: Node) -> void:
	if not is_instance_valid(horse_root):
		return
	var ap: AnimationPlayer = _find_horse_animation_player(horse_root)
	if ap == null:
		return
	for n in ["horse_A_", "Idle", "idle", "IdleAnimation"]:
		if ap.has_animation(n):
			ap.play(n)
			return
	var names := ap.get_animation_list()
	if names.size() > 0:
		ap.play(names[0])

func _find_horse_animation_player(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var found := _find_horse_animation_player(c)
		if found != null:
			return found
	return null

func _build_player_home() -> void:
	# Builder run 24 — Backlog #10: Housing / player-shaped spaces.
	# Places the PlayerHome cottage at HOME_POS (north plaza edge).
	# THEME §1 §3 §12 §13 — see PlayerHome.gd for full rationale.
	var home := StaticBody3D.new()
	home.set_script(HOME_SCRIPT)
	home.position = HOME_POS
	home.name = "PlayerHome"
	add_child(home)
	_dlog("player_home spawned at %s" % str(HOME_POS))

func _build_loot_chests() -> void:
	# Common chests scattered around the wilds, plus a rare chest deeper in
	var spots = [
		{"pos": Vector3( 22, 0,  10), "pool":"chest_common", "items":2},
		{"pos": Vector3(-18, 0,  22), "pool":"chest_common", "items":2},
		{"pos": Vector3( 28, 0, -30), "pool":"chest_common", "items":3},
		{"pos": Vector3(-32, 0, -18), "pool":"chest_common", "items":3},
		{"pos": Vector3( 45, 0,  20), "pool":"chest_rare",   "items":4},
		{"pos": Vector3(-45, 0,  45), "pool":"chest_rare",   "items":4},
	]
	for s in spots:
		var c := StaticBody3D.new()
		c.set_script(CHEST_SCRIPT)
		c.position = s.pos + Vector3(0, 0.0, 0)
		c.loot_pool = s.pool
		c.item_count = s.items
		if s.pool == "chest_rare":
			c.glow_color = Color(0.55, 0.45, 1.0)  # purple glow for rare chests
		c.rotation.y = randf() * TAU
		add_child(c)

func _build_boss_arena(center: Vector3) -> void:
	# A circular arena with stone monoliths around the perimeter
	var arena := Node3D.new()
	arena.position = center
	add_child(arena)
	# Stone monoliths in a ring
	var rng := RandomNumberGenerator.new(); rng.randomize()
	for i in 8:
		var ang := (float(i) / 8.0) * TAU
		var r := 9.0
		var stone := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.2, 4.5 + rng.randf() * 1.5, 1.2)
		stone.mesh = bm
		stone.material_override = MAT_STONE(1.5)
		stone.position = Vector3(cos(ang) * r, bm.size.y * 0.5, sin(ang) * r)
		stone.rotation.y = rng.randf() * 0.4
		arena.add_child(stone)
	# Skull pile in the center
	for i in 5:
		var skull := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.18; sm.height = 0.28
		skull.mesh = sm
		var sklm := StandardMaterial3D.new()
		sklm.albedo_color = Color(0.85, 0.80, 0.72)
		sklm.roughness = 0.85
		skull.material_override = sklm
		skull.position = Vector3(rng.randf_range(-0.6, 0.6), 0.1 + i * 0.05, rng.randf_range(-0.6, 0.6))
		arena.add_child(skull)
	# Banner pole behind boss
	var pole := Node3D.new()
	pole.position = Vector3(0, 0, -2)
	arena.add_child(pole)
	var post := MeshInstance3D.new()
	var pcm := CylinderMesh.new()
	pcm.top_radius = 0.06; pcm.bottom_radius = 0.06; pcm.height = 5.5
	post.mesh = pcm
	post.material_override = MAT_DARK_WOOD(0.4)
	post.position.y = 2.75
	pole.add_child(post)
	var ban_mat := StandardMaterial3D.new()
	ban_mat.albedo_color = Color(0.18, 0.32, 0.10)
	ban_mat.roughness = 0.85
	ban_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Env: 2026-05-06 — boss banner was a static QuadMesh, violating
	# THEME §12 ("banners must FLAP — Banned: static should-move props").
	# Wrap the cloth in a pivot Node3D anchored at the pole top so the
	# banner_cloths sway in _process() reads as wind passing through.
	var boss_ban_pivot := Node3D.new()
	boss_ban_pivot.position = Vector3(0, 5.4, 0)  # top of 5.5m pole
	boss_ban_pivot.add_to_group("banner_cloths")
	var _boss_ban_rng := RandomNumberGenerator.new(); _boss_ban_rng.randomize()
	boss_ban_pivot.set_meta("phase", _boss_ban_rng.randf() * TAU)
	pole.add_child(boss_ban_pivot)
	var ban := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(2.2, 1.4)
	ban.mesh = qm
	ban.material_override = ban_mat
	# Cloth hangs from the pivot, offset to one side so a small Y-rotation
	# on the pivot reads as the cloth catching wind.
	ban.position = Vector3(1.1, -1.1, 0)
	boss_ban_pivot.add_child(ban)
	# Spawn the boss
	var boss := CharacterBody3D.new()
	boss.set_script(BOSS_SCRIPT)
	boss.position = center + Vector3(0, 1.0, 0)
	add_child(boss)

func _make_goblin_camp(center: Vector3) -> void:
	# Env: 2026-05-06 — fires must flicker (THEME §12). The goblin camp fire
	# previously rendered as a constant-glow ember log + constant-energy point
	# light, which read as static props (banned). Now: ember log emission and
	# point light energy are pulsed in _process via the existing
	# "goblin_fires" group, plus a tiny spark/ember particle emitter (8 quads,
	# perf-bounded) gives the pit visible upward heat-shimmer. Bandit camps
	# stay deliberately cold (ash + no light) — narrative choice, not a bug.
	var pit := Node3D.new()
	pit.position = center
	add_child(pit)
	# Stone ring
	var rng := RandomNumberGenerator.new(); rng.randomize()
	for i in 6:
		var ang := (float(i) / 6.0) * TAU
		var stone := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.18; sm.height = 0.28
		stone.mesh = sm
		stone.material_override = MAT_STONE(0.5)
		stone.position = Vector3(cos(ang) * 0.7, 0.12, sin(ang) * 0.7)
		stone.scale = Vector3(1.0, 0.7, 1.0)
		pit.add_child(stone)
	# Glowing ember log — named "EmberLog" so the _process flicker loop can
	# pulse its emission_energy_multiplier alongside the point light.
	var log := MeshInstance3D.new()
	log.name = "EmberLog"
	var lcm := CylinderMesh.new()
	lcm.top_radius = 0.10; lcm.bottom_radius = 0.10; lcm.height = 0.9
	log.mesh = lcm
	var em := StandardMaterial3D.new()
	em.albedo_color = Color(0.20, 0.06, 0.04)
	em.emission_enabled = true
	em.emission = Color(1.0, 0.40, 0.10)
	em.emission_energy_multiplier = 1.8
	log.material_override = em
	log.rotation = Vector3(0, 0, PI / 2)
	log.position.y = 0.18
	pit.add_child(log)
	# Warm flickering point light
	var lt := OmniLight3D.new()
	lt.name = "GoblinFireLight"
	lt.light_color = Color(1.0, 0.45, 0.18)
	lt.light_energy = 1.4
	lt.omni_range = 8.0
	lt.position.y = 0.5
	pit.add_child(lt)
	# Tiny spark/ember particles. Smaller than the village campfire (8 vs 30)
	# to keep perf on a worst-case world with multiple goblin camps. Reuses
	# the soft radial alpha texture so sparks read as wisps, not squares.
	var sparks := GPUParticles3D.new()
	sparks.position.y = 0.35
	sparks.amount = 8
	sparks.lifetime = 1.2
	sparks.preprocess = 0.8
	var spm := ParticleProcessMaterial.new()
	spm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	spm.emission_sphere_radius = 0.18
	spm.gravity = Vector3(0, 1.0, 0)
	spm.initial_velocity_min = 0.3
	spm.initial_velocity_max = 0.9
	spm.scale_min = 0.10
	spm.scale_max = 0.28
	spm.color = Color(1.0, 0.55, 0.12)
	spm.color_ramp = _make_fire_gradient()
	sparks.process_material = spm
	var sqm := QuadMesh.new()
	sqm.size = Vector2(0.10, 0.10)
	var sdm := StandardMaterial3D.new()
	sdm.albedo_color = Color(1.0, 0.65, 0.20)
	sdm.albedo_texture = _make_soft_particle_texture()
	sdm.emission_enabled = true
	sdm.emission = Color(1.0, 0.45, 0.10)
	sdm.emission_energy_multiplier = 1.5
	sdm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sdm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	sqm.material = sdm
	sparks.draw_pass_1 = sqm
	pit.add_child(sparks)
	pit.add_to_group("goblin_fires")
	# THEME §13 — settle so stone ring rests on ground regardless of where
	# `center` was sampled (no half-buried embers).
	call_deferred("_settle_to_ground", pit)

# Bandit camp prop (run 22) — silhouette of an outlaw lookout: cold ash
# pit + cracked plank. Deliberately DIMMER and SMALLER than the goblin
# fire (4 stones vs 6, no glowing ember log, no warm light) — bandits
# don't want to be seen at night. The plank suggests a recent presence
# ("they were here, they'll be back") even when bandit_count == 0, which
# is the foreshadowing payload at fresh save. THEME §13: y=0 for the pit
# itself (props rest on ground); plank pivot is at base.
func _make_bandit_camp(center: Vector3) -> void:
	var pit := Node3D.new()
	pit.position = center
	pit.add_to_group("bandit_camps")
	add_child(pit)
	# Stone ring (4 stones, smaller — a hurried camp, not a settled one)
	for i in 4:
		var ang: float = (float(i) / 4.0) * TAU
		var stone := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.16; sm.height = 0.24
		stone.mesh = sm
		stone.material_override = MAT_STONE(0.5)
		stone.position = Vector3(cos(ang) * 0.55, 0.10, sin(ang) * 0.55)
		stone.scale = Vector3(1.0, 0.7, 1.0)
		pit.add_child(stone)
	# Cold ash log (charred, no emission — bandits don't keep a fire burning)
	var log_mesh := MeshInstance3D.new()
	var lcm := CylinderMesh.new()
	lcm.top_radius = 0.09; lcm.bottom_radius = 0.09; lcm.height = 0.7
	log_mesh.mesh = lcm
	var ash := StandardMaterial3D.new()
	ash.albedo_color = Color(0.10, 0.07, 0.06)
	ash.roughness = 0.95
	log_mesh.material_override = ash
	log_mesh.rotation = Vector3(0, 0, PI / 2)
	log_mesh.position.y = 0.16
	pit.add_child(log_mesh)
	# Cracked wooden plank — leaning, suggesting a hasty toll-marker. THEME
	# §8: hand-cut wooden beam, weathered, no signage runes. Future Polisher
	# / Lore run can paint a rune on it once we have a rune texture.
	var plank := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.18, 1.4, 0.04)
	plank.mesh = pm
	plank.material_override = MAT_DARK_WOOD(0.6)
	plank.position = Vector3(1.4, 0.7, 0.0)
	plank.rotation.z = -0.18  # leaning, not perfectly upright
	pit.add_child(plank)

# ============================================================================
# Campfire — stone ring, charred logs, fire particles, warm point light
# ============================================================================
func _build_campfire() -> void:
	var fire := Node3D.new()
	fire.position = Vector3(0, 0, -2)
	fire.add_to_group("campfires")
	add_child(fire)

	# THEME §1, §11 — try the Sketchfab CC-BY campfire GLB first (real stones
	# + crossed logs with painted bark + ash). Fall through to the procedural
	# stone-ring + cylinder-logs path so the hearth never disappears.
	# Particles, FireLight, and group membership stay attached to `fire`
	# regardless of which path renders so THEME §12 motion (flicker, smoke)
	# always plays.
	var camp_packed: PackedScene = _load_glb_safe(CAMPFIRE_GLB_PATH)
	var camp_used_glb: bool = false
	if camp_packed != null:
		var camp_inst: Node = camp_packed.instantiate()
		if camp_inst != null:
			fire.add_child(camp_inst)
			if camp_inst is Node3D:
				# Tame the export — Sketchfab campfires often come in at 1.5–2m
				# wide which dominates the plaza. 0.85x reads as a small,
				# huddleable cookfire matching the procedural footprint.
				(camp_inst as Node3D).scale = Vector3(0.85, 0.85, 0.85)
			camp_used_glb = true
			# THEME §13 — make sure the rim of stones contacts ground rather
			# than half-sinking, regardless of where the GLB's pivot lives.
			call_deferred("_settle_to_ground", fire)

	if not camp_used_glb:
		# ─── Procedural fallback (legacy primitive path) ─────────────────────
		# Stone ring (8 small rocks in a circle)
		for i in 8:
			var ang := (float(i) / 8.0) * TAU
			var r := 0.9
			var stone := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.18; sm.height = 0.28
			stone.mesh = sm
			stone.material_override = MAT_STONE(0.5)
			stone.position = Vector3(cos(ang) * r, 0.12, sin(ang) * r)
			stone.scale = Vector3(1.0, 0.7, 1.0)
			fire.add_child(stone)

		# Charred logs (3 crossing each other)
		for i in 3:
			var log := MeshInstance3D.new()
			var lcm := CylinderMesh.new()
			lcm.top_radius = 0.10; lcm.bottom_radius = 0.10
			lcm.height = 1.4
			log.mesh = lcm
			var lm := StandardMaterial3D.new()
			lm.albedo_color = Color(0.10, 0.06, 0.04)
			lm.roughness = 0.95
			log.material_override = lm
			log.rotation = Vector3(0, (float(i) / 3.0) * TAU, PI / 2)
			log.position.y = 0.25
			fire.add_child(log)

	# Fire particles
	var p := GPUParticles3D.new()
	p.position.y = 0.45
	p.amount = 30
	p.lifetime = 1.6
	p.preprocess = 1.0
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.25
	pm.gravity = Vector3(0, 1.2, 0)
	pm.initial_velocity_min = 0.4
	pm.initial_velocity_max = 1.2
	pm.scale_min = 0.20
	pm.scale_max = 0.55
	pm.color = Color(1.0, 0.55, 0.10)
	pm.color_ramp = _make_fire_gradient()
	p.process_material = pm
	var qm := QuadMesh.new()
	qm.size = Vector2(0.18, 0.18)
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(1.0, 0.75, 0.30)
	dm.albedo_texture = _make_soft_particle_texture()
	dm.emission_enabled = true
	dm.emission = Color(1.0, 0.45, 0.10)
	dm.emission_energy_multiplier = 1.5
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	dm.no_depth_test = false
	qm.material = dm
	p.draw_pass_1 = qm
	fire.add_child(p)

	# Smoke particles above the fire
	var smoke := GPUParticles3D.new()
	smoke.position.y = 1.4
	smoke.amount = 18
	smoke.lifetime = 4.0
	smoke.preprocess = 2.0
	var smpm := ParticleProcessMaterial.new()
	smpm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	smpm.emission_sphere_radius = 0.2
	smpm.gravity = Vector3(0.05, 0.6, 0)
	smpm.initial_velocity_min = 0.2
	smpm.initial_velocity_max = 0.4
	smpm.scale_min = 0.25
	smpm.scale_max = 0.70
	smpm.color = Color(0.55, 0.50, 0.45, 0.5)
	smoke.process_material = smpm
	var sqm := QuadMesh.new()
	sqm.size = Vector2(0.22, 0.22)
	var sdm := StandardMaterial3D.new()
	sdm.albedo_color = Color(0.7, 0.65, 0.6, 0.45)
	sdm.albedo_texture = _make_soft_particle_texture()
	sdm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sdm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	sqm.material = sdm
	smoke.draw_pass_1 = sqm
	fire.add_child(smoke)

	# Warm flickering light
	var light := OmniLight3D.new()
	light.name = "FireLight"
	light.light_color = Color(1.0, 0.55, 0.20)
	light.light_energy = 1.2
	light.omni_range = 5.0
	light.position.y = 0.7
	light.shadow_enabled = false
	fire.add_child(light)


# ============================================================================
# Env: 2026-05-06 — soft radial alpha for particle quads (THEME §12)
# Without a texture, GPUParticles3D quads using StandardMaterial3D + emission
# render as opaque rectangles. A radial GradientTexture2D gives each particle
# a soft circular alpha falloff so fireflies, leaves, and smoke read as wisps
# instead of giant white blobs. Cached so the three atmosphere builders share
# one texture (cheap GPU memory, identical look).
# ============================================================================
var _soft_particle_tex: GradientTexture2D = null
func _make_soft_particle_texture() -> GradientTexture2D:
	if _soft_particle_tex != null:
		return _soft_particle_tex
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))      # bright opaque center
	grad.set_color(1, Color(1, 1, 1, 0))      # transparent edge
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to   = Vector2(0.5, 0.0)         # radius = 0.5
	tex.width = 64
	tex.height = 64
	_soft_particle_tex = tex
	return tex

func _make_fire_gradient() -> GradientTexture1D:
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.95, 0.55, 1.0))    # bright yellow at start
	g.set_color(1, Color(0.6, 0.10, 0.05, 0.0))    # fade to dark red transparent
	g.add_point(0.4, Color(1.0, 0.45, 0.10, 0.95)) # orange middle
	var gt := GradientTexture1D.new()
	gt.gradient = g
	return gt

# ============================================================================
# Frame update — windmill, lantern flicker, gentle tree sway, fire flicker
# ============================================================================
var _t: float = 0.0
func _process(delta: float) -> void:
	_t += delta
	for b in get_tree().get_nodes_in_group("windmill_blades"):
		b.rotate_object_local(Vector3.FORWARD, 0.5 * delta)
	for lan in get_tree().get_nodes_in_group("lanterns"):
		var light: OmniLight3D = lan.get_node_or_null("OmniLight3D")
		if light:
			light.light_energy = 1.4 + sin(_t * 5.0 + lan.position.x) * 0.35
		# Env: 2026-05-06 — lantern physical rock (THEME §12). The §12
		# motion mandate explicitly names "lanterns rock"; until now
		# only the light energy flickered while the fixture itself
		# stayed bolted-still, which reads as a static "should-move"
		# prop. A slow ±2.6° Z-tilt with per-lantern phase (lifted
		# from world position) pushes the iron+glass fixture like wind
		# catches it — small enough that the post stays anchored, big
		# enough that the spotlight pool the light casts on cobble
		# wobbles visibly. Frequencies (0.9 + 1.7) sum to a slightly
		# noisy beat so neighbouring lanterns don't oscillate in unison.
		var lan3d: Node3D = lan as Node3D
		if lan3d != null:
			var lphase: float = lan3d.position.x * 0.31 + lan3d.position.z * 0.47
			var lrock: float = sin(_t * 0.9 + lphase) * 0.045 + sin(_t * 1.7 + lphase * 1.3) * 0.020
			lan3d.rotation.z = lrock
	# Subtle tree sway
	for tree in get_tree().get_nodes_in_group("trees"):
		var s = sin(_t * 0.8 + tree.position.x * 0.3) * 0.015
		tree.rotation.z = s
	# THEME §12 — fern frond sway. Slightly faster + smaller amplitude than
	# trees so the undergrowth reads as "lighter" than the canopy.
	for frond in get_tree().get_nodes_in_group("ferns"):
		var fs = sin(_t * 1.6 + frond.position.x * 0.7 + frond.position.z * 0.4) * 0.04
		frond.rotation.z = fs
	# Env: 2026-05-06 — grass tufts join group "grass" (see _build_grass_tufts)
	# but were left static. THEME §12 bans static "should-move" props, and the
	# 220 tufts ringing the village absolutely qualify. Tilt amplitude is the
	# smallest of the foliage trio (canopy 0.015 / fern 0.04 / grass 0.07) but
	# also the most spatially varied, so the meadow ripples like wind.
	for tuft in get_tree().get_nodes_in_group("grass"):
		var gs = sin(_t * 2.1 + tuft.position.x * 0.9 + tuft.position.z * 0.6) * 0.07
		tuft.rotation.z = gs
	# Env: 2026-05-06 — pond reeds (THEME §12). Reeds bend more than grass —
	# they're rooted in mud and catch the breeze across open water — so the
	# amplitude is the largest of the foliage family (canopy 0.015 / fern
	# 0.04 / grass 0.07 / reeds 0.12). Per-reed phase lifted from set_meta so
	# the cluster around the pond rim doesn't ripple in unison.
	for reed in get_tree().get_nodes_in_group("reeds"):
		var rphase: float = float(reed.get_meta("phase", 0.0))
		var rs: float = sin(_t * 1.9 + rphase) * 0.12
		var reed3d: Node3D = reed as Node3D
		if reed3d:
			reed3d.rotation.z = rs
	# Env: 2026-05-06 — mushroom breathe (THEME §12). Mushrooms shouldn't
	# sway like leaves, but "static = dead". Slow Y-scale breathe (±3%) so
	# the cap reads as alive without wobbling like a tree.
	for mush in get_tree().get_nodes_in_group("mushrooms"):
		var mush3d: Node3D = mush as Node3D
		if mush3d:
			var mb: float = 1.0 + sin(_t * 1.1 + mush3d.position.x * 0.4 + mush3d.position.z * 0.7) * 0.03
			mush3d.scale = Vector3(1.0, mb, 1.0)
	# REFINE: motion & life — village barrel creak-rock (THEME §12).
	# Village barrels joined group "village_barrels" since run N but that group was
	# never read in _process — every barrel sat perfectly static while lanterns,
	# banners, ferns, grass, and mushrooms all moved around them. A static cargo
	# prop surrounded by animated neighbours reads as a frozen-game artefact.
	# Real wooden barrels on cobblestone are never fully still: stone is uneven,
	# hoops shrink and swell, and the same breeze that catches the banners brushes
	# the courtyard. A slow Z-tilt (±1.8°, 0.032 rad) with a second micro-harmonic
	# (±0.6°) at a non-harmonic ratio (1.0 / 2.47 ≈ 0.405) gives each barrel a
	# different beat from its neighbour while staying well inside "cargo at rest"
	# semantics (canvas-top barrels tipping at the dock do ±5°; these are settled
	# village barrels so we stay at ⅓ of that). Frequency 0.41 rad/s ≈ 15.3s
	# period — slower than the lantern rock (0.9 rad/s) because barrels are heavier.
	# Per-barrel phase lifted from world position so two barrels standing side-by-side
	# (pairs near houses/stable/market) never rock in unison.
	for barrel in get_tree().get_nodes_in_group("village_barrels"):
		var b3d: Node3D = barrel as Node3D
		if b3d == null:
			continue
		var bphase: float = b3d.position.x * 0.43 + b3d.position.z * 0.61  # REFINE: per-barrel phase, spatially varied
		var brock: float = sin(_t * 0.41 + bphase) * 0.032 + sin(_t * 1.01 + bphase * 1.7) * 0.010  # REFINE: dual-harmonic creak, incommensurable ratio
		b3d.rotation.z = brock

	# Campfire light flicker
	for f in get_tree().get_nodes_in_group("campfires"):
		var fl: OmniLight3D = f.get_node_or_null("FireLight")
		if fl:
			fl.light_energy = 2.4 + sin(_t * 17.0) * 0.4 + sin(_t * 31.0) * 0.25
	# Env: 2026-05-06 — goblin camp fire flicker (THEME §12). The point
	# light AND the ember log emission both pulse on the same noisy phase
	# so the visible mesh and the cast light tell the same story. Per-camp
	# phase (lifted from pit world position) keeps a cluster of camps from
	# flickering in lockstep.
	for gf in get_tree().get_nodes_in_group("goblin_fires"):
		var gf3d: Node3D = gf as Node3D
		if gf3d == null:
			continue
		var gphase: float = gf3d.position.x * 0.31 + gf3d.position.z * 0.47
		var gnoise: float = sin(_t * 14.0 + gphase) * 0.30 + sin(_t * 27.0 + gphase * 1.3) * 0.18
		var gfl: OmniLight3D = gf3d.get_node_or_null("GoblinFireLight")
		if gfl:
			# Base 1.4 with ±0.5 swing. Range pulses too so the cast pool
			# of warm light feels like it breathes with the embers.
			gfl.light_energy = 1.4 + gnoise
			gfl.omni_range = 8.0 + sin(_t * 5.0 + gphase) * 0.6
		var ember: MeshInstance3D = gf3d.get_node_or_null("EmberLog") as MeshInstance3D
		if ember:
			var emat: StandardMaterial3D = ember.material_override as StandardMaterial3D
			if emat:
				emat.emission_energy_multiplier = 1.8 + gnoise * 0.6
	# THEME §12 — banner flap. Each banner pivot sways around Y (wind passing
	# through) plus a small Z-roll for "billow". Per-banner phase keeps every
	# banner from moving in unison.
	for pivot in get_tree().get_nodes_in_group("banner_cloths"):
		var phase: float = float(pivot.get_meta("phase", 0.0))
		var wind: float = sin(_t * 1.6 + phase) * 0.25 + sin(_t * 0.7 + phase * 1.7) * 0.10
		var billow: float = sin(_t * 2.3 + phase) * 0.08
		pivot.rotation.y = wind
		pivot.rotation.z = billow
	# Env: 2026-05-06 — market stall awning flap (THEME §12). Cloth pitches
	# around the back-post pivot so the front lip rises/falls like wind
	# catching the canopy. Smaller amplitude than banners (0.06 vs 0.25) so
	# the slope shape stays readable, and a slow Z-sway adds side-to-side
	# motion without making the canopy feel unmoored. Per-stall phase keeps
	# adjacent stalls out of lockstep.
	for awn_pivot in get_tree().get_nodes_in_group("stall_awnings"):
		var ap3d: Node3D = awn_pivot as Node3D
		if ap3d == null:
			continue
		var aphase: float = float(ap3d.get_meta("phase", 0.0))
		var abase: float = float(ap3d.get_meta("base_pitch", 0.4))
		var flap: float = sin(_t * 1.4 + aphase) * 0.06 + sin(_t * 2.7 + aphase * 1.7) * 0.03
		var sway: float = sin(_t * 0.9 + aphase) * 0.04
		ap3d.rotation.x = abase + flap
		ap3d.rotation.z = sway
	# THEME §12 — water ripple. Subtle Y-bob on each water plane plus a slow
	# emission breathe so the surface reads as catching changing light.
	for wp in get_tree().get_nodes_in_group("water_planes"):
		var mi: MeshInstance3D = wp as MeshInstance3D
		if mi == null:
			continue
		var rest_y: float = float(mi.get_meta("rest_y", mi.position.y))
		var amp: float = float(mi.get_meta("ripple_amp", 0.02))
		var freq: float = float(mi.get_meta("ripple_freq", 1.0))
		mi.position.y = rest_y + sin(_t * freq + mi.position.x * 0.7 + mi.position.z * 0.5) * amp
		var mat: StandardMaterial3D = mi.material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = 0.18 + sin(_t * 1.8 + mi.position.x) * 0.06
	# Env: 2026-05-06 — bird V-formation drift + wing-bob (THEME §12).
	# Each flock parent translates along its heading meta and wraps around
	# the world bound so flocks loop forever. Per-bird wing-bob hinges the
	# left/right WingL / WingR meshes around their hinge axis on the bird's
	# own phase. The lead bird (index 0) bobs slightly less than the
	# trailing birds so the V reads as following the leader.
	for flock in get_tree().get_nodes_in_group("bird_flocks"):
		var f3d: Node3D = flock as Node3D
		if f3d == null:
			continue
		var heading: Vector3 = f3d.get_meta("heading", Vector3.FORWARD)
		var speed: float = float(f3d.get_meta("speed", 6.0))
		f3d.position += heading * speed * delta
		# Wrap around the world bound so the flock loops behind silhouette.
		if absf(f3d.position.x) > BIRD_WORLD_BOUND or absf(f3d.position.z) > BIRD_WORLD_BOUND:
			f3d.position.x = -f3d.position.x * 0.95
			f3d.position.z = -f3d.position.z * 0.95
		# Subtle altitude bob so the flock reads as catching thermals.
		var fphase: float = float(f3d.get_meta("phase", 0.0))
		f3d.rotation.z = sin(_t * 0.4 + fphase) * 0.04
	# Per-bird wing flap. Wing meshes named "WingL" / "WingR" hinge around X
	# in the bird's local frame, so a positive rotation lifts the wing tip.
	for bird in get_tree().get_nodes_in_group("bird_wings"):
		var b3d: Node3D = bird as Node3D
		if b3d == null:
			continue
		var bphase: float = float(b3d.get_meta("phase", 0.0))
		var flap: float = sin(_t * 6.5 + bphase) * 0.55
		var wl: MeshInstance3D = b3d.get_node_or_null("WingL") as MeshInstance3D
		var wr: MeshInstance3D = b3d.get_node_or_null("WingR") as MeshInstance3D
		# Mirror the wing rotation so they meet at the body centerline.
		if wl:
			wl.rotation.x = -flap
		if wr:
			wr.rotation.x = flap
		# Tiny vertical bob so the bird body itself reads as alive.
		var base_y: float = float(b3d.get_meta("base_y", 0.0))
		b3d.position.y = base_y + sin(_t * 6.5 + bphase) * 0.05
	# Env: 2026-05-06 — crystal pulse (THEME §12). Crystal clusters in
	# the Crystal Caves dungeon and any future open-world deposits
	# joined group "crystals" but had no motion — the cave read as a
	# museum diorama instead of the magical, breathing geode the lore
	# implies. Each cluster's heart light pulses on a slow per-cluster
	# phase, the omni range breathes in sync so the cast pool of blue
	# light scales with the inhalation, and every shard's emission
	# multiplier rides the same beat with a small per-shard offset so
	# the cluster glints like stained glass catching light from inside.
	# Frequencies (1.1 + 0.7) are intentionally non-harmonic so the
	# pulse never settles into a metronome. Amplitudes are conservative
	# (±25% on light, ±20% on emission) so the cave stays readable —
	# no flicker, no strobe, just a steady breath.
	for cluster in get_tree().get_nodes_in_group("crystals"):
		var c3d: Node3D = cluster as Node3D
		if c3d == null:
			continue
		var cphase: float = float(c3d.get_meta("pulse_phase", 0.0))
		var cnoise: float = sin(_t * 1.1 + cphase) * 0.7 + sin(_t * 0.7 + cphase * 1.7) * 0.3
		var clight: OmniLight3D = c3d.get_node_or_null("CrystalLight") as OmniLight3D
		if clight:
			var be: float = float(c3d.get_meta("light_base_energy", 1.6))
			var br: float = float(c3d.get_meta("light_base_range", 7.0))
			clight.light_energy = be + cnoise * 0.4
			clight.omni_range = br * (1.0 + cnoise * 0.06)
		var bem: float = float(c3d.get_meta("shard_base_emission", 3.2))
		var sidx: int = 0
		for sh in c3d.get_children():
			var smi: MeshInstance3D = sh as MeshInstance3D
			if smi == null:
				continue
			var smat: StandardMaterial3D = smi.material_override as StandardMaterial3D
			if smat == null:
				continue
			var sphase: float = cphase + float(sidx) * 0.4
			var sn: float = sin(_t * 1.1 + sphase) * 0.6 + sin(_t * 0.7 + sphase * 1.7) * 0.25
			smat.emission_energy_multiplier = bem + sn * 0.6
			sidx += 1

	# Phase 6 — harbor interactions (proximity + input check)
	if nordic_interactions_enabled:
		_tick_nordic_interactions()
	# Phase 12 — quest HUD tracker
	if quest_hud_enabled:
		_tick_quest_hud()



# ============================================================================
# Treasure chests — scattered through the Whisperwood and one near the well
# (CHEST_SCRIPT already declared at top of file alongside other preloads)
# ============================================================================
const CHEST_SPOTS = [
	{"pos":Vector3( 18.0,  0,  -22.0), "pool":"chest_common", "count":3, "color":Color(1.0, 0.85, 0.30)},
	{"pos":Vector3(-25.0,  0,  -16.0), "pool":"chest_common", "count":3, "color":Color(1.0, 0.85, 0.30)},
	{"pos":Vector3(  6.0,  0,  -32.0), "pool":"chest_rare",   "count":2, "color":Color(0.55, 0.85, 1.00)},
	{"pos":Vector3(-12.0,  0,  -38.0), "pool":"chest_rare",   "count":2, "color":Color(0.85, 0.45, 1.00)},
	{"pos":Vector3( 28.0,  0,    8.0), "pool":"chest_common", "count":2, "color":Color(1.0, 0.85, 0.30)},
]

func _build_chests() -> void:
	for spot in CHEST_SPOTS:
		var chest := StaticBody3D.new()
		chest.set_script(CHEST_SCRIPT)
		chest.position = spot.pos
		chest.loot_pool = spot.pool
		chest.item_count = spot.count
		chest.glow_color = spot.color
		# Random small rotation so chests don't all face the same way
		chest.rotation.y = randf_range(-PI, PI) * 0.3
		add_child(chest)

# ============================================================================
# CRYSTAL CAVES DUNGEON
# Dark cavern NW of the village. Glowing blue crystal formations, ambient
# blue light, undead + crystal-elemental encounters, boss room with the
# Crystal Guardian. Reuses Items.gd `crystal_shard` material drop.
# ============================================================================
func _make_crystal_cluster(pos: Vector3, base_scale: float, color: Color, parent: Node3D, rng: RandomNumberGenerator) -> void:
	# A cluster of 3–6 elongated emissive shards radiating from a base point.
	var cluster := Node3D.new()
	cluster.position = pos
	# scale-eng 2026-05-05: enable runtime cap-sweep (canon crystal cluster cap 4.0m).
	cluster.add_to_group("crystals")
	parent.add_child(cluster)
	var shard_count: int = rng.randi_range(3, 6)
	for i in shard_count:
		var shard := MeshInstance3D.new()
		var pm := PrismMesh.new()
		# scale-eng 2026-05-05: canon crystal cluster cap 4.0m. Boss-room
		# base_scale=2.2 used to allow shard.y up to 2.6*2.2 = 5.72m (43% over cap).
		var shard_y: float = clamp(rng.randf_range(1.2, 2.6) * base_scale, 0.5, 4.0)
		pm.size = Vector3(0.45 * base_scale, shard_y, 0.45 * base_scale)
		shard.mesh = pm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color
		# REFINE: visual — Crystal Caves — push shards toward stained-glass:
		# stronger emission + a touch more translucent so the inner light leaks.
		mat.emission_energy_multiplier = 3.2
		mat.metallic = 0.20
		mat.roughness = 0.18
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.72
		shard.material_override = mat
		var ang: float = (float(i) / float(shard_count)) * TAU + rng.randf_range(-0.4, 0.4)
		var r_off: float = rng.randf_range(0.0, 0.4) * base_scale
		shard.position = Vector3(cos(ang) * r_off, pm.size.y * 0.5, sin(ang) * r_off)
		shard.rotation = Vector3(rng.randf_range(-0.3, 0.3), rng.randf_range(0, TAU), rng.randf_range(-0.3, 0.3))
		cluster.add_child(shard)
	# Pulsing omni light at the heart of the cluster
	# Env: 2026-05-06 — named so the THEME §12 crystal-pulse loop in
	# _process can find it without scanning every child node. Base
	# energy + range are also saved as cluster meta so the pulse can
	# oscillate around the original values regardless of base_scale.
	var light := OmniLight3D.new()
	light.name = "CrystalLight"
	light.light_color = color
	light.light_energy = 1.6
	light.omni_range = 7.0 * base_scale
	light.position.y = 1.0
	cluster.add_child(light)
	# THEME §12 — per-cluster phase derived from world position so a
	# field of crystals doesn't pulse in lockstep. base_energy /
	# base_range / base_emission are the values the pulse oscillates
	# around (so caves with bigger base_scale crystals still pulse
	# proportionally).
	cluster.set_meta("pulse_phase", pos.x * 0.31 + pos.z * 0.47)
	cluster.set_meta("light_base_energy", 1.6)
	cluster.set_meta("light_base_range", 7.0 * base_scale)
	cluster.set_meta("shard_base_emission", 3.2)

func _make_stalagmite(pos: Vector3, height: float, parent: Node3D, point_down: bool = false) -> void:
	var sm := MeshInstance3D.new()
	var pm := PrismMesh.new()
	# scale-eng 2026-05-05: clamp to canon stalagmite cap 6m at spawn so a
	# rogue caller can't pass height=20 without runtime-sweep correction.
	pm.size = Vector3(0.7, clamp(height, 0.5, 6.0), 0.7)
	sm.mesh = pm
	sm.material_override = MAT_ROCK(1.0)
	sm.position = pos
	sm.add_to_group("stalagmites")  # scale-eng 2026-05-05: enable runtime sweep
	var h_eff: float = pm.size.y  # scale-eng 2026-05-05: use clamped height for offset
	if point_down:
		sm.position.y = pos.y - h_eff * 0.5
		sm.rotation.x = PI
	else:
		sm.position.y = pos.y + h_eff * 0.5
	sm.rotation.y = randf() * TAU
	parent.add_child(sm)

func _build_crystal_caves(entrance: Vector3) -> void:
	# Phase 26: all geometry scaled by S=0.25 (4× reduction from original design).
	# Original was a 48m-diameter dome with 40m-deep cave — engulfed the village.
	# Now: 12m dome, 10m-deep cave, arch at 5.5m — fits its placement at (-50,0,-40).
	const S: float = 0.25

	var caves := Node3D.new()
	caves.name = "CrystalCaves"
	caves.position = entrance
	add_child(caves)
	var rng := RandomNumberGenerator.new(); rng.randomize()
	var crystal_blue:   Color = Color(0.45, 0.80, 1.00)
	var crystal_violet: Color = Color(0.70, 0.55, 1.00)
	var crystal_teal:   Color = Color(0.45, 1.00, 0.85)

	# ── Cavern dome (inverted interior shell) ──
	var dome := MeshInstance3D.new()
	var dm   := SphereMesh.new()
	dm.radius = 24.0 * S   # → 6.0 m radius, 12 m diameter
	dm.height = 22.0 * S   # → 5.5 m
	dome.mesh = dm
	var dome_mat := StandardMaterial3D.new()
	dome_mat.albedo_color = Color(0.04, 0.05, 0.10)
	dome_mat.roughness    = 0.98
	dome_mat.cull_mode    = BaseMaterial3D.CULL_FRONT
	dome.material_override = dome_mat
	dome.position = Vector3(0, 4.0 * S, 0)   # → y=1.0
	caves.add_child(dome)

	# ── Entrance arch ──
	for sx in [-3.2 * S, 3.2 * S]:    # → ±0.8
		var col := MeshInstance3D.new()
		var cm  := CylinderMesh.new()
		cm.top_radius    = 0.7  * S   # → 0.175
		cm.bottom_radius = 0.95 * S   # → 0.24
		cm.height        = 5.5  * S   # → 1.4
		col.mesh = cm
		col.material_override = MAT_ROCK(1.5)
		col.position = Vector3(sx, 2.75 * S, 22.0 * S)   # → (±0.8, 0.7, 5.5)
		caves.add_child(col)
	var cap  := MeshInstance3D.new()
	var capm := BoxMesh.new()
	capm.size = Vector3(8.4 * S, 1.2 * S, 1.6 * S)   # → 2.1 × 0.3 × 0.4
	cap.mesh = capm
	cap.material_override = MAT_ROCK(1.5)
	cap.position = Vector3(0, 6.1 * S, 22.0 * S)     # → (0, 1.5, 5.5)
	caves.add_child(cap)

	# ── Entrance beacon crystal ──
	var beacon     := MeshInstance3D.new()
	var bm         := PrismMesh.new()
	bm.size = Vector3(1.0 * S, 2.4 * S, 1.0 * S)    # → 0.25 × 0.6 × 0.25
	beacon.mesh = bm
	var beacon_mat := StandardMaterial3D.new()
	beacon_mat.albedo_color            = crystal_blue
	beacon_mat.emission_enabled        = true
	beacon_mat.emission                = crystal_blue
	beacon_mat.emission_energy_multiplier = 1.2
	beacon.material_override = beacon_mat
	beacon.position = Vector3(0, 8.0 * S, 22.0 * S)  # → (0, 2.0, 5.5)
	caves.add_child(beacon)
	var beacon_light := OmniLight3D.new()
	beacon_light.light_color  = crystal_blue
	beacon_light.light_energy = 1.4
	beacon_light.omni_range   = 10.0 * S              # → 2.5 m
	beacon_light.position     = Vector3(0, 8.0 * S, 22.0 * S)
	caves.add_child(beacon_light)

	# ── Ambient cave lights ──
	var amb := OmniLight3D.new()
	amb.light_color  = crystal_blue
	amb.light_energy = 0.62
	amb.omni_range   = 28.0 * S                       # → 7.0 m
	amb.position     = Vector3(0, 9.0 * S, 0)         # → y=2.25
	caves.add_child(amb)
	var boss_amb := OmniLight3D.new()
	boss_amb.light_color  = crystal_violet
	boss_amb.light_energy = 2.4
	boss_amb.omni_range   = 24.0 * S                  # → 6.0 m
	boss_amb.position     = Vector3(0, 4.0 * S, -16.0 * S)  # → (0, 1.0, -4.0)
	caves.add_child(boss_amb)

	# ── Stone floor disc ──
	var floor_mesh := MeshInstance3D.new()
	var pm_floor   := CylinderMesh.new()
	pm_floor.top_radius    = 22.0 * S    # → 5.5 m
	pm_floor.bottom_radius = 22.0 * S
	pm_floor.height        = 0.4
	floor_mesh.mesh = pm_floor
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.12, 0.14, 0.20)
	floor_mat.roughness    = 0.78
	floor_mesh.material_override = floor_mat
	floor_mesh.position = Vector3(0, 0.05, 0)
	caves.add_child(floor_mesh)

	# ── Crystal formations (positions and base_scale × S) ──
	var crystal_spots: Array = [
		{"p": Vector3(-8,0, 14)*S, "s": 1.4*S, "c": crystal_blue},
		{"p": Vector3( 9,0, 11)*S, "s": 1.2*S, "c": crystal_blue},
		{"p": Vector3(14,0,  4)*S, "s": 1.6*S, "c": crystal_teal},
		{"p": Vector3(-12,0, 2)*S, "s": 1.5*S, "c": crystal_blue},
		{"p": Vector3(  4,0, -4)*S,"s": 1.0*S, "c": crystal_teal},
		{"p": Vector3( -6,0, -8)*S,"s": 1.3*S, "c": crystal_violet},
		{"p": Vector3( 12,0,-10)*S,"s": 1.4*S, "c": crystal_violet},
		{"p": Vector3(-14,0,-12)*S,"s": 1.1*S, "c": crystal_blue},
		{"p": Vector3(  0,0,-18)*S,"s": 2.2*S, "c": crystal_violet},  # boss crystal
	]
	for spot in crystal_spots:
		_make_crystal_cluster(spot["p"], spot["s"], spot["c"], caves, rng)

	# ── Stalagmites and stalactites ──
	for i in 18:
		var ang: float = rng.randf() * TAU
		var r:   float = rng.randf_range(6.0, 19.0) * S
		var pos: Vector3 = Vector3(cos(ang) * r, 0.0, sin(ang) * r)
		_make_stalagmite(pos, rng.randf_range(0.4, 1.0), caves, false)
	for i in 12:
		var ang2: float = rng.randf() * TAU
		var r2:   float = rng.randf_range(4.0, 18.0) * S
		var pos2: Vector3 = Vector3(cos(ang2) * r2, 11.5 * S, sin(ang2) * r2)
		_make_stalagmite(pos2, rng.randf_range(0.4, 1.0), caves, true)

	# ── Boss room divider pillars ──
	for sx2 in [-6.0 * S, 6.0 * S]:    # → ±1.5
		var pillar := MeshInstance3D.new()
		var pillm  := CylinderMesh.new()
		pillm.top_radius    = 0.6 * S   # → 0.15
		pillm.bottom_radius = 0.9 * S   # → 0.225
		pillm.height        = 7.0 * S   # → 1.75
		pillar.mesh = pillm
		pillar.material_override = MAT_ROCK(1.5)
		pillar.position = Vector3(sx2, 3.5 * S, -10.0 * S)  # → (±1.5, 0.9, -2.5)
		caves.add_child(pillar)

	# ── Skull pile ──
	for i in 6:
		var skull := MeshInstance3D.new()
		var sm2   := SphereMesh.new()
		sm2.radius = 0.12; sm2.height = 0.18
		skull.mesh = sm2
		var sklm := StandardMaterial3D.new()
		sklm.albedo_color = Color(0.92, 0.86, 0.74)
		sklm.roughness    = 0.92
		skull.material_override = sklm
		skull.position = Vector3(
			rng.randf_range(-1.4, 1.4) * S,
			0.08,
			-16.0 * S + rng.randf_range(-1.4, 1.4) * S)
		caves.add_child(skull)

	# ── Enemy spawns (all offsets × S) ──
	var skel_color: Color = Color(0.95, 0.95, 0.92)
	var skel_spots: Array = [
		Vector3(-6,0,12)*S, Vector3(7,0,8)*S, Vector3(11,0,-2)*S,
		Vector3(-10,0,-4)*S, Vector3(4,0,-8)*S,
	]
	for sp in skel_spots:
		_spawn_enemy("skeleton", caves.position + sp,
			"Restless Skeleton", 36, 8, 24, 7, skel_color, 2.4, 4.4)

	var elem_color: Color = Color(0.55, 0.85, 1.00)
	var elem_spots: Array = [
		Vector3(-12,0, 0)*S, Vector3(13,0,-6)*S, Vector3(-4,0,-12)*S,
	]
	for ep in elem_spots:
		_spawn_enemy("crystal_elemental", caves.position + ep,
			"Crystal Elemental", 70, 14, 55, 14, elem_color, 1.8, 3.2)

	_spawn_enemy("crystal_guardian", caves.position + Vector3(0, 0, -16.0 * S),
		"Crystal Guardian", 420, 26, 480, 200, Color(0.65, 0.85, 1.00), 1.8, 3.4)
	# Mutant guardian — flanks the crystal guardian; creature animations via Boss.glb
	_spawn_enemy("mutant", caves.position + Vector3(8.0 * S, 0, -14.0 * S),
		"Corrupted Mutant", 280, 22, 320, 80, Color(0.55, 0.35, 0.70), 1.6, 3.0)


# Walk a freshly-instanced character GLB and rescale so its visible AABB is ~1.8m tall.
# Sketchfab models come in mixed unit systems; this prevents the "giants" problem.
func _normalize_npc_scale(model: Node) -> void:
	await get_tree().process_frame
	var aabb := AABB()
	var has: bool = false
	for c in model.find_children("*", "VisualInstance3D", true):
		var v := c as VisualInstance3D
		if not v: continue
		var a := v.get_aabb()
		a = v.global_transform * a
		if not has:
			aabb = a; has = true
		else:
			aabb = aabb.merge(a)
	if not has or aabb.size.y <= 0.001:
		return
	# char-spec 2026-05-06: 1.8 (adult) → 1.65 per SIZE_STANDARDS.md §1.
	var target_height := 1.65
	var s := target_height / aabb.size.y
	# Clamp so we never blow tiny models up to 10x or shrink huge ones to dust
	s = clamp(s, 0.1, 3.0)
	model.scale = Vector3(s, s, s)


# ════════════════════════════════════════════════════════════════════════
# GLOBAL SCALE SWEEP — runs once 0.5s after _ready completes. Walks the
# entire scene tree, finds any character GLB instance whose visible AABB
# is unreasonably tall (>5m), and rescales it. Catches characters that
# any other script spawned bypassing per-script normalization.
# ════════════════════════════════════════════════════════════════════════

func _global_scale_sweep() -> void:
	# Realm-of-Eldoria size discipline — runs every 0.5s, no exemptions for
	# trees / buildings / mountains / scenery. The Scale Engineer agent owns
	# this loop. Canon (SIZE_STANDARDS_FULL): player/NPC ≤2.4m, enemy ≤1.8m,
	# boss ≤4.0m, pet ≤1.0m, tree ≤14m, building ≤7m, mountain ≤80m.
	# Anything outside band gets uniformly scaled to the target on the next tick.
	while is_inside_tree():
		await get_tree().create_timer(0.5).timeout
		var root := get_tree().current_scene
		if not root:
			continue
		# Character bodies (player + enemies + NPCs) — strict canon.
		for body in root.find_children("*", "CharacterBody3D", true):
			_check_and_normalize(body, _expected_height_for(body))
		# Static bodies — clamp by group:
		for body in root.find_children("*", "StaticBody3D", true):
			if body.is_in_group("terrain"):
				_clamp_max_height(body, 80.0)  # scale-eng: terrain clamped at mountain cap, not skipped
				continue
			if body.is_in_group("mountain"):
				_clamp_max_height(body, 80.0)
				continue
			if body.is_in_group("trees"):
				_clamp_max_height(body, 4.5)
				continue
			if body.is_in_group("buildings"):
				_clamp_max_height(body, 7.0)
				continue
			_check_and_normalize(body, _expected_height_for(body))
		# Hard upper-bound enforcement on ANY Node3D claiming to be a character.
		# Threshold lowered from 12m → 2.5m so a 4-5m hero (the Meshy bug) gets
		# caught instead of slipping under the old 12m bar.
		for body in root.find_children("*", "Node3D", true):
			var in_char_group := (body.is_in_group("player") or body.is_in_group("npcs") \
					or body.is_in_group("enemies") or body.is_in_group("pets"))
			var in_boss_group := body.is_in_group("bosses")
			if not (in_char_group or in_boss_group):
				continue
			var aabb := _measure_aabb(body)
			var cap: float = 4.0 if in_boss_group else 2.5
			if aabb.size.y > cap:
				_emergency_shrink(body, aabb, _expected_height_for(body))
		# Tree group sweep — group "trees" can be on any Node3D not just StaticBody.
		for body in root.find_children("*", "Node3D", true):
			if not body.is_in_group("trees"):
				continue
			_clamp_max_height(body, 4.5)
		# Building group sweep — same idea for stuff in group "buildings".
		for body in root.find_children("*", "Node3D", true):
			if not body.is_in_group("buildings"):
				continue
			_clamp_max_height(body, 7.0)
		# scale-eng 2026-05-05: mountain meshes spawn as bare MeshInstance3D
		# (not StaticBody3D), so the static-body branch above with the "mountain"
		# group check never fires. Walk Node3D too. Canon mountain cap 80m.
		for body in root.find_children("*", "Node3D", true):
			if not body.is_in_group("mountain"):
				continue
			_clamp_max_height(body, 80.0)
		# scale-eng 2026-05-05: decorative crystal clusters — canon cap 4.0m.
		# _make_crystal_cluster now joins "crystals" so the cluster wrapper
		# stays under cap even if a future caller passes a wild base_scale.
		for body in root.find_children("*", "Node3D", true):
			if not body.is_in_group("crystals"):
				continue
			_clamp_max_height(body, 4.0)
		# scale-eng 2026-05-05: stalagmites — canon cap 6.0m (treat as scenery
		# pillar; spawned by _make_stalagmite which now joins "stalagmites").
		for body in root.find_children("*", "Node3D", true):
			if not body.is_in_group("stalagmites"):
				continue
			_clamp_max_height(body, 6.0)
		# scale-eng 2026-05-05: lanterns — canon cap 2.5m. _make_lantern joins
		# "lanterns" already; the source fix in commit 9b7d288 made these in-spec
		# at spawn, but a runtime sweep is cheap insurance.
		for body in root.find_children("*", "Node3D", true):
			if not body.is_in_group("lanterns"):
				continue
			_clamp_max_height(body, 2.5)
		# scale-eng 2026-05-06: windmills — canon cap 18m (target 12m, floor 8m).
		# _build_windmill joins "windmills" already. Cheap insurance against a
		# stylized Sketchfab windmill GLB whose bake comes in at 30+m and the
		# 1.55x post-multiplier blowing past 18m.
		for body in root.find_children("*", "Node3D", true):
			if not body.is_in_group("windmills"):
				continue
			_clamp_max_height(body, 18.0)
		# scale-eng 2026-05-06: boulders — canon cap 5m. _make_glb_boulder joins
		# "boulders". Sketchfab boulders typically export 1-3m; cap defends
		# against future imports that ship at 8-12m natural size.
		for body in root.find_children("*", "Node3D", true):
			if not body.is_in_group("boulders"):
				continue
			_clamp_max_height(body, 5.0)
		# scale-eng 2026-05-06: campfires — canon cap 3m (incl. flame). Both
		# _build_campfire ("campfires") and _make_bandit_camp ("goblin_fires")
		# join here. Particle plumes can read tall but the visible AABB of the
		# stone ring + logs should never exceed 3m.
		for body in root.find_children("*", "Node3D", true):
			if not (body.is_in_group("campfires") or body.is_in_group("goblin_fires")):
				continue
			_clamp_max_height(body, 3.0)
		# scale-eng 2026-05-06: banner poles — canon cap 6m. _build_banners
		# joins "banner_poles". Procedural pole spawns at canonical ~4m so this
		# is insurance for a future GLB-banner swap.
		for body in root.find_children("*", "Node3D", true):
			if not body.is_in_group("banner_poles"):
				continue
			_clamp_max_height(body, 6.0)
		# scale-eng 2026-05-06: chests — canon cap 1m. Chest.gd joins "chests"
		# in _ready. Procedural body+lid is ~0.9m so this defends only against
		# future loot-chest GLB swaps that might import at 2m+.
		for body in root.find_children("*", "Node3D", true):
			if not body.is_in_group("chests"):
				continue
			_clamp_max_height(body, 1.0)


# Helper used by the sweep — uniformly shrink a Node3D so its world-space
# visual AABB y-extent ≤ max_h. No-op if already within bounds. Cheap and
# called every 0.5s on every flagged node.
func _clamp_max_height(node: Node, max_h: float) -> void:
	if not (node is Node3D):
		return
	var n3d: Node3D = node as Node3D
	var aabb := _measure_aabb(node)
	if aabb.size.y <= max_h or aabb.size.y <= 0.001:
		return
	var s: float = clamp(max_h / aabb.size.y, 0.001, 1.0)  # scale-eng 2026-05-05: floor 0.05 → 0.001
	n3d.scale = n3d.scale * s


# ════════════════════════════════════════════════════════════════════════════
# GLB FOREST + BOULDER WIRE-UP (run 13)
# ════════════════════════════════════════════════════════════════════════════
# Replaces the procedural blob trees and sphere rocks with the Sketchfab
# CC-BY GLBs that have been sitting unused under assets/models/trees/ and
# assets/models/props/. Every helper is null-safe — if the GLB can't load,
# the caller falls back to the legacy primitive code path. No save state.
# THEME §1 (medieval canon), §11 (silhouette diversity), §12 (motion: every
# tree joins group "trees" so the existing _process wind-sway picks it up),
# §13 (ground contact: deferred AABB-driven settle so no half-buried trunks).

# Loads a GLB safely, returning null if the path doesn't exist or doesn't
# resolve to a PackedScene. Used by tree / boulder / future prop spawners
# so a missing asset NEVER breaks the world build.
# ─── THEME §11, §12 — Whisperwood undergrowth + village dressing ────────────
# Three additive scatter passes that wire up the previously-unused fern,
# mushroom, and barrel GLBs. All three add purely to the visual layer:
# - ferns join group "ferns" so _process gives them a subtle leaf-sway
# - mushrooms are static low cover (small scale, a few clustered pods)
# - barrels are walk-around-able cargo near houses + stable
# Every spawn gets a deferred _settle_to_ground call so nothing floats or
# sinks (THEME §13). All paths fail silently if the GLB isn't loadable.
func _scatter_ferns(count: int) -> void:
	var packed: PackedScene = _load_glb_safe(FERN_GLB_PATH)
	if packed == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in count:
		var ang: float = rng.randf() * TAU
		var dist: float = rng.randf_range(14, 60)
		var pos: Vector3 = Vector3(cos(ang) * dist, 0, sin(ang) * dist)
		var inst: Node = packed.instantiate()
		if inst == null:
			continue
		var holder := Node3D.new()
		holder.position = pos
		holder.rotation.y = rng.randf() * TAU
		holder.add_to_group("ferns")
		add_child(holder)
		holder.add_child(inst)
		if inst is Node3D:
			var s: float = rng.randf_range(0.65, 1.10)
			(inst as Node3D).scale = Vector3(s, s, s)
		call_deferred("_settle_to_ground", holder)

func _scatter_mushrooms(count: int) -> void:
	var packed: PackedScene = _load_glb_safe(MUSHROOM_GLB_PATH)
	if packed == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	# Mushrooms cluster in pods of 2–4 instead of single instances — feels
	# more natural under tree canopies.
	var pods: int = max(1, count / 3)
	for pi in pods:
		var ang: float = rng.randf() * TAU
		var dist: float = rng.randf_range(16, 55)
		var center: Vector3 = Vector3(cos(ang) * dist, 0, sin(ang) * dist)
		var pod_size: int = rng.randi_range(2, 4)
		for mushroom_idx in pod_size:
			var inst: Node = packed.instantiate()
			if inst == null:
				continue
			var holder := Node3D.new()
			var off: Vector3 = Vector3(rng.randf_range(-0.6, 0.6), 0, rng.randf_range(-0.6, 0.6))
			holder.position = center + off
			holder.rotation.y = rng.randf() * TAU
			holder.add_to_group("mushrooms")
			add_child(holder)
			holder.add_child(inst)
			if inst is Node3D:
				var s: float = rng.randf_range(0.015, 0.03)
				(inst as Node3D).scale = Vector3(s, s, s)
				# Fallback materials so cap/stem render even if GLB textures fail
				for mesh_inst in (inst as Node3D).find_children("*", "MeshInstance3D", true):
					if not (mesh_inst is MeshInstance3D):
						continue
					var mesh_mi := mesh_inst as MeshInstance3D
					var n_surfs := mesh_mi.get_surface_override_material_count()
					if n_surfs == 0:
						continue
					var mi_aabb := mesh_mi.get_aabb()
					var mat := StandardMaterial3D.new()
					mat.roughness = 0.85
					mat.metallic = 0.0
					# Cap sits above mid-point of mesh; stem is lower
					if mi_aabb.position.y + mi_aabb.size.y * 0.5 > 0.0:
						mat.albedo_color = Color(0.6, 0.1, 0.1)
					else:
						mat.albedo_color = Color(0.9, 0.85, 0.75)
					for surf_idx in n_surfs:
						# Always override — GLB materials are often black/missing
						mesh_mi.set_surface_override_material(surf_idx, mat)
			call_deferred("_settle_to_ground", holder)

func _build_village_barrels() -> void:
	var packed: PackedScene = _load_glb_safe(BARREL_GLB_PATH)
	if packed == null:
		return
	# Hand-placed barrel positions near houses + stable + market.
	# Y stays at 0 — the GLB has its own pivot at base; _settle_to_ground
	# fixes any per-asset offset.
	var spots: Array = [
		Vector3( 4.5, 0, -3.5),
		Vector3( 5.2, 0, -3.2),
		Vector3(-7.0, 0,  4.5),
		Vector3(-6.4, 0,  5.1),
		Vector3( 9.0, 0,  6.0),
		Vector3( 9.6, 0,  5.6),
		Vector3(-3.5, 0, -7.5),
		Vector3(-9.5, 0, -2.0),
	]
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for pos in spots:
		var inst: Node = packed.instantiate()
		if inst == null:
			continue
		var holder := Node3D.new()
		holder.position = pos
		holder.rotation.y = rng.randf() * TAU
		holder.add_to_group("village_barrels")
		add_child(holder)
		holder.add_child(inst)
		if inst is Node3D:
			var s: float = rng.randf_range(0.95, 1.10)
			(inst as Node3D).scale = Vector3(s, s, s)
		# Coarse cylindrical collider so the player can't walk through them.
		var body: StaticBody3D = StaticBody3D.new()
		var col: CollisionShape3D = CollisionShape3D.new()
		var cyl: CylinderShape3D = CylinderShape3D.new()
		cyl.radius = 0.42
		cyl.height = 0.95
		col.shape = cyl
		col.position.y = 0.475
		body.add_child(col)
		holder.add_child(body)
		call_deferred("_settle_to_ground", holder)

func _load_glb_safe(path: String) -> PackedScene:
	if not ResourceLoader.exists(path):
		return null
	var res: Resource = load(path)
	if res is PackedScene:
		return res as PackedScene
	return null

# Weighted-random pick over TREE_VARIANTS. Pure: same RNG state → same pick.
func _pick_tree_variant(rng: RandomNumberGenerator) -> Dictionary:
	var total: float = 0.0
	for v in TREE_VARIANTS:
		total += float(v.get("weight", 0.0))
	if total <= 0.0:
		return TREE_VARIANTS[0]
	var r: float = rng.randf() * total
	var acc: float = 0.0
	for v in TREE_VARIANTS:
		acc += float(v.get("weight", 0.0))
		if r <= acc:
			return v
	return TREE_VARIANTS[0]

# THEME §13 — after a model has been added to the tree and its AABB is
# measurable, lift or drop the wrapper so the visible base of the model sits
# at the wrapper's y. Handles both feet-pivoted and center-pivoted GLBs.
# Called via call_deferred so AABB is valid.
func _settle_to_ground(node: Node3D) -> void:
	if not is_instance_valid(node):
		return
	var aabb: AABB = _measure_aabb(node)
	if aabb.size == Vector3.ZERO:
		return
	# Convert global-space AABB.position.y to a local-space delta by
	# subtracting the wrapper's own global y.
	var bottom_global: float = aabb.position.y
	var pivot_global: float = node.global_transform.origin.y
	var bottom_offset: float = bottom_global - pivot_global
	# If model extends below the pivot (negative offset), lift it. If it
	# floats noticeably above, pull it down.
	if bottom_offset < -0.05:
		node.position.y -= bottom_offset
	elif bottom_offset > 0.25:
		node.position.y -= bottom_offset

# Instances a tree GLB at `pos`, randomizes scale + rotation, adds a coarse
# capsule trunk collider, joins group "trees" (so the wind-sway loop in
# _process applies), and queues a deferred ground-settle.
# Returns true on success — false means the GLB couldn't load and the
# caller should fall back to the procedural path.
func _make_glb_tree(pos: Vector3, rng: RandomNumberGenerator) -> bool:
	var variant: Dictionary = _pick_tree_variant(rng)
	var path: String = String(variant.get("path", ""))
	var packed: PackedScene = _load_glb_safe(path)
	if packed == null:
		return false
	var inst: Node = packed.instantiate()
	if inst == null:
		return false
	var holder: Node3D = Node3D.new()
	holder.position = pos
	holder.rotation.y = rng.randf() * TAU
	holder.add_to_group("trees")
	var kind: String = String(variant.get("kind", "oak"))
	holder.set_meta("tree_kind", kind)
	add_child(holder)
	holder.add_child(inst)
	var s_min: float = float(variant.get("scale_min", 1.0))
	var s_max: float = float(variant.get("scale_max", 1.2))
	var s: float = rng.randf_range(s_min, s_max)
	if inst is Node3D:
		(inst as Node3D).scale = Vector3(s, s, s)
	# Trunk-shaped capsule collider per kind. Bushes are walk-through cover.
	var radius: float = 0.55 * s
	var height: float = 3.0 * s
	match kind:
		"bush":
			radius = 0.0
		"dead":
			radius = 0.32 * s
			height = 2.6 * s
		"pine":
			radius = 0.42 * s
			height = 3.4 * s
		_:
			radius = 0.55 * s
			height = 3.0 * s
	if radius > 0.05:
		var body: StaticBody3D = StaticBody3D.new()
		var col: CollisionShape3D = CollisionShape3D.new()
		var cap: CapsuleShape3D = CapsuleShape3D.new()
		cap.radius = radius
		cap.height = max(height, radius * 2.1)
		col.shape = cap
		col.position.y = cap.height * 0.5
		body.add_child(col)
		holder.add_child(body)
	# Spawn-time height clamp — Meshy/Sketchfab tree GLBs frequently export at
	# 8-30m default, which dwarfs the 1.8m player. Clamp to ≤14m at spawn so we
	# don't flash a giant tree for the 0.5s before the global sweep catches it.
	call_deferred("_clamp_tree_at_spawn", holder, inst)
	call_deferred("_settle_to_ground", holder)
	return true

# Spawn-time clamp called via call_deferred from _make_glb_tree. Measures the
# instantiated tree's visual AABB and uniformly scales it down to ≤14m if it
# came in as a giant. No-op if already in spec.
func _clamp_tree_at_spawn(holder: Node, inst: Node) -> void:
	if not is_instance_valid(holder):
		return
	var aabb := _measure_aabb(holder)
	if aabb.size.y <= 4.5 or aabb.size.y <= 0.001:
		return
	if inst is Node3D:
		var n3d: Node3D = inst as Node3D
		var shrink: float = clamp(4.5 / aabb.size.y, 0.001, 1.0)  # 2026-05-06: dropped from 14.0 — trees were still too big to see character past
		n3d.scale = n3d.scale * shrink

# Instances the boulder GLB at `pos` with randomized rotation, scale, and a
# box collider. Joins group "boulders". Returns true on success; false means
# the GLB couldn't load and `_scatter_rocks` falls back to the sphere mesh.
func _make_glb_boulder(pos: Vector3, rng: RandomNumberGenerator) -> bool:
	var packed: PackedScene = _load_glb_safe(BOULDER_GLB_PATH)
	if packed == null:
		return false
	var inst: Node = packed.instantiate()
	if inst == null:
		return false
	var holder: Node3D = Node3D.new()
	holder.position = pos
	holder.rotation = Vector3(rng.randf() * 0.4, rng.randf() * TAU, rng.randf() * 0.4)
	holder.add_to_group("boulders")
	add_child(holder)
	holder.add_child(inst)
	var s: float = rng.randf_range(0.55, 1.30)
	if inst is Node3D:
		(inst as Node3D).scale = Vector3(s, s, s * rng.randf_range(0.85, 1.15))
	var body: StaticBody3D = StaticBody3D.new()
	var col: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(1.4 * s, 1.0 * s, 1.4 * s)
	col.shape = box
	col.position.y = 0.5 * s
	body.add_child(col)
	holder.add_child(body)
	call_deferred("_settle_to_ground", holder)
	return true

func _measure_aabb(node: Node) -> AABB:
	var aabb := AABB()
	var has: bool = false
	for v in node.find_children("*", "VisualInstance3D", true):
		var vi := v as VisualInstance3D
		if not vi: continue
		var a := vi.get_aabb()
		a = vi.global_transform * a
		if not has: aabb = a; has = true
		else: aabb = aabb.merge(a)
	return aabb if has else AABB()

func _emergency_shrink(body: Node, aabb: AABB, target_h: float) -> void:
	# Used when a character is GROSSLY oversized (>12m). Force-shrink the first
	# Node3D child until target height is reached.
	if aabb.size.y <= 0.001: return
	for child in body.get_children():
		if child is CollisionShape3D or child is AnimationPlayer:
			continue
		if child is Node3D and child.has_method("get_children"):
			var c := child as Node3D
			var avg_cur: float = (c.scale.x + c.scale.y + c.scale.z) / 3.0
			var ratio: float = target_h / aabb.size.y
			var new_s: float = clamp(avg_cur * ratio, 0.001, 3.0)  # scale-eng 2026-05-05: floor 0.02 → 0.001
			c.scale = Vector3(new_s, new_s, new_s)
			print("[ScaleSweep] EMERGENCY shrunk %s from %.1fm → %.1fm (s=%.3f)" % [body.name, aabb.size.y, target_h, new_s])
			break


# ============================================================================
# God-rays through canopy — Builder run 23
# THEME §1: painterly fantasy world — warm amber shafts evoke Studio Ghibli /
#   BotW morning light spilling through the Whisperwood.
# THEME §12 MOTION & LIFE: shafts are GPUParticles3D — they drift and pulse,
#   never static quads. Each shaft particle falls slowly downward (0.15 m/s)
#   with slight horizontal sway so the ray "breathes".
# THEME §13 GROUND CONTACT: emitters sit at canopy height (~5.5 m) so shafts
#   fall INTO the ground, never rising from it. Emission box is tall (height 3m)
#   so spawn origin is mid-shaft, not at ground level.
# 5-output rule:
#   i-   Integration  — wired via _safe_call in _ready (above)
#   ii-  Schema       — GOD_RAY_SPOTS const (position, angle, color, count)
#   iii- Feedback     — _dlog on spawn; skip logged as push_warning
#   iv-  Eval         — soft alpha ramp + _make_soft_particle_texture avoids
#                       white-blob (PROBLEMS_LOG §1.3). emission_energy ≤ 1.5.
#   v-   Hooks        — each emitter joins group "god_ray_shafts" for
#                       World.gd time-of-day fade (shafts dim at dusk/night).
# ============================================================================

# Each entry: position = emitter world-pos (placed at canopy height),
# color = warm shaft tint, amount = particle count per emitter.
# Positions arc through the NW/W/SW Whisperwood treeline where the
# morning sun (Sun transform in Main.tscn = azimuth ≈ SE) punches through.
const GOD_RAY_SPOTS: Array = [
	{"pos": Vector3(-22.0, 5.5, -15.0), "color": Color(1.00, 0.88, 0.55, 0.55), "amount": 14},
	{"pos": Vector3(-18.0, 5.5,   5.0), "color": Color(1.00, 0.85, 0.45, 0.50), "amount": 12},
	{"pos": Vector3(-25.0, 5.5,  10.0), "color": Color(0.95, 0.82, 0.40, 0.48), "amount": 10},
	{"pos": Vector3(-12.0, 5.5, -28.0), "color": Color(1.00, 0.90, 0.60, 0.45), "amount": 10},
	{"pos": Vector3( -8.0, 5.5,  20.0), "color": Color(0.98, 0.86, 0.50, 0.42), "amount":  8},
]

func _build_god_rays() -> void:
	# THEME §1, §12, §13 — warm canopy shafts with motion. See block comment above.
	for entry in GOD_RAY_SPOTS:
		var world_pos: Vector3 = entry["pos"]
		var shaft_color: Color = entry["color"]
		var shaft_amount: int = entry["amount"]

		var p := GPUParticles3D.new()
		p.position = world_pos
		p.amount = shaft_amount
		# Long lifetime so shaft particles traverse the full 5 m from
		# canopy to ground before fading — at 0.15 m/s that is ~33 s.
		# Preprocess fills the emitter immediately so no "blink-in" on load.
		p.lifetime = 32.0
		p.preprocess = 16.0
		p.visibility_aabb = AABB(Vector3(-3.0, -6.0, -3.0), Vector3(6.0, 8.0, 6.0))

		var pm := ParticleProcessMaterial.new()
		# Spawn in a tall thin box representing the mid-shaft cross-section.
		# Height 3 m → particles spawn between 4 m and 7 m above ground,
		# well within the canopy gap (§13 ground-contact: no spawn below 2 m).
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pm.emission_box_extents = Vector3(0.6, 1.5, 0.6)
		# Fall downward (negative Y) to simulate gravity on light-dust.
		pm.direction = Vector3(0.0, -1.0, 0.0)
		pm.spread = 4.0  # tight cone: shaft stays columnar, not dispersed
		pm.gravity = Vector3(0.0, 0.0, 0.0)  # gravity=0; direction does the work
		pm.initial_velocity_min = 0.10
		pm.initial_velocity_max = 0.20
		# Gentle horizontal sway so the shaft "breathes" — THEME §12 motion mandate.
		pm.tangential_accel_min = 0.03
		pm.tangential_accel_max = 0.10
		# Tall thin quads: each particle is a narrow vertical strip ~0.35 m wide
		# × 1.8 m tall — stacked strips build the solid shaft column.
		pm.scale_min = 1.0
		pm.scale_max = 1.4
		pm.color = shaft_color

		# Alpha ramp: fade in at spawn (top of shaft), hold, fade at lifetime end
		# (bottom near ground). Prevents hard edge at ground intersection (§13).
		var ramp := Gradient.new()
		ramp.offsets = PackedFloat32Array([0.0, 0.12, 0.80, 1.0])
		ramp.colors = PackedColorArray([
			Color(1.0, 1.0, 1.0, 0.0),
			Color(1.0, 1.0, 1.0, 1.0),
			Color(1.0, 1.0, 1.0, 0.85),
			Color(1.0, 1.0, 1.0, 0.0),
		])
		var ramp_tex := GradientTexture1D.new()
		ramp_tex.gradient = ramp
		pm.color_ramp = ramp_tex

		p.process_material = pm

		# Quad mesh: narrow vertical strip oriented along the shaft direction.
		# Billboard DISABLED — shafts rotate with the sun angle, not the camera.
		# cull_mode DISABLED so the shaft reads from all camera angles.
		var qm := QuadMesh.new()
		qm.size = Vector2(0.35, 1.80)
		var dm := StandardMaterial3D.new()
		dm.albedo_color = shaft_color
		# _make_soft_particle_texture() gives radial alpha falloff — prevents the
		# hard-rectangle white-blob problem (PROBLEMS_LOG §1.3).
		dm.albedo_texture = _make_soft_particle_texture()
		dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
		# No billboard: shafts are world-aligned columns
		dm.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
		dm.cull_mode = BaseMaterial3D.CULL_DISABLED
		dm.vertex_color_use_as_albedo = true
		# Emission kept LOW (≤ 1.5 per PROBLEMS_LOG §1.3 — campfire blowout lesson).
		# Shafts read as bright against dark canopy shadow without HDR blowout.
		dm.emission_enabled = true
		dm.emission = shaft_color
		dm.emission_energy_multiplier = 0.80
		qm.material = dm
		p.draw_pass_1 = qm

		# Hook v: join group for World.gd time-of-day modulation.
		# World.gd can dim god_ray_shafts at dusk/night with:
		#   for shaft in get_tree().get_nodes_in_group("god_ray_shafts"):
		#       shaft.amount_ratio = clamp(daylight, 0.0, 1.0)
		p.add_to_group("god_ray_shafts")
		add_child(p)

	_dlog("Env: _build_god_rays — %d shaft emitters spawned (THEME §12 motion)" % GOD_RAY_SPOTS.size())

# SIZE_STANDARDS — see eldoria-godot/SIZE_STANDARDS.md (single source of truth).
# Tuple = (target_height_m, tolerance_fraction).  Outside band → snap to target.
# char-spec 2026-05-06: aligned with eldoria-godot/SIZE_STANDARDS.md §1-§2.
# Previously diverged: player 1.80 (adult) → 1.10 (kid Alden 9 / Owen 11),
# npcs 1.80 → 1.65 (adult NPC canon), pets 0.70 → 0.55 (below kid's knee),
# enemies 1.40 → 1.55 (medium-enemy band; per-kind matches override),
# bosses 3.20 → 2.80 (boss-standard; gargantuan bosses handled per-kind).
# The previous dict was constantly fighting Player.gd's _normalize_player_model(1.1)
# lock — the global sweep would keep trying to stretch the kid back to 1.80m.
const SIZE_STANDARDS := {
	"player":  [0.85, 0.18],   # kid-sized; [CANON-APPROVED: 2026-05-10] 1.10→0.85 (user: "still too big")
								#   tol widened 0.10→0.18 so the body's capsule doesn't oscillate against the panic-key cap.
	"npcs":    [1.65, 0.15],   # adult NPC; band [1.40, 1.90]
	"pets":    [0.55, 0.25],   # fox/squirrel/owl; band [0.41, 0.69]
	"enemies": [1.55, 0.25],   # medium default; small/elite per-kind below
	"bosses":  [2.80, 0.20],   # standard boss; gargantuan via per-kind opt-in
	# char-spec 2026-05-06: SIZE_STANDARDS.md §2 gargantuan boss tier (4.00m).
	# Members are named in the canon: Crystal Guardian, Mountain Ogre, end-realm
	# bosses only. Joining "gargantuan_bosses" overrides "bosses" in the lookup
	# below (narrowest-first match in _expected_height_for).
	"gargantuan_bosses": [4.00, 0.20],
	# scale-eng 2026-05-05: wolf canon target 1.0m cap 1.4m floor 0.7m. Was
	# matching "enemies" target 1.40 ±0.20 → band [1.12, 1.68], over canon cap.
	"wolves":  [1.00, 0.30],
}

func _expected_height_for(body: Node) -> float:
	# Match group membership against SIZE_STANDARDS, narrowest first.
	if body.is_in_group("gargantuan_bosses"): return SIZE_STANDARDS["gargantuan_bosses"][0]
	if body.is_in_group("bosses"):  return SIZE_STANDARDS["bosses"][0]
	if body.is_in_group("pets"):    return SIZE_STANDARDS["pets"][0]
	if body.is_in_group("player"):  return SIZE_STANDARDS["player"][0]
	if body.is_in_group("npcs"):    return SIZE_STANDARDS["npcs"][0]
	if body.is_in_group("wolves"):  return SIZE_STANDARDS["wolves"][0]
	if body.is_in_group("enemies"): return SIZE_STANDARDS["enemies"][0]
	# char-spec 2026-05-06: default fall-through 1.8 → 1.65 per SIZE_STANDARDS.md §1.
	return 1.65

func _tolerance_for(body: Node) -> float:
	if body.is_in_group("gargantuan_bosses"): return SIZE_STANDARDS["gargantuan_bosses"][1]
	if body.is_in_group("bosses"):  return SIZE_STANDARDS["bosses"][1]
	if body.is_in_group("pets"):    return SIZE_STANDARDS["pets"][1]
	if body.is_in_group("player"):  return SIZE_STANDARDS["player"][1]
	if body.is_in_group("npcs"):    return SIZE_STANDARDS["npcs"][1]
	if body.is_in_group("wolves"):  return SIZE_STANDARDS["wolves"][1]
	if body.is_in_group("enemies"): return SIZE_STANDARDS["enemies"][1]
	return 0.15

func _check_and_normalize(body: Node, target_height: float) -> void:
	var aabb := AABB()
	var has: bool = false
	for v in body.find_children("*", "VisualInstance3D", true):
		var vi := v as VisualInstance3D
		if not vi: continue
		var a := vi.get_aabb()
		a = vi.global_transform * a
		if not has:
			aabb = a; has = true
		else:
			aabb = aabb.merge(a)
	if not has or aabb.size.y <= 0.001:
		return
	# If the body's visible mesh is within tolerance, leave it
	var tol: float = _tolerance_for(body)
	if aabb.size.y >= target_height * (1.0 - tol) and aabb.size.y <= target_height * (1.0 + tol):
		return
	# Otherwise rescale via the FIRST direct Node3D child (the model wrapper).
	# Compute the absolute scale needed: current_visual_scale * (target / current_height).
	for child in body.get_children():
		if child is CollisionShape3D or child is AnimationPlayer:
			continue
		if child is Node3D and child.has_method("get_children"):
			var c := child as Node3D
			var avg_cur: float = (c.scale.x + c.scale.y + c.scale.z) / 3.0
			var new_s: float = clamp(avg_cur * (target_height / aabb.size.y), 0.001, 5.0)  # scale-eng 2026-05-05: floor 0.05 → 0.001
			c.scale = Vector3(new_s, new_s, new_s)
			break


# ════════════════════════════════════════════════════════════════════════
# Weather System — Builder run 36
# ════════════════════════════════════════════════════════════════════════
# Creates a Weather node as a child of the world root.
# Weather.gd owns all rain particles, fog offsets, and state transitions.
# Idempotent — if a Weather node already exists (e.g. hand-placed in scene)
# this call is a no-op.
func _build_weather() -> void:
	var parent: Node = get_parent()
	if parent == null:
		return
	# Idempotent: skip if already present
	if parent.has_node("Weather"):
		_dlog("Weather node already exists — skipping")
		return
	var weather_script: Script = load("res://scripts/Weather.gd")
	if weather_script == null:
		push_warning("[WorldBuilder] Weather.gd not found — weather system skipped")
		return
	var weather: Node3D = Node3D.new()
	weather.set_script(weather_script)
	weather.name = "Weather"
	parent.add_child(weather)
	_dlog("Weather system spawned (state: clear — transitions on new world_day)")


# ============================================================================
# NORDIC FISHING VILLAGE — Builder run 25 (rev 2: bug-fixes + upgrades)
# Fixes: pier collision, minf→mini, window cull, water plane, lighthouse pos,
#        stilt collision, smokehouse roof, boat offset, branch-end platform.
# Upgrades: cobble road Briarwood→Nordic, dock NPCs, signposts.
# ============================================================================

const NORDIC_ORIGIN   := Vector3(0.0, 0.0, 120.0)
const NORDIC_WATER_Y  : float = 0.0
const NORDIC_SEED     : int   = 7331
const NORDIC_PIER_LEN : float = 52.0
const NORDIC_PIER_W   : float = 2.6

var _nrng: RandomNumberGenerator

var _mm_batches: Dictionary = {}
var _pier_post_mesh: CylinderMesh = null
var _pier_rail_mesh: BoxMesh = null

# Phase 8 — discovery state (pre-seed known locations as discovered)
var _discovered_places: Dictionary = {
	"briarwood": true,
	"nordic": true,
}

# Phase 9 — district streaming state
var _district_timer: Timer = null
var _district_roots: Dictionary = {}    # id -> Node3D root
var _district_building: Dictionary = {} # id -> bool (prevents double-build)
var _build_root_override: Node = null   # redirects add_child in streamed builds

# Branch offsets defined as a const so dock dressing and boat placement
# can reference them by index (fixes review item: boat offset mismatch).
const NORDIC_BRANCH_T := [0.22, 0.42, 0.62, 0.80]

# ── Boat travel destinations table ───────────────────────────────────────────
# Add more entries here as you add districts. id must be unique.
# requires_discovery: false = always visible; true = hidden until discover_place() called.
const BOAT_DESTS := [
	{
		"id": "briarwood",
		"name": "Briarwood (Village)",
		"pos": Vector3(0, 0, 12),
		"cost": 0,
		"requires_discovery": false,
	},
	{
		"id": "nordic",
		"name": "Nordic Harbor",
		"pos": Vector3(0, 0, 120),
		"cost": 0,
		"requires_discovery": false,
	},
	# Uncomment when district is built:
	# {
	# 	"id": "crystal_caves",
	# 	"name": "Crystal Caves",
	# 	"pos": Vector3(-50, 0, -40),
	# 	"cost": 25,
	# 	"requires_discovery": true,
	# },
]

# ── Nordic inspector knobs (all optional — consts above are the runtime defaults)
# Set these in the Godot Inspector to tweak the district without touching code.
@export var nordic_pier_length: float = 52.0
@export var nordic_pier_width: float = 2.6
@export var nordic_pier_branch_count: int = 4
@export var nordic_shore_house_count: int = 16
@export var nordic_pier_house_count: int = 5
@export var nordic_prop_density: float = 1.0
@export var nordic_spawn_dock_npcs: bool = true

# Optional GLB overrides (Meshy backlog). Leave null to keep primitive fallbacks.
# Wire in the Inspector: e.g. glb_barrel = res://assets/models/props/wooden_barrel.glb
@export var glb_barrel: PackedScene      # wooden_barrel.glb when available
@export var glb_crate: PackedScene       # no GLB yet — leave null
@export var glb_boat_small: PackedScene  # no GLB yet — leave null
@export var glb_boat_mast: PackedScene   # no GLB yet — leave null

# Ambient audio — all optional. Leave null and the audio system is silently skipped.
# Suggested sources (all CC0): freesound.org — search "ocean waves loop", "dock creak loop", "seagull"
@export var sfx_waves_loop: AudioStream      # large-radius background ocean loop
@export var sfx_dock_creak_loop: AudioStream # medium-radius pier/rope creak near pier start
@export var sfx_gulls_one_shot: AudioStream  # single gull cry, played on a random timer

# Tuning knobs for the audio system
@export var sfx_waves_volume_db: float  = -6.0
@export var sfx_creak_volume_db: float  = -10.0
@export var sfx_gulls_interval_min: float = 5.0   # seconds between gull cries
@export var sfx_gulls_interval_max: float = 18.0

# ── Phase 5: Dock NPC Life Loop ──────────────────────────────────────────────
@export var nordic_dock_life_enabled: bool = true
@export var nordic_dock_npc_scene: PackedScene   # drag any NPC scene here; null = disabled
@export var nordic_dock_npc_height: float = 1.65
@export var nordic_dock_life_tick: float = 1.6
@export var nordic_fisherman_offset: Vector3 = Vector3(1.0, 0.0, 18.0)
@export var nordic_netmender_offset: Vector3 = Vector3(-6.0, 0.0, 10.0)
@export var nordic_harbormaster_offset: Vector3 = Vector3(3.0, 0.0, 6.0)

# ── Phase 6: Harbor Interactions ────────────────────────────────────────────
@export var nordic_interactions_enabled: bool = true
@export var nordic_fish_gold_reward: int = 6
@export var nordic_fish_cooldown_sec: float = 20.0
@export var nordic_fish_item_id: String = "fish"
@export var nordic_fish_item_qty: int = 1

# ── Phase 7: Boat Travel UI ──────────────────────────────────────────────────
@export var boat_ui_enabled: bool = true
@export var boat_dest_briarwood: Vector3 = Vector3(0, 0, 12)   # fallback when UI disabled
@export var boat_dest_nordic: Vector3 = Vector3(0, 0, 120)

# ── Phase 9: District Streaming ──────────────────────────────────────────────
@export var district_streaming_enabled: bool = true
@export var nordic_stream_load_dist: float = 180.0    # build when player within this range
@export var nordic_stream_unload_dist: float = 240.0  # free when player beyond this range
@export var nordic_stream_tick: float = 0.8           # seconds between proximity checks

func MAT_WATER() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color        = Color(0.10, 0.28, 0.45, 0.82)
	m.transparency        = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness           = 0.12
	m.metallic            = 0.05
	m.emission_enabled    = true
	m.emission            = Color(0.04, 0.12, 0.22)
	m.emission_energy_multiplier = 0.35
	return m

func MAT_PLANK(uv := 1.5) -> StandardMaterial3D:
	return _pbr_mat(
		"res://assets/textures/wood/wood_diff.jpg",
		"res://assets/textures/wood/wood_norm.jpg",
		"res://assets/textures/wood/wood_rough.jpg",
		Vector3(uv, uv, 1), Color(0.72, 0.64, 0.52))

func MAT_DARKPOST() -> StandardMaterial3D:
	return _pbr_mat(
		"res://assets/textures/wood/wood_diff.jpg",
		"res://assets/textures/wood/wood_norm.jpg",
		"",
		Vector3(1, 1, 1), Color(0.22, 0.15, 0.10))

# ── Entry point ─────────────────────────────────────────────────────────────
func _build_nordic_fishing_village() -> void:
	_nrng = RandomNumberGenerator.new()
	_nrng.seed = NORDIC_SEED

	# Init shared pier meshes for MultiMesh batching (Builder run 26 perf pass)
	_pier_post_mesh = CylinderMesh.new()
	_pier_post_mesh.top_radius    = 0.11
	_pier_post_mesh.bottom_radius = 0.14
	_pier_post_mesh.height        = 3.0
	_pier_rail_mesh = BoxMesh.new()
	_pier_rail_mesh.size = Vector3(0.10, 0.08, 3.0)  # seg_len is always 3.0

	var origin := NORDIC_ORIGIN

	# Water plane — pushed 28 m seaward so near edge is at z≈92, clear of
	# shore houses (which sit at z=108–112). FIX: was z=-10, intruded into
	# shore house band.
	var water := MeshInstance3D.new()
	var wpm   := PlaneMesh.new()
	wpm.size  = Vector2(90.0, 70.0)
	water.mesh              = wpm
	water.material_override = MAT_WATER()
	water.position          = origin + Vector3(0.0, NORDIC_WATER_Y - 0.02, -25.0)
	water.name              = "NordicHarbour"
	add_child(water)

	var pier_dir: Vector3 = Vector3(0, 0, -1)
	var shore_dir: Vector3 = Vector3(1, 0,  0)

	# Main pier
	var pier_start: Vector3 = origin + pier_dir * 6.0
	pier_start.y   = NORDIC_WATER_Y + 0.15
	_nordic_pier_spine(pier_start, pier_dir, NORDIC_PIER_LEN)

	# Branch piers — store bases so dressing can use same offsets
	var branch_dirs  : Array[Vector3] = []
	var branch_bases : Array[Vector3] = []
	for i in range(NORDIC_BRANCH_T.size()):
		var t: float = NORDIC_BRANCH_T[i]
		var bp: Vector3 = pier_start + pier_dir * (NORDIC_PIER_LEN * t)
		bp.y    = NORDIC_WATER_Y + 0.15
		var side := (1.0 if i % 2 == 0 else -1.0)
		var bd  : Vector3 = pier_dir.rotated(Vector3.UP, side * PI * 0.5)
		branch_dirs.append(bd)
		branch_bases.append(bp)
		var bl: float = _nrng.randf_range(14.0, 22.0)
		_nordic_pier_branch(bp, bd, bl)

	# Landmarks
	var lh_pos: Vector3 = origin + shore_dir * 18.0 + Vector3(0, 0, 6.0)
	lh_pos.y   = origin.y
	_nordic_longhouse(lh_pos, shore_dir)

	var sh_pos: Vector3 = origin + shore_dir * -16.0 + pier_dir * 8.0
	sh_pos.y   = origin.y
	_nordic_smokehouse(sh_pos, shore_dir)

	# Beacon at pier terminus (not 8 m past it). FIX: was NORDIC_PIER_LEN+8.
	var lp_pos: Vector3 = pier_start + pier_dir * (NORDIC_PIER_LEN - 2.0)
	lp_pos.y   = NORDIC_WATER_Y + 0.15
	_nordic_beacon(lp_pos)

	# Shore stilt houses — skip slot near longhouse to avoid overlap.
	# FIX (review nice-to-have): reserve gap at x≈18 m.
	_nordic_shore_houses(origin, shore_dir, pier_dir, 16)

	# Pier-arm stilt houses (one per branch that has room)
	for i in range(mini(branch_bases.size(), branch_dirs.size())):  # FIX: minf→mini
		var hpos: Vector3 = branch_bases[i] + branch_dirs[i] * _nrng.randf_range(8.0, 16.0) \
					+ _nordic_side(branch_dirs[i]) * _nrng.randf_range(2.5, 4.5)
		hpos.y   = NORDIC_WATER_Y + 0.15
		_nordic_stilt_house(hpos, -branch_dirs[i], Vector2(6.5, 6.0))

	# Dressing
	_nordic_dock_dressing(pier_start, pier_dir, branch_dirs, branch_bases)
	_nordic_shore_dressing(origin, shore_dir, pier_dir)

	# Dock NPCs
	_nordic_dock_npcs(origin, pier_start, pier_dir, shore_dir)

	# Shrink all MultiMesh instance counts to actual usage, then clear batch dict
	_mm_finalize()

	_dlog("Nordic fishing village built (rev2) at " + str(origin))

# Road is split into its own _safe_call so a road crash never kills the village.
func _build_nordic_road() -> void:
	var origin := NORDIC_ORIGIN
	var road_end: Vector3 = origin + Vector3(0, 0, 8)
	_nordic_cobble_road(Vector3(0, 0, 12), road_end)
	# Harbor gate arch sits at the road's northern terminus, facing south (dir = +Z)
	_nordic_harbor_gate(road_end + Vector3(0, 0, 4), Vector3(0, 0, 1))
	_dlog("Nordic cobble road + harbor gate built")

# ── Harbor ambient audio — Builder run 25 ────────────────────────────────────
# All three streams are optional — assign in the Inspector to activate.
# Suggested CC0 sources: freesound.org ("ocean waves loop", "dock creak", "seagull cry")
# Audio zones use Godot's built-in 3D distance attenuation — no extra code needed.
func _build_nordic_ambient_audio() -> void:
	if sfx_waves_loop == null and sfx_dock_creak_loop == null and sfx_gulls_one_shot == null:
		_dlog("Nordic audio: no streams assigned — skipping")
		return

	var root := Node3D.new()
	root.name = "NordicAmbientAudio"
	add_child(root)

	var origin := NORDIC_ORIGIN

	# Ocean waves — large radius, centred on the harbour water plane
	if sfx_waves_loop != null:
		var waves := AudioStreamPlayer3D.new()
		waves.name          = "WavesLoop"
		waves.stream        = sfx_waves_loop
		waves.max_distance  = 130.0
		waves.unit_size     = 1.0
		waves.volume_db     = sfx_waves_volume_db
		waves.autoplay      = true
		waves.global_position = origin + Vector3(0, 0, -20)  # over the water
		root.add_child(waves)

	# Dock creak — tighter radius, right at the pier head where ropes + posts are
	if sfx_dock_creak_loop != null:
		var creak := AudioStreamPlayer3D.new()
		creak.name          = "DockCreakLoop"
		creak.stream        = sfx_dock_creak_loop
		creak.max_distance  = 55.0
		creak.unit_size     = 1.0
		creak.volume_db     = sfx_creak_volume_db
		creak.autoplay      = true
		creak.global_position = origin + Vector3(0, 0.15, 6)  # pier start
		root.add_child(creak)

	# Gulls — random one-shots on a timer, scattered across the harbour airspace
	if sfx_gulls_one_shot != null:
		var gull_timer := Timer.new()
		gull_timer.name      = "GullTimer"
		gull_timer.wait_time = sfx_gulls_interval_min
		gull_timer.one_shot  = false
		gull_timer.autostart = true
		gull_timer.timeout.connect(func(): _play_nordic_gull(root))
		root.add_child(gull_timer)

	_dlog("Nordic ambient audio built")

func _play_nordic_gull(audio_root: Node3D) -> void:
	if sfx_gulls_one_shot == null:
		return
	if not is_instance_valid(audio_root):
		return

	# Use _nrng for position scatter — consistent with the rest of Nordic
	var origin := NORDIC_ORIGIN
	var p: Vector3 = origin + Vector3(
		_nrng.randf_range(-30.0, 30.0),
		_nrng.randf_range(3.0, 10.0),
		_nrng.randf_range(-20.0, 40.0)
	)

	var gull := AudioStreamPlayer3D.new()
	gull.stream      = sfx_gulls_one_shot
	gull.max_distance = 140.0
	gull.volume_db   = _nrng.randf_range(-14.0, -7.0)
	gull.pitch_scale = _nrng.randf_range(0.88, 1.14)
	gull.global_position = p
	audio_root.add_child(gull)
	gull.play()

	# Self-cleanup: free the player node when the cry finishes (~3 s max)
	var cleanup := Timer.new()
	cleanup.wait_time = 3.5
	cleanup.one_shot  = true
	cleanup.autostart = true
	cleanup.timeout.connect(func():
		if is_instance_valid(gull):
			gull.queue_free()
		cleanup.queue_free()
	)
	audio_root.add_child(cleanup)

	# Randomise next gull interval
	var gull_timer := audio_root.find_child("GullTimer", false, false) as Timer
	if gull_timer and is_instance_valid(gull_timer):
		gull_timer.wait_time = _nrng.randf_range(sfx_gulls_interval_min, sfx_gulls_interval_max)

# ── Utilities ────────────────────────────────────────────────────────────────
func _nordic_side(dir: Vector3) -> Vector3:
	var s: Vector3 = dir.rotated(Vector3.UP, PI * 0.5)
	return s if _nrng.randf() < 0.5 else -s  # FIX: was randi()%2 (modulo bias)

# ── Pier spine — with single batched collision body ──────────────────────────
func _nordic_pier_spine(start: Vector3, dir: Vector3, length: float) -> void:
	var seg_len := 3.0
	var count: float = int(ceil(length / seg_len))
	for i in range(count):
		var seg_pos := start + dir * (float(i) * seg_len)
		seg_pos.y   = start.y
		_nordic_pier_segment(seg_pos, dir, seg_len)
	# FIX: single collision body spanning the full pier deck
	_nordic_pier_collision(start, dir, length)

# ── Pier branch — with batched collision + end platform ──────────────────────
func _nordic_pier_branch(start: Vector3, dir: Vector3, length: float) -> void:
	var seg_len := 3.0
	var count: float = int(ceil(length / seg_len))
	for i in range(count):
		var seg_pos := start + dir * (float(i) * seg_len)
		seg_pos.y   = start.y
		_nordic_pier_segment(seg_pos, dir, seg_len)
	_nordic_pier_collision(start, dir, length)
	# End platform — FIX: wrapped in Node3D so it uses global_position
	var plat_root := Node3D.new()
	plat_root.name = "PierEndPlat"
	add_child(plat_root)
	plat_root.global_position = start + dir * (length + 1.6)
	plat_root.global_position.y = start.y
	plat_root.rotation.y = atan2(dir.x, dir.z)
	var plat  := MeshInstance3D.new()
	var pm    := BoxMesh.new()
	pm.size   = Vector3(NORDIC_PIER_W + 1.4, 0.22, 3.6)
	plat.mesh = pm
	plat.material_override = MAT_PLANK(2.0)
	plat_root.add_child(plat)
	# End-platform collision
	var pb   := StaticBody3D.new()
	var pc   := CollisionShape3D.new()
	var ps   := BoxShape3D.new()
	ps.size  = Vector3(NORDIC_PIER_W + 1.4, 0.22, 3.6)
	pc.shape = ps
	pb.add_child(pc)
	plat_root.add_child(pb)

# FIX: one StaticBody3D per pier call, sized to full deck length (not per segment)
func _nordic_pier_collision(start: Vector3, dir: Vector3, length: float) -> void:
	var mid := start + dir * (length * 0.5)
	var body := StaticBody3D.new()
	body.name = "PierCollision"
	add_child(body)
	body.global_position = mid
	body.global_position.y = start.y
	body.rotation.y = atan2(dir.x, dir.z)
	var col   := CollisionShape3D.new()
	var box   := BoxShape3D.new()
	box.size  = Vector3(NORDIC_PIER_W, 0.22, length)
	col.shape = box
	body.add_child(col)

# ── MultiMesh batching helpers (Builder run 26 — perf pass) ─────────────────
func _mm_key(mesh: Mesh, mat: Material) -> String:
	return "%s|%s" % [str(mesh.get_rid()), str(mat.get_rid()) if mat != null else "null"]

func _mm_add(parent: Node, mesh: Mesh, mat: Material, xform: Transform3D, reserve: int = 64) -> void:
	var key := _mm_key(mesh, mat)
	if not _mm_batches.has(key) or not is_instance_valid(_mm_batches[key].mmi):
		var mmi := MultiMeshInstance3D.new()
		var mm  := MultiMesh.new()
		mm.mesh = mesh
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.instance_count = reserve
		mmi.multimesh = mm
		if mat != null:
			mmi.material_override = mat
		parent.add_child(mmi)
		_mm_batches[key] = {"mmi": mmi, "mm": mm, "next": 0}
	var d: Dictionary = _mm_batches[key]
	if d.next >= d.mm.instance_count:
		d.mm.instance_count += reserve
	d.mm.set_instance_transform(d.next, xform)
	d.next += 1
	_mm_batches[key] = d

func _mm_finalize() -> void:
	for key in _mm_batches:
		var d: Dictionary = _mm_batches[key]
		if d.mm and d.next > 0:
			d.mm.instance_count = d.next
	_mm_batches.clear()

# ── Single pier segment: visuals only (collision handled by _nordic_pier_collision)
func _nordic_pier_segment(world_pos: Vector3, dir: Vector3, seg_len: float) -> Node3D:
	var seg := Node3D.new()
	seg.name = "PierSeg"
	add_child(seg)
	seg.global_position = world_pos
	seg.rotation.y = atan2(dir.x, dir.z)

	var deck := MeshInstance3D.new()
	var dm   := BoxMesh.new()
	dm.size  = Vector3(NORDIC_PIER_W, 0.20, seg_len)
	deck.mesh = dm
	deck.material_override = MAT_PLANK(2.0)
	deck.position = Vector3(0, 0.0, seg_len * 0.5)
	seg.add_child(deck)

	var y_rot     := atan2(dir.x, dir.z)
	var seg_basis := Basis(Vector3.UP, y_rot)

	# Posts — MultiMesh batch path; else branch preserved for per-node debugging
	if _pier_post_mesh != null:
		for sx in [-(NORDIC_PIER_W * 0.44), NORDIC_PIER_W * 0.44]:
			var post_local: Vector3 = Vector3(sx, -1.5, seg_len * 0.18)
			var post_world := world_pos + seg_basis * post_local
			_mm_add(seg.get_parent(), _pier_post_mesh, MAT_DARKPOST(),
					Transform3D(Basis.IDENTITY, post_world))
	else:
		for sx in [-(NORDIC_PIER_W * 0.44), NORDIC_PIER_W * 0.44]:
			var post := MeshInstance3D.new()
			var cm   := CylinderMesh.new()
			cm.top_radius    = 0.11
			cm.bottom_radius = 0.14
			cm.height        = 3.0
			post.mesh        = cm
			post.material_override = MAT_DARKPOST()
			post.position    = Vector3(sx, -1.5, seg_len * 0.18)
			seg.add_child(post)

	# Rails — MultiMesh batch path; else branch preserved for per-node debugging
	if _nrng.randf() < 0.70:
		if _pier_rail_mesh != null:
			for sx in [-(NORDIC_PIER_W * 0.47), NORDIC_PIER_W * 0.47]:
				var rail_local: Vector3 = Vector3(sx, 1.0, seg_len * 0.5)
				var rail_world := world_pos + seg_basis * rail_local
				_mm_add(seg.get_parent(), _pier_rail_mesh, MAT_PLANK(1.0),
						Transform3D(seg_basis, rail_world))
		else:
			for sx in [-(NORDIC_PIER_W * 0.47), NORDIC_PIER_W * 0.47]:
				var rail := MeshInstance3D.new()
				var rm   := BoxMesh.new()
				rm.size  = Vector3(0.10, 0.08, seg_len)
				rail.mesh = rm
				rail.material_override = MAT_PLANK(1.0)
				rail.position = Vector3(sx, 1.0, seg_len * 0.5)
				seg.add_child(rail)

	return seg

# ── Stilt house ───────────────────────────────────────────────────────────────
func _nordic_stilt_house(world_pos: Vector3, facing: Vector3, footprint: Vector2) -> Node3D:
	var house  := Node3D.new()
	house.name = "NordicHouse"
	add_child(house)
	house.global_position = world_pos
	house.rotation.y = atan2(facing.x, facing.z)

	var w      := footprint.x
	var d      := footprint.y
	var wall_h := 3.0
	var rpeak: float = _nrng.randf_range(2.2, 3.0)
	var deck_y: float = _nrng.randf_range(0.5, 1.6)
	var stilt_h := deck_y + 0.25

	for sx in [-w * 0.44, w * 0.44]:
		for sz in [-d * 0.44, d * 0.44]:
			var post := MeshInstance3D.new()
			var cm   := CylinderMesh.new()
			cm.top_radius    = 0.09
			cm.bottom_radius = 0.12
			cm.height        = stilt_h
			post.mesh = cm
			post.material_override = MAT_DARKPOST()
			post.position = Vector3(sx, stilt_h * 0.5, sz)
			house.add_child(post)

	var deck := MeshInstance3D.new()
	var ddm  := BoxMesh.new()
	ddm.size = Vector3(w, 0.22, d)
	deck.mesh = ddm
	deck.material_override = MAT_PLANK(1.5)
	deck.position.y = deck_y
	house.add_child(deck)

	var walls := MeshInstance3D.new()
	var wm    := BoxMesh.new()
	wm.size   = Vector3(w * 0.88, wall_h, d * 0.88)
	walls.mesh = wm
	walls.material_override = MAT_PLASTER(3)
	walls.position.y = deck_y + 0.11 + wall_h * 0.5
	house.add_child(walls)

	for bx in [-w * 0.42, w * 0.42]:
		for bz in [-d * 0.42, d * 0.42]:
			var beam := MeshInstance3D.new()
			var bm   := BoxMesh.new()
			bm.size  = Vector3(0.18, wall_h, 0.18)
			beam.mesh = bm
			beam.material_override = MAT_DARK_WOOD(0.5)
			beam.position = Vector3(bx, deck_y + 0.11 + wall_h * 0.5, bz)
			house.add_child(beam)

	var roof  := MeshInstance3D.new()
	var pyr   := PrismMesh.new()
	pyr.left_to_right = 0.5
	pyr.size  = Vector3(w * 1.06, rpeak, d * 1.06)
	roof.mesh = pyr
	roof.material_override = MAT_ROOF(2.0)
	roof.position.y = deck_y + 0.11 + wall_h + rpeak * 0.5
	house.add_child(roof)

	# Window — FIX: cull_mode disabled so visible from both sides
	var wwin := StandardMaterial3D.new()
	wwin.albedo_color             = Color(0.95, 0.60, 0.25)
	wwin.emission_enabled         = true
	wwin.emission                 = Color(1.0, 0.70, 0.3)
	wwin.emission_energy_multiplier = 1.0
	wwin.cull_mode                = BaseMaterial3D.CULL_DISABLED
	var win  := MeshInstance3D.new()
	var qm   := QuadMesh.new()
	qm.size  = Vector2(0.55, 0.45)
	win.mesh = qm
	win.material_override = wwin
	win.position = Vector3(0, deck_y + 0.11 + wall_h * 0.55, d * 0.445)
	house.add_child(win)

	if _nrng.randf() < 0.60:
		var porch := MeshInstance3D.new()
		var pm    := BoxMesh.new()
		pm.size   = Vector3(w * 0.38, 0.16, 1.5)
		porch.mesh = pm
		porch.material_override = MAT_PLANK(1.0)
		porch.position = Vector3(0, deck_y + 0.08, d * 0.54)
		house.add_child(porch)

	# FIX: collision matches walls only (not the under-deck gap)
	var body  := StaticBody3D.new()
	var col   := CollisionShape3D.new()
	var box   := BoxShape3D.new()
	box.size  = Vector3(w * 0.88, wall_h + 0.22, d * 0.88)
	col.shape = box
	col.position.y = deck_y + 0.11 + wall_h * 0.5
	body.add_child(col)
	house.add_child(body)

	return house

# ── Longhouse ─────────────────────────────────────────────────────────────────
func _nordic_longhouse(world_pos: Vector3, facing: Vector3) -> void:
	var b     := Node3D.new()
	b.name    = "NordicLonghouse"
	add_child(b)
	b.global_position = world_pos
	b.rotation.y = atan2(facing.x, facing.z)

	var w := 8.0; var d := 20.0; var wh := 4.2

	var base := MeshInstance3D.new()
	var bsm  := BoxMesh.new()
	bsm.size = Vector3(w, 0.65, d)
	base.mesh = bsm
	base.material_override = MAT_STONE(2.0)
	base.position.y = 0.32
	b.add_child(base)

	var walls := MeshInstance3D.new()
	var wm    := BoxMesh.new()
	wm.size   = Vector3(w * 0.92, wh, d * 0.92)
	walls.mesh = wm
	walls.material_override = MAT_PLASTER(3)
	walls.position.y = 0.65 + wh * 0.5
	b.add_child(walls)

	for bx in [-w * 0.44, w * 0.44]:
		for bz in [-d * 0.44, d * 0.44]:
			var beam := MeshInstance3D.new()
			var bm   := BoxMesh.new()
			bm.size  = Vector3(0.25, wh, 0.25)
			beam.mesh = bm
			beam.material_override = MAT_DARK_WOOD(0.5)
			beam.position = Vector3(bx, 0.65 + wh * 0.5, bz)
			b.add_child(beam)

	var eave  := MeshInstance3D.new()
	var em    := BoxMesh.new()
	em.size   = Vector3(w + 1.0, 0.22, d + 1.0)
	eave.mesh = em
	eave.material_override = MAT_DARK_WOOD(0.5)
	eave.position.y = 0.65 + wh + 0.11
	b.add_child(eave)

	var roof  := MeshInstance3D.new()
	var pyr   := PrismMesh.new()
	pyr.left_to_right = 0.5
	pyr.size  = Vector3(w + 1.2, 4.0, d + 1.2)
	roof.mesh = pyr
	roof.material_override = MAT_ROOF(2.5)
	roof.position.y = 0.65 + wh + 2.2
	b.add_child(roof)

	var sign  := MeshInstance3D.new()
	var sm    := BoxMesh.new()
	sm.size   = Vector3(2.0, 0.55, 0.10)
	sign.mesh = sm
	sign.material_override = MAT_DARK_WOOD(1.0)
	sign.position = Vector3(0, 2.4, d * 0.50)
	b.add_child(sign)

	# FIX: collision sized to wall footprint (was full w×d, now w*0.92 × d*0.92)
	var body  := StaticBody3D.new()
	var col   := CollisionShape3D.new()
	var box   := BoxShape3D.new()
	box.size  = Vector3(w * 0.92, wh + 0.65, d * 0.92)
	col.shape = box
	col.position.y = (wh + 0.65) * 0.5
	body.add_child(col)
	b.add_child(body)

	_register_interactable(b, "inn")

# ── Smokehouse ────────────────────────────────────────────────────────────────
func _nordic_smokehouse(world_pos: Vector3, facing: Vector3) -> void:
	var b     := Node3D.new()
	b.name    = "NordicSmokehouse"
	add_child(b)
	b.global_position = world_pos
	b.rotation.y = atan2(facing.x, facing.z)

	var w := 5.5; var d := 5.5; var wh := 3.0

	var base := MeshInstance3D.new()
	var bsm  := BoxMesh.new()
	bsm.size = Vector3(w, 0.5, d)
	base.mesh = bsm
	base.material_override = MAT_STONE(2.0)
	base.position.y = 0.25
	b.add_child(base)

	var walls := MeshInstance3D.new()
	var wm    := BoxMesh.new()
	wm.size   = Vector3(w * 0.90, wh, d * 0.90)
	walls.mesh = wm
	walls.material_override = MAT_WOOD(1.5)
	walls.position.y = 0.5 + wh * 0.5
	b.add_child(walls)

	# FIX: roof added (was missing entirely)
	var roof  := MeshInstance3D.new()
	var pyr   := PrismMesh.new()
	pyr.left_to_right = 0.5
	pyr.size  = Vector3(w * 1.05, 1.6, d * 1.05)
	roof.mesh = pyr
	roof.material_override = MAT_ROOF(2.0)
	roof.position.y = 0.5 + wh + 0.85
	b.add_child(roof)

	# FIX: chimney base pinned to wall top + small offset into roof
	var ch_h: float = _nrng.randf_range(3.5, 5.2)
	var ch   := MeshInstance3D.new()
	var cm   := CylinderMesh.new()
	cm.top_radius    = 0.38
	cm.bottom_radius = 0.48
	cm.height        = ch_h
	ch.mesh  = cm
	ch.material_override = MAT_STONE(1.0)
	ch.position = Vector3(w * 0.18, 0.5 + wh - 0.3 + ch_h * 0.5, -d * 0.08)
	b.add_child(ch)

	var body  := StaticBody3D.new()
	var col   := CollisionShape3D.new()
	var box   := BoxShape3D.new()
	box.size  = Vector3(w, wh + 0.5, d)
	col.shape = box
	col.position.y = (wh + 0.5) * 0.5
	body.add_child(col)
	b.add_child(body)

# ── Lighthouse beacon ─────────────────────────────────────────────────────────
func _nordic_beacon(world_pos: Vector3) -> void:
	var b     := Node3D.new()
	b.name    = "NordicBeacon"
	add_child(b)
	b.global_position = world_pos

	var tower := MeshInstance3D.new()
	var cm    := CylinderMesh.new()
	cm.top_radius    = 1.1
	cm.bottom_radius = 1.55
	cm.height        = 10.0
	tower.mesh = cm
	tower.material_override = MAT_STONE(1.5)
	tower.position.y = 5.0
	b.add_child(tower)

	var cap  := MeshInstance3D.new()
	var capm := BoxMesh.new()
	capm.size = Vector3(2.2, 1.6, 2.2)
	cap.mesh  = capm
	cap.material_override = MAT_DARK_WOOD(0.5)
	cap.position.y = 10.8
	b.add_child(cap)

	var light := OmniLight3D.new()
	light.light_color  = Color(1.0, 0.82, 0.42)
	light.light_energy = 3.5
	light.omni_range   = 40.0
	light.position     = Vector3(0, 11.6, 0)
	b.add_child(light)

	var body  := StaticBody3D.new()
	var col   := CollisionShape3D.new()
	var cyl   := CylinderShape3D.new()
	cyl.radius = 1.55
	cyl.height = 10.0
	col.shape  = cyl
	col.position.y = 5.0
	body.add_child(col)
	b.add_child(body)

# ── Shore houses ─────────────────────────────────────────────────────────────
func _nordic_shore_houses(origin: Vector3, shore_dir: Vector3, pier_dir: Vector3, count: int) -> void:
	var spacing := 9.0
	for i in range(count):
		var t   := float(i) - float(count) * 0.5
		# FIX: skip slot near longhouse (at shore_dir * 18 m) to avoid overlap
		if abs(t * spacing - 18.0) < 7.0:
			continue
		var pos := origin + shore_dir * (t * spacing) \
					+ pier_dir * _nrng.randf_range(4.0, 12.0) \
					+ _nordic_side(shore_dir) * _nrng.randf_range(0.0, 3.5)
		pos.y   = origin.y
		var fp: Vector2 = Vector2(_nrng.randf_range(6.0, 8.0), _nrng.randf_range(5.5, 7.0))
		_nordic_stilt_house(pos, -pier_dir, fp)

# ── Fish rack ─────────────────────────────────────────────────────────────────
func _nordic_fish_rack(world_pos: Vector3, facing: Vector3) -> void:
	var n     := Node3D.new()
	n.name    = "FishRack"
	add_child(n)
	n.global_position = world_pos
	n.rotation.y = atan2(facing.x, facing.z)

	for sx in [-1.1, 1.1]:
		for sz in [-0.5, 0.5]:
			var post := MeshInstance3D.new()
			var cm   := CylinderMesh.new()
			cm.top_radius    = 0.055
			cm.bottom_radius = 0.07
			cm.height        = 1.55
			post.mesh = cm
			post.material_override = MAT_DARKPOST()
			post.position = Vector3(sx, 0.77, sz)
			n.add_child(post)

	var bar  := MeshInstance3D.new()
	var bm   := BoxMesh.new()
	bm.size  = Vector3(2.6, 0.07, 0.10)
	bar.mesh = bm
	bar.material_override = MAT_PLANK(1.0)
	bar.position.y = 1.42
	n.add_child(bar)

	_register_interactable(n, "fish_rack")

# ── Clutter (barrel / crate) ──────────────────────────────────────────────────
func _nordic_clutter(world_pos: Vector3) -> void:
	var n := Node3D.new()
	add_child(n)
	n.global_position = world_pos
	n.rotation.y = _nrng.randf_range(-PI, PI)

	# GLB fast-path: use wooden_barrel.glb when wired in the Inspector.
	# AABB scaler ensures correct height regardless of GLB source scale.
	if glb_barrel != null and _nrng.randf() < 0.55:
		var inst: Node3D = glb_barrel.instantiate() as Node3D
		n.add_child(inst)
		_scale_node_to_height(inst, _nrng.randf_range(0.55, 0.80))
		return
	# Primitive fallback (also used for crates when glb_crate is null)
	var mi := MeshInstance3D.new()
	if _nrng.randf() < 0.55:
		var cm := CylinderMesh.new()
		cm.top_radius    = 0.22
		cm.bottom_radius = 0.25
		cm.height        = _nrng.randf_range(0.5, 0.80)
		mi.mesh  = cm
		mi.material_override = MAT_DARK_WOOD(0.5)
		mi.position.y = cm.height * 0.5
	else:
		var bx := BoxMesh.new()
		bx.size = Vector3(_nrng.randf_range(0.38, 0.70),
							_nrng.randf_range(0.28, 0.52),
							_nrng.randf_range(0.38, 0.70))
		mi.mesh = bx
		mi.material_override = MAT_WOOD(1.0)
		mi.position.y = bx.size.y * 0.5
	n.add_child(mi)

# ── Boat ─────────────────────────────────────────────────────────────────────
func _nordic_boat(world_pos: Vector3, facing: Vector3) -> void:
	var n := Node3D.new()
	n.name = "NordicBoat"
	add_child(n)
	n.global_position = world_pos
	n.rotation.y = atan2(facing.x, facing.z)

	var hull := MeshInstance3D.new()
	var bm   := BoxMesh.new()
	bm.size  = Vector3(_nrng.randf_range(1.7, 2.4), 0.65, _nrng.randf_range(4.5, 7.5))
	hull.mesh = bm
	hull.material_override = MAT_DARK_WOOD(1.5)
	hull.position.y = 0.32
	n.add_child(hull)

	if _nrng.randf() < 0.50:
		var mast := MeshInstance3D.new()
		var cm   := CylinderMesh.new()
		cm.top_radius    = 0.06
		cm.bottom_radius = 0.09
		cm.height        = _nrng.randf_range(4.0, 6.5)
		mast.mesh = cm
		mast.material_override = MAT_DARKPOST()
		mast.position = Vector3(0, 0.65 + cm.height * 0.5, -bm.size.z * 0.12)
		n.add_child(mast)

	_register_interactable(n, "boat_travel")

# ── Woodpile ─────────────────────────────────────────────────────────────────
func _nordic_woodpile(world_pos: Vector3) -> void:
	var n  := Node3D.new()
	n.name = "Woodpile"
	add_child(n)
	n.global_position = world_pos
	n.rotation.y = _nrng.randf_range(-PI, PI)

	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(_nrng.randf_range(0.9, 1.8),
						_nrng.randf_range(0.35, 0.65),
						_nrng.randf_range(0.55, 1.1))
	mi.mesh = bm
	mi.material_override = MAT_DARK_WOOD(1.0)
	mi.position.y = bm.size.y * 0.5
	n.add_child(mi)

# ── Dock dressing ─────────────────────────────────────────────────────────────
func _nordic_dock_dressing(pier_start: Vector3, pier_dir: Vector3, branch_dirs: Array[Vector3], branch_bases: Array[Vector3]) -> void:
	# Fish racks
	for i in range(10):
		var z: float = _nrng.randf_range(5.0, NORDIC_PIER_LEN * 0.65)
		var x: float = (-1.0 if _nrng.randf() < 0.5 else 1.0) * _nrng.randf_range(3.0, 7.0)
		var p: Vector3 = pier_start + pier_dir * z + pier_dir.rotated(Vector3.UP, PI * 0.5) * x
		p.y   = NORDIC_WATER_Y + 0.15
		_nordic_fish_rack(p, -pier_dir)

	# Clutter
	for i in range(38):
		var p: Vector3 = pier_start + pier_dir * _nrng.randf_range(2.0, NORDIC_PIER_LEN) \
					+ pier_dir.rotated(Vector3.UP, PI * 0.5) * _nrng.randf_range(-6.0, 6.0)
		p.y   = NORDIC_WATER_Y + 0.15
		_nordic_clutter(p)

	# FIX: boats use NORDIC_BRANCH_T offsets to match actual branch positions
	for i in range(branch_dirs.size()):
		if _nrng.randf() < 0.75:
			var bp: Vector3 = branch_bases[i] + branch_dirs[i] * _nrng.randf_range(12.0, 20.0)
			bp    += _nordic_side(branch_dirs[i]) * 4.2
			bp.y  = NORDIC_WATER_Y - 0.06
			_nordic_boat(bp, -branch_dirs[i])

	# Two boats alongside main pier
	for i in range(2):
		var bp: Vector3 = pier_start + pier_dir * _nrng.randf_range(15.0, 35.0)
		bp    += pier_dir.rotated(Vector3.UP, PI * 0.5) * ((-1.0 if _nrng.randf() < 0.5 else 1.0) * 4.5)
		bp.y  = NORDIC_WATER_Y - 0.06
		_nordic_boat(bp, -pier_dir)

# ── Shore dressing ────────────────────────────────────────────────────────────
func _nordic_shore_dressing(origin: Vector3, shore_dir: Vector3, pier_dir: Vector3) -> void:
	for i in range(50):
		var p: Vector3 = origin + shore_dir * _nrng.randf_range(-55.0, 55.0) \
					+ pier_dir * _nrng.randf_range(3.0, 18.0) \
					+ _nordic_side(shore_dir) * _nrng.randf_range(0.0, 5.0)
		p.y   = origin.y
		if _nrng.randf() < 0.40:
			_nordic_woodpile(p)
		elif _nrng.randf() < 0.55:
			_nordic_clutter(p)
		else:
			_nordic_fish_rack(p, shore_dir)

# ── Dock NPCs (Upgrade 2) ─────────────────────────────────────────────────────
# Uses same _make_npc() pipeline as Briarwood — NPC.gd handles dialogue + scale.
func _nordic_dock_npcs(origin: Vector3, pier_start: Vector3, pier_dir: Vector3, shore_dir: Vector3) -> void:
	var npc_defs := [
		{
			"name": "Fisherman Torben",
			"role": "dock_fisher",
			"pos":  pier_start + pier_dir * 38.0 + shore_dir * 1.2,
			"line": "The sea gives, and the sea takes. Today she gives — look at this catch!",
			"lines": [
				"Cast your line past the big rock. That's where the big ones hide.",
				"Storm's coming. I can smell it on the wind.",
				"My father fished this pier. His father too.",
			],
			"bark_lines": ["Hm… the tide is turning.", "Fine day for it!", "Almost full. Almost."],
			"bark_min": 18.0, "bark_max": 35.0,
			"tint": Color(0.8, 0.75, 0.65),
			"schedule": [
				pier_start + pier_dir * 38.0 + shore_dir * 1.2,
				pier_start + pier_dir * 32.0,
				pier_start + pier_dir * 42.0 - shore_dir * 1.5,
			],
		},
		{
			"name": "Net-mender Sigrid",
			"role": "dock_mender",
			"pos":  origin + shore_dir * -14.0 + pier_dir * 6.0,
			"line": "These nets don't mend themselves, you know.",
			"lines": [
				"A good net is the difference between a feast and an empty table.",
				"The longhouse is warm tonight. Come by when you're done exploring.",
				"I've heard strange lights out past the rocks at night. Be careful.",
			],
			"bark_lines": ["Loop, knot, pull…", "Almost done with this one.", "The old ways hold best."],
			"bark_min": 22.0, "bark_max": 40.0,
			"tint": Color(0.75, 0.72, 0.68),
			"schedule": [
				origin + shore_dir * -14.0 + pier_dir * 6.0,
				origin + shore_dir * -10.0 + pier_dir * 4.0,
			],
		},
		{
			"name": "Harbormaster Bjorn",
			"role": "dock_master",
			"pos":  origin + shore_dir * 16.0 + Vector3(0, 0, 3.0),
			"line": "Welcome to Northhaven. Mind the ropes — they'll catch your feet.",
			"lines": [
				"Every ship that leaves here carries a piece of this village.",
				"You're looking for adventure? Ha. It usually finds you first.",
				"The lighthouse has kept ships safe for three generations. Don't touch it.",
			],
			"bark_lines": ["Tide's right on schedule.", "Watch those barrels!", "Morning!"],
			"bark_min": 25.0, "bark_max": 45.0,
			"tint": Color(0.7, 0.68, 0.62),
			"schedule": [
				origin + shore_dir * 16.0 + Vector3(0, 0, 3.0),
				origin + shore_dir * 12.0 + pier_dir * 5.0,
				pier_start + shore_dir * 2.0,
			],
		},
	]
	for d in npc_defs:
		_make_npc(d)

# ── Cobble road Briarwood → Nordic (Upgrade 3) ───────────────────────────────
func _nordic_cobble_road(road_start: Vector3, road_end: Vector3) -> void:
	var dir  := road_end - road_start
	dir.y    = 0.0
	var dist: float = dir.length()
	if dist < 1.0:
		return
	dir = dir.normalized()
	var side: Vector3 = dir.rotated(Vector3.UP, PI * 0.5)
	var steps := int(dist / 2.2)
	var p     := road_start

	# Seed from main _rng (road uses world rng for wobble, not _nrng)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9988

	for i in range(steps + 1):
		var t      := float(i) / float(maxi(1, steps))
		# Gentle meander that fades to straight near both ends
		var wobble: float = sin(t * PI * 3.0) * 1.1 + rng.randf_range(-0.3, 0.3)
		# Widen near the Nordic plaza
		var width: float = lerp(2.8, 4.8, smoothstep(0.75, 1.0, t))

		var seg    := MeshInstance3D.new()
		var bm     := BoxMesh.new()
		bm.size    = Vector3(width, 0.16, 2.3)
		seg.mesh   = bm
		seg.material_override = MAT_PATH(3.0)
		seg.global_position = p + side * wobble + Vector3(0, 0.02, 0)
		seg.rotation.y = atan2(dir.x, dir.z)
		seg.name   = "RoadSeg"
		add_child(seg)

		# Lantern post every ~16 m
		if i % 7 == 0 and i > 0:
			for lx in [-width * 0.6, width * 0.6]:
				_nordic_road_lantern(p + side * (wobble + lx) + Vector3(0, 0, 0))

		# Story prop every ~30 m (rune stone, broken cart)
		if i % 14 == 7:
			_nordic_road_prop(p + side * (wobble + rng.randf_range(2.5, 4.0)))

		p += dir * 2.2

	# Signpost at start (Briarwood end) and 60% along road
	_nordic_signpost(road_start + dir * 3.0 + side * 2.2, -dir,
						"Northhaven Docks →", "← Briarwood Village")
	_nordic_signpost(road_start + dir * (dist * 0.60) + side * 2.5, dir,
						"← Briarwood", "Northhaven →")

# ── Road lantern post ─────────────────────────────────────────────────────────
func _nordic_road_lantern(world_pos: Vector3) -> void:
	# Try the existing lantern GLB first (same fallback contract as village)
	if ResourceLoader.exists(LANTERN_GLB_PATH):
		var sc := load(LANTERN_GLB_PATH)
		if sc is PackedScene:
			var inst: Node3D = (sc as PackedScene).instantiate()
			add_child(inst)
			inst.global_position = world_pos
			return
	# Primitive fallback
	var n    := Node3D.new()
	n.name   = "RoadLantern"
	add_child(n)
	n.global_position = world_pos
	var post := MeshInstance3D.new()
	var cm   := CylinderMesh.new()
	cm.top_radius    = 0.05
	cm.bottom_radius = 0.07
	cm.height        = 2.4
	post.mesh = cm
	post.material_override = MAT_DARKPOST()
	post.position.y = 1.2
	n.add_child(post)
	var lamp := MeshInstance3D.new()
	var bm   := BoxMesh.new()
	bm.size  = Vector3(0.22, 0.22, 0.22)
	lamp.mesh = bm
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = Color(0.95, 0.8, 0.35)
	lmat.emission_enabled = true
	lmat.emission = Color(1.0, 0.85, 0.4)
	lmat.emission_energy_multiplier = 1.5
	lamp.material_override = lmat
	lamp.position.y = 2.52
	n.add_child(lamp)
	var omni := OmniLight3D.new()
	omni.light_energy = 1.2
	omni.light_color  = Color(1.0, 0.82, 0.42)
	omni.omni_range   = 8.0
	omni.position.y   = 2.52
	n.add_child(omni)

# ── Road story prop (rune stone / broken cart) ────────────────────────────────
func _nordic_road_prop(world_pos: Vector3) -> void:
	var n  := Node3D.new()
	n.name = "RoadProp"
	add_child(n)
	n.global_position = world_pos
	n.rotation.y = _nrng.randf_range(-PI, PI)
	# Rune stone — tall thin boulder with a carved-looking dark face
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.45, _nrng.randf_range(0.9, 1.5), 0.22)
	mi.mesh = bm
	mi.material_override = MAT_STONE(1.0)
	mi.position.y = bm.size.y * 0.5
	n.add_child(mi)
	# Dark inscription face
	var face := MeshInstance3D.new()
	var fm   := QuadMesh.new()
	fm.size  = Vector2(0.30, bm.size.y * 0.65)
	face.mesh = fm
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.12, 0.10, 0.08)
	fmat.cull_mode    = BaseMaterial3D.CULL_DISABLED
	face.material_override = fmat
	face.position = Vector3(0, bm.size.y * 0.5, 0.115)
	n.add_child(face)

# ── Directional signpost ──────────────────────────────────────────────────────
func _nordic_signpost(world_pos: Vector3, facing: Vector3, top_text: String, bot_text: String) -> void:
	var n  := Node3D.new()
	n.name = "Signpost"
	add_child(n)
	n.global_position = world_pos
	n.rotation.y = atan2(facing.x, facing.z)

	# Post
	var post := MeshInstance3D.new()
	var cm   := CylinderMesh.new()
	cm.top_radius    = 0.055
	cm.bottom_radius = 0.07
	cm.height        = 2.2
	post.mesh = cm
	post.material_override = MAT_DARKPOST()
	post.position.y = 1.1
	n.add_child(post)

	# Two sign boards
	for i in range(2):
		var board := MeshInstance3D.new()
		var bm    := BoxMesh.new()
		bm.size   = Vector3(1.1, 0.22, 0.08)
		board.mesh = bm
		board.material_override = MAT_DARK_WOOD(1.0)
		board.position = Vector3(0.5, 1.9 - float(i) * 0.30, 0)
		board.rotation.z = deg_to_rad(_nrng.randf_range(-4.0, 4.0))
		n.add_child(board)

	# Labels (billboarded for readability from any angle)
	var texts := [top_text, bot_text]
	for i in range(2):
		if texts[i].is_empty():
			continue
		var lbl := Label3D.new()
		lbl.text       = texts[i]
		lbl.font_size  = 22
		lbl.outline_size = 5
		lbl.outline_modulate = Color(0, 0, 0)
		lbl.modulate   = Color(1.0, 0.92, 0.68)
		lbl.billboard  = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.position   = Vector3(0.5, 1.96 - float(i) * 0.30, 0.1)
		n.add_child(lbl)

# ── Harbor gate arch — marks the northern road terminus into Northhaven ───────
# Stone post × 2 + crossbeam + "NORTHHAVEN" banner label.
# Facing dir = which way players are travelling THROUGH the gate (into harbor).
func _nordic_harbor_gate(world_pos: Vector3, facing: Vector3) -> void:
	var root := Node3D.new()
	root.name = "HarborGate"
	add_child(root)
	root.global_position = world_pos
	root.rotation.y = atan2(facing.x, facing.z)

	var post_h   : float = 4.2
	var post_w   : float = 0.55
	var gate_w   : float = 5.0   # clear passage width between post centres
	var beam_h   : float = 0.50
	var beam_overhang : float = 0.65

	# Left and right stone pillars
	for side in [-1.0, 1.0]:
		var pillar := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(post_w, post_h, post_w)
		pillar.mesh = bm
		pillar.material_override = MAT_STONE(1.5)
		pillar.position = Vector3(side * (gate_w * 0.5), post_h * 0.5, 0.0)
		root.add_child(pillar)
		# Collision for each pillar so players can't walk through the posts
		var body := StaticBody3D.new()
		var col  := CollisionShape3D.new()
		var box  := BoxShape3D.new()
		box.size = Vector3(post_w, post_h, post_w)
		col.shape = box
		col.position = pillar.position
		body.add_child(col)
		root.add_child(body)
		# Stone cap on top
		var cap := MeshInstance3D.new()
		var cm  := BoxMesh.new()
		cm.size = Vector3(post_w + 0.2, 0.28, post_w + 0.2)
		cap.mesh = cm
		cap.material_override = MAT_STONE(1.0)
		cap.position = Vector3(side * (gate_w * 0.5), post_h + 0.14, 0.0)
		root.add_child(cap)

	# Crossbeam spanning both pillars
	var beam := MeshInstance3D.new()
	var bbm  := BoxMesh.new()
	bbm.size = Vector3(gate_w + post_w * 2.0 + beam_overhang * 2.0, beam_h, post_w * 0.80)
	beam.mesh = bbm
	beam.material_override = MAT_DARK_WOOD(0.5)
	beam.position = Vector3(0.0, post_h + beam_h * 0.5 + 0.28, 0.0)
	root.add_child(beam)

	# Banner board centred on the beam
	var banner := MeshInstance3D.new()
	var sbm    := BoxMesh.new()
	sbm.size   = Vector3(gate_w * 0.70, 0.60, 0.12)
	banner.mesh = sbm
	banner.material_override = MAT_DARK_WOOD(0.8)
	banner.position = Vector3(0.0, post_h + 0.28 + beam_h * 0.5 - 0.35, post_w * 0.45)
	root.add_child(banner)

	# "NORTHHAVEN" label — fixed (not billboarded) so it reads as a real sign
	var lbl := Label3D.new()
	lbl.text             = "NORTHHAVEN"
	lbl.font_size        = 52
	lbl.outline_size     = 8
	lbl.outline_modulate = Color(0.0, 0.0, 0.0)
	lbl.modulate         = Color(1.0, 0.88, 0.55)
	lbl.billboard        = BaseMaterial3D.BILLBOARD_DISABLED
	lbl.pixel_size       = 0.003
	lbl.position         = banner.position + Vector3(0.0, 0.05, 0.07)
	root.add_child(lbl)

	# Ambient torch lights on each pillar top — same warm amber as road lanterns
	for side in [-1.0, 1.0]:
		var torch := OmniLight3D.new()
		torch.light_color  = Color(1.0, 0.78, 0.40)
		torch.light_energy = 2.8
		torch.omni_range   = 14.0
		torch.position     = Vector3(side * (gate_w * 0.5), post_h + 0.5, 0.0)
		root.add_child(torch)

# ============================================================================
# GLB AABB SCALER — Builder run 25 (ported from WorldBuilder_patched.gd)
# Used by _nordic_clutter() for barrel GLB, and available for any future
# GLB prop that needs to be normalised to a target world-space dimension.
# ============================================================================

## Scale node so its tallest visual axis (Y) equals target_h metres.
func _scale_node_to_height(n: Node3D, target_h: float) -> void:
	var aabb := _visual_aabb(n)
	if aabb.size.y <= 0.0001:
		return
	var s := target_h / aabb.size.y
	s = clamp(s, 0.05, 10.0)
	n.scale = n.scale * Vector3.ONE * s

## Scale node so its depth axis (Z) equals target_len metres.
func _scale_node_to_length(n: Node3D, target_len: float) -> void:
	var aabb := _visual_aabb(n)
	if aabb.size.z <= 0.0001:
		return
	var s := target_len / aabb.size.z
	s = clamp(s, 0.05, 10.0)
	n.scale = n.scale * Vector3.ONE * s

## Merge all VisualInstance3D AABBs in world-space and return the combined AABB.
## Returns an empty AABB if the node has no visual children.
func _visual_aabb(n: Node3D) -> AABB:
	var has: bool = false
	var out := AABB()
	for v in n.find_children("*", "VisualInstance3D", true, false):
		var vi := v as VisualInstance3D
		if not vi:
			continue
		var a := vi.get_aabb()
		a = vi.global_transform * a
		if not has:
			out = a
			has = true
		else:
			out = out.merge(a)
	if not has:
		return AABB()
	return out

# ============================================================================
# PHASE 5 — Dock NPC Life Loop
# ============================================================================

var _nordic_life_root: Node3D = null
var _nordic_life_dock_npcs: Array = []
var _nordic_life_timer: Timer = null

func _build_nordic_dock_life() -> void:
	if not nordic_dock_life_enabled:
		return
	if nordic_dock_npc_scene == null:
		return

	if _nordic_life_root and is_instance_valid(_nordic_life_root):
		_nordic_life_root.queue_free()

	_nordic_life_root = Node3D.new()
	_nordic_life_root.name = "NordicDockLife"
	add_child(_nordic_life_root)

	_nordic_life_dock_npcs.clear()

	var anchor := NORDIC_ORIGIN

	var fisher := _spawn_dock_npc(_nordic_life_root, "Fisherman",    anchor + nordic_fisherman_offset)
	var mend   := _spawn_dock_npc(_nordic_life_root, "NetMender",    anchor + nordic_netmender_offset)
	var master := _spawn_dock_npc(_nordic_life_root, "HarborMaster", anchor + nordic_harbormaster_offset)

	if fisher: _nordic_life_dock_npcs.append(fisher)
	if mend:   _nordic_life_dock_npcs.append(mend)
	if master: _nordic_life_dock_npcs.append(master)

	if _nordic_life_dock_npcs.is_empty():
		return

	_configure_dock_route(fisher, [
		anchor + nordic_fisherman_offset,
		anchor + nordic_fisherman_offset + Vector3(0, 0, 14),
		anchor + nordic_fisherman_offset + Vector3(-3, 0, 8),
		anchor + nordic_fisherman_offset + Vector3(2, 0, 4),
	], true)

	_configure_dock_route(mend, [
		anchor + nordic_netmender_offset + Vector3(-0.8, 0, -0.8),
		anchor + nordic_netmender_offset + Vector3(0.8, 0, -0.6),
		anchor + nordic_netmender_offset + Vector3(0.6, 0, 0.9),
		anchor + nordic_netmender_offset + Vector3(-0.7, 0, 0.7),
	], false)

	_configure_dock_route(master, [
		anchor + nordic_harbormaster_offset + Vector3(-2.2, 0, 0.4),
		anchor + nordic_harbormaster_offset + Vector3(2.0, 0, 0.2),
		anchor + nordic_harbormaster_offset + Vector3(1.0, 0, -1.2),
		anchor + nordic_harbormaster_offset + Vector3(-1.4, 0, -1.0),
	], true)

	_nordic_life_timer = Timer.new()
	_nordic_life_timer.name = "NordicLifeTick"
	_nordic_life_timer.wait_time = max(0.4, nordic_dock_life_tick)
	_nordic_life_timer.one_shot = false
	_nordic_life_timer.autostart = true
	_nordic_life_timer.timeout.connect(_tick_nordic_dock_life)
	_nordic_life_root.add_child(_nordic_life_timer)

	_tick_nordic_dock_life()


func _spawn_dock_npc(parent: Node3D, role: String, pos: Vector3) -> Node3D:
	var npc := nordic_dock_npc_scene.instantiate() as Node3D
	if npc == null:
		return null

	parent.add_child(npc)
	npc.name = "DockNPC_%s" % role
	npc.global_position = pos
	npc.set_meta("dock_role", role)

	if has_method("_scale_node_to_height"):
		_scale_node_to_height(npc, nordic_dock_npc_height)

	_try_play_anim(npc, "idle")

	npc.set_meta("dock_route", [])
	npc.set_meta("dock_idx", 0)
	npc.set_meta("dock_idle_until", 0.0)
	npc.set_meta("dock_is_patroller", true)

	# Register harbor master as an interactable (Phase 6)
	if role == "HarborMaster":
		_register_interactable(npc, "harbor_master")

	return npc


func _configure_dock_route(npc: Node3D, points: Array, patroller: bool) -> void:
	if npc == null or not is_instance_valid(npc):
		return
	npc.set_meta("dock_route", points)
	npc.set_meta("dock_idx", 0)
	npc.set_meta("dock_is_patroller", patroller)
	npc.set_meta("dock_idle_until", 0.0)


func _tick_nordic_dock_life() -> void:
	if _nordic_life_dock_npcs.is_empty():
		return

	var now := Time.get_ticks_msec() / 1000.0
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for npc in _nordic_life_dock_npcs:
		if npc == null or not is_instance_valid(npc):
			continue

		var route: Array = npc.get_meta("dock_route", [])
		if route.is_empty():
			continue

		var idle_until: float = float(npc.get_meta("dock_idle_until", 0.0))
		if now < idle_until:
			if rng.randf() < 0.55:
				npc.rotation.y += rng.randf_range(-0.5, 0.5)
			continue

		var idx: int = int(npc.get_meta("dock_idx", 0))
		idx = clamp(idx, 0, route.size() - 1)
		var target: Vector3 = route[idx]

		var dist: float = npc.global_position.distance_to(target)
		if dist < 0.9:
			var role := str(npc.get_meta("dock_role", "Worker"))
			var wait := 0.0
			match role:
				"Fisherman":    wait = rng.randf_range(1.0, 2.4)
				"NetMender":    wait = rng.randf_range(1.8, 4.0)
				"HarborMaster": wait = rng.randf_range(0.8, 1.8)
				_:              wait = rng.randf_range(0.8, 2.2)

			npc.set_meta("dock_idle_until", now + wait)
			_try_play_anim(npc, "idle")
			idx = (idx + 1) % route.size()
			npc.set_meta("dock_idx", idx)
			continue

		_try_play_anim(npc, "walk")
		_npc_go_to(npc, target)


func _npc_go_to(npc: Node3D, target: Vector3) -> void:
	if npc.has_method("walk_to"):
		npc.call("walk_to", target)
		return

	var agent: Node = npc.find_child("Agent", true, false)
	if agent == null:
		agent = npc.find_child("NavigationAgent3D", true, false)
	if agent and agent is NavigationAgent3D:
		(agent as NavigationAgent3D).target_position = target
		return

	# Tween fallback — kills any in-progress tween to avoid stacking
	if npc.has_meta("dock_tween"):
		var old = npc.get_meta("dock_tween")
		if old is Tween and is_instance_valid(old):
			(old as Tween).kill()

	var t := npc.create_tween()
	npc.set_meta("dock_tween", t)

	var role := str(npc.get_meta("dock_role", "Worker"))
	var speed := 2.0
	match role:
		"Fisherman":    speed = 2.6
		"HarborMaster": speed = 2.2
		"NetMender":    speed = 1.4

	var dist: float = npc.global_position.distance_to(target)
	var dur: float = clamp(dist / max(0.1, speed), 0.4, 6.0)

	var dir := target - npc.global_position
	dir.y = 0
	if dir.length() > 0.001:
		npc.rotation.y = atan2(dir.x, dir.z)

	t.tween_property(npc, "global_position", target, dur)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _try_play_anim(npc: Node3D, logical: String) -> void:
	var aps := npc.find_children("*", "AnimationPlayer", true, false)
	if aps.is_empty():
		return
	var ap := aps[0] as AnimationPlayer
	if ap == null:
		return

	var candidates: Dictionary = {
		"idle": ["idle", "Idle", "humanoid/idle", "humanoid/Idle"],
		"walk": ["walk", "Walk", "humanoid/walk", "humanoid/Walk", "run", "Run"],
	}
	var list: Array = candidates.get(logical, [logical])
	for anim_name in list:
		if ap.has_animation(anim_name):
			if ap.current_animation != anim_name:
				ap.play(anim_name)
			return


# ============================================================================
# PHASE 6 — Harbor Interactions
# ============================================================================

var _nordic_interactables: Array = []
var _nordic_interact_cd: Dictionary = {}

func _register_interactable(node: Node3D, kind: String) -> void:
	if node == null or not is_instance_valid(node):
		return
	node.set_meta("interactable_kind", kind)
	node.add_to_group("world_interactables")
	_nordic_interactables.append(node)


func _tick_nordic_interactions() -> void:
	var player := _get_player()
	if player == null:
		return

	var best: Node3D = null
	var best_d2 := 999999.0
	var player_pos: Vector3 = player.global_position

	for n in _nordic_interactables:
		if n == null or not is_instance_valid(n):
			continue
		var d2 := player_pos.distance_squared_to(n.global_position)
		if d2 < best_d2:
			best_d2 = d2
			best = n

	if best == null or best_d2 > (2.6 * 2.6):
		return

	_show_interact_hint(best)

	if Input.is_action_just_pressed("interact"):
		_handle_interaction(best, player)


func _get_player() -> Node3D:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0 and players[0] is Node3D:
		return players[0] as Node3D
	return null


func _show_interact_hint(node: Node3D) -> void:
	var kind := str(node.get_meta("interactable_kind", ""))
	if kind == "":
		return
	var key := "hint|" + str(node.get_instance_id())
	var now := Time.get_ticks_msec() / 1000.0
	if float(_nordic_interact_cd.get(key, 0.0)) > now:
		return
	_nordic_interact_cd[key] = now + 1.25

	var msg := ""
	match kind:
		"fish_rack":       msg = "Press E: Collect fish"
		"inn":             msg = "Press E: Rest at the Inn"
		"boat_travel":     msg = "Press E: Take boat"
		"harbor_master":   msg = "Press E: Talk to Harbor Master"
		"quest_board":     msg = "Press E: View quests"
		"training_dummy":  msg = "Press E: Train (restore HP)"
		"smith_shop":      msg = "Press E: Visit Smith"
		"merchant_shop":   msg = "Press E: Visit Merchant"
		"mayor":           msg = "Press E: Talk to Mayor"
		"innkeeper":       msg = "Press E: Talk to Innkeeper"
		"crafting":        msg = "Press E: Craft items"
		"enter_inn":       msg = "Press E: Enter the Inn"
		"enter_shop":      msg = "Press E: Enter the Shop"
		"enter_smith":     msg = "Press E: Enter the Smithy"
		"exit_interior":   msg = "Press E: Exit"
		"inn_bed":         msg = "Press E: Rest & Save"
		_:                 msg = "Press E: Interact"
	_try_toast(msg)


func _handle_interaction(node: Node3D, player: Node3D) -> void:
	var kind := str(node.get_meta("interactable_kind", ""))
	if kind == "":
		return

	var now := Time.get_ticks_msec() / 1000.0
	var cd_key := "use|" + str(node.get_instance_id())
	if now < float(_nordic_interact_cd.get(cd_key, 0.0)):
		_try_toast("Not ready yet…")
		return

	match kind:
		"fish_rack":
			_nordic_interact_cd[cd_key] = now + nordic_fish_cooldown_sec
			_collect_fish(player)
		"inn":
			_nordic_interact_cd[cd_key] = now + 2.0
			_rest_at_inn(player)
		"boat_travel":
			_nordic_interact_cd[cd_key] = now + 2.0
			_boat_travel(player)
			_tutorial_on_event("boat")
		"harbor_master":
			_nordic_interact_cd[cd_key] = now + 0.5
			_harbor_master_turnin(player)
			_tutorial_on_event("harbor_master")
		"mayor":
			_nordic_interact_cd[cd_key] = now + 0.5
			_mayor_talk(player)
		"innkeeper":
			_nordic_interact_cd[cd_key] = now + 0.5
			_innkeeper_talk(player)
		"quest_board":
			_nordic_interact_cd[cd_key] = now + 0.5
			_show_quest_board_ui(player)
			_tutorial_on_event("board")
		"training_dummy":
			_nordic_interact_cd[cd_key] = now + 1.5  # short cooldown — feels like repeated hits
			_interact_training_dummy(player)
			_tutorial_on_event("dummy_hit")
		"smith_shop":
			_nordic_interact_cd[cd_key] = now + 1.0
			_show_shop_ui(player, "smith")
			_tutorial_on_event("smith")
		"merchant_shop":
			_nordic_interact_cd[cd_key] = now + 1.0
			_show_shop_ui(player, "merchant")
		"crafting":
			_nordic_interact_cd[cd_key] = now + 0.5
			_show_crafting_ui(player)
		"enter_inn":
			_nordic_interact_cd[cd_key] = now + 1.0
			_enter_interior(player, "inn")
		"enter_shop":
			_nordic_interact_cd[cd_key] = now + 1.0
			_enter_interior(player, "shop")
		"enter_smith":
			_nordic_interact_cd[cd_key] = now + 1.0
			_enter_interior(player, "smith")
		"exit_interior":
			_nordic_interact_cd[cd_key] = now + 1.0
			_exit_interior(player)
		"inn_bed":
			_nordic_interact_cd[cd_key] = now + 2.0
			_inn_rest_and_save(player)
			_tutorial_on_event("rest")
		_:
			_try_toast("Nothing happens.")


func _collect_fish(player: Node3D) -> void:
	var did_item: bool = false
	var inv = player.get("inventory") if "inventory" in player else null
	if inv and inv.has_method("add_item"):
		inv.add_item(nordic_fish_item_id, nordic_fish_item_qty)
		did_item = true

	if did_item:
		_try_toast("+%d %s" % [nordic_fish_item_qty, nordic_fish_item_id])
	else:
		if "gold" in player:
			player.gold += nordic_fish_gold_reward
			if player.has_signal("stats_changed"):
				player.stats_changed.emit()
		_try_toast("+%d gold (fish sale)" % nordic_fish_gold_reward)

	_call_world_sfx("pickup")


func _rest_at_inn(player: Node3D) -> void:
	if "hp" in player and "max_hp" in player:
		player.hp = player.max_hp
	if "mp" in player and "max_mp" in player:
		player.mp = player.max_mp
	if player.has_signal("stats_changed"):
		player.stats_changed.emit()
	_try_toast("Rested. Fully healed.")
	_call_world_sfx("rest")
	get_tree().call_group("world", "save_game")


func _boat_travel(player: Node3D) -> void:
	# Phase 21 — tutorial gate: boat is locked until step 4 (after smith visit)
	if tutorial_gating_enabled and tutorial_enabled and not _tutorial_done:
		if _tutorial_step < 4:
			match _tutorial_step:
				0: _try_toast("The dockhand shrugs: \"Check the Notice Board first, traveller.\"")
				1: _try_toast("Dockhand: \"Prove yourself on the training dummy before I let you board.\"")
				2: _try_toast("Dockhand: \"You look tired. Rest at the Inn, then come back.\"")
				3: _try_toast("Dockhand: \"Get your gear sorted at the Smith first.\"")
			return
	if boat_ui_enabled:
		_show_boat_travel_ui(player)
	else:
		player.global_position = boat_dest_briarwood + Vector3(0, 0.02, 0)
		_try_toast("Boat ride… Briarwood!")
		_call_world_sfx("boat")


func _harbor_master_talk(player: Node3D) -> void:
	var inv = player.get("inventory") if "inventory" in player else null
	var has_fish: bool = inv != null and inv.has_method("count_item") \
					and inv.count_item(nordic_fish_item_id) > 0

	if has_fish and inv and inv.has_method("consume_item"):
		inv.consume_item(nordic_fish_item_id, 1)
		if "gold" in player:
			player.gold += 15
			if player.has_signal("stats_changed"):
				player.stats_changed.emit()
		_try_toast("Harbor Master: Fine catch. Here's 15 gold.")
		_call_world_sfx("quest_complete")
	else:
		_try_toast("Harbor Master: Bring me a fish from the racks.")
		_call_world_sfx("dialog")


func _try_toast(msg: String) -> void:
	if get_tree():
		get_tree().call_group("world", "_show_toast", msg)
	print("[Nordic] " + msg)


func _call_world_sfx(sfx_name: String) -> void:
	get_tree().call_group("world", "play_sfx", sfx_name)


# ============================================================================
# PHASE 7 — Boat Travel UI
# ============================================================================

var _boat_ui_layer: CanvasLayer = null
var _boat_ui_panel: Panel = null
var _boat_ui_player: Node3D = null


func _ensure_boat_ui() -> void:
	if _boat_ui_layer and is_instance_valid(_boat_ui_layer):
		return

	_boat_ui_layer = CanvasLayer.new()
	_boat_ui_layer.name = "BoatTravelUI"
	add_child(_boat_ui_layer)

	_boat_ui_panel = Panel.new()
	_boat_ui_panel.name = "Panel"
	_boat_ui_panel.visible = false
	_boat_ui_panel.size = Vector2(520, 260)
	_boat_ui_panel.position = (get_viewport().get_visible_rect().size * 0.5) \
								- (_boat_ui_panel.size * 0.5)
	_boat_ui_layer.add_child(_boat_ui_panel)

	var root := VBoxContainer.new()
	root.name = "Root"
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.offset_left = 18
	root.offset_top = 18
	root.offset_right = -18
	root.offset_bottom = -18
	_boat_ui_panel.add_child(root)

	var title := Label.new()
	title.text = "Choose Destination"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	root.add_child(title)

	root.add_child(_ui_spacer(10))

	# Dynamic destination buttons — built from BOAT_DESTS table (Phase 8)
	for d in BOAT_DESTS:
		var dest_id := str(d.get("id", ""))
		if dest_id == "":
			continue
		var dest_name := str(d.get("name", dest_id))
		var cost      := int(d.get("cost", 0))
		var requires  := bool(d.get("requires_discovery", false))
		var unlocked  := not requires or bool(_discovered_places.get(dest_id, false))

		var btn := Button.new()
		btn.text     = dest_name + ("  —  %d gold" % cost if cost > 0 else "")
		btn.disabled = not unlocked
		btn.pressed.connect(func(did := dest_id): _boat_ui_go(did))
		root.add_child(btn)

		if not unlocked:
			var hint := Label.new()
			hint.text     = "Locked — discover this place first."
			hint.modulate = Color(0.8, 0.8, 0.8)
			root.add_child(hint)

	root.add_child(_ui_spacer(8))

	var btn_cancel := Button.new()
	btn_cancel.text = "Cancel"
	btn_cancel.pressed.connect(func(): _hide_boat_travel_ui())
	root.add_child(btn_cancel)

	_boat_ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS


func _ui_spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _show_boat_travel_ui(player: Node3D) -> void:
	_ensure_boat_ui()
	_boat_ui_player = player
	_boat_ui_panel.visible = true

	if _boat_ui_player and _boat_ui_player.has_method("set_cinematic_lock"):
		_boat_ui_player.call("set_cinematic_lock", true)

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_try_toast("Boat ready.")


func _hide_boat_travel_ui() -> void:
	if _boat_ui_panel and is_instance_valid(_boat_ui_panel):
		_boat_ui_panel.visible = false

	if _boat_ui_player and is_instance_valid(_boat_ui_player):
		if _boat_ui_player.has_method("set_cinematic_lock"):
			_boat_ui_player.call("set_cinematic_lock", false)

	_boat_ui_player = null
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _boat_ui_go(dest_id: String) -> void:
	if _boat_ui_player == null or not is_instance_valid(_boat_ui_player):
		_hide_boat_travel_ui()
		return

	# Look up in BOAT_DESTS table (Phase 8)
	var dest := {}
	for d in BOAT_DESTS:
		if str(d.get("id", "")) == dest_id:
			dest = d
			break
	if dest.is_empty():
		_try_toast("Unknown destination.")
		_hide_boat_travel_ui()
		return

	# Unlock gate
	var requires := bool(dest.get("requires_discovery", false))
	if requires and not bool(_discovered_places.get(dest_id, false)):
		_try_toast("Locked — discover it first.")
		return

	# Cost gate
	var cost := int(dest.get("cost", 0))
	if cost > 0 and ("gold" in _boat_ui_player):
		if int(_boat_ui_player.gold) < cost:
			_try_toast("Need %d gold." % cost)
			return
		_boat_ui_player.gold -= cost
		if _boat_ui_player.has_signal("stats_changed"):
			_boat_ui_player.stats_changed.emit()

	var target: Vector3 = Vector3(dest.get("pos", Vector3.ZERO))
	var label  := str(dest.get("name", dest_id))

	# Lock player movement while traveling
	if _boat_ui_player.has_method("set_cinematic_lock"):
		_boat_ui_player.call("set_cinematic_lock", true)

	# Force-load destination district if streaming is on (Phase 9/10)
	_ensure_destination_loaded(dest_id)
	var district_id := _district_id_for_destination(dest_id)
	if district_streaming_enabled and district_id != "":
		_try_toast("Preparing route…")
		var max_frames := 90  # ~1.5 s at 60 fps
		while max_frames > 0 and not _is_district_loaded(district_id):
			await get_tree().process_frame
			max_frames -= 1

	# Close UI before teleport so it doesn't flash on arrival
	_hide_boat_travel_ui()

	_teleport_player_to(target, _boat_ui_player)
	_call_world_sfx("boat")
	_try_toast("Boat ride… %s!" % label)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var ke := event as InputEventKey
	if not ke.pressed or ke.echo:
		return
	if ke.keycode != KEY_ESCAPE:
		return

	# Dialog UI (highest priority — story beats can override anything)
	if _dlg_panel != null and is_instance_valid(_dlg_panel) and _dlg_panel.visible:
		_hide_dialog()
		get_viewport().set_input_as_handled()
		return

	# Quest board takes priority (closes first if open)
	if _qb_panel != null and is_instance_valid(_qb_panel) and _qb_panel.visible:
		_hide_quest_board_ui()
		get_viewport().set_input_as_handled()
		return

	# Shop UI
	if _shop_panel != null and is_instance_valid(_shop_panel) and _shop_panel.visible:
		_hide_shop_ui()
		get_viewport().set_input_as_handled()
		return

	# Crafting UI
	if _craft_panel != null and is_instance_valid(_craft_panel) and _craft_panel.visible:
		_hide_crafting_ui()
		get_viewport().set_input_as_handled()
		return

	# Boat UI
	if _boat_ui_panel != null and is_instance_valid(_boat_ui_panel) and _boat_ui_panel.visible:
		_hide_boat_travel_ui()
		get_viewport().set_input_as_handled()

# ============================================================================
# PHASE 8 — Discovery system
# ============================================================================

func discover_place(id: String) -> void:
	_discovered_places[id] = true
	_try_toast("Discovered: %s" % id)
	# Wire into your save system here if you have one:
	# GameBrain.set_flag("discovered_" + id, true)

# ============================================================================
# PHASE 9 — District streaming
# ============================================================================

func _init_district_streaming() -> void:
	if _district_timer and is_instance_valid(_district_timer):
		_district_timer.queue_free()

	_district_timer = Timer.new()
	_district_timer.name = "DistrictStreamingTick"
	_district_timer.wait_time = max(0.2, nordic_stream_tick)
	_district_timer.one_shot = false
	_district_timer.autostart = true
	_district_timer.timeout.connect(_tick_district_streaming)
	add_child(_district_timer)

	_tick_district_streaming()


func _tick_district_streaming() -> void:
	if not district_streaming_enabled:
		return
	var player := _get_player_for_streaming()
	if player == null:
		return

	var d: float = player.global_position.distance_to(NORDIC_ORIGIN)
	if d <= nordic_stream_load_dist:
		_ensure_district_loaded("nordic")
	elif d >= nordic_stream_unload_dist:
		_try_unload_district("nordic")


func _get_player_for_streaming() -> Node3D:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0 and players[0] is Node3D:
		return players[0] as Node3D
	return null


func _ensure_district_loaded(id: String) -> void:
	if _district_roots.has(id) and is_instance_valid(_district_roots[id]):
		return
	if bool(_district_building.get(id, false)):
		return
	_district_building[id] = true
	match id:
		"nordic":
			_safe_call("_build_nordic_streamed")
		_:
			_district_building[id] = false


func _build_nordic_streamed() -> void:
	# Creates a district root so all Nordic nodes can be freed as a group.
	# IMPORTANT: to make unloading work, Nordic build functions must call
	# _add_to_build_root() instead of add_child() for their top-level nodes.
	# Until that refactor is done, nodes go to WorldBuilder root as usual,
	# but the streaming load/build trigger still works correctly.
	var root := Node3D.new()
	root.name = "District_Nordic"
	add_child(root)
	_set_build_root(root)

	_build_nordic_fishing_village()
	_build_nordic_road()
	if has_method("_build_nordic_ambient_audio"):
		_build_nordic_ambient_audio()
	if nordic_dock_life_enabled and has_method("_build_nordic_dock_life"):
		_build_nordic_dock_life()

	_clear_build_root()
	_district_roots["nordic"] = root
	_district_building["nordic"] = false


func _set_build_root(n: Node) -> void:
	_build_root_override = n

func _clear_build_root() -> void:
	_build_root_override = null

# Use this instead of add_child() for top-level district nodes in build functions.
# While _build_root_override is set (during a streamed build), nodes go under the
# district root so the whole district can be freed with one queue_free().
func _add_to_build_root(n: Node) -> void:
	if _build_root_override and is_instance_valid(_build_root_override):
		_build_root_override.add_child(n)
	else:
		add_child(n)


func _try_unload_district(id: String) -> void:
	if not _district_roots.has(id):
		return
	var root: Node3D = _district_roots.get(id)
	if root == null or not is_instance_valid(root):
		_district_roots.erase(id)
		return

	# Never unload if player is still inside the district radius
	var player := _get_player_for_streaming()
	if player:
		var anchor := NORDIC_ORIGIN if id == "nordic" else root.global_position
		if player.global_position.distance_to(anchor) < nordic_stream_load_dist * 0.75:
			return

	root.queue_free()
	_district_roots.erase(id)

# ============================================================================
# PHASE 10 — Stream-safe travel helpers
# ============================================================================

func _district_id_for_destination(dest_id: String) -> String:
	match dest_id:
		"nordic":    return "nordic"
		"briarwood": return ""  # always loaded
		_:           return ""


func _is_district_loaded(id: String) -> bool:
	if id == "":
		return true
	return _district_roots.has(id) and is_instance_valid(_district_roots[id])


func _ensure_destination_loaded(dest_id: String) -> void:
	if not district_streaming_enabled:
		return
	var did := _district_id_for_destination(dest_id)
	if did != "":
		_ensure_district_loaded(did)


func _teleport_player_to(target: Vector3, player: Node3D) -> void:
	if player == null or not is_instance_valid(player):
		return
	player.global_position = target + Vector3(0, 0.02, 0)
	if player.has_method("set_cinematic_lock"):
		player.call("set_cinematic_lock", false)

# ============================================================================
# BRIARWOOD HUB BUILDER v1
# ============================================================================

func _build_briarwood_hub() -> void:
	if _briarwood_root and is_instance_valid(_briarwood_root):
		_briarwood_root.queue_free()

	_briarwood_root = Node3D.new()
	_briarwood_root.name = "BriarwoodHub"
	_briarwood_root.global_position = briarwood_origin
	add_child(_briarwood_root)

	var plaza    := briarwood_origin + bw_plaza_offset
	var gate     := briarwood_origin + bw_gate_offset
	var market   := briarwood_origin + bw_market_offset
	var craft    := briarwood_origin + bw_craft_offset
	var shrine   := briarwood_origin + bw_shrine_offset
	var townhall := briarwood_origin + bw_townhall_offset

	var civic := _build_bw_civic_core(_briarwood_root, plaza, townhall, shrine)
	_build_bw_market_street(_briarwood_root, market, plaza)
	_build_bw_craft_row(_briarwood_root, craft, plaza)
	# Phase 24: real layout replaces the simple ring
	if bw_real_village_enabled:
		_build_bw_real_layout(_briarwood_root, plaza, gate, market, craft, townhall)
	else:
		_build_bw_residential_ring(_briarwood_root, plaza, bw_house_count)
	_build_bw_edge_read(_briarwood_root, plaza)
	_spawn_bw_npcs(_briarwood_root, plaza, market, craft, gate)
	_register_bw_interactions(civic, plaza, market, craft)
	_spawn_briarwood_quest_givers(_briarwood_root, townhall, market, craft)
	_safe_call("_build_briarwood_life")
	if briarwood_atmosphere_enabled:
		_build_briarwood_atmosphere(_briarwood_root, plaza, market, craft, gate, townhall)
	if bw_dressing_enabled:
		_dress_briarwood_v2(_briarwood_root, plaza, market, craft, gate)
	if bw_multimesh_enabled:
		_mm_finalize()

	_dlog("Briarwood Hub built — %d children" % _briarwood_root.get_child_count())


# ── Civic core ────────────────────────────────────────────────────────────────

func _build_bw_civic_core(root: Node3D, plaza: Vector3, townhall: Vector3, shrine: Vector3) -> Dictionary:
	var out := {}

	# Well — landmark at plaza centre
	var well := MeshInstance3D.new()
	well.name = "PlazaWell"
	var wm := CylinderMesh.new()
	wm.top_radius    = 1.2
	wm.bottom_radius = 1.35
	wm.height        = 0.9
	well.mesh = wm
	well.material_override = MAT_STONE(2.0)
	well.global_position = plaza + Vector3(0, 0.45, 0)
	root.add_child(well)
	out["well"] = well

	# Quest board
	var board: Node3D = _make_bw_quest_board(plaza + Vector3(2.6, 0, -1.2))
	root.add_child(board)
	out["quest_board"] = board

	# Town hall
	var hall := _make_bw_townhall(townhall)
	root.add_child(hall)
	out["townhall"] = hall

	# Shrine
	var sh := _make_bw_shrine(shrine)
	root.add_child(sh)
	out["shrine"] = sh

	# Lantern ring (10 posts around plaza)
	for i in range(10):
		var ang := TAU * float(i) / 10.0
		var p: Vector3 = plaza + Vector3(cos(ang), 0, sin(ang)) * 10.0
		root.add_child(_make_bw_lantern_post(p))

	return out


# ============================================================================
# Phase 23 — Briarwood Style Kit (timber + stone + warm windows)
# ============================================================================

func _bw_mat_stone() -> StandardMaterial3D:
	return MAT_STONE(1.0)

func _bw_mat_timber() -> StandardMaterial3D:
	# Plaster wall infill between dark-wood timbers — half-timbered "Tudor" look
	return MAT_PLASTER(2.0)

func _bw_mat_darkwood() -> StandardMaterial3D:
	return MAT_DARK_WOOD(0.72)

func _bw_mat_roof() -> StandardMaterial3D:
	return MAT_ROOF(1.8)

func _bw_window_material(energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color            = Color(1.0, 0.88, 0.60, 0.90)
	mat.emission_enabled        = true
	mat.emission                = Color(1.0, 0.75, 0.45)
	mat.emission_energy_multiplier = energy
	mat.transparency            = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat

func _bw_add_warm_window(parent: Node3D, local_pos: Vector3, side_sign: float, energy: float) -> void:
	var win := Node3D.new()
	win.name = "Window"
	win.position = local_pos
	parent.add_child(win)

	var frame := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(0.08, 0.62, 0.92)
	frame.mesh = fm
	frame.material_override = _bw_mat_darkwood()
	win.add_child(frame)

	var glass := MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(0.03, 0.52, 0.80)
	glass.mesh = gm
	glass.name = "WindowGlass"
	glass.position = Vector3(side_sign * 0.04, 0.0, 0.0)
	glass.material_override = _bw_window_material(energy)
	win.add_child(glass)

func _bw_gable_roof(w: float, d: float, base_y: float, pitch_deg: float, overhang: float) -> Node3D:
	var n := Node3D.new()
	n.name = "BWRoof"
	n.position.y = base_y

	var pitch    := deg_to_rad(pitch_deg)
	var roof_mat := _bw_mat_roof()
	var half     := (w * 0.5 + overhang)
	var plen     := (d + overhang * 2.0)

	for sx in [-1.0, 1.0]:
		var plane := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(half, 0.18, plen)
		plane.mesh = bm
		plane.material_override = roof_mat
		plane.position = Vector3(sx * half * 0.5, 0.0, 0.0)
		plane.rotation.z = sx * pitch
		n.add_child(plane)

	var ridge := MeshInstance3D.new()
	var rb := BoxMesh.new()
	rb.size = Vector3(0.18, 0.18, plen)
	ridge.mesh = rb
	ridge.material_override = _bw_mat_darkwood()
	ridge.position = Vector3(0.0, 0.55, 0.0)
	n.add_child(ridge)

	return n

func _bw_add_timber_frame(parent: Node3D, w: float, d: float, wall_h: float, base_y: float) -> void:
	var beam_mat := _bw_mat_darkwood()
	# Corner posts
	for sx in [-w * 0.40, w * 0.40]:
		for sz in [-d * 0.40, d * 0.40]:
			var post := MeshInstance3D.new()
			var pm := BoxMesh.new()
			pm.size = Vector3(0.16, wall_h, 0.16)
			post.mesh = pm
			post.position = Vector3(sx, base_y + wall_h * 0.5, sz)
			post.material_override = beam_mat
			parent.add_child(post)

	# Horizontal mid-bands front and back
	var band_mesh := BoxMesh.new()
	band_mesh.size = Vector3(w * 0.92, 0.14, 0.14)
	for z in [-d * 0.40, d * 0.40]:
		var band := MeshInstance3D.new()
		band.mesh = band_mesh
		band.position = Vector3(0.0, base_y + 1.5, z)
		band.material_override = beam_mat
		parent.add_child(band)

func _bw_add_chimney(parent: Node3D, local_pos: Vector3, height: float) -> void:
	if not bw_chimney_enabled:
		return
	var chim := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius    = 0.35
	cm.bottom_radius = 0.45
	cm.height        = height
	chim.mesh = cm
	chim.position = local_pos + Vector3(0.0, height * 0.5, 0.0)
	chim.material_override = _bw_mat_stone()
	parent.add_child(chim)

func _bw_add_signboard(parent: Node3D, local_pos: Vector3, text: String) -> void:
	var sign := Node3D.new()
	sign.name = "SignBoard"
	sign.position = local_pos
	parent.add_child(sign)

	var board := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.9, 0.55, 0.08)
	board.mesh = bm
	board.material_override = _bw_mat_darkwood()
	board.position = Vector3(0.0, 2.2, 0.0)
	sign.add_child(board)

	var label := Label3D.new()
	label.text            = text
	label.billboard       = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test   = true
	label.pixel_size      = 0.0034
	label.font_size       = 34
	label.outline_size    = 8
	label.outline_modulate = Color(0, 0, 0, 1)
	label.modulate        = Color(1.0, 0.88, 0.55)
	label.position        = Vector3(0.0, 2.2, 0.06)
	sign.add_child(label)


# ============================================================================
# Phase 23 — Briarwood landmark builders
# ============================================================================

func _make_bw_townhall(pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = "TownHall"
	n.global_position = pos

	const W      := 10.0
	const D      := 20.0
	const WALL_H := 4.2
	const BASE_H := 0.7

	# Stone foundation
	var base := MeshInstance3D.new()
	var bsm := BoxMesh.new()
	bsm.size = Vector3(W, BASE_H, D)
	base.mesh = bsm
	base.position.y = BASE_H * 0.5
	base.material_override = _bw_mat_stone()
	n.add_child(base)

	# Plaster walls
	var walls := MeshInstance3D.new()
	var wm := BoxMesh.new()
	wm.size = Vector3(W * 0.92, WALL_H, D * 0.92)
	walls.mesh = wm
	walls.position.y = BASE_H + WALL_H * 0.5
	walls.material_override = _bw_mat_timber()
	n.add_child(walls)

	# Timber frame
	_bw_add_timber_frame(n, W, D, WALL_H, BASE_H)

	# Gable roof
	var pitch: float = randf_range(bw_roof_pitch_min, bw_roof_pitch_max)
	n.add_child(_bw_gable_roof(W * 1.08, D * 1.05, BASE_H + WALL_H + 0.25, pitch, bw_roof_overhang))

	# Collision
	var body := StaticBody3D.new()
	var col  := CollisionShape3D.new()
	var box  := BoxShape3D.new()
	box.size = Vector3(W, BASE_H + WALL_H + 3.6, D)
	col.shape = box
	col.position.y = box.size.y * 0.5
	body.add_child(col)
	n.add_child(body)

	# Entrance steps
	var steps := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(4.6, 0.35, 2.4)
	steps.mesh = sm
	steps.position = Vector3(0.0, 0.18, D * 0.52)
	steps.material_override = _bw_mat_stone()
	n.add_child(steps)

	# Flag pole
	var pole := MeshInstance3D.new()
	var pcm := CylinderMesh.new()
	pcm.top_radius    = 0.06
	pcm.bottom_radius = 0.08
	pcm.height        = 6.2
	pole.mesh = pcm
	pole.material_override = _bw_mat_darkwood()
	pole.position = Vector3(-W * 0.32, BASE_H + WALL_H - 0.4, D * 0.40)
	n.add_child(pole)

	# Warm windows (4 side windows + 2 front gable)
	_bw_add_warm_window(n, Vector3( W * 0.44, BASE_H + 1.9, -3.0),  1.0, bw_window_energy_day)
	_bw_add_warm_window(n, Vector3( W * 0.44, BASE_H + 1.9,  3.0),  1.0, bw_window_energy_day)
	_bw_add_warm_window(n, Vector3(-W * 0.44, BASE_H + 1.9, -3.0), -1.0, bw_window_energy_day)
	_bw_add_warm_window(n, Vector3(-W * 0.44, BASE_H + 1.9,  3.0), -1.0, bw_window_energy_day)

	# Signboard + chimney
	_bw_add_signboard(n, Vector3(0.0, 0.0, D * 0.52 + 0.3), "TOWN HALL")
	_bw_add_chimney(n, Vector3(W * 0.28, BASE_H + WALL_H + 0.2, -D * 0.10), 6.2)

	return n


func _make_bw_shrine(pos: Vector3) -> Node3D:
	var shrine := Node3D.new()
	shrine.name = "Shrine"
	shrine.global_position = pos

	var base := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(4.0, 0.6, 4.0)
	base.mesh = bm
	base.material_override = MAT_STONE(2.0)
	base.position.y = 0.3
	shrine.add_child(base)

	var pillar := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius    = 0.35
	cm.bottom_radius = 0.45
	cm.height        = 4.2
	pillar.mesh = cm
	pillar.material_override = MAT_STONE(1.0)
	pillar.position.y = 0.6 + 2.1
	shrine.add_child(pillar)

	# Emissive top sphere — "spirit light"
	var orb := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.38
	sm.height = 0.76
	orb.mesh = sm
	var orb_mat := StandardMaterial3D.new()
	orb_mat.albedo_color = Color(0.6, 0.85, 1.0)
	orb_mat.emission_enabled = true
	orb_mat.emission = Color(0.5, 0.8, 1.0)
	orb_mat.emission_energy_multiplier = 1.4
	orb.material_override = orb_mat
	orb.position.y = 0.6 + 4.2 + 0.38
	shrine.add_child(orb)

	return shrine


func _make_bw_quest_board(pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = "QuestBoard"
	n.global_position = pos

	var post := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius    = 0.10
	cm.bottom_radius = 0.12
	cm.height        = 2.2
	post.mesh = cm
	post.material_override = MAT_DARK_WOOD(0.5)
	post.position.y = 1.1
	n.add_child(post)

	var board := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2.2, 1.2, 0.12)
	board.mesh = bm
	board.material_override = MAT_DARK_WOOD(1.5)
	board.position = Vector3(0, 1.6, 0.06)
	n.add_child(board)

	# Warm notice-light
	var light := OmniLight3D.new()
	light.light_color  = Color(1.0, 0.85, 0.55)
	light.light_energy = 0.8
	light.omni_range   = 5.0
	light.position     = Vector3(0, 2.4, 0.3)
	n.add_child(light)

	return n


func _make_bw_lantern_post(pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.add_to_group("lanterns")

	var shaft := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius    = 0.05
	cm.bottom_radius = 0.07
	cm.height        = 3.0
	shaft.mesh = cm
	shaft.material_override = MAT_DARK_WOOD(0.5)
	shaft.position.y = 1.5
	n.add_child(shaft)

	var globe := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.22
	sm.height = 0.44
	globe.mesh = sm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(1.0, 0.9, 0.6)
	gm.emission_enabled = true
	gm.emission = Color(1.0, 0.75, 0.3)
	gm.emission_energy_multiplier = 1.0
	globe.material_override = gm
	globe.position.y = 3.1
	n.add_child(globe)

	var light := OmniLight3D.new()
	light.name = "OmniLight3D"
	light.light_color  = Color(1.0, 0.78, 0.40)
	light.light_energy = 1.4
	light.omni_range   = 10.0
	light.position.y   = 3.1
	n.add_child(light)

	n.global_position = pos
	return n


# ── Market street ─────────────────────────────────────────────────────────────

func _build_bw_market_street(root: Node3D, market: Vector3, plaza: Vector3) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234

	var dir: Vector3 = (plaza - market); dir.y = 0.0; dir = dir.normalized()
	var side: Vector3 = dir.rotated(Vector3.UP, PI * 0.5)

	# Inn frontage anchor — styled inn replaces the generic house
	var inn_bldg := _make_bw_inn(market + dir * -6.0, -dir)
	root.add_child(inn_bldg)

	# Stall row
	for i in range(bw_market_stall_count):
		var t  := float(i) - float(bw_market_stall_count) * 0.5
		var p: Vector3 = market + side * (t * 3.2) + dir * rng.randf_range(-1.5, 1.5)
		root.add_child(_make_bw_stall(p, -dir))

	# Clutter scatter
	var clutter_n := int(40.0 * bw_prop_density)
	for i in range(clutter_n):
		var p: Vector3 = market + side * rng.randf_range(-18.0, 18.0) \
					+ dir * rng.randf_range(-7.0, 10.0)
		root.add_child(_make_bw_clutter(p, rng))

	# Market lanterns on a line
	for i in range(6):
		var t := float(i) - 2.5
		var p := market + side * (t * 4.0)
		root.add_child(_make_bw_lantern_post(p))


func _make_bw_inn(pos: Vector3, facing: Vector3 = Vector3(0, 0, -1)) -> Node3D:
	var n := Node3D.new()
	n.name = "Inn"
	n.global_position = pos
	n.rotation.y = atan2(facing.x, facing.z)

	const W      := 11.0
	const D      := 16.0
	const WALL_H := 4.0
	const BASE_H := 0.7

	var base := MeshInstance3D.new()
	var bsm := BoxMesh.new()
	bsm.size = Vector3(W, BASE_H, D)
	base.mesh = bsm
	base.position.y = BASE_H * 0.5
	base.material_override = _bw_mat_stone()
	n.add_child(base)

	var walls := MeshInstance3D.new()
	var wm := BoxMesh.new()
	wm.size = Vector3(W * 0.92, WALL_H, D * 0.92)
	walls.mesh = wm
	walls.position.y = BASE_H + WALL_H * 0.5
	walls.material_override = _bw_mat_timber()
	n.add_child(walls)

	_bw_add_timber_frame(n, W, D, WALL_H, BASE_H)

	var pitch: float = randf_range(bw_roof_pitch_min, bw_roof_pitch_max)
	n.add_child(_bw_gable_roof(W * 1.12, D * 1.08, BASE_H + WALL_H + 0.25, pitch, bw_roof_overhang))

	# Collision
	var body := StaticBody3D.new()
	var col  := CollisionShape3D.new()
	var box  := BoxShape3D.new()
	box.size = Vector3(W, BASE_H + WALL_H + 3.6, D)
	col.shape = box
	col.position.y = box.size.y * 0.5
	body.add_child(col)
	n.add_child(body)

	# Porch
	if bw_porch_enabled:
		var porch := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(6.0, 0.22, 2.4)
		porch.mesh = pm
		porch.position = Vector3(0.0, BASE_H + 0.11, D * 0.52)
		porch.material_override = _bw_mat_darkwood()
		n.add_child(porch)

	# Signboard + chimney
	_bw_add_signboard(n, Vector3(0.0, 0.0, D * 0.52 + 0.2), "THE OAK & ALE")
	_bw_add_chimney(n, Vector3(W * 0.30, BASE_H + WALL_H + 0.2, -D * 0.15), 6.0)

	# Warm windows (3 per long side)
	for wz in [-4.0, 0.0, 4.0]:
		_bw_add_warm_window(n, Vector3( W * 0.44, BASE_H + 1.8, wz),  1.0, bw_window_energy_day)
		_bw_add_warm_window(n, Vector3(-W * 0.44, BASE_H + 1.8, wz), -1.0, bw_window_energy_day)

	return n


func _make_bw_stall(pos: Vector3, facing: Vector3) -> Node3D:
	var stall := Node3D.new()
	stall.global_position = pos
	stall.rotation.y = atan2(facing.x, facing.z)

	var counter := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.8, 0.8, 0.8)
	counter.mesh = bm
	counter.material_override = MAT_DARK_WOOD(1.5)
	counter.position.y = 0.4
	stall.add_child(counter)

	for dx in [-0.8, 0.8]:
		var post := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius    = 0.05
		pm.bottom_radius = 0.05
		pm.height        = 1.6
		post.mesh = pm
		post.material_override = MAT_DARK_WOOD(0.5)
		post.position = Vector3(dx, 1.2, -0.3)
		stall.add_child(post)

	# Awning with flap animation (same rig as the Briarwood market stalls)
	var awn_pivot := Node3D.new()
	awn_pivot.position = Vector3(0, 1.95, -0.3)
	awn_pivot.set_meta("phase", randf() * TAU)
	awn_pivot.set_meta("base_pitch", 0.4)
	awn_pivot.add_to_group("stall_awnings")
	stall.add_child(awn_pivot)

	var awn_mat := StandardMaterial3D.new()
	awn_mat.albedo_color = Color(0.62, 0.18, 0.14)
	awn_mat.roughness    = 0.7
	awn_mat.cull_mode    = BaseMaterial3D.CULL_DISABLED
	var awn := MeshInstance3D.new()
	var am := BoxMesh.new()
	am.size = Vector3(2.2, 0.05, 1.2)
	awn.mesh = am
	awn.material_override = awn_mat
	awn.position = Vector3(0, 0.05, 0.4)
	awn_pivot.add_child(awn)

	return stall


# ── Craft row ─────────────────────────────────────────────────────────────────

func _build_bw_craft_row(root: Node3D, craft: Vector3, plaza: Vector3) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5678

	var dir: Vector3 = (plaza - craft); dir.y = 0.0; dir = dir.normalized()
	var side: Vector3 = dir.rotated(Vector3.UP, PI * 0.5)

	# Smith building — styled smithy replaces the generic house + standalone chimney
	var smithy := _make_bw_smithy(craft, -dir)
	root.add_child(smithy)

	# Chimney smoke light (warm glow above smithy chimney)
	var smoke_light := OmniLight3D.new()
	smoke_light.light_color  = Color(1.0, 0.55, 0.2)
	smoke_light.light_energy = 1.2
	smoke_light.omni_range   = 8.0
	smoke_light.global_position = craft + Vector3(2.2, 8.0, -1.6)
	root.add_child(smoke_light)

	# Two more buildings along craft row
	root.add_child(_make_bw_house(craft + side * 9.0))
	root.add_child(_make_bw_house(craft + side * -9.0))

	# Yard clutter (log piles + barrels)
	var yard_n := int(40.0 * bw_prop_density)
	for i in range(yard_n):
		var p: Vector3 = craft + side * rng.randf_range(-12.0, 12.0) \
					+ dir * rng.randf_range(-5.0, 7.0)
		root.add_child(_make_bw_clutter(p, rng))

	# Fence posts along craft yard front
	for i in range(12):
		var t  := float(i) - 5.5
		var p  := craft + side * (t * 1.8) + dir * 4.5
		var fp := MeshInstance3D.new()
		var fcm := CylinderMesh.new()
		fcm.top_radius    = 0.07
		fcm.bottom_radius = 0.09
		fcm.height        = 1.2
		fp.mesh = fcm
		fp.material_override = MAT_DARK_WOOD(0.5)
		fp.global_position = p + Vector3(0, 0.6, 0)
		root.add_child(fp)


# ── Residential ring ─────────────────────────────────────────────────────────

func _build_bw_residential_ring(root: Node3D, plaza: Vector3, count: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7331

	var ring_r := 28.0
	for i in range(count):
		var ang := (TAU * float(i) / float(maxi(1, count))) \
					+ rng.randf_range(-0.18, 0.18)
		var r: float = rng.randf_range(ring_r * 0.85, ring_r * 1.15)
		var p: Vector3 = plaza + Vector3(cos(ang) * r, 0.0, sin(ang) * r)
		root.add_child(_make_bw_house(p))


# ── Hub house (parented version of _make_building, sized 7×6m) ───────────────

func _make_bw_house(pos: Vector3) -> Node3D:
	var house := Node3D.new()
	house.add_to_group("buildings")
	house.global_position = pos

	# Slight random yaw so the ring doesn't look drilled
	house.rotation.y = randf_range(-PI, PI)

	var w := 7.0; var d := 6.0; var wh := 3.2

	# Foundation
	var foundation := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(w, 0.5, d)
	foundation.mesh = fm
	foundation.material_override = MAT_FOUNDATION(2)
	foundation.position.y = 0.25
	house.add_child(foundation)

	# Walls
	var wall := MeshInstance3D.new()
	var wm := BoxMesh.new()
	wm.size = Vector3(w * 0.94, wh, d * 0.94)
	wall.mesh = wm
	wall.material_override = MAT_PLASTER(3)
	wall.position.y = 0.5 + wh * 0.5
	house.add_child(wall)

	# Collision (foundation + walls height)
	var body := StaticBody3D.new()
	var col  := CollisionShape3D.new()
	var box  := BoxShape3D.new()
	box.size = Vector3(w * 0.94, 0.5 + wh, d * 0.94)
	col.shape = box
	col.position.y = (0.5 + wh) * 0.5
	body.add_child(col)
	house.add_child(body)

	# Corner timber beams
	for dx in [-(w * 0.45), w * 0.45]:
		for dz in [-(d * 0.45), d * 0.45]:
			var beam := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.22, wh, 0.22)
			beam.mesh = bm
			beam.material_override = MAT_DARK_WOOD(0.5)
			beam.position = Vector3(dx, 0.5 + wh * 0.5, dz)
			house.add_child(beam)

	# Eave
	var eave := MeshInstance3D.new()
	var em := BoxMesh.new()
	em.size = Vector3(w + 0.3, 0.18, d + 0.3)
	eave.mesh = em
	eave.material_override = MAT_DARK_WOOD(0.5)
	eave.position.y = 0.5 + wh
	house.add_child(eave)

	# Gable roof
	var roof := MeshInstance3D.new()
	var pyr := PrismMesh.new()
	pyr.left_to_right = 0.5
	pyr.size = Vector3(w + 0.4, 2.6, d + 0.4)
	roof.mesh = pyr
	roof.material_override = MAT_ROOF(2.0)
	roof.position.y = 0.5 + wh + 1.3
	house.add_child(roof)

	# Chimney
	var chim := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(0.5, 1.8, 0.5)
	chim.mesh = cm
	chim.material_override = MAT_STONE(1)
	chim.name = "Chimney"
	chim.position = Vector3(w * 0.28, 0.5 + wh + 0.9, d * 0.3)
	house.add_child(chim)

	# Emissive window
	var win_mat := StandardMaterial3D.new()
	win_mat.albedo_color = Color(0.95, 0.6, 0.25)
	win_mat.emission_enabled = true
	win_mat.emission = Color(1.0, 0.7, 0.3)
	win_mat.emission_energy_multiplier = 1.0
	var win := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.85, 0.7)
	win.mesh = qm
	win.material_override = win_mat
	win.position = Vector3(0, 0.5 + wh * 0.72, d * 0.471)
	house.add_child(win)

	# Door
	var door := MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(0.9, 2.1, 0.08)
	door.mesh = dm
	door.material_override = MAT_DARK_WOOD(0.6)
	door.position = Vector3(-w * 0.2, 0.5 + 1.05, d * 0.471)
	house.add_child(door)

	return house


func _make_bw_smithy(pos: Vector3, facing: Vector3 = Vector3(0, 0, -1)) -> Node3D:
	var n := Node3D.new()
	n.name = "Smithy"
	n.global_position = pos
	n.rotation.y = atan2(facing.x, facing.z)

	const W      := 9.0
	const D      := 12.0
	const WALL_H := 3.6
	const BASE_H := 0.6

	var base := MeshInstance3D.new()
	var bsm := BoxMesh.new()
	bsm.size = Vector3(W, BASE_H, D)
	base.mesh = bsm
	base.position.y = BASE_H * 0.5
	base.material_override = _bw_mat_stone()
	n.add_child(base)

	var walls := MeshInstance3D.new()
	var wm := BoxMesh.new()
	wm.size = Vector3(W * 0.92, WALL_H, D * 0.92)
	walls.mesh = wm
	walls.position.y = BASE_H + WALL_H * 0.5
	walls.material_override = _bw_mat_timber()
	n.add_child(walls)

	_bw_add_timber_frame(n, W, D, WALL_H, BASE_H)

	var pitch: float = randf_range(bw_roof_pitch_min, bw_roof_pitch_max)
	n.add_child(_bw_gable_roof(W * 1.10, D * 1.10, BASE_H + WALL_H + 0.25, pitch, bw_roof_overhang))

	# Collision
	var body := StaticBody3D.new()
	var col  := CollisionShape3D.new()
	var box  := BoxShape3D.new()
	box.size = Vector3(W, BASE_H + WALL_H + 3.2, D)
	col.shape = box
	col.position.y = box.size.y * 0.5
	body.add_child(col)
	n.add_child(body)

	# Tall chimney (primary visual read: "this is the smith")
	_bw_add_chimney(n, Vector3(W * 0.25, BASE_H + WALL_H + 0.2, -D * 0.12), 7.2)

	# Signboard + one warm front window
	_bw_add_signboard(n, Vector3(0.0, 0.0, D * 0.52 + 0.2), "BLACKSMITH")
	_bw_add_warm_window(n, Vector3(W * 0.44, BASE_H + 1.7, 0.0), 1.0, bw_window_energy_day)

	return n


# ── Clutter prop (barrel or crate — replaces missing _make_woodpile) ─────────

func _make_bw_clutter(pos: Vector3, rng: RandomNumberGenerator) -> Node3D:
	var n := Node3D.new()
	n.global_position = pos
	n.rotation.y = rng.randf_range(-PI, PI)
	n.add_to_group("village_barrels")

	var mi := MeshInstance3D.new()
	if rng.randf() < 0.55:
		var cm := CylinderMesh.new()
		cm.top_radius    = 0.22
		cm.bottom_radius = 0.25
		cm.height        = rng.randf_range(0.5, 0.82)
		mi.mesh = cm
		mi.material_override = MAT_DARK_WOOD(0.5)
		mi.position.y = cm.height * 0.5
	else:
		var bx := BoxMesh.new()
		bx.size = Vector3(rng.randf_range(0.38, 0.70),
							rng.randf_range(0.28, 0.52),
							rng.randf_range(0.38, 0.70))
		mi.mesh = bx
		mi.material_override = MAT_WOOD(1.0)
		mi.position.y = bx.size.y * 0.5
	n.add_child(mi)
	return n


# ── Palisade edge read ────────────────────────────────────────────────────────

func _build_bw_edge_read(root: Node3D, plaza: Vector3) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var r := 44.0
	var post_count := 70
	for i in range(post_count):
		var ang := TAU * float(i) / float(post_count)
		var p: Vector3 = plaza + Vector3(cos(ang), 0, sin(ang)) * r
		var post := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius    = 0.12
		cm.bottom_radius = 0.16
		cm.height        = rng.randf_range(2.2, 3.2)
		post.mesh = cm
		post.material_override = MAT_DARK_WOOD(0.5)
		post.global_position = p + Vector3(0, cm.height * 0.5, 0)
		root.add_child(post)


# ── NPC crowd ─────────────────────────────────────────────────────────────────

func _spawn_bw_npcs(root: Node3D, plaza: Vector3, market: Vector3, craft: Vector3, gate: Vector3) -> void:
	if briarwood_npc_scene == null:
		return

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var hubs := [plaza, market, craft, gate]
	for i in range(bw_npc_count):
		var base: Vector3 = hubs[rng.randi() % hubs.size()]
		var p: Vector3 = base + Vector3(rng.randf_range(-8.0, 8.0), 0.0, rng.randf_range(-8.0, 8.0))
		var npc  := briarwood_npc_scene.instantiate() as Node3D
		if npc == null:
			continue
		npc.global_position = p
		npc.rotation.y = rng.randf_range(-PI, PI)
		root.add_child(npc)


# ── Interactions: quest board, inn marker, smith marker, training dummy ───────

func _register_bw_interactions(civic: Dictionary, plaza: Vector3, market: Vector3, craft: Vector3) -> void:
	# Quest board (already created; just register)
	if civic.has("quest_board"):
		var qb := civic["quest_board"] as Node3D
		_register_interactable(qb, "quest_board")
		_register_minimap_marker(qb, "Board", "❖")

	# Training dummy at plaza edge
	var dummy: Node3D = _make_training_dummy(plaza + Vector3(-2.6, 0, 3.0))
	_briarwood_root.add_child(dummy)
	_register_interactable(dummy, "training_dummy")

	# Inn marker (frontage of the anchor building near market)
	var inn_marker := Node3D.new()
	inn_marker.name = "InnMarker"
	inn_marker.global_position = market + Vector3(0, 0, -6)
	_briarwood_root.add_child(inn_marker)
	_register_interactable(inn_marker, "inn")
	_register_minimap_marker(inn_marker, "Inn", "🏠")

	# Smith marker
	var smith_marker := Node3D.new()
	smith_marker.name = "SmithMarker"
	smith_marker.global_position = craft + Vector3(0, 0, 1.5)
	_briarwood_root.add_child(smith_marker)
	_register_interactable(smith_marker, "smith_shop")
	_register_minimap_marker(smith_marker, "Smith", "⚒")

	# Merchant marker (market stall area)
	var merchant_marker := Node3D.new()
	merchant_marker.name = "MerchantMarker"
	merchant_marker.global_position = market + Vector3(4.0, 0, 2.0)
	_briarwood_root.add_child(merchant_marker)
	_register_interactable(merchant_marker, "merchant_shop")

	# Alchemy bench / crafting marker (near market)
	var bench := Node3D.new()
	bench.name = "AlchemyBench"
	bench.global_position = market + Vector3(-6.0, 0, 3.0)
	_briarwood_root.add_child(bench)
	_register_interactable(bench, "crafting")

	# Door markers — interior portals (Phase 17)
	var door_inn := Node3D.new()
	door_inn.name = "DoorInn"
	door_inn.global_position = inn_marker.global_position + Vector3(0, 0, 1.5)
	_briarwood_root.add_child(door_inn)
	_register_interactable(door_inn, "enter_inn")

	var door_shop := Node3D.new()
	door_shop.name = "DoorShop"
	door_shop.global_position = merchant_marker.global_position + Vector3(0, 0, 1.5)
	_briarwood_root.add_child(door_shop)
	_register_interactable(door_shop, "enter_shop")

	var door_smith := Node3D.new()
	door_smith.name = "DoorSmith"
	door_smith.global_position = smith_marker.global_position + Vector3(0, 0, 1.5)
	_briarwood_root.add_child(door_smith)
	_register_interactable(door_smith, "enter_smith")

	# Boat road marker (points travellers toward Nordic harbor)
	var boat_marker := Node3D.new()
	boat_marker.name = "BoatRoadMarker"
	boat_marker.global_position = briarwood_origin + bw_gate_offset + Vector3(0, 0, -8)
	_briarwood_root.add_child(boat_marker)
	_register_minimap_marker(boat_marker, "Boat → Nordic", "⛵")


func _make_training_dummy(pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = "TrainingDummy"
	n.global_position = pos

	var pole := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius    = 0.18
	cm.bottom_radius = 0.22
	cm.height        = 2.0
	pole.mesh = cm
	pole.material_override = MAT_DARK_WOOD(0.5)
	pole.position.y = 1.0
	n.add_child(pole)

	var head := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.32
	sm.height = 0.64
	head.mesh = sm
	head.material_override = MAT_PLASTER(1.0)
	head.position.y = 2.32
	n.add_child(head)

	# Crossbar arms
	var arms := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.6, 0.14, 0.14)
	arms.mesh = bm
	arms.material_override = MAT_DARK_WOOD(0.5)
	arms.position.y = 1.55
	n.add_child(arms)

	return n


func _interact_training_dummy(player: Node3D) -> void:
	if player == null or not is_instance_valid(player):
		return

	# Advance active kill-quest targeting "training_dummy"
	if "active_quest" in player:
		var aq = player.active_quest
		if aq is Dictionary and aq.size() > 0 \
				and str(aq.get("kind", "")) == "kill" \
				and str(aq.get("target", "")) == "training_dummy":
			aq["killed"] = int(aq.get("killed", 0)) + 1
			player.active_quest = aq
			if player.has_signal("stats_changed"):
				player.stats_changed.emit()
			get_tree().call_group("world", "on_quest_progress", aq)
			var got  := int(aq.get("killed", 0))
			var need := int(aq.get("needed", 0))
			_try_toast("Thwack! Hit %d/%d" % [got, need])
			if player.has_method("is_quest_ready_to_turn_in") \
					and bool(player.call("is_quest_ready_to_turn_in")):
				_try_toast("Combo mastered — return to the board!")
		else:
			_try_toast("Thwack! Practise your stance.")
	else:
		_try_toast("Thwack! Practise your stance.")

	# Partial HP restore each hit
	if "hp" in player and "max_hp" in player:
		var heal: int = maxi(1, int(player.max_hp) / 8)
		player.hp = mini(int(player.hp) + heal, int(player.max_hp))
		if player.has_signal("stats_changed"):
			player.stats_changed.emit()

	_call_world_sfx("hit")

# ============================================================================
# QUEST BOARD UI — Briarwood (Quest System 3)
# ============================================================================

func _ensure_questboard_ui() -> void:
	if _qb_layer and is_instance_valid(_qb_layer):
		return

	_qb_layer = CanvasLayer.new()
	_qb_layer.name = "QuestBoardUI"
	_qb_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_qb_layer)

	_qb_panel = Panel.new()
	_qb_panel.name = "Panel"
	_qb_panel.visible = false
	_qb_panel.size = Vector2(760, 420)
	_qb_panel.position = (get_viewport().get_visible_rect().size * 0.5) \
							- (_qb_panel.size * 0.5)
	_qb_layer.add_child(_qb_panel)

	var outer := HBoxContainer.new()
	outer.anchor_right  = 1.0
	outer.anchor_bottom = 1.0
	outer.offset_left   = 18
	outer.offset_top    = 18
	outer.offset_right  = -18
	outer.offset_bottom = -18
	_qb_panel.add_child(outer)

	# ── Left column: quest list ──────────────────────────────────────────────
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(300, 0)
	outer.add_child(left)

	var list_title := Label.new()
	list_title.text = "Briarwood Notice Board"
	list_title.add_theme_font_size_override("font_size", 20)
	left.add_child(list_title)

	left.add_child(_ui_spacer(6))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(scroll)

	_qb_list_root = VBoxContainer.new()
	_qb_list_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_qb_list_root)

	# ── Right column: detail + buttons ──────────────────────────────────────
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(right)

	_qb_detail = RichTextLabel.new()
	_qb_detail.bbcode_enabled = true
	_qb_detail.fit_content = true
	_qb_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_qb_detail.text = "[b]Select a notice on the left.[/b]"
	right.add_child(_qb_detail)

	right.add_child(_ui_spacer(8))

	var btn_row := HBoxContainer.new()
	right.add_child(btn_row)

	var btn_accept := Button.new()
	btn_accept.text = "Accept Quest"
	btn_accept.pressed.connect(func(): _qb_accept_selected())
	btn_row.add_child(btn_accept)

	var btn_turnin := Button.new()
	btn_turnin.text = "Turn In"
	btn_turnin.pressed.connect(func(): _qb_turn_in())
	btn_row.add_child(btn_turnin)

	right.add_child(_ui_spacer(4))

	var btn_close := Button.new()
	btn_close.text = "Close  [Esc]"
	btn_close.pressed.connect(func(): _hide_quest_board_ui())
	right.add_child(btn_close)


func _show_quest_board_ui(player: Node3D) -> void:
	if not briarwood_questboard_enabled:
		return
	# Phase 21 — soft gate: nudge the player to meet the Mayor first.
	# This is intentionally a gentle hint, not a hard block, so kids aren't
	# stuck if they reach the board before the intro fires.
	if tutorial_enabled and mayor_intro_enabled and not _tutorial_done and not _mayor_intro_ran:
		_try_toast("A voice calls out: \"Talk to the Mayor first, traveller!\"")
		# Don't return — still let them open the board.
	_ensure_questboard_ui()

	_qb_player = player
	_qb_selected_id = ""
	_qb_panel.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if _qb_player and _qb_player.has_method("set_cinematic_lock"):
		_qb_player.call("set_cinematic_lock", true)

	_qb_rebuild_list()
	_qb_show_details("")


func _hide_quest_board_ui() -> void:
	if _qb_panel and is_instance_valid(_qb_panel):
		_qb_panel.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if _qb_player and is_instance_valid(_qb_player):
		if _qb_player.has_method("set_cinematic_lock"):
			_qb_player.call("set_cinematic_lock", false)
	_qb_player = null
	_qb_selected_id = ""


func _qb_rebuild_list() -> void:
	if _qb_list_root == null:
		return
	for c in _qb_list_root.get_children():
		c.queue_free()

	var active := _qb_get_active_quest()
	var has_active := active.size() > 0

	for q in BRIARWOOD_QUESTS:
		var id    := str(q.get("id", ""))
		var title := str(q.get("title", "Quest"))
		var btn   := Button.new()
		# Gray out quests that aren't the active one
		btn.disabled = has_active and not _qb_matches_active(id, active)
		if has_active and _qb_matches_active(id, active):
			btn.text = "★ " + title
		else:
			btn.text = title
		btn.pressed.connect(func(qid := id): _qb_select(qid))
		_qb_list_root.add_child(btn)


func _qb_select(id: String) -> void:
	_qb_selected_id = id
	_qb_show_details(id)


func _qb_show_details(id: String) -> void:
	if _qb_detail == null:
		return
	if id == "":
		_qb_detail.text = "[b]Briarwood Notice Board[/b]\n\nPick a notice on the left to read it."
		return

	var qdef := _qb_find_def(id)
	if qdef.is_empty():
		_qb_detail.text = "[color=red]Quest not found.[/color]"
		return

	var title  := str(qdef.get("title", "Quest"))
	var desc   := str(qdef.get("desc", ""))
	var qdata  := qdef.get("quest", {}) as Dictionary
	var kind   := str(qdata.get("kind", ""))
	var gold   := int(qdata.get("gold_reward", 0))
	var xp     := int(qdata.get("xp_reward", 0))
	var giver  := str(qdata.get("giver", "Briarwood Board"))

	var text := "[b]%s[/b]\n" % title
	text += "[i]Posted by: %s[/i]\n\n" % giver
	text += "%s\n\n" % desc

	if kind == "kill":
		var need := int(qdata.get("needed", 1))
		text += "[b]Objective:[/b] Defeat %d %s\n" % [need, str(qdata.get("target", "enemy"))]
	elif kind == "fetch":
		var need := int(qdata.get("needed", 1))
		text += "[b]Objective:[/b] Bring %d %s\n" % [need, str(qdata.get("item", "item"))]

	text += "[b]Reward:[/b] %d gold  +  %d XP\n\n" % [gold, xp]

	var active := _qb_get_active_quest()
	if active.size() > 0:
		if _qb_matches_active(id, active):
			text += "[color=yellow][b]ACTIVE:[/b][/color]  "
			text += _qb_progress_string(active) + "\n"
			if player_is_quest_ready():
				text += "\n[color=lime]Ready to turn in![/color]"
		else:
			text += "[color=gray]You have another quest in progress.[/color]"
	else:
		text += "[color=aqua]Available — press Accept.[/color]"

	_qb_detail.text = text


func _qb_accept_selected() -> void:
	if _qb_player == null or not is_instance_valid(_qb_player):
		return
	if _qb_selected_id == "":
		_try_toast("Select a quest first.")
		return

	var active := _qb_get_active_quest()
	if active.size() > 0:
		_try_toast("Finish your current quest first.")
		return

	var qdef := _qb_find_def(_qb_selected_id)
	if qdef.is_empty():
		return
	var qdata := qdef.get("quest", {}) as Dictionary
	if qdata.is_empty():
		return

	if _qb_player.has_method("accept_quest"):
		_qb_player.call("accept_quest", qdata)
		_try_toast("Quest accepted: %s" % str(qdef.get("title", "Quest")))
		_call_world_sfx("quest_accept")
	else:
		_try_toast("Player missing accept_quest().")

	_qb_rebuild_list()
	_qb_show_details(_qb_selected_id)


func _qb_turn_in() -> void:
	if _qb_player == null or not is_instance_valid(_qb_player):
		return
	if not player_is_quest_ready():
		_try_toast("Quest not finished yet.")
		return
	if not _qb_player.has_method("complete_quest_if_done"):
		_try_toast("Player missing complete_quest_if_done().")
		return

	var ok := bool(_qb_player.call("complete_quest_if_done"))
	if ok:
		_try_toast("Quest complete! Rewards granted.")
		_call_world_sfx("quest_complete")
		_qb_selected_id = ""
		_qb_rebuild_list()
		_qb_show_details("")
	else:
		_try_toast("Not finished yet.")


func _qb_find_def(id: String) -> Dictionary:
	for q in BRIARWOOD_QUESTS:
		if str(q.get("id", "")) == id:
			return q
	return {}


func _qb_get_active_quest() -> Dictionary:
	if _qb_player == null or not is_instance_valid(_qb_player):
		return {}
	if not ("active_quest" in _qb_player):
		return {}
	var aq = _qb_player.active_quest
	if aq is Dictionary and aq.size() > 0:
		return aq
	return {}


func player_is_quest_ready() -> bool:
	if _qb_player == null or not is_instance_valid(_qb_player):
		return false
	if _qb_player.has_method("is_quest_ready_to_turn_in"):
		return bool(_qb_player.call("is_quest_ready_to_turn_in"))
	# Fallback: check progress manually
	var aq := _qb_get_active_quest()
	if aq.is_empty():
		return false
	var kind := str(aq.get("kind", ""))
	if kind == "kill":
		return int(aq.get("killed", 0)) >= int(aq.get("needed", 999))
	if kind == "fetch":
		return int(aq.get("have", 0)) >= int(aq.get("needed", 999))
	return false


func _qb_matches_active(def_id: String, active: Dictionary) -> bool:
	if def_id == "":
		return false
	var def := _qb_find_def(def_id)
	if def.is_empty():
		return false
	var q    := def.get("quest", {}) as Dictionary
	var kind := str(active.get("kind", "kill"))
	if kind != str(q.get("kind", "kill")):
		return false
	if kind == "kill":
		return str(active.get("target", "")) == str(q.get("target", ""))
	if kind == "fetch":
		return str(active.get("item", "")) == str(q.get("item", ""))
	return false


func _qb_progress_string(active: Dictionary) -> String:
	var kind := str(active.get("kind", ""))
	match kind:
		"kill":
			var got  := int(active.get("killed", 0))
			var need := int(active.get("needed", 0))
			return "%d / %d defeated" % [got, need]
		"fetch":
			var got  := int(active.get("have", 0))
			var need := int(active.get("needed", 0))
			return "%d / %d collected" % [got, need]
	return ""


# ============================================================================
# Phase 11 — NPC Quest Givers + Turn-in Markers
# ============================================================================

func _spawn_briarwood_quest_givers(root: Node3D, townhall: Vector3, market: Vector3, craft: Vector3) -> void:
	if root == null or not is_instance_valid(root):
		return
	_spawn_named_giver(root, "Mayor",     townhall + Vector3(0, 0, 8),  "mayor")
	_spawn_named_giver(root, "Innkeeper", market   + Vector3(-3, 0, 0), "innkeeper")
	_spawn_named_giver(root, "Smith",     craft    + Vector3(0, 0, 3),  "smith_shop")


func _spawn_named_giver(root: Node3D, display_name: String, pos: Vector3, kind: String) -> Node3D:
	var npc: Node3D = null
	if briarwood_npc_scene != null:
		npc = briarwood_npc_scene.instantiate() as Node3D
	if npc == null:
		var mi := MeshInstance3D.new()
		var cm := CapsuleMesh.new()
		cm.radius = 0.3
		cm.height = 1.8
		mi.mesh = cm
		mi.material_override = _pbr_mat("", "", "", Vector3(1,1,1), Color(0.6, 0.75, 0.9))
		npc = mi
	npc.name = display_name.replace(" ", "_")
	root.add_child(npc)
	npc.global_position = pos

	# Floating name tag
	var label := Label3D.new()
	label.text = display_name
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = Vector3(0, 2.3, 0)
	label.pixel_size = 0.004
	label.font_size = 36
	label.outline_size = 8
	label.modulate = Color(1.0, 1.0, 0.85, 1.0)
	npc.add_child(label)

	_register_interactable(npc, kind)
	return npc


func _init_quest_markers() -> void:
	if _quest_marker_timer and is_instance_valid(_quest_marker_timer):
		return
	_quest_marker_timer = Timer.new()
	_quest_marker_timer.name = "QuestMarkerTick"
	_quest_marker_timer.wait_time = maxf(0.2, quest_marker_tick)
	_quest_marker_timer.autostart = true
	_quest_marker_timer.one_shot = false
	_quest_marker_timer.timeout.connect(_tick_quest_markers)
	add_child(_quest_marker_timer)
	_tick_quest_markers()


func _tick_quest_markers() -> void:
	if not quest_marker_enabled:
		return
	var player := _get_player()
	var has_quest: bool = false
	var ready: bool = false
	var active_kind := ""
	var active_target := ""
	var active_item := ""
	var turn_in_kind := ""

	if player != null:
		if "active_quest" in player and player.active_quest is Dictionary and player.active_quest.size() > 0:
			var aq: Dictionary = player.active_quest
			has_quest = true
			active_kind   = str(aq.get("kind", ""))
			active_target = str(aq.get("target", ""))
			active_item   = str(aq.get("item", ""))
			turn_in_kind  = str(aq.get("turn_in", ""))
			if player.has_method("is_quest_ready_to_turn_in"):
				ready = bool(player.call("is_quest_ready_to_turn_in"))
			elif active_kind == "kill":
				ready = int(aq.get("killed", 0)) >= int(aq.get("needed", 999))
			elif active_kind == "fetch":
				ready = int(aq.get("have", 0)) >= int(aq.get("needed", 999))

	# Quest board — show "?" when player has no quest
	var board_node := _find_first_interactable_kind("quest_board")
	if board_node:
		var show_board := not has_quest
		_set_marker(board_node, show_board, "?", player)

	# Mayor — show "!" when crate delivery is ready to turn in
	var mayor_node := _find_first_interactable_kind("mayor")
	if mayor_node:
		var show_mayor := has_quest and ready and turn_in_kind == ""
		_set_marker(mayor_node, show_mayor, "!", player)

	# Innkeeper — show "!" when innkeeper quest ready
	var inn_node := _find_first_interactable_kind("innkeeper")
	if inn_node:
		var show_inn := has_quest and ready
		_set_marker(inn_node, show_inn, "!", player)

	# Harbor master — show "!" when crate delivery turn-in
	var hm_node := _find_first_interactable_kind("harbor_master")
	if hm_node:
		var show_hm := has_quest and ready and turn_in_kind == "harbor_master"
		_set_marker(hm_node, show_hm, "!", player)


func _find_first_interactable_kind(kind: String) -> Node3D:
	var nodes := get_tree().get_nodes_in_group("world_interactables")
	for n in nodes:
		if n is Node3D and str(n.get_meta("interactable_kind", "")) == kind:
			return n as Node3D
	return null


func _set_marker(target: Node, enabled: bool, symbol: String, player: Node3D = null, fade_dist: float = 55.0) -> void:
	if target == null or not is_instance_valid(target):
		return

	var key := str(target.get_instance_id())
	if not _quest_markers.has(key):
		var l := Label3D.new()
		l.text = symbol
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		l.position = Vector3(0, 3.0, 0)
		l.pixel_size = 0.004
		l.font_size = 48
		l.outline_size = 10
		l.outline_modulate = Color(0, 0, 0, 1)
		l.modulate = Color(1.0, 0.95, 0.30, 1.0)
		target.add_child(l)
		_quest_markers[key] = l

	var label: Label3D = _quest_markers[key]
	if label == null or not is_instance_valid(label):
		_quest_markers.erase(key)
		return

	label.text = symbol
	label.visible = enabled

	if enabled and player != null and target is Node3D:
		var d: float = (player as Node3D).global_position.distance_to((target as Node3D).global_position)
		var a := clampf(1.0 - (d / fade_dist), 0.15, 1.0)
		var c := label.modulate
		c.a = a
		label.modulate = c


func _mayor_talk(player: Node3D) -> void:
	if player == null or not is_instance_valid(player):
		return
	# Phase 21 — first-meet greeting (only if intro was skipped / disabled)
	if not _mayor_intro_ran and mayor_intro_enabled and tutorial_enabled and not _tutorial_done:
		_run_mayor_intro()
		return
	show_dialog(
		player,
		"Mayor Aldric",
		"Briarwood stands because we stand together.\nWhat can I do for you?",
		[
			{"label": "Check Notice Board",      "action": func(): _show_quest_board_ui(player)},
			{"label": "Any advice for a traveller?", "action": func(): _try_toast("Stay on the roads at night, and mind the treeline.")},
			{"label": "Leave",                   "action": func(): pass},
		]
	)


func _innkeeper_talk(player: Node3D) -> void:
	if player == null or not is_instance_valid(player):
		return
	show_dialog(
		player,
		"Innkeeper Bram",
		"Welcome to the Briar & Barrel!\nWarm fire, soft beds. Need something?",
		[
			{"label": "Rest & Save",             "action": func(): _inn_rest_and_save(player)},
			{"label": "Harbor delivery quest",   "action": func(): _innkeeper_offer_delivery(player)},
			{"label": "Never mind",              "action": func(): pass},
		]
	)


func _smith_talk(player: Node3D) -> void:
	if player == null or not is_instance_valid(player):
		return
	show_dialog(
		player,
		"Smith Edda",
		"Fire and iron — that's what makes a warrior.\nWhat'll it be?",
		[
			{"label": "Browse Smith Shop",       "action": func(): _show_shop_ui(player, "smith")},
			{"label": "Upgrade weapon (+DMG)",   "action": func(): _smith_upgrade()},
			{"label": "Leave",                   "action": func(): pass},
		]
	)


func _harbor_master_turnin(player: Node3D) -> void:
	if player == null or not is_instance_valid(player):
		return
	if "active_quest" in player and player.active_quest is Dictionary and player.active_quest.size() > 0:
		var aq: Dictionary = player.active_quest
		var ready: bool = false
		if player.has_method("is_quest_ready_to_turn_in"):
			ready = bool(player.call("is_quest_ready_to_turn_in"))
		elif str(aq.get("kind","")) == "fetch":
			ready = int(aq.get("have",0)) >= int(aq.get("needed",999))
		if ready and str(aq.get("turn_in","")) == "harbor_master":
			if player.has_method("complete_quest_if_done"):
				var ok := bool(player.call("complete_quest_if_done"))
				if ok:
					_try_toast("Harbor Master: The crate arrived safely. Well done!")
					_call_world_sfx("quest_complete")
					return
			_try_toast("Harbor Master: I can see you've brought the crate — well done!")
			_call_world_sfx("quest_complete")
			return
	# Fall through to original fish-trade behaviour
	_harbor_master_talk(player)


# ============================================================================
# Phase 12 — Quest HUD Tracker
# ============================================================================

func _ensure_quest_hud() -> void:
	if _qh_layer and is_instance_valid(_qh_layer):
		return
	_qh_layer = CanvasLayer.new()
	_qh_layer.name = "QuestHUD"
	add_child(_qh_layer)

	_qh_panel = Panel.new()
	_qh_panel.name = "Panel"
	_qh_panel.size = Vector2(360, 120)
	_qh_panel.position = quest_hud_corner
	_qh_layer.add_child(_qh_panel)

	_qh_label = RichTextLabel.new()
	_qh_label.bbcode_enabled = true
	_qh_label.fit_content = true
	_qh_label.anchor_right = 1.0
	_qh_label.anchor_bottom = 1.0
	_qh_label.offset_left = 12
	_qh_label.offset_top = 10
	_qh_label.offset_right = -10
	_qh_label.offset_bottom = -10
	_qh_panel.add_child(_qh_label)


func _tick_quest_hud() -> void:
	if not quest_hud_enabled:
		return
	var player := _get_player()
	if player == null:
		return
	_ensure_quest_hud()

	if not ("active_quest" in player) or not (player.active_quest is Dictionary) or player.active_quest.size() == 0:
		_qh_panel.visible = false
		return

	_qh_panel.visible = true
	var aq: Dictionary = player.active_quest

	var kind := str(aq.get("kind", "kill"))
	var ready: bool = false
	if player.has_method("is_quest_ready_to_turn_in"):
		ready = bool(player.call("is_quest_ready_to_turn_in"))
	elif kind == "kill":
		ready = int(aq.get("killed", 0)) >= int(aq.get("needed", 999))
	elif kind == "fetch":
		ready = int(aq.get("have", 0)) >= int(aq.get("needed", 999))

	var title := _quest_title_from_active(aq)
	var body := ""
	match kind:
		"kill":
			body = "Defeat [b]%s[/b]\nProgress: [b]%d/%d[/b]" % [
				str(aq.get("target", "")),
				int(aq.get("killed", 0)),
				int(aq.get("needed", 0)),
			]
		"fetch":
			body = "Bring [b]%s[/b]\nProgress: [b]%d/%d[/b]" % [
				str(aq.get("item", "")),
				int(aq.get("have", 0)),
				int(aq.get("needed", 0)),
			]

	var status := "[color=#ffd66b][b]READY TO TURN IN![/b][/color]" if ready else "[color=#cccccc]In progress[/color]"
	_qh_label.text = "[b]%s[/b]\n%s\n%s" % [title, body, status]


func _quest_title_from_active(aq: Dictionary) -> String:
	var kind := str(aq.get("kind", "kill"))
	for d in BRIARWOOD_QUESTS:
		var q := d.get("quest", {}) as Dictionary
		if str(q.get("kind", "")) != kind:
			continue
		if kind == "kill" and str(q.get("target", "")) == str(aq.get("target", "")):
			return str(d.get("title", "Quest"))
		if kind == "fetch" and str(q.get("item", "")) == str(aq.get("item", "")):
			return str(d.get("title", "Quest"))
	return "Quest"


# ============================================================================
# Phase 12 — Briarwood Crowd Life Loops
# ============================================================================

func _build_briarwood_life() -> void:
	if not briarwood_life_enabled:
		return
	if _briarwood_root == null or not is_instance_valid(_briarwood_root):
		return
	if briarwood_npc_scene == null:
		return

	if _bw_life_root and is_instance_valid(_bw_life_root):
		_bw_life_root.queue_free()

	_bw_life_root = Node3D.new()
	_bw_life_root.name = "BriarwoodLife"
	_briarwood_root.add_child(_bw_life_root)
	_bw_life_npcs.clear()

	var plaza  := briarwood_origin + bw_plaza_offset
	var gate   := briarwood_origin + bw_gate_offset
	var market := briarwood_origin + bw_market_offset

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	# Guards (2) patrol gate ↔ plaza
	for i in range(2):
		var npc := briarwood_npc_scene.instantiate() as Node3D
		if npc == null:
			continue
		_bw_life_root.add_child(npc)
		npc.name = "LifeGuard_%d" % i
		npc.global_position = gate + Vector3(rng.randf_range(-2, 2), 0, rng.randf_range(-2, 2))
		npc.set_meta("life_role", "guard")
		npc.set_meta("life_route", [
			gate   + Vector3(-1, 0,  0),
			plaza  + Vector3( 0, 0, -4),
			plaza  + Vector3( 2, 0,  2),
			gate   + Vector3( 1, 0,  1),
		])
		npc.set_meta("life_idx", 0)
		_bw_life_npcs.append(npc)

	# Villagers wander near plaza + market
	var vill_count := clampi(bw_npc_count, 8, 18)
	for i in range(vill_count):
		var npc2 := briarwood_npc_scene.instantiate() as Node3D
		if npc2 == null:
			continue
		_bw_life_root.add_child(npc2)
		npc2.name = "LifeVillager_%d" % i
		var hub: Vector3 = plaza if rng.randf() < 0.55 else market
		npc2.global_position = hub + Vector3(rng.randf_range(-8, 8), 0, rng.randf_range(-8, 8))
		npc2.set_meta("life_role", "villager")
		npc2.set_meta("life_home", npc2.global_position)
		npc2.set_meta("life_idle_until", 0.0)
		_bw_life_npcs.append(npc2)

	_bw_life_timer = Timer.new()
	_bw_life_timer.name = "BriarwoodLifeTick"
	_bw_life_timer.wait_time = maxf(0.4, briarwood_life_tick)
	_bw_life_timer.autostart = true
	_bw_life_timer.one_shot = false
	_bw_life_timer.timeout.connect(_tick_briarwood_life)
	_bw_life_root.add_child(_bw_life_timer)

	_tick_briarwood_life()


func _tick_briarwood_life() -> void:
	if _bw_life_npcs.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var now := Time.get_ticks_msec() / 1000.0

	for npc in _bw_life_npcs:
		if npc == null or not is_instance_valid(npc):
			continue
		var role := str(npc.get_meta("life_role", "villager"))
		if role == "guard":
			var route: Array = npc.get_meta("life_route", [])
			if route.is_empty():
				continue
			var idx := int(npc.get_meta("life_idx", 0))
			var target: Vector3 = route[idx]
			if npc.global_position.distance_to(target) < 0.9:
				idx = (idx + 1) % route.size()
				npc.set_meta("life_idx", idx)
			_npc_go_to(npc, target)
			_try_play_anim(npc, "walk")
		else:
			var idle_until := float(npc.get_meta("life_idle_until", 0.0))
			if now < idle_until:
				if rng.randf() < 0.4:
					npc.rotation.y += rng.randf_range(-0.5, 0.5)
				_try_play_anim(npc, "idle")
				continue
			var home: Vector3 = npc.get_meta("life_home", npc.global_position)
			var target2: Vector3 = home + Vector3(rng.randf_range(-6, 6), 0, rng.randf_range(-6, 6))
			npc.set_meta("life_idle_until", now + rng.randf_range(1.0, 3.0))
			_npc_go_to(npc, target2)
			_try_play_anim(npc, "walk")


# ============================================================================
# Phase 13 — Briarwood Atmosphere (Audio Zones + Micro VFX)
# ============================================================================

func _build_briarwood_atmosphere(root: Node3D, plaza: Vector3, market: Vector3, craft: Vector3, gate: Vector3, townhall: Vector3) -> void:
	var aroot := Node3D.new()
	aroot.name = "BriarwoodAtmosphere"
	root.add_child(aroot)

	# ── Audio zones (3D loops, distance falloff) ───────────────────────────
	_add_loop_3d(aroot, "BW_Birds",  sfx_bw_birds_loop,  plaza  + Vector3(0,   2.0,  0),    80.0, -10.0)
	_add_loop_3d(aroot, "BW_Wind",   sfx_bw_wind_loop,   gate   + Vector3(0,   2.0,  0),   110.0, -12.0)
	_add_loop_3d(aroot, "BW_Tavern", sfx_bw_tavern_loop, market + Vector3(0,   2.0, -6.0),  55.0, -10.0)
	_add_loop_3d(aroot, "BW_Hammer", sfx_bw_hammer_loop, craft  + Vector3(0,   2.0,  2.0),  65.0,  -8.0)
	_add_loop_3d(aroot, "BW_Forge",  sfx_bw_forge_loop,  craft  + Vector3(2.0, 1.0, -1.0),  55.0, -12.0)

	# ── Micro VFX ─────────────────────────────────────────────────────────
	if bw_smoke_enabled:
		aroot.add_child(_make_smoke_stack(craft + Vector3(2.2, 6.0, -1.6)))

	if bw_flag_enabled:
		aroot.add_child(_make_flag_sway(townhall + Vector3(-3.8, 6.0, 8.2)))

	if bw_lantern_sway_enabled:
		_sway_lanterns_in_tree(root)


func _add_loop_3d(parent: Node3D, node_name: String, stream: AudioStream, pos: Vector3, max_dist: float, vol_db: float) -> void:
	if stream == null:
		return
	var p := AudioStreamPlayer3D.new()
	p.name = node_name
	p.stream = stream
	p.autoplay = true
	p.max_distance = max_dist
	p.volume_db = vol_db
	p.global_position = pos
	parent.add_child(p)


func _make_smoke_stack(pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = "SmokeStack"
	n.global_position = pos

	var gpu := GPUParticles3D.new()
	gpu.amount = 60
	gpu.lifetime = 3.8
	gpu.one_shot = false
	gpu.emitting = true
	gpu.visibility_aabb = AABB(Vector3(-6, -6, -6), Vector3(12, 12, 12))
	n.add_child(gpu)

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 18.0
	mat.gravity = Vector3(0, 0.25, 0)
	mat.initial_velocity_min = 0.6
	mat.initial_velocity_max = 1.3
	mat.scale_min = 0.35
	mat.scale_max = 0.9
	mat.damping_min = 0.0
	mat.damping_max = 0.15
	mat.color = Color(0.70, 0.70, 0.70, 0.45)
	gpu.process_material = mat

	var draw := QuadMesh.new()
	draw.size = Vector2(0.6, 0.6)
	gpu.draw_pass_1 = draw

	return n


func _make_flag_sway(pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = "TownHallFlag"
	n.global_position = pos

	# Pole
	var pole := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.05
	cm.bottom_radius = 0.07
	cm.height = 4.8
	pole.mesh = cm
	pole.material_override = MAT_DARK_WOOD(1.0)
	pole.position = Vector3(0, -2.4, 0)
	n.add_child(pole)

	# Flag cloth
	var flag := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(1.6, 0.9)
	flag.mesh = qm
	var flag_mat := StandardMaterial3D.new()
	flag_mat.albedo_color = Color(0.55, 0.12, 0.12)  # deep red
	flag_mat.roughness = 0.9
	flag.material_override = flag_mat
	flag.position = Vector3(0.9, -1.2, 0)
	flag.rotation.y = deg_to_rad(90)
	n.add_child(flag)

	# Sway tween
	var tw := n.create_tween().set_loops()
	tw.tween_property(flag, "rotation:z", deg_to_rad(12), 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(flag, "rotation:z", deg_to_rad(-10), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	return n


func _sway_lanterns_in_tree(root: Node) -> void:
	# Find every Node3D with "Lantern" in its name under root and apply a wind sway tween.
	# Each gets a slightly different period so they don't oscillate in unison.
	var lanterns := root.find_children("*Lantern*", "Node3D", true, false)
	for i in range(lanterns.size()):
		var ln := lanterns[i] as Node3D
		if ln == null:
			continue
		var period_a := 1.7 + float(i % 5) * 0.12
		var period_b := 2.0 + float(i % 7) * 0.09
		var tw := ln.create_tween().set_loops()
		tw.tween_property(ln, "rotation:z", deg_to_rad(4),  period_a).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(ln, "rotation:z", deg_to_rad(-3), period_b).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# ============================================================================
# Phases 14/15 — Real Shop UI (buy/sell + icons + equip + smith upgrade)
# ============================================================================

func _item_name(id: String) -> String:
	return str(ITEM_DB.get(id, {}).get("name", id))

func _item_icon(id: String) -> String:
	return str(ITEM_DB.get(id, {}).get("icon", "•"))

func _item_slot(id: String) -> String:
	return str(ITEM_DB.get(id, {}).get("slot", ""))


func _ensure_shop_ui() -> void:
	if _shop_layer and is_instance_valid(_shop_layer):
		return
	_shop_layer = CanvasLayer.new()
	_shop_layer.name = "ShopUI"
	_shop_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_shop_layer)

	_shop_panel = Panel.new()
	_shop_panel.name = "ShopPanel"
	_shop_panel.visible = false
	_shop_panel.size = Vector2(880, 480)
	_shop_panel.position = get_viewport().get_visible_rect().size * 0.5 - _shop_panel.size * 0.5
	_shop_layer.add_child(_shop_panel)

	var outer := VBoxContainer.new()
	outer.name = "VBoxContainer"
	outer.anchor_right  = 1.0
	outer.anchor_bottom = 1.0
	outer.offset_left   = 18
	outer.offset_top    = 18
	outer.offset_right  = -18
	outer.offset_bottom = -18
	_shop_panel.add_child(outer)

	var title := Label.new()
	title.name = "Title"
	title.text = "Shop"
	title.add_theme_font_size_override("font_size", 22)
	outer.add_child(title)

	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(split)

	# Left: shop items (Buy)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(380, 0)
	split.add_child(left)
	var left_hdr := Label.new()
	left_hdr.text = "For Sale"
	left.add_child(left_hdr)
	var left_scroll := ScrollContainer.new()
	left_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(left_scroll)
	_shop_shop_list = VBoxContainer.new()
	_shop_shop_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_scroll.add_child(_shop_shop_list)

	# Right: inventory (Sell)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(right)
	var right_hdr := Label.new()
	right_hdr.text = "Your Bag (Sell)"
	right.add_child(right_hdr)
	var right_scroll := ScrollContainer.new()
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(right_scroll)
	_shop_inv_list = VBoxContainer.new()
	_shop_inv_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.add_child(_shop_inv_list)

	# Detail strip
	_shop_detail = RichTextLabel.new()
	_shop_detail.bbcode_enabled = true
	_shop_detail.fit_content = true
	_shop_detail.custom_minimum_size = Vector2(0, 72)
	outer.add_child(_shop_detail)

	# Bottom bar: gold + upgrade (smith) + close
	var bottom := HBoxContainer.new()
	outer.add_child(bottom)

	_shop_gold_label = Label.new()
	_shop_gold_label.text = "Gold: 0"
	bottom.add_child(_shop_gold_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(spacer)

	var up_btn := Button.new()
	up_btn.name = "UpgradeBtn"
	up_btn.text = "⚒ Upgrade (+DMG)"
	up_btn.visible = false
	up_btn.pressed.connect(func(): _smith_upgrade())
	bottom.add_child(up_btn)

	var close_btn := Button.new()
	close_btn.text = "Close  [Esc]"
	close_btn.pressed.connect(func(): _hide_shop_ui())
	bottom.add_child(close_btn)


func _show_shop_ui(player: Node3D, kind: String) -> void:
	if not bw_shops_enabled:
		return
	_ensure_shop_ui()
	_shop_player = player
	_shop_kind   = kind
	_shop_panel.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if _shop_player and _shop_player.has_method("set_cinematic_lock"):
		_shop_player.call("set_cinematic_lock", true)

	var title_node := _shop_panel.get_node_or_null("VBoxContainer/Title")
	if title_node is Label:
		(title_node as Label).text = "Blacksmith" if kind == "smith" else "Merchant"

	var up_btn := _shop_panel.find_child("UpgradeBtn", true, false) as Button
	if up_btn:
		up_btn.visible = (kind == "smith")

	_shop_refresh()


func _hide_shop_ui() -> void:
	if _shop_panel and is_instance_valid(_shop_panel):
		_shop_panel.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if _shop_player and is_instance_valid(_shop_player) and _shop_player.has_method("set_cinematic_lock"):
		_shop_player.call("set_cinematic_lock", false)
	_shop_player = null
	_shop_kind   = ""


# ── Phase 16: rotating stock helpers ─────────────────────────────────────────

func _shop_day_index() -> int:
	if shop_day_length_real_seconds > 0.0:
		return int(floor((Time.get_ticks_msec() / 1000.0) / shop_day_length_real_seconds))
	return int(floor(Time.get_unix_time_from_system() / 86400.0))


func _shop_rng(kind: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(shop_global_seed) ^ (_shop_day_index() * 1103515245) ^ int(hash(kind))
	return rng


func _shop_daily_stock(kind: String) -> Array:
	var pool: Array = SHOP_POOLS.get(kind, [])
	if pool.is_empty():
		return SHOP_ITEMS.get(kind, [])
	var n := 5 if kind == "merchant" else 4
	var rng := _shop_rng(kind)
	var shuffled := pool.duplicate()
	for i in range(shuffled.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp = shuffled[i]
		shuffled[i] = shuffled[j]
		shuffled[j] = tmp
	var picked: Array = []
	for k in range(mini(n, shuffled.size())):
		var def := _shop_find_item_def(kind, str(shuffled[k]))
		if def.is_empty():
			def = {"id": str(shuffled[k]), "name": _item_name(str(shuffled[k])), "price": 20, "sell": 10}
		picked.append(def)
	return picked


func _shop_find_item_def(kind: String, id: String) -> Dictionary:
	for it in SHOP_ITEMS.get(kind, []):
		if str(it.get("id", "")) == id:
			var out: Dictionary = it.duplicate()
			out["name"] = _item_name(id)
			return out
	return {}


# ── Bag slot helpers (adjust here if your Inventory schema differs) ───────────

func _inv_bag(inv: Node) -> Array:
	if inv == null:
		return []
	if "bag" in inv and inv.bag is Array:
		return inv.bag
	return []


func _slot_id(slot: Dictionary) -> String:
	return str(slot.get("id", ""))


func _slot_qty(slot: Dictionary) -> int:
	if slot.has("qty"):   return int(slot["qty"])
	if slot.has("count"): return int(slot["count"])
	return 1


func _set_slot_qty(slot: Dictionary, qty: int) -> void:
	if slot.has("qty"):
		slot["qty"] = qty
	elif slot.has("count"):
		slot["count"] = qty
	else:
		slot["qty"] = qty


# ── Shop refresh (Phase 14+15+16 all-in-one) ─────────────────────────────────

func _shop_refresh() -> void:
	if _shop_player == null or not is_instance_valid(_shop_player):
		return
	if _shop_shop_list == null or _shop_inv_list == null:
		return

	var g := 0
	if "gold" in _shop_player:
		g = int(_shop_player.gold)
	_shop_gold_label.text = "Gold: %d" % g

	for c in _shop_shop_list.get_children():
		c.queue_free()
	for c in _shop_inv_list.get_children():
		c.queue_free()

	# ── For Sale list ─────────────────────────────────────────────────────────
	var items: Array = _shop_daily_stock(_shop_kind) if shop_stock_rotation_enabled \
						else SHOP_ITEMS.get(_shop_kind, [])
	for it in items:
		var id    := str(it.get("id", ""))
		var price := int(it.get("price", 0))
		var nice  := "%s %s" % [_item_icon(id), _item_name(id)]

		var row := HBoxContainer.new()
		_shop_shop_list.add_child(row)

		var lbl := Label.new()
		lbl.text = "%s  —  %dg" % [nice, price]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)

		var buy_btn := Button.new()
		buy_btn.text = "Buy"
		buy_btn.pressed.connect(func(_i := id, _p := price, _n := nice): _shop_buy(_i, _p, _n))
		row.add_child(buy_btn)

		var slot_name := _item_slot(id)
		if slot_name != "":
			var eq_btn := Button.new()
			eq_btn.text = "Equip"
			eq_btn.pressed.connect(func(_i := id, _s := slot_name): _shop_equip(_i, _s))
			row.add_child(eq_btn)

	# ── Sell list (real bag slots) ────────────────────────────────────────────
	var inv := _shop_get_inventory()
	if inv == null:
		var warn := Label.new()
		warn.text = "(No inventory found)"
		_shop_inv_list.add_child(warn)
	else:
		var bag := _inv_bag(inv)
		if bag.size() > 0:
			for i in range(bag.size()):
				var s = bag[i]
				if not (s is Dictionary):
					continue
				var sid := _slot_id(s)
				var qty := _slot_qty(s)
				if sid == "" or qty <= 0:
					continue
				var sell_p := _shop_sell_price(sid)
				var row2 := HBoxContainer.new()
				_shop_inv_list.add_child(row2)
				var lbl2 := Label.new()
				lbl2.text = "%s %s x%d  —  %dg" % [_item_icon(sid), _item_name(sid), qty, sell_p]
				lbl2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row2.add_child(lbl2)
				var sell_btn := Button.new()
				sell_btn.text = "Sell 1"
				sell_btn.pressed.connect(func(_idx := i, _p := sell_p):
					_shop_sell_slot(_shop_get_inventory(), _idx, 1, _p)
				)
				row2.add_child(sell_btn)
		else:
			# Fallback: show known items player owns via count_item
			for it2 in SHOP_ITEMS.get(_shop_kind, []):
				var sid2 := str(it2.get("id", ""))
				var have := 0
				if inv.has_method("count_item"):
					have = int(inv.count_item(sid2))
				if have <= 0:
					continue
				var sell_p2 := _shop_sell_price(sid2)
				var row3 := HBoxContainer.new()
				_shop_inv_list.add_child(row3)
				var lbl3 := Label.new()
				lbl3.text = "%s %s x%d  —  %dg" % [_item_icon(sid2), _item_name(sid2), have, sell_p2]
				lbl3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row3.add_child(lbl3)
				var sell_btn2 := Button.new()
				sell_btn2.text = "Sell 1"
				sell_btn2.pressed.connect(func(_i2 := sid2, _p2 := sell_p2): _shop_sell(_i2, 1, _p2))
				row3.add_child(sell_btn2)

	var detail := "[b]Tip:[/b] Buy on the left, sell on the right."
	if _shop_kind == "smith":
		detail = "[b]Smith[/b]\nUpgrade weapon: costs 2 iron_ingot + 40g.\n\n" + detail
	_shop_detail.text = detail


func _shop_get_inventory() -> Node:
	if _shop_player == null or not is_instance_valid(_shop_player):
		return null
	var inv = _shop_player.get("inventory") if "inventory" in _shop_player else null
	return inv


func _shop_buy(item_id: String, price: int, display_name: String) -> void:
	if _shop_player == null or not is_instance_valid(_shop_player):
		return
	if not ("gold" in _shop_player):
		_try_toast("Player has no gold field.")
		return
	if int(_shop_player.gold) < price:
		_try_toast("Not enough gold.")
		return
	var inv := _shop_get_inventory()
	if inv == null or not inv.has_method("add_item"):
		_try_toast("No inventory.add_item().")
		return
	_shop_player.gold -= price
	inv.add_item(item_id, 1)
	if _shop_player.has_signal("stats_changed"):
		_shop_player.stats_changed.emit()
	_try_toast("Bought: %s" % display_name)
	_shop_refresh()


func _shop_sell(item_id: String, qty: int, unit_price: int) -> void:
	if _shop_player == null or not is_instance_valid(_shop_player):
		return
	if not ("gold" in _shop_player):
		_try_toast("Player has no gold field.")
		return
	var inv := _shop_get_inventory()
	if inv == null or not inv.has_method("count_item") or not inv.has_method("consume_item"):
		_try_toast("Inventory missing count/consume.")
		return
	if int(inv.count_item(item_id)) < qty:
		_try_toast("You don't have that.")
		return
	inv.consume_item(item_id, qty)
	_shop_player.gold += unit_price * qty
	if _shop_player.has_signal("stats_changed"):
		_shop_player.stats_changed.emit()
	_try_toast("Sold: %s" % _item_name(item_id))
	_shop_refresh()


func _shop_sell_slot(inv: Node, slot_index: int, qty: int, unit_price: int) -> void:
	if _shop_player == null or not is_instance_valid(_shop_player):
		return
	if inv == null or not ("gold" in _shop_player):
		return
	var bag := _inv_bag(inv)
	if slot_index < 0 or slot_index >= bag.size():
		return
	var slot = bag[slot_index]
	if not (slot is Dictionary):
		return
	var id  := _slot_id(slot)
	var have := _slot_qty(slot)
	if have < qty:
		_try_toast("Not enough to sell.")
		return
	if inv.has_method("consume_item"):
		inv.consume_item(id, qty)
	else:
		var new_qty := have - qty
		if new_qty <= 0:
			bag.remove_at(slot_index)
		else:
			_set_slot_qty(slot, new_qty)
			bag[slot_index] = slot
		if "bag" in inv:
			inv.bag = bag
	_shop_player.gold += unit_price * qty
	if inv.has_signal("inventory_changed"):
		inv.inventory_changed.emit()
	if _shop_player.has_signal("stats_changed"):
		_shop_player.stats_changed.emit()
	_try_toast("Sold: %s" % _item_name(id))
	_shop_refresh()


func _shop_sell_price(item_id: String) -> int:
	for k in SHOP_ITEMS.keys():
		for it in SHOP_ITEMS[k]:
			if str(it.get("id", "")) == item_id:
				return int(it.get("sell", maxi(1, int(it.get("price", 2)) / 2)))
	return 1


func _shop_equip(item_id: String, slot: String) -> void:
	var inv := _shop_get_inventory()
	if inv == null:
		_try_toast("No inventory.")
		return
	if inv.has_method("count_item") and int(inv.count_item(item_id)) <= 0:
		_try_toast("You don't own that yet.")
		return
	if "equipped" in inv and inv.equipped is Dictionary:
		inv.equipped[slot] = item_id
		if inv.has_signal("equipment_changed"):
			inv.equipment_changed.emit()
		_try_toast("Equipped %s" % _item_name(item_id))
		_shop_refresh()
		return
	if inv.has_method("set_equipped"):
		inv.call("set_equipped", slot, item_id)
		_try_toast("Equipped %s" % _item_name(item_id))
		_shop_refresh()
		return
	_try_toast("Inventory has no equip system yet.")


func _smith_upgrade() -> void:
	# Phase 21 — tutorial gate: upgrades unlock at step 3 (after inn rest)
	if tutorial_gating_enabled and tutorial_enabled and not _tutorial_done:
		if _tutorial_step < 3:
			_try_toast("Edda: \"Rest up at the Inn first. I'll still be here when you're ready.\"")
			return
	if _shop_player == null or not is_instance_valid(_shop_player) or _shop_kind != "smith":
		return
	var inv := _shop_get_inventory()
	if inv == null:
		_try_toast("No inventory.")
		return
	if not ("gold" in _shop_player):
		_try_toast("Player has no gold.")
		return
	if int(_shop_player.gold) < 40:
		_try_toast("Need 40 gold.")
		return
	if not inv.has_method("count_item") or not inv.has_method("consume_item"):
		_try_toast("Inventory missing count/consume.")
		return
	if int(inv.count_item("iron_ingot")) < 2:
		_try_toast("Need 2 iron_ingot.")
		return
	inv.consume_item("iron_ingot", 2)
	_shop_player.gold -= 40
	if "upgrade_bonus_damage" in inv:
		inv.upgrade_bonus_damage = float(inv.upgrade_bonus_damage) + 1.0
	elif inv.has_method("set_upgrade_bonus_damage"):
		inv.call("set_upgrade_bonus_damage", 1.0)
	else:
		inv.set_meta("upgrade_bonus_damage", float(inv.get_meta("upgrade_bonus_damage", 0.0)) + 1.0)
	if inv.has_signal("equipment_changed"):
		inv.equipment_changed.emit()
	if _shop_player.has_signal("stats_changed"):
		_shop_player.stats_changed.emit()
	_try_toast("Smith: Weapon damage +1!")
	_shop_refresh()


# ============================================================================
# Phase 16 — Crafting UI
# ============================================================================

func _ensure_crafting_ui() -> void:
	if _craft_layer and is_instance_valid(_craft_layer):
		return
	_craft_layer = CanvasLayer.new()
	_craft_layer.name = "CraftUI"
	_craft_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_craft_layer)

	_craft_panel = Panel.new()
	_craft_panel.name = "CraftPanel"
	_craft_panel.visible = false
	_craft_panel.size = Vector2(760, 420)
	_craft_panel.position = get_viewport().get_visible_rect().size * 0.5 - _craft_panel.size * 0.5
	_craft_layer.add_child(_craft_panel)

	var outer := HBoxContainer.new()
	outer.anchor_right  = 1.0
	outer.anchor_bottom = 1.0
	outer.offset_left   = 18
	outer.offset_top    = 18
	outer.offset_right  = -18
	outer.offset_bottom = -18
	_craft_panel.add_child(outer)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(340, 0)
	outer.add_child(left)

	var t := Label.new()
	t.text = "Crafting"
	t.add_theme_font_size_override("font_size", 22)
	left.add_child(t)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(scroll)

	_craft_list = VBoxContainer.new()
	_craft_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_craft_list)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(right)

	_craft_detail = RichTextLabel.new()
	_craft_detail.bbcode_enabled = true
	_craft_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_craft_detail)

	var close_btn := Button.new()
	close_btn.text = "Close  [Esc]"
	close_btn.pressed.connect(func(): _hide_crafting_ui())
	right.add_child(close_btn)


func _show_crafting_ui(player: Node3D) -> void:
	_ensure_crafting_ui()
	_craft_player = player
	_craft_panel.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if _craft_player and _craft_player.has_method("set_cinematic_lock"):
		_craft_player.call("set_cinematic_lock", true)
	_craft_rebuild()


func _hide_crafting_ui() -> void:
	if _craft_panel and is_instance_valid(_craft_panel):
		_craft_panel.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if _craft_player and is_instance_valid(_craft_player) and _craft_player.has_method("set_cinematic_lock"):
		_craft_player.call("set_cinematic_lock", false)
	_craft_player = null


func _craft_rebuild() -> void:
	for c in _craft_list.get_children():
		c.queue_free()
	_craft_detail.text = "[b]Crafting[/b]\nSelect a recipe to craft.\n\nMaterials are taken from your bag."

	var inv := _shop_get_inventory() if _craft_player != null else null

	for r in CRAFT_RECIPES:
		var row := HBoxContainer.new()
		_craft_list.add_child(row)

		var rname := str(r.get("name", "Recipe"))
		var can_craft: bool = true
		if inv != null and inv.has_method("count_item"):
			for inp in r.get("inputs", []):
				if int(inv.count_item(str(inp.get("id", "")))) < int(inp.get("qty", 1)):
					can_craft = false
					break

		var lbl := Label.new()
		lbl.text = rname
		lbl.modulate = Color(1, 1, 1, 1) if can_craft else Color(0.55, 0.55, 0.55, 1)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)

		var btn := Button.new()
		btn.text = "Craft"
		btn.disabled = not can_craft
		btn.pressed.connect(func(_rid := str(r.get("id", ""))): _craft_do(_rid))
		row.add_child(btn)


func _craft_do(recipe_id: String) -> void:
	if _craft_player == null or not is_instance_valid(_craft_player):
		return
	var inv := _shop_get_inventory()
	if inv == null:
		_try_toast("No inventory.")
		return
	if not inv.has_method("count_item") or not inv.has_method("consume_item") or not inv.has_method("add_item"):
		_try_toast("Inventory missing craft methods.")
		return

	var recipe := {}
	for r in CRAFT_RECIPES:
		if str(r.get("id", "")) == recipe_id:
			recipe = r
			break
	if recipe.is_empty():
		return

	for inp in recipe.get("inputs", []):
		var iid := str(inp.get("id", ""))
		var q   := int(inp.get("qty", 1))
		if int(inv.count_item(iid)) < q:
			_try_toast("Missing: %s x%d" % [_item_name(iid), q])
			return

	for inp in recipe.get("inputs", []):
		inv.consume_item(str(inp.get("id", "")), int(inp.get("qty", 1)))

	for out in recipe.get("outputs", []):
		inv.add_item(str(out.get("id", "")), int(out.get("qty", 1)))

	if inv.has_signal("inventory_changed"):
		inv.inventory_changed.emit()
	if _craft_player and _craft_player.has_signal("stats_changed"):
		_craft_player.stats_changed.emit()

	_try_toast("Crafted: %s" % str(recipe.get("name", "Item")))
	_craft_rebuild()


# ============================================================================
# Phase 17 — Town Schedule (day/night cycle + NPC shifts)
# ============================================================================

func _town_time_of_day() -> float:
	if day_length_seconds <= 0.1:
		return 0.35
	return fmod((Time.get_ticks_msec() / 1000.0) / day_length_seconds, 1.0)


func _is_night(t: float) -> bool:
	return (t >= night_start) or (t <= night_end)


func _init_town_schedule() -> void:
	if _schedule_timer and is_instance_valid(_schedule_timer):
		_schedule_timer.queue_free()
	_schedule_timer = Timer.new()
	_schedule_timer.name = "TownScheduleTick"
	_schedule_timer.wait_time = 1.0
	_schedule_timer.autostart = true
	_schedule_timer.one_shot = false
	_schedule_timer.timeout.connect(_tick_town_schedule)
	add_child(_schedule_timer)
	_tick_town_schedule()


func _tick_town_schedule() -> void:
	if not town_schedule_enabled:
		return
	var t := _town_time_of_day()
	var night := _is_night(t)
	if night != _last_night_state:
		_last_night_state = night
		_apply_briarwood_lighting(night)
		_apply_briarwood_npc_shift(night)


func _apply_briarwood_lighting(night: bool) -> void:
	var root := _briarwood_root if _briarwood_root and is_instance_valid(_briarwood_root) else get_tree().current_scene
	if root == null:
		return
	for l in root.find_children("*Lantern*", "Node3D", true, false):
		var ln := l as Node3D
		if ln == null:
			continue
		for lx in ln.find_children("*", "OmniLight3D", true, false):
			var ol := lx as OmniLight3D
			if ol:
				ol.visible = night
	for m in root.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi == null or mi.name.to_lower().find("window") == -1:
			continue
		var mat := mi.material_override
		if mat is StandardMaterial3D:
			var sm := mat as StandardMaterial3D
			if sm.emission_enabled:
				sm.emission_energy_multiplier = bw_window_energy_night if night else bw_window_energy_day


func _apply_briarwood_npc_shift(night: bool) -> void:
	for npc in _bw_life_npcs:
		if npc == null or not is_instance_valid(npc):
			continue
		if str(npc.get_meta("life_role", "villager")) == "villager" and night:
			var home: Vector3 = npc.get_meta("life_home", npc.global_position)
			_npc_go_to(npc, home)
			npc.set_meta("life_idle_until", (Time.get_ticks_msec() / 1000.0) + 6.0)


# ============================================================================
# Phase 17 — Interior Portals
# ============================================================================

func _enter_interior(player: Node3D, kind: String) -> void:
	if player == null or not is_instance_valid(player):
		return

	_call_world_sfx("door_open")
	_transition_fade(true, transition_fade_time)
	await get_tree().create_timer(maxf(0.05, transition_fade_time)).timeout

	var scene: PackedScene = null
	match kind:
		"inn":   scene = briarwood_inn_interior
		"shop":  scene = briarwood_shop_interior
		"smith": scene = briarwood_smith_interior
	_exterior_return_pos = player.global_position
	_interior_kind = kind

	if _interior_root and is_instance_valid(_interior_root):
		_interior_root.queue_free()

	if scene == null:
		if interior_fallback_builders_enabled:
			_interior_root = _build_interior_fallback(kind)
		else:
			_try_toast("Interior not set in Inspector.")
			_transition_fade(false, transition_fade_time)
			return
	else:
		_interior_root = scene.instantiate() as Node3D

	if _interior_root == null:
		_try_toast("Failed to load interior.")
		_transition_fade(false, transition_fade_time)
		return

	_interior_root.name = "Interior_%s" % kind
	add_child(_interior_root)

	var spawn := _interior_root.find_child("Spawn", true, false)
	if spawn and spawn is Node3D:
		player.global_position = (spawn as Node3D).global_position + Vector3(0, 0.02, 0)
	else:
		player.global_position = _interior_root.global_position + Vector3(0, 0.02, 0)

	_interior_register_points()
	_interior_audio_enter(kind)
	_transition_fade(false, transition_fade_time)
	_try_toast("Entered %s — press E on the exit to leave." % kind)


func _exit_interior(player: Node3D) -> void:
	if player == null or not is_instance_valid(player):
		return

	_call_world_sfx("door_open")
	_transition_fade(true, transition_fade_time)
	await get_tree().create_timer(maxf(0.05, transition_fade_time)).timeout

	if _interior_root and is_instance_valid(_interior_root):
		_interior_root.queue_free()
	_interior_root = null
	_interior_kind = ""
	player.global_position = _exterior_return_pos + Vector3(0, 0.02, 0)
	_interior_audio_exit()
	_transition_fade(false, transition_fade_time)
	_try_toast("Back outside.")


# ============================================================================
# Phase 18A — Interior fallback builders
# ============================================================================

func _build_interior_fallback(kind: String) -> Node3D:
	var root := Node3D.new()
	root.name = "InteriorFallback_%s" % kind

	# Floor
	var floor_mi := MeshInstance3D.new()
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(16, 0.25, 14)
	floor_mi.mesh = floor_mesh
	floor_mi.material_override = MAT_WOOD(3.0)
	floor_mi.position.y = -0.12
	root.add_child(floor_mi)

	# Walls shell (hollow shell — just ceiling for collision)
	var wall_mi := MeshInstance3D.new()
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(16.4, 0.25, 14.4)
	wall_mi.mesh = wall_mesh
	wall_mi.material_override = MAT_STONE(2.0)
	wall_mi.position.y = 4.25
	root.add_child(wall_mi)

	# Spawn point
	var spawn := Node3D.new()
	spawn.name = "Spawn"
	spawn.position = Vector3(0, 0.5, 5.0)
	root.add_child(spawn)

	# Exit door interactable
	var exit_node := Node3D.new()
	exit_node.name = "ExitDoor"
	exit_node.position = Vector3(0, 0, 6.5)
	root.add_child(exit_node)
	_register_interactable(exit_node, "exit_interior")

	match kind:
		"inn":   _build_inn_contents(root)
		"shop":  _build_shop_contents(root)
		"smith": _build_smith_contents(root)

	return root


func _build_inn_contents(root: Node3D) -> void:
	# Counter
	root.add_child(_box_prop(Vector3(0, 0, 1.0), Vector3(6.0, 1.0, 1.2), "Counter", MAT_DARK_WOOD(1.5)))

	# Tables + stools
	for p in [Vector3(-4.0, 0, -1.5), Vector3(3.5, 0, -2.0), Vector3(-2.0, 0, -4.0)]:
		root.add_child(_box_prop(p, Vector3(2.2, 0.9, 1.6), "Table", MAT_WOOD(2.0)))

	# Fireplace
	root.add_child(_box_prop(Vector3(-6.5, 0, -5.0), Vector3(2.0, 1.6, 1.4), "Fireplace", MAT_STONE(2.0)))

	# Bed — interactable
	var bed: Node3D = _box_prop(Vector3(6.0, 0, -4.5), Vector3(2.2, 0.7, 3.0), "Bed", MAT_ROOF(2.0))
	root.add_child(bed)
	_register_interactable(bed, "inn_bed")

	# Small lantern on counter
	root.add_child(_make_bw_lantern_post(Vector3(2.5, 1.0, 1.0)))


func _build_shop_contents(root: Node3D) -> void:
	# Counter
	root.add_child(_box_prop(Vector3(0, 0, 1.0), Vector3(6.0, 1.0, 1.2), "Counter", MAT_DARK_WOOD(1.5)))

	# Shelves lining back wall
	for x in [-6.0, -4.0, -2.0, 0.0, 2.0, 4.0, 6.0]:
		root.add_child(_box_prop(Vector3(x, 0.6, -5.5), Vector3(1.2, 2.0, 0.5), "Shelf", MAT_WOOD(2.0)))

	# Merchant interactable spot
	var npc_spot := Node3D.new()
	npc_spot.name = "MerchantInside"
	npc_spot.position = Vector3(0, 0, 0.2)
	root.add_child(npc_spot)
	_register_interactable(npc_spot, "merchant_shop")


func _build_smith_contents(root: Node3D) -> void:
	# Anvil — interactable (opens smith shop)
	var anvil: Node3D = _box_prop(Vector3(2.5, 0, 1.0), Vector3(1.4, 0.9, 1.0), "Anvil", MAT_STONE(2.0))
	root.add_child(anvil)
	_register_interactable(anvil, "smith_shop")

	# Forge block
	root.add_child(_box_prop(Vector3(-5.5, 0, -4.0), Vector3(3.0, 1.6, 2.4), "Forge", MAT_STONE(2.0)))

	# Tool racks
	for x in [-6.0, -4.0, -2.0]:
		root.add_child(_box_prop(Vector3(x, 0.6, 5.5), Vector3(1.0, 2.0, 0.5), "ToolRack", MAT_DARK_WOOD(1.5)))


func _box_prop(pos: Vector3, size: Vector3, prop_name: String, mat: StandardMaterial3D = null) -> Node3D:
	var n := Node3D.new()
	n.name = prop_name
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	if mat != null:
		mi.material_override = mat
	mi.position = Vector3(0, size.y * 0.5, 0)
	n.add_child(mi)
	n.position = pos
	return n


# ============================================================================
# Phase 18B — Inn Rest/Save
# ============================================================================

func _inn_rest_and_save(player: Node3D) -> void:
	if player == null or not is_instance_valid(player):
		return
	if "hp" in player and "max_hp" in player:
		player.hp = player.max_hp
	if "mp" in player and "max_mp" in player:
		player.mp = player.max_mp
	if player.has_signal("stats_changed"):
		player.stats_changed.emit()
	get_tree().call_group("world", "save_game")
	# Optional: skip to morning
	if town_schedule_enabled:
		_town_time = 0.28
	_try_toast("Rested. Fully healed and saved.")
	_call_world_sfx("rest")


# ============================================================================
# Phase 18C — Dialog system
# ============================================================================

func _ensure_dialog_ui() -> void:
	if _dlg_layer and is_instance_valid(_dlg_layer):
		return

	_dlg_layer = CanvasLayer.new()
	_dlg_layer.name = "DialogUI"
	_dlg_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_dlg_layer)

	_dlg_panel = Panel.new()
	_dlg_panel.name = "DialogPanel"
	_dlg_panel.visible = false
	_dlg_panel.size = Vector2(820, 260)
	_dlg_panel.position = Vector2(40, get_viewport().get_visible_rect().size.y - 300)
	_dlg_layer.add_child(_dlg_panel)

	var outer := VBoxContainer.new()
	outer.anchor_right  = 1.0
	outer.anchor_bottom = 1.0
	outer.offset_left   = 16
	outer.offset_top    = 14
	outer.offset_right  = -16
	outer.offset_bottom = -14
	_dlg_panel.add_child(outer)

	_dlg_title = Label.new()
	_dlg_title.add_theme_font_size_override("font_size", 20)
	outer.add_child(_dlg_title)

	_dlg_text = RichTextLabel.new()
	_dlg_text.bbcode_enabled = true
	_dlg_text.fit_content = true
	_dlg_text.custom_minimum_size = Vector2(0, 80)
	outer.add_child(_dlg_text)

	_dlg_choices = VBoxContainer.new()
	outer.add_child(_dlg_choices)


func show_dialog(player: Node3D, speaker: String, text: String, choices: Array) -> void:
	_ensure_dialog_ui()
	_dlg_player = player
	_dlg_title.text = speaker
	_dlg_text.text  = text

	for c in _dlg_choices.get_children():
		c.queue_free()

	for ch in choices:
		if not (ch is Dictionary):
			continue
		var btn := Button.new()
		btn.text = str(ch.get("label", "..."))
		var act = ch.get("action", null)
		btn.pressed.connect(func():
			_hide_dialog()
			if act is Callable:
				act.call()
		)
		_dlg_choices.add_child(btn)

	_dlg_panel.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if player and player.has_method("set_cinematic_lock"):
		player.call("set_cinematic_lock", true)
	_call_world_sfx("dialog")


func _hide_dialog() -> void:
	if _dlg_panel and is_instance_valid(_dlg_panel):
		_dlg_panel.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if _dlg_player and is_instance_valid(_dlg_player) and _dlg_player.has_method("set_cinematic_lock"):
		_dlg_player.call("set_cinematic_lock", false)
	_dlg_player = null


# ============================================================================
# Phase 18D — NPC quest helper (innkeeper delivery offer)
# ============================================================================

func _innkeeper_offer_delivery(player: Node3D) -> void:
	if player == null or not is_instance_valid(player):
		return
	if "active_quest" in player and player.active_quest is Dictionary and player.active_quest.size() > 0:
		_try_toast("Finish your current task first.")
		return
	var qdef := _qb_find_def("bw_deliver_crate_nordic")
	if qdef.is_empty():
		_try_toast("No deliveries today.")
		return
	var q := qdef.get("quest", {}) as Dictionary
	var inv = player.get("inventory") if "inventory" in player else null
	if inv != null and inv.has_method("add_item"):
		inv.add_item("supply_crate", 1)
	if player.has_method("accept_quest"):
		player.call("accept_quest", q)
		_try_toast("Take that crate to the Harbor Master at the Nordic docks.")


# ============================================================================
# Phase 20A — Fade transition controller
# ============================================================================

func _ensure_fade() -> void:
	if _fade_layer and is_instance_valid(_fade_layer):
		return
	_fade_layer = CanvasLayer.new()
	_fade_layer.name = "FadeLayer"
	_fade_layer.layer = 128  # render on top of everything
	_fade_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_fade_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.name = "FadeRect"
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.anchor_right  = 1.0
	_fade_rect.anchor_bottom = 1.0
	_fade_rect.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(_fade_rect)


func _transition_fade(fade_out: bool, seconds: float) -> void:
	if not transitions_enabled:
		return
	_ensure_fade()
	if _fade_tween and is_instance_valid(_fade_tween):
		_fade_tween.kill()
	_fade_tween = create_tween()
	var target_a := 1.0 if fade_out else 0.0
	_fade_tween.tween_property(_fade_rect, "color:a", target_a, maxf(0.05, seconds)) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# ============================================================================
# Phase 20B — Interior audio controller
# ============================================================================

func _ensure_music_player() -> void:
	if _music_player and is_instance_valid(_music_player):
		return
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Music"
	add_child(_music_player)


func _set_music(stream: AudioStream, id: String) -> void:
	if not interior_audio_enabled or stream == null:
		return
	_ensure_music_player()
	if _current_music_id == id and _music_player.playing:
		return
	_music_player.stream = stream
	_music_player.play()
	_current_music_id = id


func _interior_audio_enter(kind: String) -> void:
	if not interior_audio_enabled:
		return
	match kind:
		"inn":   _set_music(music_inn,   "inn")
		"shop":  _set_music(music_shop,  "shop")
		"smith": _set_music(music_smith, "smith")


func _interior_audio_exit() -> void:
	_set_music(music_outside, "outside")


# ============================================================================
# Phase 20B — Interior interactable registration helper
# ============================================================================

func _interior_register_points() -> void:
	if _interior_root == null or not is_instance_valid(_interior_root):
		return
	var exit := _interior_root.find_child("ExitDoor", true, false)
	if exit and exit is Node3D:
		_register_interactable(exit as Node3D, "exit_interior")
	var bed := _interior_root.find_child("Bed", true, false)
	if bed and bed is Node3D:
		_register_interactable(bed as Node3D, "inn_bed")
	var merchant := _interior_root.find_child("MerchantSpot", true, false)
	if merchant and merchant is Node3D:
		_register_interactable(merchant as Node3D, "merchant_shop")
	var anvil := _interior_root.find_child("AnvilSpot", true, false)
	if anvil and anvil is Node3D:
		_register_interactable(anvil as Node3D, "smith_shop")


# ============================================================================
# Phase 20C — Minimap markers
# ============================================================================

func _register_minimap_marker(node: Node3D, label: String, icon: String = "●") -> void:
	if node == null or not is_instance_valid(node) or not minimap_markers_enabled:
		return
	node.set_meta("minimap_label", label)
	node.set_meta("minimap_icon",  icon)
	node.add_to_group("minimap_markers")

	var l := Label3D.new()
	l.text = "%s %s" % [icon, label]
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.pixel_size  = 0.003
	l.font_size   = 22
	l.outline_size = 6
	l.outline_modulate = Color(0, 0, 0, 1)
	l.modulate    = Color(1.0, 0.96, 0.55, 0.85)
	l.position    = Vector3(0, 2.2, 0)
	node.add_child(l)


# ============================================================================
# Phase 20D — Tutorial chain (first 10 minutes)
# ============================================================================

func _tutorial_start_if_needed() -> void:
	if not tutorial_enabled or _tutorial_done:
		return
	# Small delay so the world finishes building before the first hint fires
	await get_tree().create_timer(2.0).timeout
	if not tutorial_enabled or _tutorial_done:
		return
	# Phase 21 — cinematic intro fires once on very first load
	if mayor_intro_enabled and not _mayor_intro_ran:
		_run_mayor_intro()
		return  # intro ends with the board hint baked in
	_try_toast("Welcome to Briarwood! Check the Notice Board in the plaza.")


func _tutorial_on_event(ev: String) -> void:
	if not tutorial_enabled or _tutorial_done:
		return

	match _tutorial_step:
		0:
			# Phase 21 — intro acceptance moves player gently toward the board
			if ev == "_intro_accept":
				_safe_call("_intro_advance_to_board")
			elif ev == "board":
				_tutorial_step = 1
				_tutorial_last_progress_time = Time.get_ticks_msec() / 1000.0  # Phase 22
				_try_toast("Tutorial: Hit the training dummy 3 times.")
				_tutorial_assign_kill("training_dummy", 3, "Guard Captain")
		1:
			# Any event while on step 1 — check if kill quest is finished
			var p := _get_player()
			if p != null:
				var ready: bool = false
				if p.has_method("is_quest_ready_to_turn_in"):
					ready = bool(p.call("is_quest_ready_to_turn_in"))
				elif "active_quest" in p and p.active_quest is Dictionary:
					var aq: Dictionary = p.active_quest
					if str(aq.get("kind","")) == "kill":
						ready = int(aq.get("killed",0)) >= int(aq.get("needed",999))
				if ready:
					_tutorial_step = 2
					_tutorial_last_progress_time = Time.get_ticks_msec() / 1000.0  # Phase 22
					_try_toast("Nice form! Rest at the Inn bed to recover.")
		2:
			if ev == "rest":
				_tutorial_step = 3
				_tutorial_last_progress_time = Time.get_ticks_msec() / 1000.0  # Phase 22
				_try_toast("Visit the Smith and browse upgrades.")
		3:
			if ev == "smith":
				_tutorial_step = 4
				_tutorial_last_progress_time = Time.get_ticks_msec() / 1000.0  # Phase 22
				_try_toast("Take the boat to Nordic Harbor.")
		4:
			if ev == "boat":
				_tutorial_step = 5
				_tutorial_last_progress_time = Time.get_ticks_msec() / 1000.0  # Phase 22
				_try_toast("Talk to the Harbor Master at the docks.")
		5:
			if ev == "harbor_master":
				_tutorial_done = true
				_tutorial_step = 6
				_tutorial_last_progress_time = Time.get_ticks_msec() / 1000.0  # Phase 22
				_clear_tutorial_trail()
				_hide_tutorial_arrow()
				_try_toast("Tutorial complete! Briarwood is yours to explore.")
				_call_world_sfx("quest_complete")


func _tutorial_assign_kill(target: String, needed: int, giver: String) -> void:
	var p := _get_player()
	if p == null or not is_instance_valid(p) or not p.has_method("accept_quest"):
		return
	if ("active_quest" in p) and (p.active_quest is Dictionary) and p.active_quest.size() > 0:
		return  # don't clobber an existing quest
	p.call("accept_quest", {
		"kind": "kill", "target": target,
		"needed": needed, "giver": giver,
		"gold_reward": 0, "xp_reward": 0,
	})


# ============================================================================
# Phase 21A — Cinematic Mayor Intro
# ============================================================================
# Plays on first load (or first Mayor interaction if auto-fire is missed).
# Uses the existing show_dialog + toast infrastructure — no new UI nodes.
# Sequence: fade-in black → Mayor greeting panel → choice to accept tutorial
# quest or skip. After dismissal the tutorial toast fires as normal.
#
# The sequence is intentionally non-blocking for the rest of the world:
# it uses `await` inside the coroutine but the caller (_tutorial_start_if_needed
# or _mayor_talk) simply calls it and moves on. Any panel click calls
# _hide_dialog() which clears the lock before the next await completes.
# ============================================================================

func _run_mayor_intro() -> void:
	if not mayor_intro_enabled:
		return
	if _mayor_intro_ran:
		return
	_mayor_intro_ran = true

	var player := _get_player()
	if player == null:
		# World isn't ready yet — reschedule once more
		await get_tree().create_timer(1.0).timeout
		player = _get_player()
		if player == null:
			_try_toast("Welcome to Briarwood. Check the Notice Board.")
			return

	# ── 1. Lock movement briefly ─────────────────────────────────────────────
	if player.has_method("set_cinematic_lock"):
		player.call("set_cinematic_lock", true)

	# ── 2. Ensure screen is visible (fade in if needed) ─────────────────────
	_transition_fade(false, 0.25)

	# ── 3. Title card toast ──────────────────────────────────────────────────
	_try_toast("⚜  Briarwood — Home Village  ⚜")

	# ── 4. Soft walk toward plaza (tween position, doesn't fight physics) ────
	var plaza  := briarwood_origin + bw_plaza_offset
	var target: Vector3 = Vector3(plaza.x, player.global_position.y, plaza.z - 2.0)
	var start  := player.global_position
	var walk_dur := 1.8
	var tw := create_tween()
	tw.tween_property(player, "global_position",
		Vector3(target.x, start.y, target.z), walk_dur) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await get_tree().create_timer(walk_dur + 0.1).timeout

	# ── 5. Mayor greeting dialog ─────────────────────────────────────────────
	# Lambdas hoisted to local vars — multi-statement func() inside nested
	# dict/array causes GDScript "Unindent doesn't match" parse error.
	var _dlg_intro_accept := func():
		_try_toast("Mayor: Start at the Notice Board — it keeps the village's troubles sorted.")
		_tutorial_step = 0
		_tutorial_on_event("_intro_accept")
	var _dlg_board_now := func():
		_tutorial_step = 0
		_show_quest_board_ui(player)
		_tutorial_on_event("board")
	var _dlg_skip_tour := func():
		_tutorial_done = true
		_clear_tutorial_trail()
		_hide_tutorial_arrow()
		_try_toast("Mayor: Fair enough. Briarwood's yours to explore.")
	show_dialog(
		player,
		"Mayor Aldric",
		"Welcome to Briarwood.\n\n" \
		+ "Merchants from the coast, rangers from the north, trouble from " \
		+ "everywhere else — this village has seen it all.\n\n" \
		+ "I'd feel better knowing you can handle yourself before I point " \
		+ "you toward the harbor road.",
		[
			{"label": "Got it — what do you need?",        "action": _dlg_intro_accept},
			{"label": "Open Notice Board now",             "action": _dlg_board_now},
			{"label": "I know Briarwood — skip the tour.", "action": _dlg_skip_tour},
		]
	)

	# ── 6. Unlock after a short delay (dialog system unlocks too on close) ───
	await get_tree().create_timer(0.5).timeout
	if player != null and is_instance_valid(player):
		if player.has_method("set_cinematic_lock"):
			player.call("set_cinematic_lock", false)


# ── Tutorial-step advance triggered by intro acceptance ────────────────────
# Called when the player picks "I'm ready" in the intro dialog.
# We re-use _tutorial_on_event but need a dedicated event string so the
# normal board/boat events don't accidentally advance the intro mid-flight.
# The function simply ensures step 0 is active and shows the board hint.

func _intro_advance_to_board() -> void:
	if _tutorial_done:
		return
	_tutorial_step = 0
	await get_tree().create_timer(1.2).timeout
	if not _tutorial_done:
		_try_toast("Hint: Walk up to the Notice Board and press E.")


# ── Patch _tutorial_on_event to also accept "_intro_accept" ─────────────────
# We override the event check inline: if the intro fires "_intro_accept"
# we kick off the board-hint delay so the flow reads naturally.
# (This extends the existing function via a call — no duplicate match needed.)

func _intro_accept_chain() -> void:
	_safe_call("_intro_advance_to_board")


# ============================================================================
# Phase 22A — Tutorial polish init + tick
# ============================================================================

func _init_tutorial_polish() -> void:
	if _tutorial_tick_timer and is_instance_valid(_tutorial_tick_timer):
		_tutorial_tick_timer.queue_free()

	_tutorial_tick_timer = Timer.new()
	_tutorial_tick_timer.name = "TutorialPolishTick"
	_tutorial_tick_timer.wait_time = 0.5
	_tutorial_tick_timer.one_shot = false
	_tutorial_tick_timer.autostart = true
	_tutorial_tick_timer.timeout.connect(_tick_tutorial_polish)
	add_child(_tutorial_tick_timer)

	_tutorial_last_progress_time = Time.get_ticks_msec() / 1000.0
	_ensure_tutorial_arrow()
	_ensure_tutorial_trail()


func _tick_tutorial_polish() -> void:
	if not tutorial_enabled or _tutorial_done:
		_hide_tutorial_arrow()
		_clear_tutorial_trail()
		return

	var player := _get_player()
	if player == null:
		return

	# Update objective arrow
	_update_tutorial_arrow_target()
	_update_tutorial_arrow_visual(player)

	# Sparkle breadcrumb trail
	if tutorial_trail_enabled:
		_tick_tutorial_trail(player)

	# NPC proximity barks
	if tutorial_barks_enabled:
		_tick_tutorial_barks(player)

	# Fail-safe hints + auto-help
	if tutorial_failsafe_enabled:
		_tick_tutorial_failsafe(player)


# ============================================================================
# Phase 22B — Objective Arrow
# ============================================================================

func _ensure_tutorial_arrow() -> void:
	if _arrow_root and is_instance_valid(_arrow_root):
		return

	_arrow_root = Node3D.new()
	_arrow_root.name = "TutorialArrow"
	add_child(_arrow_root)

	# Downward-pointing cone (CylinderMesh with top_radius=0 = cone)
	_arrow_mesh = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius    = 0.0
	cm.bottom_radius = 0.28
	cm.height        = 0.55
	_arrow_mesh.mesh = cm
	_arrow_mesh.rotation_degrees.x = 180.0   # tip points down
	_arrow_root.add_child(_arrow_mesh)

	# Material — golden, unshaded so it reads against any background
	var mat := StandardMaterial3D.new()
	mat.albedo_color         = Color(1.0, 0.85, 0.15)
	mat.emission_enabled     = true
	mat.emission             = Color(0.9, 0.65, 0.05)
	mat.emission_energy_multiplier = 0.9
	mat.shading_mode         = BaseMaterial3D.SHADING_MODE_UNSHADED
	_arrow_mesh.material_override = mat

	# Label below the arrow
	_arrow_label = Label3D.new()
	_arrow_label.text           = ""
	_arrow_label.billboard      = BaseMaterial3D.BILLBOARD_ENABLED
	_arrow_label.no_depth_test  = true
	_arrow_label.pixel_size     = 0.0035
	_arrow_label.font_size      = 26
	_arrow_label.outline_size   = 8
	_arrow_label.outline_modulate = Color(0, 0, 0, 1)
	_arrow_label.modulate       = Color(1.0, 0.95, 0.30)
	_arrow_label.position       = Vector3(0, 0.9, 0)
	_arrow_root.add_child(_arrow_label)

	_arrow_root.visible = false


func _hide_tutorial_arrow() -> void:
	if _arrow_root and is_instance_valid(_arrow_root):
		_arrow_root.visible = false


func _update_tutorial_arrow_target() -> void:
	# Pick the interactable node the player should visit next
	match _tutorial_step:
		0: _arrow_target = _find_first_interactable_kind("quest_board")
		1: _arrow_target = _find_first_interactable_kind("training_dummy")
		2: _arrow_target = _find_first_interactable_kind("inn_bed")
		3: _arrow_target = _find_first_interactable_kind("smith_shop")
		4: _arrow_target = _find_first_interactable_kind("boat_travel")
		5: _arrow_target = _find_first_interactable_kind("harbor_master")
		_: _arrow_target = null


func _update_tutorial_arrow_visual(player: Node3D) -> void:
	if not tutorial_arrow_enabled:
		_hide_tutorial_arrow()
		return
	if _arrow_root == null or not is_instance_valid(_arrow_root):
		_ensure_tutorial_arrow()
		return
	if _arrow_target == null or not is_instance_valid(_arrow_target):
		_arrow_root.visible = false
		return

	_arrow_root.visible = true

	# Hover above the target + sinusoidal bob
	var t   := Time.get_ticks_msec() / 1000.0
	var bob := sin(t * 2.6) * 0.18
	_arrow_root.global_position = _arrow_target.global_position + Vector3(0, 3.2 + bob, 0)

	# Rotate toward player (cosmetic orientation only)
	var to_player := player.global_position - _arrow_root.global_position
	to_player.y = 0.0
	if to_player.length_squared() > 0.0001:
		_arrow_root.rotation.y = atan2(to_player.x, to_player.z)

	# Fade out when the player is very close (< 3 m) — avoids visual clutter
	var dist: float = player.global_position.distance_to(_arrow_target.global_position)
	var alpha := clampf(remap(dist, 1.5, 5.0, 0.0, 1.0), 0.0, 1.0)
	_arrow_root.modulate = Color(1, 1, 1, alpha)

	# Update the objective label text
	_arrow_label.text = _tutorial_objective_text()


func _tutorial_objective_text() -> String:
	match _tutorial_step:
		0: return "Notice Board"
		1: return "Training Dummy"
		2: return "Rest at Inn"
		3: return "Visit Smith"
		4: return "Boat to Harbor"
		5: return "Harbor Master"
	return ""


# ============================================================================
# Phase 22C — NPC Barks (proximity + per-NPC cooldown)
# ============================================================================

func _tick_tutorial_barks(player: Node3D) -> void:
	var now := Time.get_ticks_msec() / 1000.0

	_bark_if_close(player, _find_first_interactable_kind("mayor"),     "mayor",     now)
	_bark_if_close(player, _find_first_interactable_kind("innkeeper"),  "innkeeper", now)
	_bark_if_close(player, _find_first_interactable_kind("smith_shop"), "smith",     now)
	_bark_if_close(player, _find_first_interactable_kind("quest_board"),"board",     now)


func _bark_if_close(player: Node3D, npc: Node3D, key: String, now: float) -> void:
	if npc == null or not is_instance_valid(npc):
		return
	var cd_key := "bark|" + key
	if float(_bark_cd.get(cd_key, 0.0)) > now:
		return
	if player.global_position.distance_to(npc.global_position) > 6.0:
		return

	var line := ""
	match key:
		"board":
			match _tutorial_step:
				0: line = "Read the board — it will give you a task."
		"mayor":
			match _tutorial_step:
				0: line = "The Notice Board keeps the village sorted. Start there."
				1: line = "Show those dummies what you're made of."
				2: line = "Rest up — the Inn bed is just inside."
				4, 5: line = "You're doing well, traveller."
		"innkeeper":
			match _tutorial_step:
				2: line = "Beds are warm. A short rest does wonders."
				3, 4, 5: line = "Safe travels whenever you need a room."
		"smith":
			match _tutorial_step:
				3: line = "Glad you came — let's see what your kit needs."
				4, 5: line = "Bring iron ingots next time for an upgrade."

	if line == "":
		return

	_try_toast(line)
	_bark_cd[cd_key] = now + 18.0   # 18-second cooldown per NPC


# ============================================================================
# Phase 22D — Fail-Safe (hint after 2 min, auto-help after 5 min)
# ============================================================================

func _tick_tutorial_failsafe(player: Node3D) -> void:
	var now  := Time.get_ticks_msec() / 1000.0
	var idle := now - _tutorial_last_progress_time

	# ── 1. Gentle hint (120 s) — toast + point arrow, once per 60 s ──────────
	if idle >= tutorial_hint_after_sec and idle < tutorial_autofix_after_sec:
		var cd := float(_bark_cd.get("failsafe_hint", 0.0))
		if now > cd:
			_bark_cd["failsafe_hint"] = now + 60.0
			_try_toast("Hint: Head to " + _tutorial_objective_text() + ".")
		return

	# ── 2. Auto-help (300 s) — open UI or nudge, once per 120 s ─────────────
	if idle >= tutorial_autofix_after_sec:
		var cd2 := float(_bark_cd.get("failsafe_fix", 0.0))
		if now <= cd2:
			return
		_bark_cd["failsafe_fix"] = now + 120.0
		_try_toast("Need a hand? Opening the next step…")

		# Sparkle trail re-emphasis — show a fresh trail burst then toast the step.
		# For the two UI-triggerable steps we still open the panel; for everything
		# else the trail + toast is enough and avoids yanking control.
		# Sparkle trail re-emphasis — show a fresh trail burst then toast the step.
		# For the two UI-triggerable steps we still open the panel; for everything
		# else the trail + toast is enough and avoids yanking control.
		match _tutorial_step:
			0:
				_show_quest_board_ui(player)
			4:
				_show_boat_travel_ui(player)
			_:
				_try_toast("Follow the sparkles to " + _tutorial_objective_text() + "!")
				# Force an immediate trail rebuild so the path is freshly visible
				_trail_last_update = 0.0


# ============================================================================
# Phase 22B — Sparkle breadcrumb trail
# ============================================================================

func _ensure_tutorial_trail() -> void:
	if _trail_root and is_instance_valid(_trail_root):
		return
	_trail_root = Node3D.new()
	_trail_root.name = "TutorialTrail"
	add_child(_trail_root)


func _clear_tutorial_trail() -> void:
	if _trail_root and is_instance_valid(_trail_root):
		_trail_root.queue_free()
	_trail_root = null


func _tick_tutorial_trail(player: Node3D) -> void:
	if not tutorial_trail_enabled:
		return
	if _trail_root == null or not is_instance_valid(_trail_root):
		_ensure_tutorial_trail()
		return  # spawned fresh — nothing to clear yet

	var now := Time.get_ticks_msec() / 1000.0
	if now - _trail_last_update < tutorial_trail_update_sec:
		return
	_trail_last_update = now

	if _arrow_target == null or not is_instance_valid(_arrow_target):
		_trail_root.visible = false
		return

	_trail_root.visible = true

	# Remove previous pip nodes (they self-queue_free via cleanup timers too,
	# but clearing here prevents a one-frame overlap on fast updates)
	for c in _trail_root.get_children():
		c.queue_free()

	var start := player.global_position
	var end   := _arrow_target.global_position
	var dir   := end - start
	dir.y = 0.0
	var dist: float = dir.length()
	if dist < 1.2:
		return   # player is already right on top of the target
	dir = dir.normalized()

	# Side vector for organic jitter
	var side: Vector3 = dir.rotated(Vector3.UP, PI * 0.5)

	var count := clampi(tutorial_trail_count, 4, 18)
	var step  := clampf(tutorial_trail_step, 0.9, 3.0)

	for i in range(count):
		var t := float(i + 1) * step
		if t > dist:
			break
		var p := start + dir * t
		p.y = start.y + tutorial_trail_height

		# Subtle sinusoidal weave — unique phase per pip so they're staggered
		var jitter := sin(now * 1.8 + float(i) * 0.9) * 0.25
		p += side * jitter

		# Fade size: pips near the player are smaller (less obtrusive)
		var size_scale := 0.55 + float(i) * 0.06

		_trail_root.add_child(_make_sparkle_pip(p, size_scale))


func _make_sparkle_pip(pos: Vector3, size: float) -> Node3D:
	var n := Node3D.new()
	n.global_position = pos

	var gpu := GPUParticles3D.new()
	gpu.amount        = 10
	gpu.lifetime      = 0.55
	gpu.one_shot      = true
	gpu.emitting      = true
	gpu.visibility_aabb = AABB(Vector3(-2, -2, -2), Vector3(4, 4, 4))
	n.add_child(gpu)

	var mat := ParticleProcessMaterial.new()
	mat.direction              = Vector3(0, 1, 0)
	mat.spread                 = 35.0
	mat.gravity                = Vector3(0, -0.35, 0)
	mat.initial_velocity_min   = 0.35
	mat.initial_velocity_max   = 0.75
	mat.scale_min              = 0.10 * size
	mat.scale_max              = 0.22 * size
	mat.color                  = Color(1.0, 0.92, 0.55, 0.65)
	gpu.process_material = mat

	var quad := QuadMesh.new()
	quad.size = Vector2(0.25, 0.25)
	gpu.draw_pass_1 = quad

	# Self-cleaning timer — pip lives just long enough for one emission cycle
	var cleanup := Timer.new()
	cleanup.one_shot    = true
	cleanup.wait_time   = 0.8
	cleanup.autostart   = true
	cleanup.timeout.connect(func():
		if is_instance_valid(n):
			n.queue_free()
	)
	n.add_child(cleanup)

	return n


# ============================================================================
# Phase 24A — Street Dressing (fence/laundry/cart/clutter/plaza furniture)
# ============================================================================

# ── Material wrappers (bw_mat_stone already in Phase 23 kit) ─────────────────

func _bw_mat_fence() -> StandardMaterial3D:
	return MAT_DARK_WOOD(0.65)

func _bw_mat_clutter() -> StandardMaterial3D:
	return MAT_DARK_WOOD(0.55)


# ── Lazy-init mesh getters ────────────────────────────────────────────────────

func _bw_get_fence_post_mesh() -> CylinderMesh:
	if _bw_fence_post_mesh == null:
		_bw_fence_post_mesh = CylinderMesh.new()
		_bw_fence_post_mesh.top_radius    = 0.10
		_bw_fence_post_mesh.bottom_radius = 0.13
		_bw_fence_post_mesh.height        = 1.55
	return _bw_fence_post_mesh

func _bw_get_bench_mesh() -> BoxMesh:
	if _bw_bench_mesh == null:
		_bw_bench_mesh = BoxMesh.new()
		_bw_bench_mesh.size = Vector3(1.8, 0.45, 0.55)
	return _bw_bench_mesh

func _bw_get_crate_mesh() -> BoxMesh:
	if _bw_crate_mesh == null:
		_bw_crate_mesh = BoxMesh.new()
		_bw_crate_mesh.size = Vector3(0.6, 0.45, 0.6)
	return _bw_crate_mesh

func _bw_get_barrel_mesh() -> CylinderMesh:
	if _bw_barrel_mesh == null:
		_bw_barrel_mesh = CylinderMesh.new()
		_bw_barrel_mesh.top_radius    = 0.22
		_bw_barrel_mesh.bottom_radius = 0.26
		_bw_barrel_mesh.height        = 0.80
	return _bw_barrel_mesh

func _bw_get_woodpile_mesh() -> BoxMesh:
	if _bw_woodpile_mesh == null:
		_bw_woodpile_mesh = BoxMesh.new()
		_bw_woodpile_mesh.size = Vector3(1.3, 0.55, 0.9)
	return _bw_woodpile_mesh


# ── Main dressing entry point ─────────────────────────────────────────────────

func _dress_briarwood_v2(root: Node3D, plaza: Vector3, market: Vector3, craft: Vector3, gate: Vector3) -> void:
	_build_bw_plaza_furniture(root, plaza,  int(6  * bw_dressing_density))
	_build_bw_market_dressing(root, market, plaza, int(5 * bw_dressing_density))
	_build_bw_craft_dressing(root,  craft,  plaza, int(8 * bw_dressing_density))
	_build_bw_residential_dressing(root, plaza, int(18 * bw_dressing_density))
	_build_bw_gate_dressing(root, gate, plaza)


# ── Plaza furniture ───────────────────────────────────────────────────────────

func _build_bw_plaza_furniture(root: Node3D, plaza: Vector3, count: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for i in range(count):
		var ang    := TAU * float(i) / float(maxi(1, count))
		var p: Vector3 = plaza + Vector3(cos(ang), 0.0, sin(ang)) * 8.8
		var facing: Vector3 = (plaza - p); facing.y = 0.0; facing = facing.normalized()
		var rot    := Basis(Vector3.UP, atan2(facing.x, facing.z))
		var xf: Transform3D = Transform3D(rot, p + Vector3(0.0, 0.22, 0.0))

		if bw_multimesh_enabled and bw_mm_benches:
			_mm_add(root, _bw_get_bench_mesh(), _bw_mat_fence(), xf, 64)
		else:
			root.add_child(_make_bw_bench_node(p, facing))

	# Stone planters scattered across plaza
	for i in range(int(4 * bw_dressing_density)):
		var p2: Vector3 = plaza + Vector3(rng.randf_range(-6.0, 6.0), 0.0, rng.randf_range(-6.0, 6.0))
		var pot := MeshInstance3D.new()
		var cm  := CylinderMesh.new()
		cm.top_radius    = 0.75
		cm.bottom_radius = 0.85
		cm.height        = 0.55
		pot.mesh = cm
		pot.material_override = _bw_mat_stone()
		pot.global_position = p2 + Vector3(0.0, 0.28, 0.0)
		root.add_child(pot)


func _make_bw_bench_node(pos: Vector3, facing: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = "Bench"
	n.global_position = pos
	n.rotation.y = atan2(facing.x, facing.z)
	var m := MeshInstance3D.new()
	m.mesh = _bw_get_bench_mesh()
	m.position.y = 0.22
	m.material_override = _bw_mat_fence()
	n.add_child(m)
	return n


# ── Market dressing ───────────────────────────────────────────────────────────

func _build_bw_market_dressing(root: Node3D, market: Vector3, plaza: Vector3, count: int) -> void:
	var rng  := RandomNumberGenerator.new()
	rng.randomize()
	var dir: Vector3 = (plaza - market); dir.y = 0.0; dir = dir.normalized()
	var side: Vector3 = dir.rotated(Vector3.UP, PI * 0.5)

	# Carts parked near market
	for i in range(count):
		var p: Vector3 = market + side * rng.randf_range(-12.0, 12.0) + dir * rng.randf_range(-3.0, 7.0)
		root.add_child(_make_bw_cart(p, -dir))

	# Free-standing hanging signboards
	for i in range(int(6 * bw_dressing_density)):
		var p2: Vector3 = market + side * rng.randf_range(-14.0, 14.0) + dir * rng.randf_range(-5.0, 5.0)
		var post := Node3D.new()
		post.global_position = p2
		root.add_child(post)
		_bw_add_signboard(post, Vector3.ZERO, "MARKET" if rng.randf() < 0.5 else "GOODS")

	# Extra clutter scatter over market area
	for i in range(int(20 * bw_dressing_density)):
		var p3: Vector3 = market + side * rng.randf_range(-18.0, 18.0) + dir * rng.randf_range(-8.0, 10.0)
		_bw_place_clutter(root, p3, rng)


func _make_bw_cart(pos: Vector3, facing: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = "Cart"
	n.global_position = pos
	n.rotation.y = atan2(facing.x, facing.z)

	var bed := MeshInstance3D.new()
	var bm  := BoxMesh.new()
	bm.size = Vector3(1.6, 0.5, 2.4)
	bed.mesh = bm
	bed.position.y = 0.25
	bed.material_override = _bw_mat_fence()
	n.add_child(bed)

	for sx in [-0.85, 0.85]:
		for sz in [-1.0, 1.0]:
			var w   := MeshInstance3D.new()
			var wcm := CylinderMesh.new()
			wcm.top_radius    = 0.26
			wcm.bottom_radius = 0.26
			wcm.height        = 0.14
			w.mesh = wcm
			w.rotation_degrees.x = 90.0
			w.position = Vector3(sx, 0.26, sz)
			w.material_override = _bw_mat_fence()
			n.add_child(w)

	return n


# ── Craft yard dressing ───────────────────────────────────────────────────────

func _build_bw_craft_dressing(root: Node3D, craft: Vector3, plaza: Vector3, count: int) -> void:
	var rng  := RandomNumberGenerator.new()
	rng.randomize()
	var dir: Vector3 = (plaza - craft); dir.y = 0.0; dir = dir.normalized()
	var side: Vector3 = dir.rotated(Vector3.UP, PI * 0.5)

	# Fence line defining yard boundary
	_build_bw_fence_line(root, craft + side * 8.0 + dir * -4.0,
								craft + side * 8.0 + dir *  10.0)

	# Yard clutter scatter
	for i in range(count):
		var p: Vector3 = craft + side * rng.randf_range(-10.0, 10.0) + dir * rng.randf_range(-6.0, 10.0)
		_bw_place_clutter(root, p, rng)

	# Chopping block (log stump)
	var block := MeshInstance3D.new()
	var bcm   := CylinderMesh.new()
	bcm.top_radius    = 0.55
	bcm.bottom_radius = 0.60
	bcm.height        = 0.55
	block.mesh = bcm
	block.material_override = _bw_mat_fence()
	block.global_position = craft + Vector3(5.0, 0.28, 6.0)
	root.add_child(block)


# ── Residential dressing ──────────────────────────────────────────────────────

func _build_bw_residential_dressing(root: Node3D, plaza: Vector3, count: int) -> void:
	var rng    := RandomNumberGenerator.new()
	rng.randomize()
	var ring_r := 30.0

	for i in range(count):
		var ang    := TAU * float(i) / float(maxi(1, count))
		var center: Vector3 = plaza + Vector3(cos(ang), 0.0, sin(ang)) * ring_r

		# Small yard fence segment
		var a: Vector3 = center + Vector3(rng.randf_range(-3.0, 3.0), 0.0, rng.randf_range(-3.0, 3.0))
		var b: Vector3 = a + Vector3(rng.randf_range(4.0, 8.0), 0.0, rng.randf_range(-2.0, 2.0))
		_build_bw_fence_line(root, a, b)

		# Laundry line (35% chance)
		if rng.randf() < 0.35:
			_build_bw_laundry_line(root, a + Vector3(0.0, 0.0, 2.0),
											a + Vector3(3.5, 0.0, 2.5), rng)

		# Yard clutter (55% chance)
		if rng.randf() < 0.55:
			_bw_place_clutter(root, center + Vector3(rng.randf_range(-4.0, 4.0), 0.0,
														rng.randf_range(-4.0, 4.0)), rng)


func _build_bw_laundry_line(root: Node3D, a: Vector3, b: Vector3, rng: RandomNumberGenerator) -> void:
	var mat := _bw_mat_fence()

	# Posts at each end
	for p in [a, b]:
		var post := MeshInstance3D.new()
		var pcm  := CylinderMesh.new()
		pcm.top_radius    = 0.07
		pcm.bottom_radius = 0.09
		pcm.height        = 1.9
		post.mesh = pcm
		post.material_override = mat
		post.global_position = p + Vector3(0.0, 0.95, 0.0)
		root.add_child(post)

	# Horizontal line beam
	var mid := (a + b) * 0.5
	var len: float = Vector2(b.x - a.x, b.z - a.z).length()
	var line := MeshInstance3D.new()
	var lbm  := BoxMesh.new()
	lbm.size = Vector3(0.05, 0.05, len)
	line.mesh = lbm
	line.material_override = mat
	line.global_position = mid + Vector3(0.0, 1.65, 0.0)
	line.rotation.y = atan2(b.x - a.x, b.z - a.z)
	root.add_child(line)

	# Cloth pieces hanging from line
	var cloth_n: int = rng.randi_range(2, 5)
	for i in range(cloth_n):
		var t   := float(i + 1) / float(cloth_n + 1)
		var cp: Vector3 = a.lerp(b, t) + Vector3(0.0, 1.55, 0.0)
		var cl  := MeshInstance3D.new()
		var cbm := BoxMesh.new()
		cbm.size = Vector3(0.35, 0.25, 0.03)
		cl.mesh = cbm
		var cm := StandardMaterial3D.new()
		cm.albedo_color = Color(rng.randf_range(0.4, 1.0),
								rng.randf_range(0.4, 1.0),
								rng.randf_range(0.4, 1.0))
		cl.material_override = cm
		cl.global_position = cp
		cl.rotation.y = rng.randf_range(-PI, PI)
		root.add_child(cl)


# ── Fence line builder (MultiMesh preferred) ──────────────────────────────────

func _build_bw_fence_line(root: Node3D, a: Vector3, b: Vector3) -> void:
	var mat := _bw_mat_fence()
	var dir := b - a; dir.y = 0.0
	var len: float = dir.length()
	if len < 0.5:
		return
	dir = dir.normalized()

	var post_spacing := 1.6
	var posts: int = int(ceil(len / post_spacing)) + 1

	for i in range(posts):
		var p  := a + dir * (float(i) * post_spacing)
		var xf: Transform3D = Transform3D(Basis.IDENTITY, p + Vector3(0.0, 0.78, 0.0))
		if bw_multimesh_enabled and bw_mm_fences:
			_mm_add(root, _bw_get_fence_post_mesh(), mat, xf, 256)
		else:
			var post := MeshInstance3D.new()
			post.mesh = _bw_get_fence_post_mesh()
			post.material_override = mat
			post.global_position = p + Vector3(0.0, 0.78, 0.0)
			root.add_child(post)

	# Two rails spanning the whole segment
	var rail_mesh := BoxMesh.new()
	rail_mesh.size = Vector3(0.10, 0.10, len)
	var mid := (a + b) * 0.5
	var yaw := atan2(b.x - a.x, b.z - a.z)
	var rot := Basis(Vector3.UP, yaw)
	for rail_y in [0.55, 1.05]:
		var xf2: Transform3D = Transform3D(rot, mid + Vector3(0.0, rail_y, 0.0))
		if bw_multimesh_enabled and bw_mm_fences:
			_mm_add(root, rail_mesh, mat, xf2, 128)
		else:
			var rail := MeshInstance3D.new()
			rail.mesh = rail_mesh
			rail.material_override = mat
			rail.global_position = mid + Vector3(0.0, rail_y, 0.0)
			rail.rotation.y = yaw
			root.add_child(rail)


# ── Generic clutter placer (MultiMesh preferred) ──────────────────────────────

func _bw_place_clutter(root: Node3D, p: Vector3, rng: RandomNumberGenerator) -> void:
	var mat  := _bw_mat_clutter()
	var kind: float = rng.randf()
	var rot: Basis = Basis(Vector3.UP, rng.randf_range(-PI, PI))

	if bw_multimesh_enabled and bw_mm_clutter:
		if kind < 0.45:
			_mm_add(root, _bw_get_barrel_mesh(),  mat, Transform3D(rot, p + Vector3(0.0, 0.40, 0.0)),  256)
		elif kind < 0.80:
			_mm_add(root, _bw_get_crate_mesh(),   mat, Transform3D(rot, p + Vector3(0.0, 0.225, 0.0)), 256)
		else:
			_mm_add(root, _bw_get_woodpile_mesh(), mat, Transform3D(rot, p + Vector3(0.0, 0.275, 0.0)), 128)
		return

	# Fallback node path
	var m := MeshInstance3D.new()
	if kind < 0.45:
		m.mesh = _bw_get_barrel_mesh()
		m.global_position = p + Vector3(0.0, 0.40, 0.0)
	elif kind < 0.80:
		m.mesh = _bw_get_crate_mesh()
		m.global_position = p + Vector3(0.0, 0.225, 0.0)
	else:
		m.mesh = _bw_get_woodpile_mesh()
		m.global_position = p + Vector3(0.0, 0.275, 0.0)
	m.material_override = mat
	m.rotation.y = rng.randf_range(-PI, PI)
	root.add_child(m)


# ── Gate dressing ─────────────────────────────────────────────────────────────

func _build_bw_gate_dressing(root: Node3D, gate: Vector3, plaza: Vector3) -> void:
	# Signpost beside the gate arch
	var sp := Node3D.new()
	sp.global_position = gate + Vector3(2.4, 0.0, 1.4)
	root.add_child(sp)
	_bw_add_signboard(sp, Vector3.ZERO, "BRIARWOOD")

	# Two flanking lantern posts
	root.add_child(_make_bw_lantern_post(gate + Vector3(-3.0, 0.0, 2.0)))
	root.add_child(_make_bw_lantern_post(gate + Vector3( 3.0, 0.0, 2.0)))


# ============================================================================
# Phase 24B — Real Village Layout (palisade, loop roads, farms)
# ============================================================================

func _build_bw_real_layout(root: Node3D, plaza: Vector3, gate: Vector3,
		market: Vector3, craft: Vector3, _townhall: Vector3) -> void:
	# 1. Elliptical palisade with gate gap + towers
	_build_bw_palisade(root, plaza, gate)

	# 2. Two loop roads
	var outer := _bw_loop_points(plaza,
		bw_palisade_radius_x * 0.84, bw_palisade_radius_z * 0.84, 28)
	var inner := _bw_loop_points(plaza,
		bw_palisade_radius_x * bw_inner_loop_scale,
		bw_palisade_radius_z * bw_inner_loop_scale, 22)

	for i in range(outer.size() - 1):
		_build_bw_cobble_strip(outer[i], outer[i + 1], root)
	for i in range(inner.size() - 1):
		_build_bw_cobble_strip(inner[i], inner[i + 1], root)

	# 3. Houses along both loop roads, facing the road
	_place_houses_along_loop(root, outer, 14, "residential")
	_place_houses_along_loop(root, inner, 12, "residential")

	# 4. Yard fence segments behind houses
	_build_bw_yards(root, outer)
	_build_bw_yards(root, inner)

	# 5. Farms outside the gate
	if bw_farm_enabled:
		_build_bw_farms(root, gate, plaza)


func _bw_loop_points(center: Vector3, rx: float, rz: float, n: int) -> Array[Vector3]:
	var pts: Array[Vector3] = []
	for i in range(n + 1):
		var t := TAU * float(i) / float(n)
		pts.append(center + Vector3(cos(t) * rx, 0.0, sin(t) * rz))
	return pts


# ── Cobble road strip (lightweight Briarwood version) ─────────────────────────

func _build_bw_cobble_strip(a: Vector3, b: Vector3, parent: Node3D) -> void:
	var dir := b - a; dir.y = 0.0
	var dist: float = dir.length()
	if dist < 0.5:
		return
	dir = dir.normalized()
	var steps := int(dist / 2.0)
	for i in range(steps + 1):
		var p   := a + dir * float(i) * 2.0
		var seg := MeshInstance3D.new()
		var bm  := BoxMesh.new()
		bm.size = Vector3(3.0, 0.12, 2.1)
		seg.mesh = bm
		seg.material_override = MAT_PATH(3.0)
		seg.global_position = p + Vector3(0.0, 0.02, 0.0)
		seg.rotation.y = atan2(dir.x, dir.z)
		parent.add_child(seg)


# ── Palisade with gate gap + towers ──────────────────────────────────────────

func _build_bw_palisade(root: Node3D, center: Vector3, gate: Vector3) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7331

	var mat       := _bw_mat_fence()
	var gate_dir: Vector3 = (gate - center); gate_dir.y = 0.0; gate_dir = gate_dir.normalized()
	var gate_yaw  := atan2(gate_dir.x, gate_dir.z)
	var half_gap  := (bw_gate_width / maxf(1.0, bw_palisade_radius_z)) * 0.5

	var post_n := 120
	for i in range(post_n):
		var t := TAU * float(i) / float(post_n)
		var p: Vector3 = center + Vector3(cos(t) * bw_palisade_radius_x,
									0.0,
									sin(t) * bw_palisade_radius_z)

		var yaw      := atan2((p - center).x, (p - center).z)
		var ang_diff: float = absf(wrapf(yaw - gate_yaw, -PI, PI))
		if ang_diff < half_gap:
			continue   # gate gap

		var h: float = rng.randf_range(2.4, 3.4)
		var xf: Transform3D = Transform3D(Basis.IDENTITY.scaled(Vector3(1.0, h / 1.55, 1.0)),
								p + Vector3(0.0, h * 0.5, 0.0))
		if bw_multimesh_enabled and bw_mm_fences:
			_mm_add(root, _bw_get_fence_post_mesh(), mat, xf, 512)
		else:
			var post := MeshInstance3D.new()
			var pcm  := CylinderMesh.new()
			pcm.top_radius    = 0.12
			pcm.bottom_radius = 0.16
			pcm.height        = h
			post.mesh = pcm
			post.material_override = mat
			post.global_position = p + Vector3(0.0, h * 0.5, 0.0)
			root.add_child(post)

	_build_bw_gate_towers(root, gate, gate_dir)


func _build_bw_gate_towers(root: Node3D, gate: Vector3, forward: Vector3) -> void:
	var side: Vector3 = forward.rotated(Vector3.UP, PI * 0.5)
	for s in [-1.0, 1.0]:
		var p: Vector3 = gate + side * (bw_gate_width * 0.55 * float(s))
		var tower := MeshInstance3D.new()
		var bm    := BoxMesh.new()
		bm.size = Vector3(2.2, 4.2, 2.2)
		tower.mesh = bm
		tower.global_position = p + Vector3(0.0, 2.1, 0.0)
		tower.material_override = _bw_mat_stone()
		root.add_child(tower)


# ── Houses along loop roads ───────────────────────────────────────────────────

func _place_houses_along_loop(root: Node3D, pts: Array[Vector3], count: int, zone: String = "residential") -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for i in range(count):
		var idx: int = int(rng.randi_range(0, pts.size() - 2))
		var a   := pts[idx]
		var b   := pts[idx + 1]

		# Tangent along road segment
		var road_dir := (b - a)
		road_dir.y = 0.0
		if road_dir.length() < 0.01:
			continue
		road_dir = road_dir.normalized()

		# Pick a point along segment (avoid endpoints)
		var mid: Vector3 = a.lerp(b, rng.randf_range(0.22, 0.78))

		# Choose which side of road
		var outward: Vector3 = road_dir.rotated(Vector3.UP, PI * 0.5)
		if rng.randf() < 0.5:
			outward = -outward

		# Decide house kind first so setback depends on it
		var kind    := _bw_pick_house_kind(zone, rng)
		var setback := _bw_setback_for_kind(kind)

		# Plot center offset from road by setback
		var plot_center := mid + outward * setback

		# Facing: toward road (inward = -outward)
		var facing := -outward

		# Build house
		var house := _bw_build_kind(kind, plot_center, facing, rng)
		root.add_child(house)

		# Auto yard behind house
		if bw_yard_fence_enabled:
			_bw_auto_yard_for_house(root, house, plot_center, road_dir, outward, kind, zone, rng)


# ── Yard fence segments ───────────────────────────────────────────────────────

func _build_bw_yards(root: Node3D, pts: Array[Vector3]) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var i := 0
	while i < pts.size() - 1:
		var a        := pts[i]
		var b        := pts[i + 1]
		var mid      := (a + b) * 0.5
		var road_dir: Vector3 = (b - a); road_dir.y = 0.0; road_dir = road_dir.normalized()
		var back: Vector3 = road_dir.rotated(Vector3.UP, PI * 0.5)

		var p1 := mid + back * (bw_house_setback + 2.0)
		var p2: Vector3 = p1 + road_dir * rng.randf_range(6.0, 10.0)
		_build_bw_fence_line(root, p1, p2)

		if rng.randf() < 0.25:
			_build_bw_laundry_line(root, p1, p1 + Vector3(3.5, 0.0, 1.0), rng)

		i += 2   # step by 2 so fence runs are spaced


# ── Farm fields outside gate ──────────────────────────────────────────────────

func _build_bw_farms(root: Node3D, gate: Vector3, plaza: Vector3) -> void:
	var rng     := RandomNumberGenerator.new()
	rng.seed    = 7331
	var forward := (gate - plaza); forward.y = 0.0
	if forward.length_squared() > 0.001:
		forward = forward.normalized()
	else:
		forward = Vector3(0.0, 0.0, 1.0)

	var base := gate + forward * 18.0

	for i in range(4):
		var fw: float = rng.randf_range(8.0, 14.0)
		var fd: float = rng.randf_range(10.0, 16.0)
		var p: Vector3 = base + Vector3(rng.randf_range(-14.0, 14.0), 0.0, rng.randf_range(6.0, 18.0))

		var field := MeshInstance3D.new()
		var bm    := BoxMesh.new()
		bm.size = Vector3(fw, 0.08, fd)
		field.mesh = bm
		var fm := StandardMaterial3D.new()
		fm.albedo_color = Color(0.22, 0.35, 0.16)
		field.material_override = fm
		field.global_position = p + Vector3(0.0, 0.04, 0.0)
		root.add_child(field)

		# Fence along front edge
		_build_bw_fence_line(root,
			p + Vector3(-fw * 0.5, 0.0, -fd * 0.5),
			p + Vector3( fw * 0.5, 0.0, -fd * 0.5))


# ============================================================================
# Phase 24C — House Types + Variants
# ============================================================================

func _make_bw_house_variant(pos: Vector3, facing: Vector3, zone: String) -> Node3D:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var t: float = rng.randf()
	var kind := "small"

	if zone == "market" and t < bw_shopfront_weight_market:
		kind = "shopfront"
	else:
		var sum := bw_house_small_weight + bw_house_medium_weight \
					+ bw_house_large_weight + bw_house_corner_weight
		var r := t * sum
		if r < bw_house_small_weight:
			kind = "small"
		elif r < bw_house_small_weight + bw_house_medium_weight:
			kind = "medium"
		elif r < bw_house_small_weight + bw_house_medium_weight + bw_house_large_weight:
			kind = "large"
		else:
			kind = "corner"

	match kind:
		"shopfront": return _bw_build_shopfront(pos, facing, rng)
		"large":     return _bw_build_house(pos, facing, Vector2(9.0, 7.0), 4.0,  true,  true,  rng)
		"medium":    return _bw_build_house(pos, facing, Vector2(7.0, 6.0), 3.4,  true,  true,  rng)
		"corner":    return _bw_build_corner_house(pos, facing, rng)
		_:           return _bw_build_house(pos, facing, Vector2(6.0, 5.0), 3.2,  false, true,  rng)


func _bw_build_house(pos: Vector3, facing: Vector3, footprint: Vector2, wall_h: float,
		chimney: bool, porch: bool, rng: RandomNumberGenerator) -> Node3D:
	var n := Node3D.new()
	n.name = "BW_House"
	n.global_position = pos
	n.rotation.y = atan2(facing.x, facing.z)

	var w      := footprint.x
	var d      := footprint.y
	var base_h := 0.55

	# Stone base
	var base := MeshInstance3D.new()
	var bsm  := BoxMesh.new()
	bsm.size = Vector3(w, base_h, d)
	base.mesh = bsm
	base.position.y = base_h * 0.5
	base.material_override = _bw_mat_stone()
	n.add_child(base)

	# Plaster walls
	var walls := MeshInstance3D.new()
	var wm    := BoxMesh.new()
	wm.size = Vector3(w * 0.92, wall_h, d * 0.92)
	walls.mesh = wm
	walls.position.y = base_h + wall_h * 0.5
	walls.material_override = _bw_mat_timber()
	n.add_child(walls)

	# Timber frame + gable roof
	_bw_add_timber_frame(n, w, d, wall_h, base_h)
	var pitch: float = rng.randf_range(bw_roof_pitch_min, bw_roof_pitch_max)
	n.add_child(_bw_gable_roof(w * 1.10, d * 1.08, base_h + wall_h + 0.25, pitch, bw_roof_overhang))

	# Collision
	var body := StaticBody3D.new()
	var col  := CollisionShape3D.new()
	var box  := BoxShape3D.new()
	box.size = Vector3(w, base_h + wall_h + 2.8, d)
	col.shape = box
	col.position.y = box.size.y * 0.5
	body.add_child(col)
	n.add_child(body)

	# Optional porch slab (front-facing)
	if porch and bw_porch_enabled and rng.randf() < 0.75:
		var pm  := MeshInstance3D.new()
		var pbm := BoxMesh.new()
		pbm.size = Vector3(w * 0.42, 0.18, 1.8)
		pm.mesh = pbm
		pm.position = Vector3(0.0, base_h + 0.09, d * 0.52)
		pm.material_override = _bw_mat_darkwood()
		n.add_child(pm)

	# 2–4 warm windows on random sides
	var win_count: int = rng.randi_range(2, 4)
	for _i in range(win_count):
		var side: float = -1.0 if rng.randf() < 0.5 else 1.0
		var z: float = rng.randf_range(-d * 0.25, d * 0.25)
		_bw_add_warm_window(n, Vector3(side * w * 0.44, base_h + 1.7, z), side, bw_window_energy_day)

	# Optional chimney
	if chimney and bw_chimney_enabled and rng.randf() < 0.70:
		_bw_add_chimney(n, Vector3(w * 0.28, base_h + wall_h + 0.2, -d * 0.15),
						rng.randf_range(5.6, 7.0))

	return n


func _bw_build_corner_house(pos: Vector3, facing: Vector3, rng: RandomNumberGenerator) -> Node3D:
	var n := _bw_build_house(pos, facing, Vector2(7.0, 6.0), 3.4, true, true, rng)
	n.name = "BW_CornerHouse"

	# Lean-to wing on one side
	var wing := MeshInstance3D.new()
	var wbm  := BoxMesh.new()
	wbm.size = Vector3(3.2, 2.4, 4.0)
	wing.mesh = wbm
	wing.material_override = _bw_mat_timber()
	wing.position = Vector3(4.2, 0.55 + 1.2, -1.0)
	n.add_child(wing)

	# Shed roof over lean-to
	var shed := MeshInstance3D.new()
	var sbm  := BoxMesh.new()
	sbm.size = Vector3(3.36, 0.16, 4.2)
	shed.mesh = sbm
	shed.material_override = _bw_mat_roof()
	shed.position = Vector3(4.2, 0.55 + 2.5, -1.0)
	shed.rotation_degrees.z = 18.0
	n.add_child(shed)

	return n


func _bw_build_shopfront(pos: Vector3, facing: Vector3, rng: RandomNumberGenerator) -> Node3D:
	var n := _bw_build_house(pos, facing, Vector2(8.0, 6.0), 3.4, true, true, rng)
	n.name = "BW_Shopfront"

	# Forward-tilted awning
	var awn := MeshInstance3D.new()
	var abm := BoxMesh.new()
	abm.size = Vector3(4.0, 0.14, 2.0)
	awn.mesh = abm
	awn.material_override = _bw_mat_darkwood()
	awn.position = Vector3(0.0, 0.55 + 2.4, 3.4)
	awn.rotation_degrees.x = -12.0
	n.add_child(awn)

	# Signboard
	_bw_add_signboard(n, Vector3(0.0, 0.0, 3.4), "SHOP" if rng.randf() < 0.5 else "TRADER")
	return n


# ============================================================================
# Phase 25 — Street Alignment helpers
# ============================================================================

func _bw_pick_house_kind(zone: String, rng: RandomNumberGenerator) -> String:
	if zone == "market" and rng.randf() < bw_shopfront_weight_market:
		return "shopfront"

	var w_small  := bw_house_small_weight
	var w_med    := bw_house_medium_weight
	var w_large  := bw_house_large_weight
	var w_corner := bw_house_corner_weight
	var sum      := w_small + w_med + w_large + w_corner

	var t: float = rng.randf() * sum
	if t < w_small:
		return "small"
	elif t < w_small + w_med:
		return "medium"
	elif t < w_small + w_med + w_large:
		return "large"
	else:
		return "corner"


func _bw_setback_for_kind(kind: String) -> float:
	match kind:
		"small":     return bw_setback_small
		"medium":    return bw_setback_medium
		"large":     return bw_setback_large
		"shopfront": return bw_setback_shop
		"corner":    return bw_setback_corner
		_:           return bw_setback_medium


func _bw_build_kind(kind: String, pos: Vector3, facing: Vector3,
		rng: RandomNumberGenerator) -> Node3D:
	match kind:
		"shopfront": return _bw_build_shopfront(pos, facing, rng)
		"large":     return _bw_build_house(pos, facing, Vector2(9.0, 7.0), 4.0, true,  true,  rng)
		"medium":    return _bw_build_house(pos, facing, Vector2(7.0, 6.0), 3.4, true,  true,  rng)
		"corner":    return _bw_build_corner_house(pos, facing, rng)
		_:           return _bw_build_house(pos, facing, Vector2(6.0, 5.0), 3.2, false, true,  rng)


func _bw_auto_yard_for_house(root: Node3D, _house: Node3D, plot_center: Vector3,
		road_dir: Vector3, outward: Vector3, kind: String, zone: String,
		rng: RandomNumberGenerator) -> void:
	# Yard dimensions vary by house type
	var yard_w: float = rng.randf_range(bw_yard_width_min, bw_yard_width_max)
	match kind:
		"large":     yard_w *= 1.15
		"small":     yard_w *= 0.90

	var yard_d := bw_yard_depth
	if kind == "shopfront":
		yard_d *= 0.55   # shops have little/no backyard

	# Yard is behind the house = further away from road
	var back_dir := outward
	var side_dir := road_dir

	var yard_center := plot_center + back_dir * (yard_d * 0.55)

	var half_w := yard_w * 0.5
	var half_d := yard_d * 0.5

	# Rectangle corners
	var p1 := yard_center - side_dir * half_w - back_dir * half_d
	var p2 := yard_center + side_dir * half_w - back_dir * half_d
	var p3 := yard_center + side_dir * half_w + back_dir * half_d
	var p4 := yard_center - side_dir * half_w + back_dir * half_d

	# Fence 3 sides — front (road-facing) stays open
	_build_bw_fence_line(root, p1, p2)   # back edge
	_build_bw_fence_line(root, p2, p3)   # right side
	_build_bw_fence_line(root, p4, p1)   # left side

	# Yard clutter
	if rng.randf() < 0.65 and kind != "shopfront":
		var clutter_p: Vector3 = yard_center + Vector3(
			rng.randf_range(-half_w * 0.6, half_w * 0.6),
			0.0,
			rng.randf_range(-half_d * 0.6, half_d * 0.6))
		_bw_place_clutter(root, clutter_p, rng)

	# Laundry (residential only, occasional)
	if zone == "residential" and rng.randf() < 0.22:
		var la := yard_center - side_dir * (half_w * 0.45) + back_dir * (half_d * 0.20)
		var lb := yard_center + side_dir * (half_w * 0.45) + back_dir * (half_d * 0.20)
		_build_bw_laundry_line(root, la, lb, rng)
