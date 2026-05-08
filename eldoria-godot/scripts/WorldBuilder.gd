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
}
@export var npc_script: Script = preload("res://scripts/NPC.gd")

var _buildings_built: bool = false

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
const LANTERN_GLB_PATH: String  = "res://assets/models/props/lantern.glb"
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

# Convenience accessors
func MAT_GRASS(uv := 30.0) -> StandardMaterial3D:
	return _pbr_mat("res://assets/textures/grass/grass_diff.jpg",
		"res://assets/textures/grass/grass_norm.jpg",
		"res://assets/textures/grass/grass_rough.jpg",
		Vector3(uv, uv, 1))

func MAT_WOOD(uv := 1.5) -> StandardMaterial3D:
	return _pbr_mat("res://assets/textures/wood/wood_diff.jpg",
		"res://assets/textures/wood/wood_norm.jpg",
		"res://assets/textures/wood/wood_rough.jpg",
		Vector3(uv, uv, 1), Color(0.85, 0.66, 0.45))

func MAT_DARK_WOOD(uv := 1.5) -> StandardMaterial3D:
	return _pbr_mat("res://assets/textures/wood/wood_diff.jpg",
		"res://assets/textures/wood/wood_norm.jpg",
		"res://assets/textures/wood/wood_rough.jpg",
		Vector3(uv, uv, 1), Color(0.35, 0.22, 0.13))

func MAT_ROOF(uv := 2.5) -> StandardMaterial3D:
	return _pbr_mat("res://assets/textures/thatch/shingle_diff.jpg",
		"res://assets/textures/thatch/shingle_norm.jpg",
		"",
		Vector3(uv, uv, 1), Color(0.7, 0.42, 0.32))

func MAT_STONE(uv := 2.0) -> StandardMaterial3D:
	return _pbr_mat("res://assets/textures/stone/stone_diff.jpg",
		"res://assets/textures/stone/stone_norm.jpg",
		"res://assets/textures/stone/stone_rough.jpg",
		Vector3(uv, uv, 1))

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
	 "schedule":[Vector3( 2.5, 0,  0.0), Vector3( 2.5, 0,  0.0), Vector3( 3.0, 0, -5.0), Vector3( 8.6, 0, -2.0)]},
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

