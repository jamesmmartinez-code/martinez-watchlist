extends CharacterBody3D
class_name Enemy

# Realm of Eldoria — Goblin / Wolf / Bandit enemy.
# Wanders idly until player enters aggro_range, then chases and melees.
# On death drops XP + gold, respawns after respawn_delay seconds.

@export var enemy_name: String = "Goblin Scout"
@export var enemy_kind: String = "goblin"   # "goblin" | "wolf" | "bandit"
@export var max_hp: int = 28
@export var damage: int = 6
@export var move_speed: float = 2.6
@export var chase_speed: float = 4.6
# REFINE: combat-feel — aggro pulled in from 9.0 → 8.0; kid-friendly for Alden, still tense in clusters.
@export var aggro_range: float = 8.0
@export var attack_range: float = 1.6
# REFINE: combat-feel — longer recovery (1.2 → 1.45) so kids have a clean window to reposition between hits.
@export var attack_cooldown: float = 1.45
@export var xp_reward: int = 18
@export var gold_reward: int = 4
@export var respawn_delay: float = 35.0
@export var tint: Color = Color(0.45, 0.85, 0.30)
@export var enemy_model: PackedScene = preload("res://assets/models/npcs/worker_girl.glb")
# THEME §4 — per-kind real fantasy models override the placeholder RobotExpressive.
# Source-credited GLBs (CC-BY) live under assets/models/enemies/. When a kind has
# a dedicated model here, _spawn_model uses it AND skips the green-tint modulate
# (the model carries its own hand-painted textures — tinting muddies them).
const KIND_MODELS := {
	# THEME §4 + §12 — goblin_scout.glb (Sketchfab CC-BY) is the animated
	# variant: ships with IdleAnimation, WalkAnimation, RunAnimation embedded.
	# Replaces the static T-pose goblin.glb (Orc Tomahawk) that had ZERO
	# animations — every goblin in the wood was frozen mid-stride, violating
	# THEME §12 MOTION. Auto-played by _play_model_idle_anim() (the "IdleAnimation"
	# name is already first in that function's lookup list, no other code change
	# needed). The old goblin.glb stays in assets/ for now in case a future run
	# wants a second silhouette for Brutes; both Scouts and Brutes currently
	# share this single animated model and rely on per-kind scale + name label
	# for differentiation (WorldBuilder lines ~1221 and ~1226).
	"goblin": preload("res://assets/models/enemies/goblin_scout.glb"),
	# THEME §4 + §12 — wolf.glb (CC-BY) is a real quadruped wolf with embedded
	# idle/walk/run animations. Replaces the worker_girl.glb fallback that had
	# been making "Dire Wolves" appear as a humanoid woman model — silhouette-
	# broken at 30m and immersion-shattering. wolf.glb stands on its own four
	# legs (Y-up, forward in -Z), so the legacy `rotation.x = -PI/2` quadruped
	# hack below is GUARDED behind uses_real_model — applying it to a real
	# quadruped would flip the wolf onto its back. Idle anim auto-plays via
	# _play_model_idle_anim().
	"wolf":   preload("res://assets/models/enemies/wolf.glb"),
	# THEME §4 — undead and crystal-cave kinds previously fell back to
	# worker_girl.glb (a humanoid woman in merchant apron — silhouette-broken
	# at 30m). The "skeleton" kind now resolves to a dedicated bone-textured
	# enemy GLB (Sketchfab uid aa225d17845e4d84b582646b7573114f, "skeleton
	# warrior" by 3dMondra, CC-BY-4.0 — see CREDITS.md). It ships with 9
	# embedded animations including "Idle 01", "Combat Run 01", "Warrior
	# Heavy Attack Sword 01", "Death 01" — every §12 MOTION need covered by
	# one source. The Sketchfab "Idle 01" name is matched by the case-
	# insensitive substring fallback in _play_model_idle_anim() (no other
	# code change is needed; the lookup list was extended to include "Idle 01"
	# explicitly, as a belt-and-suspenders pin for the most common Sketchfab
	# naming convention). KIND_TINT_OVERRIDE below was relaxed for "skeleton"
	# so the model's hand-painted bone textures show through unmodulated —
	# tinting them muddied the silhouette.
	#
	# Character run (2026-05-06, second pass): crystal_elemental and
	# crystal_guardian PROMOTED from warrior.glb (placeholder reuse — humanoid
	# woman in merchant apron, silhouette-broken at 30m) to a dedicated
	# stone-golem GLB sourced from Sketchfab uid 19c1855bdb2c4cdc89da2cfb64da48cf
	# ("Drugdör The Golem Animated" by Phons, CC-BY-4.0 — see CREDITS.md).
	# 1.49 MiB GLB (well under §15's 20 MiB cap), 2 meshes, 1 skin, 9 embedded
	# animations: "Idle", "Walk", "Attack1/2/3", "Defence1/2/3", "IdlePieces"
	# — every §12 MOTION need covered by one source. The "Idle" name is an
	# exact match in _play_model_idle_anim()'s lookup list (no substring
	# fallback needed). Both crystal kinds REUSE this single GLB and
	# differentiate by scale + tint (same boss-variant pattern as
	# bandit/bandit_captain): crystal_elemental at 1.10× with cyan modulate,
	# crystal_guardian at 1.55× with frost-pale modulate (see WorldBuilder
	# _spawn_enemy calls in _make_crystal_caves). KIND_TINT_OVERRIDE stays
	# on for both kinds — the golem's natural stone-grey rock texture is
	# what we WANT to tint here (it's the canvas the per-kind crystal/frost
	# Color paints onto, mirroring the goblin → goblin_warlord pattern).
	"skeleton":          preload("res://assets/models/enemies/skeleton.glb"),
	"crystal_elemental": preload("res://assets/models/enemies/crystal_elemental.glb"),
	"crystal_guardian":  preload("res://assets/models/enemies/crystal_elemental.glb"),
	# THEME §4 (Bandits — human, hooded, leather, scarves over face).
	# Character run (2026-05-06): bandit kind PROMOTED from warrior.glb
	# (placeholder reuse) to a dedicated rogue/bandit GLB sourced from
	# Sketchfab uid e49c999cc7ce4668a7fdeff328ad0b93 ("Animated Stylized
	# Character - Rogue Warrior" by Karthiknaidu97, CC-BY-4.0 — see
	# CREDITS.md). The model is a Prince-of-Persia-inspired hooded rogue
	# with cloth outfit, leather armor, and dual sword/dagger — exactly
	# the THEME §4 silhouette ("human, hooded, leather, scarves over
	# face"). 5.77 MiB GLB (well under §15's 20 MiB cap), 6 meshes,
	# 1 skin, 4 embedded animations: "Idle", "Walk", "Run", "Attack" —
	# every §12 MOTION need covered by one source. Idle auto-plays via
	# the case-insensitive substring match in _play_model_idle_anim()
	# (the GLTF track name is "Character_animated_warrior|Idle"; Godot's
	# importer typically renames to "Idle" or keeps the suffix — the
	# substring fallback catches both). Real role-correct model →
	# "bandit" was REMOVED from KIND_TINT_OVERRIDE below so the hand-
	# painted leather/cloth textures show through unmodulated. The
	# drop_table (Items.gd "bandit" key), KIND_TO_FACTION mapping
	# ("bandit" → "bandits"), and WorldBuilder._make_bandit_camp /
	# south-road spawn pattern all stay wired exactly as before — this
	# is a model-only swap.
	"bandit":            preload("res://assets/models/enemies/bandit.glb"),
	# COMPOUND: bandit_captain mini-boss. Now reuses the same dedicated
	# bandit.glb as the regular bandit (was warrior.glb), scaled up at
	# the visual layer (1.40× via the `bandit_captain` match branch
	# below) and re-tinted to a deeper purple-leather (KIND_TINT_OVERRIDE
	# stays on for captain — the silhouette differentiator from regular
	# bandits is scale + tint, mirroring the goblin → goblin_warlord
	# boss-variant pattern). The `bandit_captain` kind shares the
	# `bandits` faction (KIND_TO_FACTION mapping below) so kills count
	# toward Roan's road-clear quest target `bandit` — see
	# World.QUEST_CATALOG.bandit_road_for_roan note about
	# captain-as-bandit in the kill counter. Spawns ONLY at extreme
	# bandit pressure (≥0.70) where regular bandit_count is also 4 —
	# see WorldBuilder._bandit_captain_should_spawn.
	"bandit_captain":    preload("res://assets/models/enemies/bandit.glb"),
}

