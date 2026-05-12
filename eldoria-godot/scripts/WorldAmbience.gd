extends Node
# Realm of Eldoria — WorldAmbience (autoload singleton)
#
# Owns all dynamic environmental visuals + dynamic music.
# Runs a cheap 0.5s-interval loop rather than _process() so it never
# shows up on the GPU profiler.
#
# Registered as autoload "WorldAmbience" in project.godot [autoload].
#
# ── What it manages ───────────────────────────────────────────────────────────
#  Sun (DirectionalLight3D)
#    • Elevation from WorldState.time_of_day  (sin curve, 0°=horizon, 70°=noon)
#    • Color shifts: warm gold at dawn/dusk, cool white at noon, deep blue at night
#    • Shadows off below horizon (saves GPU, avoids shadow artifacts)
#
#  WorldEnvironment (Environment resource)
#    • Fog density + color: rises with WorldState.corruption_level + season
#    • Glow intensity: pulses slightly with EnemyDirector.intensity
#    • Tone mapping: ACES, slight saturation/contrast boost
#    • Ambient light: dark blue-grey base so emissive enemies pop
#
#  Music
#    • Picks a track from Audio.play_music() based on intensity + season
#    • 2-second hysteresis prevents rapid ping-pong
#
# ── Scene compatibility ────────────────────────────────────────────────────────
# Nodes are located by type/name each cycle, then cached.
# If a scene already has DirectionalLight3D or WorldEnvironment those are used;
# otherwise they are created programmatically and attached to the current scene.

# ==========================================================================
# Config
# ==========================================================================
const UPDATE_INTERVAL: float  = 0.50   # seconds between environment ticks
const MUSIC_INTERVAL:  float  = 2.00   # seconds between music re-evaluations

const SUN_MAX_ELEVATION: float = 70.0  # degrees above horizon at noon

# ==========================================================================
# Cached scene nodes (re-resolved after scene changes)
# ==========================================================================
var _sun: DirectionalLight3D = null
var _world_env_node: WorldEnvironment = null
var _env: Environment = null
var _last_scene: Node = null   # detect scene changes

# ==========================================================================
# Music state
# ==========================================================================
var _current_music_tier: int  = -1   # 0=calm, 1=light, 2=heavy, 3=dark
var _music_timer: float       = 0.0

# ==========================================================================
# Timers
# ==========================================================================
var _update_timer: float = 0.0

# ==========================================================================
# Signals
# ==========================================================================
signal sun_set()    # emitted when sun goes below horizon
signal sun_rise()   # emitted when sun crosses horizon upward
var _was_day: bool = true

# ==========================================================================
# Lifecycle
# ==========================================================================
func _ready() -> void:
	# Connect to WorldState signals for instant reaction to major changes
	if is_instance_valid(WorldState):
		WorldState.season_changed.connect(_on_season_changed)
		WorldState.corruption_changed.connect(_on_corruption_changed)

func _process(delta: float) -> void:
	_update_timer -= delta
	_music_timer  -= delta

	if _update_timer <= 0.0:
		_update_timer = UPDATE_INTERVAL
		_ensure_nodes()
		_update_sun()
		_update_environment()

	if _music_timer <= 0.0:
		_music_timer = MUSIC_INTERVAL
		_update_music()

# ==========================================================================
# Node resolution (lazy; re-resolves after scene changes)
# ==========================================================================
func _ensure_nodes() -> void:
	var scene := get_tree().current_scene
	if not scene:
		return

	# Scene changed — clear cached refs so we look fresh
	if scene != _last_scene:
		_sun = null
		_world_env_node = null
		_env = null
		_last_scene = scene

	# ── DirectionalLight3D ─────────────────────────────────────────────────
	if not _sun or not is_instance_valid(_sun):
		_sun = _find_node_of_type(scene, "DirectionalLight3D") as DirectionalLight3D
		if not _sun:
			_sun = _create_sun(scene)

	# ── WorldEnvironment ───────────────────────────────────────────────────
	if not _world_env_node or not is_instance_valid(_world_env_node):
		_world_env_node = _find_node_of_type(scene, "WorldEnvironment") as WorldEnvironment
		if not _world_env_node:
			_world_env_node = _create_world_env(scene)
		if _world_env_node:
			_env = _world_env_node.environment
			if not _env:
				_env = _build_environment()
				_world_env_node.environment = _env

func _find_node_of_type(root: Node, class_name_str: String) -> Node:
	if root.get_class() == class_name_str:
		return root
	for child in root.get_children():
		var found := _find_node_of_type(child, class_name_str)
		if found:
			return found
	return null

