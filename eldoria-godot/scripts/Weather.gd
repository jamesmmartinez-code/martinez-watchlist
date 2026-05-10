extends Node3D
class_name Weather

# Realm of Eldoria — Dynamic Weather System (Builder run 36)
#
# Weather cycles across 4 states keyed on world_day (read from World.time_of_day
# and World.world_day). Adds NO new world primitives — reads only existing
# World.time_of_day, World.world_day, World.world_env, and World._show_toast().
#
# States:
#   "clear"       — default; no rain, ambient fog unchanged
#   "overcast"    — light grey sky tint, slightly denser fog, no rain
#   "rain"        — light rain particle curtain, heavier fog, muffled glow
#   "heavy_rain"  — dense rain curtain, max fog damper, dark sky
#
# Cycle: state hashes from (world_day MOD 7) so the week has a rhythm.
# Days 0,1 = clear | Day 2 = overcast | Days 3,4 = clear | Day 5 = rain |
# Day 6 = heavy_rain. Player sees a ~2 real-min (≈10 in-game-day) weather arc
# before it loops, making the world feel seasonal without a full calendar system.
#
# THEME hooks:
#   §1  painterly: rain is soft alpha-blended streaks — no opaque squares
#   §3  palette: overcast sky shifts toward stone-grey (#8C9BAB); rain cools
#               ambient to blue-slate; heavy rain darkens sun energy ~40%
#   §12 MOTION & LIFE: rain particles have random horizontal drift (wind),
#               _process lerps fog density so transitions breathe not snap
#   §13 GROUND CONTACT: rain emitter placed at canopy height 8m; particles
#               die at y=0 (ground) with lifetime tuned to travel distance
#
# Integration:
#   - WorldBuilder._ready calls _safe_call("_build_weather") which creates
#     this node and adds it as child of World (group "weather").
#   - World._process can read get_tree().get_nodes_in_group("weather") to
#     apply fog corrections each frame — handled internally here instead.
#   - player_home group: on rain start the hearth CPUParticles fires faster
#     (heavier smoke = shelter feeling). Reads group "player_home" for this.

# ── Cycle definition (day-of-week → state) ───────────────────────────────────
# Array[String] — index = world_day MOD 7
const WEEKLY_CYCLE: Array[String] = [
	"clear",       # day 0
	"clear",       # day 1
	"overcast",    # day 2
	"clear",       # day 3
	"rain",        # day 4
	"rain",        # day 5
	"heavy_rain",  # day 6
]

# ── Visual parameters per state ───────────────────────────────────────────────
# fog_density_add: additive offset on top of World._process baseline (0.0020)
# fog_emission_mul: multiplier on World's volumetric_fog_emission_energy
# sun_energy_mul: multiplier on sun.light_energy
# sky_tint: Color to additively blend toward (alpha = blend strength 0.0..1.0)
const STATE_PARAMS: Dictionary = {
	"clear":      {"fog_add": 0.000, "fog_em": 1.00, "sun_mul": 1.00, "rain_density": 0.00},
	"overcast":   {"fog_add": 0.001, "fog_em": 0.75, "sun_mul": 0.70, "rain_density": 0.00},
	"rain":       {"fog_add": 0.002, "fog_em": 0.55, "sun_mul": 0.55, "rain_density": 0.45},
	"heavy_rain": {"fog_add": 0.004, "fog_em": 0.30, "sun_mul": 0.35, "rain_density": 1.00},
}

# ── Runtime state ─────────────────────────────────────────────────────────────
var _current_state: String = "clear"
var _target_state: String = "clear"
var _fog_add: float = 0.0
var _fog_em: float = 1.0
var _sun_mul: float = 1.0
var _rain_density: float = 0.0
var _last_day: int = -1
var _transition_speed: float = 0.08  # lerp alpha per second — gentle drift

var _rain_emitter: GPUParticles3D = null
var _world: Node = null

func _ready() -> void:
	add_to_group("weather")
	_world = get_parent()
	_build_rain_emitter()
	# Evaluate initial state for current world_day without announcing a toast
	_pick_state_silent()