# THEME §4 — kinds whose KIND_MODELS entry is a model that ships with
# essentially-untextured / monochrome geometry where the per-kind `tint`
# modulate IS the silhouette differentiator at 30m. The Drugdör golem GLB used
# by crystal_elemental and crystal_guardian is a stone-grey rock figure — the
# crystal-cyan / frost-pale modulate paints it as ice/crystal beings. Real
# role-correct models that ship hand-painted textures (goblin, wolf, skeleton,
# bandit) keep those textures unmodulated; they are NOT in this map.
const KIND_TINT_OVERRIDE := {
	# THEME §4 — "skeleton" was REMOVED from this map when its KIND_MODELS
	# entry promoted from warrior.glb (placeholder reuse) to skeleton.glb (a
	# real bone-textured CC-BY model). The hand-painted bone material is the
	# silhouette signal we want at 30m; modulating it bone-white-on-bone-
	# white washes out the rib detail.
	#
	# crystal_elemental / crystal_guardian STAY in this map even though their
	# KIND_MODELS entry was promoted off warrior.glb on 2026-05-06: they now
	# share the Drugdör stone-golem GLB (Sketchfab CC-BY, neutral grey rock
	# textures). The cyan / frost-pale Color passed in by WorldBuilder
	# `_spawn_enemy` is what makes them read as "crystal beings" rather than
	# "two grey rock golems"; without the override the Color is dropped and
	# the elemental / guardian silhouettes collapse onto each other at 30m.
	"crystal_elemental": true,
	"crystal_guardian":  true,
	# THEME §4 — "bandit" was REMOVED from this map (Character run
	# 2026-05-06) when its KIND_MODELS entry promoted from warrior.glb
	# (placeholder reuse) to bandit.glb (the dedicated Sketchfab CC-BY
	# rogue — Prince-of-Persia-inspired hooded outlaw). The hand-painted
	# leather/cloth/hood textures ARE the silhouette signal we want at
	# 30m; modulating them with WorldBuilder's dark-leather Color washed
	# out the painted hood and read as flat charcoal blob, not "rogue
	# outlaw". The Color passed in by WorldBuilder._spawn_enemy is now
	# ignored for the regular `bandit` kind (the real model carries
	# its own silhouette).
	#
	# `bandit_captain` STAYS in this override map — captain reuses the
	# same bandit.glb at 1.40× scale and re-tints to a deeper
	# purple-leather to differentiate from regular bandits at 30m
	# (mirrors the goblin → goblin_warlord boss-variant pattern; the
	# tint is the boss-tier silhouette differentiator since the
	# underlying model is shared).
	"bandit_captain":    true,
}

# Map of enemy kind → faction id for the run-7 adaptive-cooldown schema.
# When a kind's faction has a `pressure` entry in `World.factions`, the enemy
# resolves its `attack_cooldown` against that scalar at spawn — the THIRD
# output on the same scalar that already drives NPC.gd dialogue tier 3 (run 4)
# and WorldBuilder spawn density (runs 5–6). Kinds NOT in this map (e.g.
# bandit until a bandit faction exists) keep the @export'd baseline.
# See SYSTEM_REGISTRY.md "Enemy Cooldown Schema."
const KIND_TO_FACTION := {
	"goblin": "whisperwood_goblins",
	"wolf": "dire_wolves",
	"skeleton": "crystal_caves",
	"crystal_elemental": "crystal_caves",
	"crystal_guardian": "crystal_caves",
	# COMPOUND (run 21 — Builder): bandits faction wired. The instant a
	# bandit-kind enemy spawns (next Builder run wires the road pattern +
	# warrior.glb model), the FOUR existing readers of faction_pressure
	# light up automatically: attack_cooldown band (lines 549-563),
	# chase_speed band (run 8), spawn density helper pattern (runs 5/6),
	# and the agitated ⚡ prefix at the AGITATED_COOLDOWN_THRESHOLD.
	# Pressure semantics for "bandits" are INVERTED relative to the others
	# (high = bandits bold, low = bandits hidden) per the World.gd
	# `update_bandit_pressure()` derivation. The cooldown lerp still reads
	# correctly: a bold bandit (pressure 0.8) gets the agitated faster-
	# attack rung; a dormant bandit (pressure 0.0) keeps baseline. That's
	# precisely the "they're feeling brave today" feedback we want.
	"bandit": "bandits",
	# Run 23 — bandit_captain shares the bandits faction. All five readers
	# of faction_pressure (cooldown band, chase_speed band, damage band,
	# xp_reward band, spawn density helpers) light up at captain spawn,
	# so a captain at pressure 0.7+ inherits the agitated rung WITHOUT
	# the captain having its own scalar.
	"bandit_captain": "bandits",
}

# Cooldown band: baseline = kid-friendly recovery valve (Alden's 9-yo timing
# window). Min = Owen's mastery rung (still readable, but punishing). NEVER
# widen this band without re-reading PLAYER_MODEL.md — these endpoints are
# tuned to the 9/11-year-old combat-feel target.
const ATTACK_COOLDOWN_BASELINE: float = 1.45
const ATTACK_COOLDOWN_MIN: float = 1.05
# Threshold below which an enemy reads as "agitated" to the player and earns
# a ⚡ prefix on its floating name. Corresponds to roughly pressure ≤ 0.625
# — clearly past the first reducer for either goblins or wolves.
const AGITATED_COOLDOWN_THRESHOLD: float = 1.30