func _ready() -> void:
	if _buildings_built: return
	_buildings_built = true
	_dlog("_ready START")
	_populate_npc_models()
	_dlog("NPC_MODELS=%d" % NPC_MODELS.size())
	# Bisect: each step prints before/after so DevTools console reveals which call halts.
	_safe_call("_build_ground_overlay")
	_safe_call("_build_path_network")
	_safe_call("_build_village")
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
	_safe_call("_build_butterflies")  # Env 2026-05-06: daytime ambient life — THEME §12
	_safe_call("_build_bird_flocks")  # Env 2026-05-06: ambient life — V-formation birds, THEME §12
	_safe_call("_build_god_rays")  # Builder run 23: god-rays through canopy — THEME §1 §12 §13
	_safe_call("_build_smoke_chimneys")
	_safe_call("_build_campfire")
	_safe_call("_build_enemies")
	_safe_call("_build_pet")
	_safe_call("_build_stable_horse")
	_safe_call("_build_loot_chests")
	call_deferred("_global_scale_sweep")
	_safe_call("_build_player_home")  # Builder run 24 — Backlog #10
	_safe_call("_build_crystal_caves", [Vector3(-50, 0, -40)])
	_dlog("_ready DONE — children=%d" % get_child_count())

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
		path.material_override = MAT_STONE(length / 2)
		path.position = center + Vector3(0, 0.02, 0)
		path.rotation.y = atan2(dir.x, dir.z)
		path.name = "Path"
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
	foundation.material_override = MAT_STONE(2)
	foundation.position.y = 0.25
	house.add_child(foundation)

	# Walls (wood planks)
	var wall := MeshInstance3D.new()
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(3.6, 2.6, 3.6)
	wall.mesh = wall_mesh
	wall.material_override = MAT_WOOD(2)
	wall.position.y = 1.3 + 0.5
	house.add_child(wall)

	# Wall collision so player can't walk through
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.6, 3.1, 3.6)
	col.shape = box
	col.position.y = 1.55
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
		var ang := rng.randf() * TAU
		# Inner ring (40%) — village-edge trees at 24-40m. Outer ring (60%) —
		# Whisperwood proper at 40-72m. The bias gives a sense of the forest
		# pressing in without crowding the central plaza.
		var dist: float
		if rng.randf() < 0.4:
			dist = rng.randf_range(24.0, 40.0)
		else:
			dist = rng.randf_range(40.0, 72.0)
		var pos := Vector3(cos(ang) * dist, 0, sin(ang) * dist)
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
		var ang := rng.randf() * TAU
		var dist := rng.randf_range(20, 70)
		var pos := Vector3(cos(ang) * dist, 0, sin(ang) * dist)
		# THEME §1 — try the Sketchfab CC-BY boulder GLB first; fall through to
		# the legacy sphere-primitive path if the asset isn't loadable.
		if _make_glb_boulder(pos, rng):
			continue
		# ─── Procedural fallback (legacy primitive path) ─────────────────────
		var size := rng.randf_range(0.7, 1.8)
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
		var ang := (float(i) / 36.0) * TAU + rng.randf_range(-0.05, 0.05)
		var r := 220.0 + rng.randf_range(-15, 15)  # 2026-05-06 [CANON-APPROVED: SIZE_STANDARDS.md §6 — was 90m, mountain ring must be 200m+]
		var pos := Vector3(cos(ang) * r, 0, sin(ang) * r)
		var h := rng.randf_range(20, 40)
		var base_r := rng.randf_range(8, 14)
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
		var ang := (float(i) / 28.0) * TAU + rng.randf_range(-0.1, 0.1)
		var r := 320.0 + rng.randf_range(-25, 25)  # 2026-05-06 [CANON-APPROVED: outer ring pushed back from 160m to 320m so it reads as horizon]
		var pos := Vector3(cos(ang) * r, 0, sin(ang) * r)
		var h := rng.randf_range(45, 80)
		var base_r := rng.randf_range(15, 25)
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
	var spots = [Vector3(2.5, 0, 0), Vector3(-2.5, 0, 0)]
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
	var pos := Vector3(0, 0, 12)
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
			# tower but not walk through it. Sized for the procedural
			# canon (radius ~1.1, height ~5).
			var mill_body: StaticBody3D = StaticBody3D.new()
			var mill_col: CollisionShape3D = CollisionShape3D.new()
			var mill_cyl: CylinderShape3D = CylinderShape3D.new()
			mill_cyl.radius = 1.4
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
		var ang := rng.randf() * TAU
		var rx := cos(ang) * (3.5 + rng.randf() * 0.5)
		var rz := sin(ang) * (2.5 + rng.randf() * 0.5)
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
	add_child(npc)

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
	npc.add_child(area)
	var acol := CollisionShape3D.new()
	var ashape := SphereShape3D.new()
	# REFINE: character — InteractArea radius 2.5 → 2.7 m. Alden's low-friction-interaction affinity: a slightly wider 'within talking distance' bubble means he doesn't have to plant himself directly on top of a villager to trigger the prompt. Owen still walks past at speed without spurious triggers (the player_in_range gate clears on body_exit).
	ashape.radius = 2.7
	acol.shape = ashape
	# REFINE: character — InteractArea y 1.0 → 1.1. Centers the sphere around the villager's chest rather than waist, so a player approaching from a slope still trips the area on the chest line (THEME §13 ground-contact spirit — geometry follows where bodies actually meet).
	acol.position.y = 1.1
	area.add_child(acol)

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
		var pos := Vector3(rng.randf_range(-60, 60), 0, rng.randf_range(-60, 60))
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
	var caves := Node3D.new()
	caves.name = "CrystalCaves"
	caves.position = entrance
	add_child(caves)
	var rng := RandomNumberGenerator.new(); rng.randomize()
	var crystal_blue: Color = Color(0.45, 0.80, 1.00)
	var crystal_violet: Color = Color(0.70, 0.55, 1.00)
	var crystal_teal: Color = Color(0.45, 1.00, 0.85)

	# ── Cavern dome (inverted) — the dark interior shell ──
	# Done as a downward-scaled half-sphere shell offset upward so it caps the
	# play area without blocking the camera too aggressively.
	var dome := MeshInstance3D.new()
	var dm := SphereMesh.new()
	dm.radius = 24.0; dm.height = 22.0
	dome.mesh = dm
	var dome_mat := StandardMaterial3D.new()
	# REFINE: visual — Crystal Caves — push interior shell darker and more matte
	# so the cave feels oppressively dim and the crystal emissives carry the look.
	dome_mat.albedo_color = Color(0.04, 0.05, 0.10)
	dome_mat.roughness = 0.98
	dome_mat.cull_mode = BaseMaterial3D.CULL_FRONT  # render the inside
	dome.material_override = dome_mat
	dome.position = Vector3(0, 4.0, 0)
	caves.add_child(dome)

	# ── Entrance arch (two stone columns + capstone) ──
	for sx in [-3.2, 3.2]:
		var col := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.7; cm.bottom_radius = 0.95; cm.height = 5.5
		col.mesh = cm
		col.material_override = MAT_ROCK(1.5)
		col.position = Vector3(sx, 2.75, 22.0)
		caves.add_child(col)
	var cap := MeshInstance3D.new()
	var capm := BoxMesh.new()
	capm.size = Vector3(8.4, 1.2, 1.6)
	cap.mesh = capm
	cap.material_override = MAT_ROCK(1.5)
	cap.position = Vector3(0, 6.1, 22.0)
	caves.add_child(cap)
	# Glowing entrance crystal above the arch — a beacon from the village
	var beacon := MeshInstance3D.new()
	var bm := PrismMesh.new()
	bm.size = Vector3(1.0, 2.4, 1.0)
	beacon.mesh = bm
	var beacon_mat := StandardMaterial3D.new()
	beacon_mat.albedo_color = crystal_blue
	beacon_mat.emission_enabled = true
	beacon_mat.emission = crystal_blue
	# REFINE: visual — Crystal Caves — beacon throws further so the cave reads
	# as a destination from the village edge (helps Alden spot the entrance).
	beacon_mat.emission_energy_multiplier = 4.0
	beacon.material_override = beacon_mat
	beacon.position = Vector3(0, 8.0, 22.0)
	caves.add_child(beacon)
	var beacon_light := OmniLight3D.new()
	beacon_light.light_color = crystal_blue
	# REFINE: visual — Crystal Caves — beacon light reaches the village treeline
	beacon_light.light_energy = 3.2
	beacon_light.omni_range = 18.0
	beacon_light.position = Vector3(0, 8.0, 22.0)
	caves.add_child(beacon_light)

	# ── Ambient blue cave light ──
	var amb := OmniLight3D.new()
	amb.light_color = crystal_blue
	# REFINE: visual — Crystal Caves — dimmer chamber ambient (was 0.85) so the
	# crystal clusters do the heavy lifting; cave reads as cave, not as lit room.
	amb.light_energy = 0.62
	amb.omni_range = 28.0
	amb.position = Vector3(0, 9.0, 0)
	caves.add_child(amb)
	# Secondary deep-violet light at the boss room end
	var boss_amb := OmniLight3D.new()
	boss_amb.light_color = crystal_violet
	# REFINE: visual — Crystal Caves — stronger violet pool around the Guardian;
	# helps the boss room read as cinematic without changing combat numbers.
	boss_amb.light_energy = 2.4
	boss_amb.omni_range = 24.0
	boss_amb.position = Vector3(0, 4.0, -16.0)
	caves.add_child(boss_amb)

	# ── Stone floor disc — a darker rocky ground inside the cave ──
	var floor_mesh := MeshInstance3D.new()
	var pm_floor := CylinderMesh.new()
	pm_floor.top_radius = 22.0; pm_floor.bottom_radius = 22.0; pm_floor.height = 0.4
	floor_mesh.mesh = pm_floor
	var floor_mat := StandardMaterial3D.new()
	# REFINE: visual — Crystal Caves — cooler, wetter-looking stone floor.
	# Lower roughness so the crystal glow catches a faint sheen on the rock.
	floor_mat.albedo_color = Color(0.12, 0.14, 0.20)
	floor_mat.roughness = 0.78
	floor_mesh.material_override = floor_mat
	floor_mesh.position = Vector3(0, 0.05, 0)
	caves.add_child(floor_mesh)

	# ── Glowing crystal formations scattered through the cave ──
	var crystal_spots: Array = [
		{"p": Vector3(-8, 0, 14), "s": 1.4, "c": crystal_blue},
		{"p": Vector3( 9, 0, 11), "s": 1.2, "c": crystal_blue},
		{"p": Vector3(14, 0,  4), "s": 1.6, "c": crystal_teal},
		{"p": Vector3(-12,0,  2), "s": 1.5, "c": crystal_blue},
		{"p": Vector3(  4,0, -4), "s": 1.0, "c": crystal_teal},
		{"p": Vector3(-6, 0, -8), "s": 1.3, "c": crystal_violet},
		{"p": Vector3( 12,0, -10),"s": 1.4, "c": crystal_violet},
		{"p": Vector3(-14,0,-12), "s": 1.1, "c": crystal_blue},
		{"p": Vector3(  0,0, -18),"s": 2.2, "c": crystal_violet},  # giant central crystal in boss room
	]
	for spot in crystal_spots:
		var p: Vector3 = spot["p"]
		var s: float = spot["s"]
		var c: Color = spot["c"]
		_make_crystal_cluster(p, s, c, caves, rng)

	# ── Stalagmites (floor) and stalactites (ceiling) ──
	for i in 18:
		var ang: float = rng.randf() * TAU
		var r: float = rng.randf_range(6.0, 19.0)
		var pos: Vector3 = Vector3(cos(ang) * r, 0.0, sin(ang) * r)
		var h: float = rng.randf_range(1.2, 3.0)
		_make_stalagmite(pos, h, caves, false)
	for i in 12:
		var ang2: float = rng.randf() * TAU
		var r2: float = rng.randf_range(4.0, 18.0)
		var pos2: Vector3 = Vector3(cos(ang2) * r2, 11.5, sin(ang2) * r2)
		var h2: float = rng.randf_range(1.5, 3.5)
		_make_stalagmite(pos2, h2, caves, true)

	# ── Boss room divider — a stone arch separating the entry chamber from the boss room ──
	for sx2 in [-6.0, 6.0]:
		var pillar := MeshInstance3D.new()
		var pillm := CylinderMesh.new()
		pillm.top_radius = 0.6; pillm.bottom_radius = 0.9; pillm.height = 7.0
		pillar.mesh = pillm
		pillar.material_override = MAT_ROCK(1.5)
		pillar.position = Vector3(sx2, 3.5, -10.0)
		caves.add_child(pillar)

	# ── Skull pile in front of the boss crystal — ominous ──
	for i in 6:
		var skull := MeshInstance3D.new()
		var sm2 := SphereMesh.new()
		sm2.radius = 0.20; sm2.height = 0.32
		skull.mesh = sm2
		var sklm := StandardMaterial3D.new()
		# REFINE: visual — Crystal Caves — older / chalkier bone tint reads
		# clearer under the cool blue ambient than the warmer arena-skull color.
		sklm.albedo_color = Color(0.92, 0.86, 0.74)
		sklm.roughness = 0.92
		skull.material_override = sklm
		skull.position = Vector3(rng.randf_range(-1.4, 1.4), 0.18, -16.0 + rng.randf_range(-1.4, 1.4))
		caves.add_child(skull)

	# ── ENEMY SPAWNS ──
	# Skeletons (use enemy_kind="skeleton", bone-white tint)
	var skel_color: Color = Color(0.95, 0.95, 0.92)
	var skel_spots: Array = [
		Vector3(-6, 0, 12), Vector3( 7, 0, 8), Vector3(11, 0, -2),
		Vector3(-10, 0, -4), Vector3( 4, 0, -8),
	]
	for sp in skel_spots:
		var pos3: Vector3 = caves.position + sp
		_spawn_enemy("skeleton", pos3, "Restless Skeleton", 36, 8, 24, 7, skel_color, 2.4, 4.4)

	# Crystal Elementals — slower, hard-hitting, glowing
	var elem_color: Color = Color(0.55, 0.85, 1.00)
	var elem_spots: Array = [
		Vector3(-12, 0, 0), Vector3(13, 0, -6), Vector3(-4, 0, -12),
	]
	for ep in elem_spots:
		var pos4: Vector3 = caves.position + ep
		_spawn_enemy("crystal_elemental", pos4, "Crystal Elemental", 70, 14, 55, 14, elem_color, 1.8, 3.2)

	# Boss: Crystal Guardian — beefy crystal_guardian with massive HP and big drops
	var guardian_pos: Vector3 = caves.position + Vector3(0, 0, -16.0)
	_spawn_enemy("crystal_guardian", guardian_pos, "Crystal Guardian",
		420, 26, 480, 200, Color(0.65, 0.85, 1.00), 1.8, 3.4)