func _create_sun(parent: Node) -> DirectionalLight3D:
	var light := DirectionalLight3D.new()
	light.name = "WorldSun"
	light.light_color        = Color(1.0, 0.95, 0.85)
	light.light_energy       = 1.4
	light.shadow_enabled     = true
	light.rotation_degrees   = Vector3(-45.0, -30.0, 0.0)
	parent.call_deferred("add_child", light)
	return light

func _create_world_env(parent: Node) -> WorldEnvironment:
	var we := WorldEnvironment.new()
	we.name = "WorldEnv"
	we.environment = _build_environment()
	parent.call_deferred("add_child", we)
	_env = we.environment
	return we

func _build_environment() -> Environment:
	var env := Environment.new()

	# ── Background ──────────────────────────────────────────────────────────
	env.background_mode  = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.06, 0.10)

	# ── Ambient light — dark so emissive enemies pop ────────────────────────
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color  = Color(0.10, 0.12, 0.20)
	env.ambient_light_energy = 0.30

	# ── Glow ───────────────────────────────────────────────────────────────
	env.glow_enabled    = true
	env.glow_normalized = false
	env.glow_intensity  = 0.80
	env.glow_bloom      = 0.15
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE

	# ── Fog ────────────────────────────────────────────────────────────────
	env.fog_enabled            = true
	env.fog_density            = 0.012
	env.fog_light_color        = Color(0.10, 0.12, 0.22)
	env.fog_aerial_perspective = 0.25

	# ── Tone mapping ───────────────────────────────────────────────────────
	env.tonemap_mode     = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.05
	env.tonemap_white    = 1.0

	# ── Color adjustment ───────────────────────────────────────────────────
	env.adjustment_enabled    = true
	env.adjustment_saturation = 1.10
	env.adjustment_contrast   = 1.15

	return env

# ==========================================================================
# Sun
# ==========================================================================
func _update_sun() -> void:
	if not _sun or not is_instance_valid(_sun):
		return
	if not is_instance_valid(WorldState):
		return

	var t := WorldState.time_of_day
	# sin curve: elevation = 0 at dawn (t=6) and dusk (t=18), peak at noon (t=12)
	var elevation := sin((t - 6.0) / 24.0 * TAU) * SUN_MAX_ELEVATION

	_sun.rotation_degrees.x = -elevation         # negative = angled down from above
	_sun.rotation_degrees.y = (t / 24.0) * 45.0 - 20.0  # slow E→W arc

	# ── Color by time of day ────────────────────────────────────────────────
	var is_day := elevation > 0.0
	if is_day:
		var noon_t := clampf(elevation / SUN_MAX_ELEVATION, 0.0, 1.0)
		# Dawn/dusk = warm orange; high noon = clean white
		_sun.light_color  = Color(1.0, 0.95, 0.85).lerp(Color(1.0, 0.72, 0.40), 1.0 - noon_t)
		_sun.light_energy = lerpf(0.60, 1.50, noon_t)
		_sun.shadow_enabled = true
	else:
		# Night: deep indigo moonlight
		_sun.light_color  = Color(0.25, 0.30, 0.55)
		_sun.light_energy = 0.18
		_sun.shadow_enabled = false   # save GPU at night

	# ── Day/night crossing signals ─────────────────────────────────────────
	var now_day := is_day
	if now_day and not _was_day:
		emit_signal("sun_rise")
		if is_instance_valid(Audio):
			Audio.play_ambient("birds_morning")
	elif not now_day and _was_day:
		emit_signal("sun_set")
		if is_instance_valid(Audio):
			Audio.play_ambient("crickets_night")
	_was_day = now_day