# REFINE: adaptive — Run-8 chase_speed band. FOURTH output on the same
# `faction_pressure` scalar that already drives NPC dialogue tier 3 (run 4),
# goblin spawn density (run 5), wolf spawn density (run 6), and attack
# cooldown (run 7). Multiplicative because per-kind chase_speed varies
# (Brutes are tank-slow, scouts/skeletons are fast) — preserving each kind's
# role-shape matters more than a flat ceiling. +17% lands a default-4.6
# scout at ~5.38 at pressure 0, matching run-7's proposed [4.6, 5.4] band.
# A wolf at chase_speed 1.05 lifts to ~1.23 — proportional, role preserved.
# At pressure 1.0 (fresh save) every enemy stays at its WorldBuilder-assigned
# baseline, so Alden's first-hour combat feels identical to runs 1–7.
const CHASE_SPEED_AGITATION_GAIN: float = 0.17

# REFINE: adaptive — Run-9 damage band. FIFTH output on the same
# `faction_pressure` scalar that already drives NPC dialogue tier 3 (run 4),
# goblin spawn density (run 5), wolf spawn density (run 6), attack
# cooldown (run 7), and chase speed (run 8). The PLAYER_MODEL.md run-7
# follow-up explicitly named adaptive damage as Output #5 — and warned
# that damage is the most sensitive of the four enemy knobs because it
# compounds *with* cooldown and chase_speed (faster chase + faster swing
# + bigger hit = three vectors stacking on Alden's 9-yo combat tolerance).
# Therefore the band is TIGHTER than chase_speed's +17%: +12% ceiling.
# Multiplicative because per-kind damage varies (Brute > Scout, Boss >>
# everything) — preserving each kind's role-shape matters more than a
# flat ceiling. A goblin scout's 6 damage lifts to round(6.72) = 7 at
# pressure 0.0, a brute's 9 lifts to round(10.08) = 10, a boss's 22
# lifts to round(24.64) = 25 — proportional, role preserved. The clamp
# uses ceil(ceiling_f) (=11 for the brute case) so a future tighter
# round() rule can't escape the band. At pressure 1.0
# (fresh save) every enemy stays at its WorldBuilder-assigned baseline,
# so Alden's first-hour combat feels byte-identical to runs 1–8. The
# `⚡` agitated prefix from _resolve_adaptive_cooldown is reused — same
# pressure scalar trips the same threshold; one marker, three coupled
# effects (cooldown + chase_speed + damage) for cleaner readability.
const DAMAGE_AGITATION_GAIN: float = 0.12

# REFINE: adaptive — Run-10 xp_reward band. SIXTH and (per the run-9 follow-up)
# FINAL output on the same `faction_pressure` scalar that already drives NPC
# dialogue tier 3 (run 4), goblin spawn density (run 5), wolf spawn density
# (run 6), attack cooldown (run 7), chase speed (run 8), and damage (run 9).
# The PLAYER_MODEL.md run-9 follow-up explicitly named adaptive xp_reward as
# Output #6 candidate — *inverted* on the same scalar so the harder fight is
# also the bigger reward, closing Owen's mastery loop. A tamed faction's
# survivors are tougher (cooldown / chase / damage all up) AND give MORE XP
# per kill, not less. +20% ceiling — wider than damage's +12% because xp is
# a pure-positive knob (no on-Alden tolerance pressure to balance against),
# and because the size of the ⚡ reward should *feel* commensurate with the
# three coupled punisher-buffs the prefix already promises. Multiplicative
# because per-kind xp_reward varies wildly (Scout 18, Boss 480) — preserving
# each kind's relative weight matters more than a flat ceiling. A scout's
# 18 xp lifts to round(21.6) = 22 at pressure 0.0; a brute's 36 lifts to
# round(43.2) = 43; a boss's 480 lifts to round(576.0) = 576 — proportional,
# role preserved. The clamp uses ceil(ceiling_f) so a future tighter round()
# rule can't escape the band. At pressure 1.0 (fresh save) every enemy stays
# at its WorldBuilder-assigned baseline, so Alden's first-hour grind is
# byte-identical to runs 1–9. After this lands, the enemy axis of
# `faction_pressure` is FULLY wired (6 outputs: dialogue + 2x density +
# cooldown + chase + damage + xp); the next true frontier is the day
# `World.player_pressure_signal()` ships.
const XP_REWARD_AGITATION_GAIN: float = 0.20

var hp: int
var _state: String = "idle"  # idle | wander | chase | attack | dead
var _player: CharacterBody3D = null
var _attack_timer: float = 0.0
var _wander_timer: float = 0.0
var _wander_target: Vector3
var _spawn_pos: Vector3
var _gravity: float = 20.0
var _model: Node3D
var _hp_bar: Node3D
var _label: Label3D


signal died(enemy)