# Walk a freshly-instanced character GLB and rescale so its visible AABB is ~1.8m tall.
# Sketchfab models come in mixed unit systems; this prevents the "giants" problem.
func _normalize_npc_scale(model: Node) -> void:
	await get_tree().process_frame
	var aabb := AABB()
	var has := false
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
				continue   # ground plane is allowed to be huge
			if body.is_in_group("mountain"):
				_clamp_max_height(body, 80.0)
				continue
			if body.is_in_group("trees"):
				_clamp_max_height(body, 14.0)
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
			_clamp_max_height(body, 14.0)
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
		var ang := rng.randf() * TAU
		var dist := rng.randf_range(14, 60)
		var pos := Vector3(cos(ang) * dist, 0, sin(ang) * dist)
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
		var ang := rng.randf() * TAU
		var dist := rng.randf_range(16, 55)
		var center := Vector3(cos(ang) * dist, 0, sin(ang) * dist)
		var pod_size: int = rng.randi_range(2, 4)
		for mi in pod_size:
			var inst: Node = packed.instantiate()
			if inst == null:
				continue
			var holder := Node3D.new()
			var off := Vector3(rng.randf_range(-0.6, 0.6), 0, rng.randf_range(-0.6, 0.6))
			holder.position = center + off
			holder.rotation.y = rng.randf() * TAU
			holder.add_to_group("mushrooms")
			add_child(holder)
			holder.add_child(inst)
			if inst is Node3D:
				var s: float = rng.randf_range(0.55, 0.95)
				(inst as Node3D).scale = Vector3(s, s, s)
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
	var has := false
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
	"player":  [1.10, 0.18],   # kid-sized; tol widened 0.10→0.18 so the body's
	                           #   capsule doesn't oscillate against the panic-key cap.
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
	var has := false
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
		if child is Node3D and child.has_method("get_children"):
			var c := child as Node3D
			var avg_cur: float = (c.scale.x + c.scale.y + c.scale.z) / 3.0
			var new_s: float = clamp(avg_cur * (target_height / aabb.size.y), 0.001, 5.0)  # scale-eng 2026-05-05: floor 0.05 → 0.001
			c.scale = Vector3(new_s, new_s, new_s)
			break