# ==========================================================================
# Environment (fog + glow + ambient)
# ==========================================================================
func _update_environment() -> void:
	if not _env:
		return

	var corruption: float = WorldState.corruption_level if is_instance_valid(WorldState) else 0.0
	var season: String    = WorldState.season          if is_instance_valid(WorldState) else "calm"
	var intensity: float  = EnemyDirector.intensity    if is_instance_valid(EnemyDirector) else 0.0

	# ── Fog density + color ────────────────────────────────────────────────
	var fog_density: float
	var fog_color:   Color
	if season == "apocalypse":
		fog_density = lerpf(0.04, 0.10, corruption)
		fog_color   = Color(0.20, 0.04, 0.04).lerp(Color(0.08, 0.02, 0.02), corruption)
	elif season == "war":
		fog_density = lerpf(0.020, 0.055, corruption)
		fog_color   = Color(0.18, 0.08, 0.06)
	elif season == "unrest":
		fog_density = lerpf(0.012, 0.030, corruption)
		fog_color   = Color(0.12, 0.10, 0.14)
	else:
		fog_density = lerpf(0.008, 0.020, corruption)
		fog_color   = Color(0.10, 0.12, 0.22)

	# Night darkens fog naturally
	if not WorldState.is_daytime() if is_instance_valid(WorldState) else false:
		fog_density *= 1.30
		fog_color = fog_color.darkened(0.25)

	_env.fog_density     = fog_density
	_env.fog_light_color = fog_color

	# ── Glow intensity — pulses with combat intensity ──────────────────────
	var base_glow: float = lerpf(0.65, 1.20, corruption * 0.5)
	var fight_glow: float = lerpf(0.0, 0.40, intensity)
	_env.glow_intensity = base_glow + fight_glow

	# ── Ambient light — darker as corruption rises (enemies pop harder) ────
	var ambient_e: float = lerpf(0.30, 0.12, corruption)
	_env.ambient_light_energy = ambient_e

	# ── Saturation down in apocalypse (desaturated horror look) ───────────
	_env.adjustment_saturation = lerpf(1.10, 0.70, clampf(corruption - 0.70, 0.0, 1.0) / 0.30)

# ==========================================================================
# Music
# ==========================================================================
const MUSIC_THRESHOLDS: Array[float] = [0.25, 0.60, 0.90]

func _update_music() -> void:
	if not is_instance_valid(Audio):
		return

	var intensity: float = EnemyDirector.intensity if is_instance_valid(EnemyDirector) else 0.0
	var season: String   = WorldState.season        if is_instance_valid(WorldState) else "calm"
	var is_day: bool     = WorldState.is_daytime()  if is_instance_valid(WorldState) else true

	var target_tier: int
	if season == "apocalypse":
		target_tier = 3   # always dark
	elif intensity >= MUSIC_THRESHOLDS[2]:
		target_tier = 2   # full combat
	elif intensity >= MUSIC_THRESHOLDS[1]:
		target_tier = 1   # building combat
	elif intensity >= MUSIC_THRESHOLDS[0]:
		target_tier = 0   # low tension
	else:
		target_tier = -1  # full calm — ambient only

	if target_tier == _current_music_tier:
		return
	_current_music_tier = target_tier

	match target_tier:
		-1:
			Audio.stop_music(2.5)
			if is_day:
				Audio.play_ambient("ambient_day")
			else:
				Audio.play_ambient("ambient_night")
		0:
			Audio.play_music("combat_ambient", 1.5)
		1:
			Audio.play_music("combat_light",   1.2)
		2:
			Audio.play_music("combat_heavy",   0.8)
		3:
			Audio.play_music("ambient_dark",   1.8)

# ==========================================================================
# Signal reactions (instant response, no wait for update tick)
# ==========================================================================
func _on_season_changed(new_season: String) -> void:
	# Force immediate fog + music re-evaluation
	_update_timer = 0.0
	_music_timer  = 0.0
	if is_instance_valid(Juice):
		match new_season:
			"war":
				Juice.show_notification("The world enters open war.", Color(0.90, 0.35, 0.20))
			"apocalypse":
				Juice.show_notification("The corruption is overwhelming.", Color(0.70, 0.15, 0.15))
				Juice.screen_tint(Color(0.60, 0.05, 0.05, 0.28), 1.5, 2.0)
			"unrest":
				Juice.show_notification("Tensions are rising across the land.", Color(0.85, 0.65, 0.25))

func _on_corruption_changed(new_level: float) -> void:
	# Spike: instant dramatic fog pulse at major thresholds
	if new_level > 0.85 and _env:
		if is_instance_valid(Juice):
			Juice.screen_tint(Color(0.50, 0.05, 0.05, 0.20), 0.0, 1.5)
		if is_instance_valid(NarrativeSystem):
			NarrativeSystem.record_event("corruption_spike", {"level": new_level})

# ==========================================================================
# Public helpers (called by other systems)
# ==========================================================================
func get_ambient_light_factor() -> float:
	# 0.0 = full night, 1.0 = full noon.  Read by enemies for patrol timing.
	return WorldState.get_ambient_light_factor() if is_instance_valid(WorldState) else 1.0

func get_fog_density() -> float:
	return _env.fog_density if _env else 0.0