func _ready() -> void:
	hp = max_hp
	# Run-7: faction-pressure-driven attack cooldown. Resolved ONCE at spawn
	# (not per-frame) so combat hot path stays cheap. Mutates `attack_cooldown`
	# in-place — the existing _do_attack() path is untouched.
	_resolve_adaptive_cooldown()
	# REFINE: adaptive — Run-8 chase_speed lerp on the same scalar.
	# Fail-soft contract is identical to cooldown's; runs AFTER WorldBuilder
	# has set the per-kind chase_speed export so the baseline read is correct.
	_resolve_adaptive_chase_speed()
	# REFINE: adaptive — Run-9 damage lerp on the same scalar (Output #5).
	# Same fail-soft contract; runs AFTER WorldBuilder has set the per-kind
	# damage export so the baseline read is correct. Tightest band of the
	# three (+12% vs cooldown's [1.05,1.45]/+38% and chase_speed's +17%)
	# because damage compounds with the other two on the same pressure axis.
	_resolve_adaptive_damage()
	# REFINE: adaptive — Run-10 xp_reward inverse-lerp on the same scalar
	# (Output #6, FINAL on the enemy axis). Same fail-soft contract; runs
	# AFTER WorldBuilder has set the per-kind xp_reward export so the baseline
	# read is correct. Pure-positive knob (Owen's mastery loop closer) — wider
	# +20% band than damage's +12% because there's no Alden-tolerance pressure
	# to balance against on the reward side.
	_resolve_adaptive_xp_reward()
	_spawn_pos = global_position
	add_to_group("enemies")
	collision_layer = 4    # enemy layer
	collision_mask = 1 | 4 # collide with world (1) and other enemies (4)

	# Capsule collider
	var cs := CollisionShape3D.new()
	var caps := CapsuleShape3D.new()
	caps.radius = 0.40; caps.height = 1.6
	cs.shape = caps
	cs.position.y = 0.9
	add_child(cs)

	# Hit area for player attacks (a slightly larger area than the body)
	var hit_area := Area3D.new()
	hit_area.name = "HitArea"
	hit_area.collision_layer = 8
	hit_area.collision_mask = 0
	add_child(hit_area)
	var hac := CollisionShape3D.new()
	var hcaps := CapsuleShape3D.new()
	hcaps.radius = 0.55; hcaps.height = 1.8
	hac.shape = hcaps
	hac.position.y = 0.9
	hit_area.add_child(hac)

	# Visual model
	_spawn_model()

	# Floating name label
	_label = Label3D.new()
	_label.text = enemy_name
	_label.font_size = 22
	_label.outline_size = 4
	_label.outline_modulate = Color(0, 0, 0)
	_label.modulate = Color(1.0, 0.55, 0.45) if enemy_kind == "goblin" else Color(0.85, 0.85, 1.0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position = Vector3(0, 2.1, 0)
	_label.no_depth_test = true
	add_child(_label)

	# Floating HP bar (a billboard plane that scales)
	_hp_bar = _make_hp_bar()
	add_child(_hp_bar)

	_pick_wander_target()

func _spawn_model() -> void:
	if _model:
		_model.queue_free()
	# THEME §4: prefer a per-kind hand-crafted GLB (assets/models/enemies/) when present;
	# fall back to the @export'd placeholder for kinds we haven't sourced yet.
	var src: PackedScene = KIND_MODELS.get(enemy_kind, enemy_model)
	var uses_real_model: bool = src != enemy_model
	_model = src.instantiate()
	call_deferred("_normalize_to_height", _model, 1.5)  # enemies ~1.5m
	# Scale by kind
	match enemy_kind:
		"goblin":
			_model.scale = Vector3(0.85, 0.85, 0.85)
		"wolf":
			# Real wolf.glb stands on its own four legs (Y-up). NO unconditional
			# rotation.x = -PI/2 — that legacy hack would flip a real quadruped
			# onto its back. Apply it ONLY when the kind has fallen back to a
			# humanoid placeholder (worker_girl) so the silhouette at least
			# suggests a four-legged shape.
			# scale-eng 2026-05-05: wolves now join "wolves" group. The global
			# sweep targets that group at 1.0m ±30% (canon: target 1.0 cap 1.4
			# floor 0.7); previously they matched "enemies" target 1.40 ±20%
			# → band [1.12, 1.68], over the 1.4m wolf cap. Body is added below to
			# both groups so the sweep finds the correct target.
			add_to_group("wolves")
			_model.scale = Vector3(0.95, 0.95, 0.95)
			if not uses_real_model:
				_model.rotation.x = -PI / 2  # placeholder-only quadruped hack
		"bandit":
			_model.scale = Vector3(1.05, 1.05, 1.05)
		"skeleton":
			_model.scale = Vector3(1.00, 1.05, 1.00)
		"crystal_elemental":
			_model.scale = Vector3(1.10, 1.20, 1.10)
		"crystal_guardian":
			_model.scale = Vector3(1.55, 1.65, 1.55)
		"bandit_captain":
			# COMPOUND (run 23 — Builder): captain reads as a mini-boss at
			# 30m by silhouette alone — 1.40× the regular bandit_scale (1.05).
			# Y bumped a touch higher than X/Z to add the "shoulders that
			# enter the room first" feel. Final visible height after the
			# global scale sweep clamps to ≤1.4m for "enemies" group; the
			# captain also joins the "boss_silhouettes" group below for any
			# future polish run that wants to lift bosses above the cap.
			add_to_group("boss_silhouettes")
			_model.scale = Vector3(1.40, 1.50, 1.40)
		_:
			_model.scale = Vector3(1.0, 1.0, 1.0)
	add_child(_model)
	# Real fantasy models carry their own painted textures — applying a
	# placeholder tint would muddy them. Tint only the fallback humanoid OR
	# the kinds in KIND_TINT_OVERRIDE (currently the stone-grey Drugdör golem
	# GLB shared by crystal_elemental / crystal_guardian, plus bandit_captain
	# whose deeper purple-leather Color is the silhouette differentiator
	# from regular bandits — the kind's `tint` Color is the whole point of
	# the silhouette in those branches).
	var force_tint: bool = KIND_TINT_OVERRIDE.get(enemy_kind, false)
	if (not uses_real_model) or force_tint:
		_model.call_deferred("propagate_call", "set", ["modulate", tint])
	# Auto-play idle animation whenever the model carries one (every real
	# role-correct GLB in KIND_MODELS ships at least an "Idle" anim — see
	# _play_model_idle_anim()). Static T-pose enemies are banned per THEME §12.
	if uses_real_model:
		call_deferred("_play_model_idle_anim")

func _play_model_idle_anim() -> void:
	# Walks the spawned model subtree for an AnimationPlayer and plays an idle-flavored
	# animation if one exists. Names vary by source GLB — try a few common spellings.
	# Also merges humanoid_base.tres so canonical "humanoid/idle" works for any
	# enemy whose source GLB shipped without an idle (RIGGING_STANDARD §Required).
	if not is_instance_valid(_model):
		return
	var ap: AnimationPlayer = _find_animation_player(_model)
	if ap == null:
		return
	const HUMANOID_BASE_LIB := "res://assets/animations/humanoid_base.tres"
	if ResourceLoader.exists(HUMANOID_BASE_LIB):
		var _lib := load(HUMANOID_BASE_LIB) as AnimationLibrary
		if _lib != null:
			if ap.has_animation_library("humanoid"):
				ap.remove_animation_library("humanoid")
			ap.add_animation_library("humanoid", _lib)
	# Exact-name lookup: the "IdleAnimation" / "Idle" / "Armature|Idle" forms
	# are the names the existing rigged GLBs ship with. "Idle 01" was added
	# when the Sketchfab "skeleton warrior" GLB landed — Sketchfab's exporter
	# names animations like "Idle 01" / "Combat Run 01" / "Death 01" with a
	# trailing space + index. Pinning the literal spares us a substring match
	# on the hot idle path.
	for n in ["humanoid/idle", "IdleAnimation", "Idle", "idle", "Idle 01", "ANIM_Idle", "Armature|Idle"]:
		if ap.has_animation(n):
			ap.play(n)
			return
	# Case-insensitive substring fallback — catches future Sketchfab/Mixamo
	# imports whose idle anim is called e.g. "idle_01", "char_idle", or
	# "Mixamo|Idle" without forcing a code change. Picks the first match in
	# the file's animation order (stable across saves).
	var names := ap.get_animation_list()
	for nm in names:
		if "idle" in String(nm).to_lower():
			ap.play(nm)
			return
	# Last resort — play whatever the file ships with first. WARNING: for
	# Sketchfab GLBs this can be a non-idle pose (e.g. "Parry Shield 01"
	# first in skeleton.glb), so the substring fallback above is preferred.
	if names.size() > 0:
		ap.play(names[0])

func _find_animation_player(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var found := _find_animation_player(c)
		if found != null:
			return found
	return null

func _make_hp_bar() -> Node3D:
	var root := Node3D.new()
	root.position = Vector3(0, 2.4, 0)
	# Background (red)
	var bg := MeshInstance3D.new()
	var bgm := StandardMaterial3D.new()
	bgm.albedo_color = Color(0.5, 0.06, 0.06)
	bgm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	bgm.no_depth_test = true
	bgm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var qm := QuadMesh.new()
	qm.size = Vector2(1.4, 0.14)
	bg.mesh = qm
	bg.material_override = bgm
	root.add_child(bg)
	# Foreground (green)
	var fg := MeshInstance3D.new()
	var fgm := StandardMaterial3D.new()
	fgm.albedo_color = Color(0.30, 0.85, 0.35)
	fgm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	fgm.no_depth_test = true
	fgm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var qmf := QuadMesh.new()
	qmf.size = Vector2(1.36, 0.10)
	fg.mesh = qmf
	fg.material_override = fgm
	fg.name = "HPFill"
	fg.position.z = 0.001
	root.add_child(fg)
	return root

func _update_hp_bar() -> void:
	if not _hp_bar: return
	var fill := _hp_bar.get_node_or_null("HPFill")
	if not fill: return
	var ratio := float(hp) / float(max_hp)
	fill.scale.x = max(0.001, ratio)
	# Hide HP bar at full HP for cleaner look
	_hp_bar.visible = (hp < max_hp and hp > 0)

func _physics_process(delta: float) -> void:
	if _state == "dead":
		return
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0

	# Find player
	if not _player:
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_player = players[0]
		else:
			# Fallback: search for the Player node
			_player = get_tree().current_scene.get_node_or_null("Player")
	if not _player:
		_idle_drift(delta)
		move_and_slide()
		return

	var to_player: Vector3 = _player.global_position - global_position
	to_player.y = 0
	var dist := to_player.length()

	_attack_timer = max(0.0, _attack_timer - delta)

	if dist < attack_range:
		_state = "attack"
		velocity.x = 0; velocity.z = 0
		_face_target(to_player, delta)
		if _attack_timer <= 0:
			_do_attack()
	elif dist < aggro_range:
		_state = "chase"
		var dir := to_player.normalized()
		velocity.x = dir.x * chase_speed
		velocity.z = dir.z * chase_speed
		_face_target(to_player, delta)
	else:
		_idle_drift(delta)

	move_and_slide()

func _face_target(dir: Vector3, delta: float) -> void:
	if dir.length() < 0.001:
		return
	var target_basis := Basis.looking_at(dir.normalized(), Vector3.UP)
	global_transform.basis = global_transform.basis.slerp(target_basis, 8.0 * delta)

func _idle_drift(delta: float) -> void:
	_state = "wander"
	_wander_timer -= delta
	if _wander_timer <= 0:
		_pick_wander_target()
	var to_target: Vector3 = _wander_target - global_position
	to_target.y = 0
	# REFINE: character — wander arrival radius 0.5 → 0.35 m. Mirrors the run-11 NPC
	# schedule arrival radius (NPC.gd `schedule_arrival_radius`). The 0.5m slop produced
	# a visible "almost-there hover" where goblins twitch in place a half-step before
	# settling; 0.35m gives a cleaner stop beat without inducing jitter (per-frame step
	# at the new wander speed below is well under 0.01m). THEME §12 — motion that lands.
	if to_target.length() < 0.35:
		velocity.x = 0; velocity.z = 0
		return
	var dir := to_target.normalized()
	# REFINE: character — wander move uses 0.55 × move_speed instead of full move_speed.
	# At full speed every goblin paced their territory like a soldier on patrol — same
	# stride between idle and chase, only the destination changed. Halving (and a bit)
	# lets the IDLE state read as "feral creature ranging" while CHASE keeps its full
	# aggro stride. Goblin scout @ move_speed 2.6 → wander 1.43 m/s; wolf @ 2.0 →
	# 1.10 m/s; brute @ 2.4 → 1.32 m/s. THEME §1 ("lived-in") + §12 (motion that
	# isn't mechanical). Compounds on Pet.gd's "stickier stop" run (Pet.gd:83) — the
	# same anti-skating instinct, applied to enemy wander.
	var wander_speed: float = move_speed * 0.55
	velocity.x = dir.x * wander_speed
	velocity.z = dir.z * wander_speed
	_face_target(to_target, delta)

func _pick_wander_target() -> void:
	var rng := RandomNumberGenerator.new(); rng.randomize()
	var ang := rng.randf() * TAU
	# REFINE: character — wander distance band 2.0–7.0 → 1.6–7.8 m. Same ~4.5m mean,
	# but the wider variance lets some loops read as "sniffing the same patch" (tight
	# 1.6–3m circles) and others as "scouting the perimeter" (wide 6–7.8m sweeps).
	# Uniform 2–7 read as a metronome on watch towers; this stops the cluster of three
	# goblins in a camp from looking like they're running the same drill in unison.
	var dist := rng.randf_range(1.6, 7.8)
	_wander_target = _spawn_pos + Vector3(cos(ang) * dist, 0, sin(ang) * dist)
	# REFINE: character — wander dwell band 2.0–5.0 → 2.4–6.5 s. The lower bound
	# being 2.0s meant some goblins re-pathed every 2 seconds — visibly twitchy, far
	# from the THEME §1 "lived-in" target. 2.4s minimum lets an idle animation cycle
	# read at least once between repaths; 6.5s ceiling adds the occasional "long stare
	# at nothing" that real animals do. Wider variance (range 2.5x → 4.1x) breaks the
	# group-sync metronome that made multi-goblin camps feel choreographed.
	_wander_timer = rng.randf_range(2.4, 6.5)

func _do_attack() -> void:
	_attack_timer = attack_cooldown
	if _player and _player.has_method("take_damage"):
		_player.take_damage(damage)
		# REFINE: combat-feel — heavier knockback (3.0 → 4.5) for a more readable "hit" beat. Adds breathing space too.
		var dir := (_player.global_position - global_position).normalized()
		_player.velocity += dir * 4.5

# ──────────────────────────────────────────────────────────────────────────
# Take damage from player
# ──────────────────────────────────────────────────────────────────────────
func take_damage(amount: int, source: Node = null) -> void:
	if _state == "dead":
		return
	hp = max(0, hp - amount)
	_update_hp_bar()
	_spawn_damage_number(amount, false)
	# Aggro the attacker if not already chasing
	if source and not _player:
		_player = source
	if hp <= 0:
		_die(source)

func _spawn_damage_number(amount: int, is_crit: bool) -> void:
	# REFINE: combat-feel — crit damage number §3 #FFD86B convergence. Crit color (1.0, 0.88, 0.22) → (1.00, 0.85, 0.42); B=0.22 read as deep amber/mustard, well off the canonical sunset-gold the rest of the project's mastery-tier surfaces converged on (UITheme.GOLD, Chest.gd glow_color, WorldMap COL_TITLE, NPC nameplate modulate, Player.gd title_label modulate, LEVEL UP! popup, Boss.gd crown emission, and the Player.gd CRIT! flash on line 468 that this run also pulled in). Crit-tier feedback now beats on one painterly gold across player flash + enemy number — Owen's mastery-affinity 'I earned that one' read aligned across the chain (PLAYER_MODEL.md — visible mastery, damage numbers). Normal-hit color (1.0, 0.72, 0.32) preserved: that's the warm-bronze hammer-hit tier, intentionally distinct from gold crit-tier — keeps the visual hierarchy 'normal hit < crit hit' readable at a glance, which is the point of this REFINE in the first place. THEME §3 palette discipline + chunkier font preserved.
	UITheme.spawn_damage_popup(get_tree().current_scene, global_position + Vector3(randf_range(-0.3, 0.3), 1.8, randf_range(-0.3, 0.3)), ("%d!" % amount) if is_crit else str(amount), Color(1.00, 0.85, 0.42) if is_crit else Color(1.0, 0.72, 0.32), 62 if is_crit else 44, 7)

func _die(source: Node) -> void:
	_state = "dead"
	get_tree().call_group("world", "play_sfx", "enemy_death")
	# Hide model + bars
	if _model: _model.visible = false
	if _hp_bar: _hp_bar.visible = false
	if _label: _label.visible = false
	# Drop loot — XP/gold to player
	if source and source.has_method("gain_xp"):
		source.gain_xp(xp_reward)
	if source and "gold" in source:
		source.gold += gold_reward
		if source.has_signal("stats_changed"):
			source.stats_changed.emit()
	# Roll item loot from drop table — equipment may roll affix variants
	var rng := RandomNumberGenerator.new(); rng.randomize()
	var drops = Items.roll_loot(enemy_kind, rng)
	var world = get_tree().current_scene
	for d in drops:
		if source and source.get("inventory"):
			# 35% chance equipment becomes an affix variant for richer loot
			var base = Items.get_item(d.id)
			if base.has("slot") and base.slot != "" and rng.randf() < 0.35:
				var affix = Items.generate_affix_item(d.id, rng)
				if not affix.is_empty():
					if world and world.has_method("register_runtime_item"):
						world.register_runtime_item(affix)
					source.inventory.add_item(affix.runtime_id, 1)
					_spawn_loot_popup(affix, 1)
					continue
			source.inventory.add_item(d.id, d.qty)
			get_tree().call_group("world", "play_sfx", "loot_pickup")
			var item = Items.get_item(d.id)
			_spawn_loot_popup(item, d.qty)
	# Floating "+XP" popup
	UITheme.spawn_damage_popup(get_tree().current_scene, global_position + Vector3(0, 2.0, 0), "+%d XP" % xp_reward, Color(0.55, 0.95, 0.45), 36, 5)
	died.emit(self)
	# Notify quest system
	get_tree().call_group("quest_listeners", "on_enemy_killed", enemy_kind)
	# Schedule respawn
	await get_tree().create_timer(respawn_delay).timeout
	_respawn()

func _respawn() -> void:
	hp = max_hp
	global_position = _spawn_pos
	if _model: _model.visible = true
	if _label: _label.visible = true
	_state = "idle"
	_player = null
	_update_hp_bar()

func _spawn_loot_popup(item: Dictionary, qty: int) -> void:
	if item.is_empty():
		return
	var color: Color = Items.RARITY_COLORS.get(item.get("rarity", "common"), Color.WHITE)
	UITheme.spawn_damage_popup(get_tree().current_scene, global_position + Vector3(0, 2.4, 0), "+ %s%s" % [item.get("name", "?"), (" x%d" % qty) if qty > 1 else ""], color, 28, 5)

# ──────────────────────────────────────────────────────────────────────────
# Run-7: Adaptive attack cooldown (THIRD output on faction_pressure scalar).
# ──────────────────────────────────────────────────────────────────────────
# Reads `World.faction_pressure(faction_id)` once at spawn and lerps the
# enemy's attack_cooldown across the kid-tuned [1.05, 1.45] band. Pressure
# 1.0 (fresh save) → 1.45 (Alden's recovery valve). Pressure 0.0 (faction
# tamed) → 1.05 (Owen's mastery rung; the few survivors hit fast). Same
# fail-soft contract as WorldBuilder spawn density: missing world node,
# missing accessor, or unmapped kind ALL fall through to baseline — never
# crash. See SYSTEM_REGISTRY.md "Enemy Cooldown Schema" for the contract.
func _resolve_adaptive_cooldown() -> void:
	var faction_id: String = KIND_TO_FACTION.get(enemy_kind, "")
	if faction_id == "":
		return  # Unmapped kind (bandit, etc.) → baseline
	var world_node: Node = get_tree().get_first_node_in_group("world")
	if world_node == null or not world_node.has_method("faction_pressure"):
		return  # Older World.gd or world not yet ready → baseline
	var pressure: float = float(world_node.faction_pressure(faction_id))
	# pressure ∈ [0,1] guaranteed by World.apply_consequence's clamp, but
	# we re-clamp defensively in case a future writer bypasses the resolver.
	pressure = clamp(pressure, 0.0, 1.0)
	var resolved: float = lerp(ATTACK_COOLDOWN_BASELINE, ATTACK_COOLDOWN_MIN, 1.0 - pressure)
	resolved = clamp(resolved, ATTACK_COOLDOWN_MIN, ATTACK_COOLDOWN_BASELINE)
	assert(resolved >= ATTACK_COOLDOWN_MIN and resolved <= ATTACK_COOLDOWN_BASELINE,
		"Enemy.attack_cooldown out of contract band [1.05, 1.45]")
	attack_cooldown = resolved
	# Player-facing feedback (Rule 2.iii): visible ⚡ prefix on the floating
	# name when this enemy is agitated. Reads at a glance: "this one will
	# hit faster." Applied via enemy_name BEFORE the label is built later
	# in _ready(), so the label picks up the prefix automatically.
	if resolved < AGITATED_COOLDOWN_THRESHOLD:
		enemy_name = "⚡ " + enemy_name


# ──────────────────────────────────────────────────────────────────────────
# REFINE: adaptive — Run-8: Adaptive chase_speed (FOURTH output on the
# faction_pressure scalar). Same shape as _resolve_adaptive_cooldown:
#   • Reads `World.faction_pressure(faction_id)` ONCE at spawn — no per-frame cost.
#   • Multiplicative, NOT absolute: each enemy kind's role-shape (tank-slow
#     Brute, fast Scout, ponderous Crystal Elemental) is preserved — every
#     kind gets the SAME +17% ceiling at pressure 0, NOT the same absolute
#     speed. Owen reads "tamed-wood survivors hunt harder" for ALL kinds.
#   • Reuses KIND_TO_FACTION (single source of truth — same map cooldown uses).
#   • Reuses the `⚡` agitated prefix from _resolve_adaptive_cooldown — no
#     second visual cue, because BOTH outputs lerp on the SAME pressure
#     scalar and trip the threshold at the same point. One marker, two
#     coupled effects: cleaner readability for the kids than two markers.
#   • Fail-soft: missing world / missing accessor / unmapped kind → baseline
#     preserved (never crash, never gate on world readiness).
# At pressure 1.0 (fresh save) every enemy keeps its WorldBuilder-assigned
# chase_speed exactly — Alden's first-hour pacing is byte-identical to runs
# 1–7. At pressure 0.0 the few survivors of a tamed faction chase 17%
# faster — Owen's mastery rung. See SYSTEM_REGISTRY.md "Enemy Chase Schema."
# ──────────────────────────────────────────────────────────────────────────
func _resolve_adaptive_chase_speed() -> void:
	var faction_id: String = KIND_TO_FACTION.get(enemy_kind, "")
	if faction_id == "":
		return  # Unmapped kind (bandit, etc.) → baseline
	var world_node: Node = get_tree().get_first_node_in_group("world")
	if world_node == null or not world_node.has_method("faction_pressure"):
		return  # Older World.gd or world not yet ready → baseline
	var pressure: float = float(world_node.faction_pressure(faction_id))
	pressure = clamp(pressure, 0.0, 1.0)
	var baseline: float = chase_speed
	var ceiling: float = baseline * (1.0 + CHASE_SPEED_AGITATION_GAIN)
	var resolved: float = lerp(baseline, ceiling, 1.0 - pressure)
	resolved = clamp(resolved, baseline, ceiling)
	assert(resolved >= baseline and resolved <= ceiling,
		"Enemy.chase_speed out of contract band [baseline, baseline*1.17]")
	chase_speed = resolved


# Normalize 3D model scale so it ends up ~target_height tall, AND lift the
# model so its BOTTOM aligns with the body's feet (THEME §13 — no half-buried
# characters). Sketchfab GLBs commonly arrive with center-pivots; without this
# lift, half the model sinks below the ground plane on spawn.
# Note: SIZE_STANDARDS.md treats _global_scale_sweep as the authoritative
# scaler — this initial normalize stays so freshly-spawned models read close
# to target before the 0.5s sweep snaps them inside the tolerance band.
func _normalize_to_height(model: Node, target_height: float) -> void:
	await get_tree().process_frame
	if not is_instance_valid(model):
		return
	# Pass 1: world-space AABB → choose uniform scale to hit target_height.
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
	# scale-eng 2026-05-05: iterative shrink. Floor 0.05 → 0.001 so wildly-oversized
	# (100×-1000×) Sketchfab/Meshy enemy GLBs can actually reach target.
	var _pass_n: int = 0
	while _pass_n < 6 and aabb.size.y > 0.001 and (aabb.size.y < target_height * 0.80 or aabb.size.y > target_height * 1.20):
		var _s: float = clamp(target_height / aabb.size.y, 0.001, 5.0)
		if model is Node3D:
			(model as Node3D).scale = (model as Node3D).scale * _s
		else:
			model.scale = Vector3(_s, _s, _s)
		await get_tree().process_frame
		if not is_instance_valid(model): return
		aabb = AABB(); has = false
		for c_re in model.find_children("*", "VisualInstance3D", true):
			var v_re := c_re as VisualInstance3D
			if not v_re: continue
			var a_re := v_re.global_transform * v_re.get_aabb()
			if not has: aabb = a_re; has = true
			else: aabb = aabb.merge(a_re)
		_pass_n += 1
	# Pass 2 (THEME §13 ground contact): re-measure in MODEL-LOCAL space to
	# find the bottom of the visible mesh relative to the model's pivot, then
	# lift the model so the bottom sits at body-local y ≈ 0. The body's capsule
	# rests its bottom near y ≈ 0.1 once gravity settles, so feet-at-0 reads
	# as planted, not floating. If the GLB pivot is already at the feet,
	# local_min_y ≈ 0 and the lift is a no-op.
	await get_tree().process_frame
	if not is_instance_valid(model) or not (model is Node3D):
		return
	var local_min_y: float = INF
	var local_has := false
	var inv_xform: Transform3D = (model as Node3D).global_transform.affine_inverse()
	for c2 in model.find_children("*", "VisualInstance3D", true):
		var v2 := c2 as VisualInstance3D
		if not v2: continue
		var a2 := v2.get_aabb()
		# Convert from v2's local frame → world → model's local frame.
		a2 = (inv_xform * v2.global_transform) * a2
		if not local_has:
			local_min_y = a2.position.y
			local_has = true
		else:
			local_min_y = min(local_min_y, a2.position.y)
	# scale-eng 2026-05-05: SYMMETRIC ground-snap. Was only LIFTING when bottom
	# sat below pivot. New Meshy GLBs sometimes have feet ABOVE pivot (crotch-
	# pivot biped). Snap feet to body-local y=0 in EITHER direction so the
	# camera doesn't end up looking at the model's boots from below.
	if local_has and abs(local_min_y) > 0.05:
		var shift: float = clamp(-local_min_y, -10.0, 2.0)
		(model as Node3D).position.y = (model as Node3D).position.y + shift

# ──────────────────────────────────────────────────────────────────────────
# REFINE: adaptive — Run-9: Adaptive damage (FIFTH output on the
# faction_pressure scalar). Same shape as _resolve_adaptive_chase_speed:
#   • Reads `World.faction_pressure(faction_id)` ONCE at spawn — no per-frame cost.
#   • Multiplicative, NOT absolute: each enemy kind's role-shape (light Scout,
#     heavier Brute, boss-tier Warlord) is preserved — every kind gets the
#     SAME +12% ceiling at pressure 0, NOT the same absolute damage.
#   • Reuses KIND_TO_FACTION (single source of truth — same map cooldown +
#     chase_speed already use).
#   • Reuses the `⚡` agitated prefix from _resolve_adaptive_cooldown — no
#     third visual cue, because all three outputs (cooldown / chase_speed /
#     damage) lerp on the SAME pressure scalar and trip the threshold at the
#     same point. One marker, three coupled effects: cleaner readability for
#     the kids than three markers.
#   • Tighter band (+12%) than chase_speed (+17%) and cooldown's effective
#     ~+38% (1.45 → 1.05 implies the LOWER value hits faster, so the
#     tightening is asymmetric) because damage stacks WITH the other two on
#     the same pressure axis: a faster-chasing, faster-swinging, harder-
#     hitting enemy is three vectors of pressure on Alden's combat tolerance,
#     not one. Damage stays the subordinate knob.
#   • Integer rounding: damage is int, so we round() the lerped float and
#     clamp the int result to [baseline, ceil(baseline*(1+gain))]. This
#     ensures the ceiling actually lands at high pressure (e.g. 6 → 7 at
#     pressure 0.0; without round-up the +12% bump would round-to-zero on
#     small baselines).
#   • Fail-soft: missing world / missing accessor / unmapped kind → baseline
#     preserved (never crash, never gate on world readiness).
# At pressure 1.0 (fresh save) every enemy keeps its WorldBuilder-assigned
# damage exactly — Alden's first-hour combat is byte-identical to runs 1–8.
# At pressure 0.0 the few survivors of a tamed faction hit 12% harder —
# Owen's mastery rung. See SYSTEM_REGISTRY.md "Enemy Damage Schema."
# ──────────────────────────────────────────────────────────────────────────
func _resolve_adaptive_damage() -> void:
	var faction_id: String = KIND_TO_FACTION.get(enemy_kind, "")
	if faction_id == "":
		return  # Unmapped kind (bandit, etc.) → baseline
	var world_node: Node = get_tree().get_first_node_in_group("world")
	if world_node == null or not world_node.has_method("faction_pressure"):
		return  # Older World.gd or world not yet ready → baseline
	var pressure: float = float(world_node.faction_pressure(faction_id))
	pressure = clamp(pressure, 0.0, 1.0)
	var baseline_i: int = damage
	if baseline_i <= 0:
		return  # Defensive: a zero/negative baseline shouldn't be amplified.
	var baseline_f: float = float(baseline_i)
	var ceiling_f: float = baseline_f * (1.0 + DAMAGE_AGITATION_GAIN)
	var resolved_f: float = lerp(baseline_f, ceiling_f, 1.0 - pressure)
	# Round to int, then clamp to the integer band. Ceil(ceiling_f) is the
	# integer ceiling (e.g. 6.72 → 7) so the +12% bump actually lands on
	# small-baseline enemies; round() on resolved_f handles the interior of
	# the band cleanly (lerp at pressure 0.5 of baseline 6 returns 6.36 →
	# round → 6, which stays at baseline as expected for the middle band).
	var ceiling_i: int = int(ceil(ceiling_f))
	var resolved_i: int = int(round(resolved_f))
	resolved_i = clamp(resolved_i, baseline_i, ceiling_i)
	assert(resolved_i >= baseline_i and resolved_i <= ceiling_i,
		"Enemy.damage out of contract band [baseline, ceil(baseline*1.12)]")
	damage = resolved_i



# ──────────────────────────────────────────────────────────────────────────
# REFINE: adaptive — Run-10: Adaptive xp_reward (SIXTH and final output on
# the faction_pressure scalar). Same shape as _resolve_adaptive_damage, with
# ONE deliberate inversion on the *direction* of the lerp:
#   • Reads `World.faction_pressure(faction_id)` ONCE at spawn — no per-frame cost.
#   • Multiplicative, NOT absolute: each enemy kind's role-shape (Scout 18 xp,
#     Brute 36, Wolf 28, Skeleton 24, Elemental 55, Boss 480) is preserved —
#     every kind gets the SAME +20% ceiling at pressure 0, NOT the same
#     absolute xp. Owen's mastery rung scales proportionally across the
#     whole bestiary.
#   • Reuses KIND_TO_FACTION (single source of truth — same map cooldown +
#     chase_speed + damage already use).
#   • Reuses the `⚡` agitated prefix from _resolve_adaptive_cooldown — no
#     fourth visual cue, because all four outputs (cooldown / chase_speed /
#     damage / xp_reward) lerp on the SAME pressure scalar and trip the
#     threshold at the same point. One marker, four coupled effects: clean
#     readability for the kids — when they see ⚡ they learn it means
#     "faster, harder, hits more, but pays more too."
#   • Wider band (+20%) than damage (+12%) and chase_speed (+17%) because
#     xp_reward is a *pure-positive* knob — there's no Alden-combat-tolerance
#     pressure to balance against on the reward side, AND the size of the ⚡
#     reward should *feel* commensurate with the three coupled punisher-buffs
#     the prefix already promises. Asymmetric on purpose: the punishment side
#     stays tight, the reward side opens up.
#   • Integer rounding: xp_reward is int, so we round() the lerped float and
#     clamp the int result to [baseline, ceil(baseline*(1+gain))]. ceil() on
#     the upper bound ensures the +20% bump actually lands on small-baseline
#     enemies (a 6-xp variant would round-to-baseline without it; the actual
#     small baseline in the bestiary is 18, where 21.6 rounds to 22 cleanly).
#   • Fail-soft: missing world / missing accessor / unmapped kind → baseline
#     preserved (never crash, never gate on world readiness).
# At pressure 1.0 (fresh save) every enemy keeps its WorldBuilder-assigned
# xp_reward exactly — Alden's first-hour grind is byte-identical to runs 1–9.
# At pressure 0.0 the few survivors of a tamed faction grant 20% more xp per
# kill — Owen's mastery rung. The enemy axis of `faction_pressure` is fully
# wired after this run. See SYSTEM_REGISTRY.md "Enemy XP Reward Schema."
# ──────────────────────────────────────────────────────────────────────────
func _resolve_adaptive_xp_reward() -> void:
	var faction_id: String = KIND_TO_FACTION.get(enemy_kind, "")
	if faction_id == "":
		return  # Unmapped kind (bandit, etc.) → baseline
	var world_node: Node = get_tree().get_first_node_in_group("world")
	if world_node == null or not world_node.has_method("faction_pressure"):
		return  # Older World.gd or world not yet ready → baseline
	var pressure: float = float(world_node.faction_pressure(faction_id))
	pressure = clamp(pressure, 0.0, 1.0)
	var baseline_i: int = xp_reward
	if baseline_i <= 0:
		return  # Defensive: a zero/negative baseline shouldn't be amplified.
	var baseline_f: float = float(baseline_i)
	var ceiling_f: float = baseline_f * (1.0 + XP_REWARD_AGITATION_GAIN)
	var resolved_f: float = lerp(baseline_f, ceiling_f, 1.0 - pressure)
	# Round to int, then clamp to the integer band. Ceil(ceiling_f) is the
	# integer ceiling (e.g. 21.6 → 22) so the +20% bump actually lands on
	# small-baseline enemies; round() on resolved_f handles the interior of
	# the band cleanly.
	var ceiling_i: int = int(ceil(ceiling_f))
	var resolved_i: int = int(round(resolved_f))
	resolved_i = clamp(resolved_i, baseline_i, ceiling_i)
	assert(resolved_i >= baseline_i and resolved_i <= ceiling_i,
		"Enemy.xp_reward out of contract band [baseline, ceil(baseline*1.20)]")
	xp_reward = resolved_i