# ── Rain particle emitter ────────────────────────────────────────────────────
# Wide flat emitter at canopy height (8m) rains straight down with slight
# wind-drift. Soft-particle texture from _make_streak_texture() so no opaque
# white quads (PROBLEMS_LOG §1.3 particle blowout prevention).
func _build_rain_emitter() -> void:
	_rain_emitter = GPUParticles3D.new()
	_rain_emitter.name = "RainEmitter"
	# Position: high above village center so rain covers the full 70m² playfield
	# THEME §13: emitter at y=8 (canopy height), particles travel to y=0 (ground)
	_rain_emitter.position = Vector3(0, 8, 0)
	_rain_emitter.amount = 600
	_rain_emitter.lifetime = 1.8
	_rain_emitter.amount_ratio = 0.0   # start invisible; _process lerps this
	_rain_emitter.visibility_aabb = AABB(Vector3(-60, -8, -60), Vector3(120, 10, 120))
	_rain_emitter.local_coords = false

	var pm := ParticleProcessMaterial.new()
	# Emit across a wide flat box: 70m × 1m × 70m centered on emitter
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(35, 0.5, 35)
	# Fall straight down (gravity), slight lateral wind-drift
	pm.direction = Vector3(0.0, -1.0, 0.0)
	pm.spread = 4.0
	pm.gravity = Vector3(0.5, -12.0, 0.3)   # slight wind push X+Z
	pm.initial_velocity_min = 6.0
	pm.initial_velocity_max = 9.0
	# Thin short streak: 0.02m wide, 0.22m long — reads as rain at distance
	pm.scale_min = 0.02
	pm.scale_max = 0.04
	# Fade in at start, fade out before hitting ground — no hard pop
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(0.15, 1.0))
	curve.add_point(Vector2(0.85, 0.8))
	curve.add_point(Vector2(1.0, 0.0))
	# Godot 4: ParticleProcessMaterial.alpha_curve expects a CurveTexture, not a raw Curve.
	# Wrap it so the parse error ("Value of type Curve cannot be assigned to Texture2D") is gone.
	var alpha_tex := CurveTexture.new()
	alpha_tex.curve = curve
	pm.alpha_curve = alpha_tex
	pm.color = Color(0.72, 0.82, 0.92, 0.55)   # cool blue-white, semi-transparent

	_rain_emitter.process_material = pm

	# Quad mesh for each streak — elongated along velocity axis
	var quad := QuadMesh.new()
	quad.size = Vector2(0.03, 0.22)
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.76, 0.88, 0.96, 0.50)
	mat.albedo_texture = _make_streak_texture()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	mat.no_depth_test = false
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	quad.material = mat
	_rain_emitter.draw_pass_1 = quad

	add_child(_rain_emitter)

# ── Procedural streak texture (PROBLEMS_LOG §1.3 compliance) ────────────────
# A 4×16 px gradient: opaque white centre, transparent top and bottom.
# Prevents the "opaque rectangle" white-blob particle problem.
func _make_streak_texture() -> ImageTexture:
	var img := Image.create(4, 16, false, Image.FORMAT_RGBA8)
	for y in 16:
		var alpha: float = sin(float(y) / 15.0 * PI)   # 0→1→0 arc
		var c := Color(0.80, 0.90, 1.00, alpha * 0.60)
		for x in 4:
			img.set_pixel(x, y, c)
	var tex := ImageTexture.create_from_image(img)
	return tex

# ── State machine ────────────────────────────────────────────────────────────
func _pick_state_silent() -> void:
	if _world == null or not _world.has_method("get") :
		return
	var day: int = int(_world.get("world_day"))
	_last_day = day
	_target_state = WEEKLY_CYCLE[day % 7]
	_current_state = _target_state
	# Snap visual params immediately (no transition on first load)
	var p: Dictionary = STATE_PARAMS.get(_target_state, STATE_PARAMS["clear"])
	_fog_add = float(p.get("fog_add", 0.0))
	_fog_em = float(p.get("fog_em", 1.0))
	_sun_mul = float(p.get("sun_mul", 1.0))
	_rain_density = float(p.get("rain_density", 0.0))
	if _rain_emitter:
		_rain_emitter.amount_ratio = _rain_density

func _pick_state_new_day() -> void:
	# Called when world_day changes. Picks new target, shows toast on change.
	if _world == null:
		return
	var day: int = int(_world.get("world_day"))
	var new_state: String = WEEKLY_CYCLE[day % 7]
	if new_state == _target_state:
		return
	var old_state: String = _target_state
	_target_state = new_state
	# Toast — child-readable, lore-flavored (THEME §7 warm gravitas)
	var msg: String = _weather_toast(old_state, new_state)
	if msg != "" and _world.has_method("_show_toast"):
		_world.call_deferred("_show_toast", msg)
	# Notify player_home group so hearth smoke reacts to rain
	_notify_home_weather(new_state)

func _weather_toast(from: String, to: String) -> String:
	if to == "overcast":
		return "Clouds roll in from the Whisperwood."
	elif to == "rain" and from == "clear":
		return "🌧 The first drops of rain kiss the cobblestones."
	elif to == "rain" and from == "overcast":
		return "🌧 The clouds break. Rain over Briarwood."
	elif to == "heavy_rain":
		return "⛈ A storm rolls down from the mountain ring."
	elif to == "clear" and (from == "rain" or from == "heavy_rain"):
		return "☀ The rain passes. Briarwood glistens."
	elif to == "clear" and from == "overcast":
		return "The clouds thin. Warm light returns."
	return ""

func _notify_home_weather(state: String) -> void:
	# player_home group hook: signal rain/clear so hearth can adjust smoke rate.
	# We write a lightweight flag — the group node reads it in its own _process.
	var raining: bool = (state == "rain" or state == "heavy_rain")
	for node in get_tree().get_nodes_in_group("player_home"):
		if node.has_method("set_rain_mode"):
			node.set_rain_mode(raining)
		elif node is Node:
			# Fallback: set a meta so PlayerHome._process can read it
			node.set_meta("weather_raining", raining)

# ── _process: lerp visual params, push to World ──────────────────────────────
func _process(delta: float) -> void:
	if _world == null:
		return
	# Detect new day
	var day: int = int(_world.get("world_day"))
	if day != _last_day:
		_last_day = day
		_pick_state_new_day()

	# Lerp toward target params
	var p: Dictionary = STATE_PARAMS.get(_target_state, STATE_PARAMS["clear"])
	var t_fog_add: float = float(p.get("fog_add", 0.0))
	var t_fog_em: float = float(p.get("fog_em", 1.0))
	var t_sun_mul: float = float(p.get("sun_mul", 1.0))
	var t_rain: float = float(p.get("rain_density", 0.0))
	var alpha: float = clamp(_transition_speed * delta * 60.0, 0.0, 1.0)

	_fog_add = lerp(_fog_add, t_fog_add, alpha)
	_fog_em = lerp(_fog_em, t_fog_em, alpha)
	_sun_mul = lerp(_sun_mul, t_sun_mul, alpha)
	_rain_density = lerp(_rain_density, t_rain, alpha)

	# Apply to rain emitter
	if _rain_emitter:
		_rain_emitter.amount_ratio = clamp(_rain_density, 0.0, 1.0)

	# Apply fog offset to World's environment (additive on top of World._process)
	var world_env_node = _world.get("world_env") if _world.has_method("get") else null
	if world_env_node and world_env_node is WorldEnvironment:
		var env := (world_env_node as WorldEnvironment).environment
		if env:
			# Add weather fog on top of the time-of-day baseline already set by World._process
			env.fog_density = clamp(env.fog_density + _fog_add, 0.0, 0.012)
			# Scale volumetric glow by weather multiplier
			env.volumetric_fog_emission_energy *= clamp(_fog_em, 0.1, 1.0)

	# Apply sun energy weather multiplier
	var sun_node = _world.get("sun") if _world.has_method("get") else null
	if sun_node and sun_node is DirectionalLight3D:
		(sun_node as DirectionalLight3D).light_energy *= clamp(_sun_mul, 0.2, 1.0)

# ── Public accessor for other systems ────────────────────────────────────────
func get_current_state() -> String:
	return _target_state

func is_raining() -> bool:
	return _target_state == "rain" or _target_state == "heavy_rain"
