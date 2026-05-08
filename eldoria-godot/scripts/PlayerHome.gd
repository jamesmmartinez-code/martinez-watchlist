extends StaticBody3D
class_name PlayerHome

# Realm of Eldoria — Player Home (Backlog #10: Housing / player-shaped spaces)
#
# A small timber-framed cottage on the north edge of Briarwood Village.
# Always visible from day one; interior dressing (lit hearth, storage chest,
# candle) appears only after first_quest_done is set on World.
#
# 5-output contract:
#   i.  INTEGRATION  — _build_player_home() called from WorldBuilder._ready
#                      via _safe_call; node joins group "player_home".
#   ii. SCHEMA       — HOME_POS const (WorldBuilder) + interior_unlocked bool
#                      + _storage_chest node + group "player_home".
#   iii.FEEDBACK     — InteractArea + E key triggers toast on first entry.
#   iv. EVAL         — interior visible only when World.has_world_flag
#                      ("first_quest_done") — re-checked each _ready.
#   v.  HOOKS        — "player_home" group (future WeatherSystem/SeasonSystem);
#                      World.set_world_flag("player_home_visited") on entry;
#                      _storage_chest joins group "chests" (Minimap pin).
#
# THEME §1  — timber-frame + thatched roof matches village houses.
# THEME §3  — warm amber window glow; sunset-gold nameplate (#FFD86B).
# THEME §12 — hearth CPUParticles3D sparks, candle sine flicker, chimney smoke.
# THEME §13 — all geometry base at y=0; no floating, no buried edges.

const INTERACT_RADIUS: float = 3.2
const CANDLE_FREQ: float     = 1.4
const CANDLE_AMP: float      = 0.18
const CANDLE_BASE: float     = 1.10

var interior_unlocked: bool  = false
var _visited: bool           = false
var _player_in_range: bool   = false
var _player: Node            = null
var _candle_mat: StandardMaterial3D = null
var _candle_t: float         = 0.0
var _world_node: Node        = null
var _storage_chest: Node3D   = null

func unlock_interior() -> void:
	if interior_unlocked:
		return
	interior_unlocked = true
	_show_interior_dressing()

func _ready() -> void:
	add_to_group("player_home")
	collision_layer = 1
	collision_mask  = 0
	_world_node = get_parent()
	if _world_node and _world_node.has_method("has_world_flag"):
		if bool(_world_node.call("has_world_flag", "first_quest_done")):
			interior_unlocked = true
	_build_shell()
	_build_nameplate()
	_build_interact_area()
	if interior_unlocked:
		_show_interior_dressing()

func _process(delta: float) -> void:
	if _candle_mat != null:
		_candle_t += delta * CANDLE_FREQ * TAU
		_candle_mat.emission_energy_multiplier = CANDLE_BASE + sin(_candle_t) * CANDLE_AMP
	if _player_in_range and _player != null:
		if Input.is_action_just_pressed("interact"):
			_on_player_interact()

func _build_shell() -> void:
	# Foundation — THEME §13: base at y=0
	var foundation := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(4.4, 0.5, 4.4)
	foundation.mesh = fm
	foundation.material_override = _mat_stone()
	foundation.position.y = 0.25
	add_child(foundation)
	var fcol := CollisionShape3D.new()
	var fbox := BoxShape3D.new()
	fbox.size = Vector3(4.4, 0.5, 4.4)
	fcol.shape = fbox
	fcol.position.y = 0.25
	add_child(fcol)

	# Walls
	var wall_mi := MeshInstance3D.new()
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(4.0, 2.8, 4.0)
	wall_mi.mesh = wall_mesh
	wall_mi.material_override = _mat_wood()
	wall_mi.position.y = 1.9
	add_child(wall_mi)
	var wcol := CollisionShape3D.new()
	var wbox := BoxShape3D.new()
	wbox.size = Vector3(4.0, 2.8, 4.0)
	wcol.shape = wbox
	wcol.position.y = 1.9
	add_child(wcol)

	# Corner timber beams
	for dx: float in [-1.9, 1.9]:
		for dz: float in [-1.9, 1.9]:
			var beam := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.22, 2.8, 0.22)
			beam.mesh = bm
			beam.material_override = _mat_dark_wood()
			beam.position = Vector3(dx, 1.9, dz)
			add_child(beam)

	# Horizontal cross beams
	for dy: float in [1.1, 2.1, 3.1]:
		for dz: float in [-2.01, 2.01]:
			var cb := MeshInstance3D.new()
			var cbm := BoxMesh.new()
			cbm.size = Vector3(4.0, 0.16, 0.16)
			cb.mesh = cbm
			cb.material_override = _mat_dark_wood()
			cb.position = Vector3(0.0, dy, dz)
			add_child(cb)

	# Eave
	var eave := MeshInstance3D.new()
	var em := BoxMesh.new()
	em.size = Vector3(4.6, 0.18, 4.6)
	eave.mesh = em
	eave.material_override = _mat_dark_wood()
	eave.position.y = 3.38
	add_child(eave)

	# Thatched roof prism
	var roof := MeshInstance3D.new()
	var pyr := PrismMesh.new()
	pyr.left_to_right = 0.5
	pyr.size = Vector3(5.0, 2.0, 5.0)
	roof.mesh = pyr
	roof.material_override = _mat_roof()
	roof.position.y = 4.38
	add_child(roof)

	# Chimney — THEME §13: rises from foundation level
	var chim := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(0.55, 1.8, 0.55)
	chim.mesh = cm
	chim.material_override = _mat_stone()
	chim.position = Vector3(1.4, 4.9, 1.2)
	chim.name = "Chimney"
	add_child(chim)

	# Front door (south face)
	var door := MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(0.95, 1.75, 0.08)
	door.mesh = dm
	door.material_override = _mat_dark_wood()
	door.position = Vector3(0.0, 1.375, 2.04)
	door.name = "Door"
	add_child(door)

	# Door lintel
	var lintel := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(1.4, 0.18, 0.10)
	lintel.mesh = lm
	lintel.material_override = _mat_dark_wood()
	lintel.position = Vector3(0.0, 2.34, 2.04)
	add_child(lintel)

	# Front window — warm amber glow (THEME §3)
	var win_mat := StandardMaterial3D.new()
	win_mat.albedo_color = Color(0.95, 0.62, 0.22)
	win_mat.emission_enabled = true
	win_mat.emission = Color(1.0, 0.72, 0.32)
	win_mat.emission_energy_multiplier = 1.4
	win_mat.roughness = 0.4
	var win := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.72, 0.60)
	win.mesh = qm
	win.material_override = win_mat
	win.position = Vector3(1.6, 2.1, 2.04)
	add_child(win)

	# East side window
	var win2 := win.duplicate() as MeshInstance3D
	win2.position   = Vector3(2.04, 2.1, -0.5)
	win2.rotation.y = PI / 2.0
	add_child(win2)

func _build_nameplate() -> void:
	var lbl := Label3D.new()
	lbl.text          = "Your Cottage"
	lbl.font_size     = 28
	lbl.modulate      = Color(1.0, 0.86, 0.46)
	lbl.outline_size  = 6
	lbl.outline_modulate = Color(0.04, 0.02, 0.04, 0.92)
	lbl.billboard     = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position      = Vector3(0.0, 5.6, 0.0)
	lbl.name          = "Nameplate"
	add_child(lbl)

func _build_interact_area() -> void:
	var area := Area3D.new()
	area.name = "InteractArea"
	var cs2 := CollisionShape3D.new()
	var sp := SphereShape3D.new()
	sp.radius = INTERACT_RADIUS
	cs2.shape = sp
	cs2.position.y = 1.2
	area.add_child(cs2)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	add_child(area)

func _show_interior_dressing() -> void:
	# Hearth glow — THEME §3 warm amber
	var hearth_light := OmniLight3D.new()
	hearth_light.light_color  = Color(1.0, 0.68, 0.28)
	hearth_light.light_energy = 1.8
	hearth_light.omni_range   = 6.0
	hearth_light.position     = Vector3(1.2, 0.6, -1.4)
	hearth_light.name         = "HearthLight"
	add_child(hearth_light)

	# Hearth flame sparks — THEME §12 MOTION
	var flame := CPUParticles3D.new()
	flame.emitting               = true
	flame.amount                 = 18
	flame.lifetime               = 0.9
	flame.emission_shape         = CPUParticles3D.EMISSION_SHAPE_SPHERE
	flame.emission_sphere_radius = 0.12
	flame.direction              = Vector3(0.0, 1.0, 0.0)
	flame.spread                 = 22.0
	flame.gravity                = Vector3(0.0, 0.4, 0.0)
	flame.initial_velocity_min   = 0.6
	flame.initial_velocity_max   = 1.1
	flame.scale_amount_min       = 0.04
	flame.scale_amount_max       = 0.10
	flame.color                  = Color(1.0, 0.55, 0.12, 0.92)
	flame.position               = Vector3(1.2, 0.55, -1.4)
	flame.name                   = "HearthFlame"
	add_child(flame)

	# Candle on windowsill — flickers via _process (THEME §12)
	var candle := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius    = 0.04
	cyl.bottom_radius = 0.05
	cyl.height        = 0.18
	candle.mesh       = cyl
	_candle_mat = StandardMaterial3D.new()
	_candle_mat.albedo_color             = Color(0.98, 0.94, 0.82)
	_candle_mat.emission_enabled         = true
	_candle_mat.emission                 = Color(1.0, 0.80, 0.40)
	_candle_mat.emission_energy_multiplier = CANDLE_BASE
	candle.material_override = _candle_mat
	candle.position          = Vector3(1.56, 1.44, 1.82)
	candle.name              = "Candle"
	add_child(candle)

	# Storage chest — lightweight visual + "chests" group for Minimap
	_storage_chest = Node3D.new()
	_storage_chest.name = "StorageChest"
	_storage_chest.add_to_group("chests")
	_storage_chest.position = Vector3(-1.3, 0.5, -1.6)
	var cb2 := MeshInstance3D.new()
	var bm2 := BoxMesh.new()
	bm2.size = Vector3(1.0, 0.7, 0.65)
	cb2.mesh = bm2
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.40, 0.24, 0.13)
	cmat.roughness    = 0.92
	cb2.material_override = cmat
	_storage_chest.add_child(cb2)
	var cglow := OmniLight3D.new()
	cglow.light_color  = Color(1.0, 0.86, 0.42)
	cglow.light_energy = 0.6
	cglow.omni_range   = 1.8
	_storage_chest.add_child(cglow)
	add_child(_storage_chest)

	# Chimney smoke — THEME §12 MOTION
	var smoke := CPUParticles3D.new()
	smoke.emitting               = true
	smoke.amount                 = 8
	smoke.lifetime               = 3.5
	smoke.emission_shape         = CPUParticles3D.EMISSION_SHAPE_SPHERE
	smoke.emission_sphere_radius = 0.08
	smoke.direction              = Vector3(0.0, 1.0, 0.0)
	smoke.spread                 = 14.0
	smoke.gravity                = Vector3(0.06, 0.1, 0.0)
	smoke.initial_velocity_min   = 0.3
	smoke.initial_velocity_max   = 0.7
	smoke.scale_amount_min       = 0.06
	smoke.scale_amount_max       = 0.16
	smoke.color                  = Color(0.72, 0.70, 0.68, 0.55)
	smoke.position               = Vector3(1.4, 6.0, 1.2)
	smoke.name                   = "ChimneySmoke"
	add_child(smoke)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		_player = body
		if not interior_unlocked and _world_node != null and _world_node.has_method("has_world_flag"):
			if bool(_world_node.call("has_world_flag", "first_quest_done")):
				unlock_interior()

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		_player = null

func _on_player_interact() -> void:
	if _world_node == null:
		return
	if not _visited and _world_node.has_method("set_world_flag"):
		_world_node.call("set_world_flag", "player_home_visited", true)
		_visited = true
	if _world_node.has_method("_show_toast"):
		if interior_unlocked:
			_world_node.call("_show_toast", "🏠 Home. The hearth is warm.")
		else:
			_world_node.call("_show_toast", "🏠 Your cottage — earn your place in the village first.")

func _mat_wood() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.72, 0.54, 0.34)
	m.roughness    = 0.88
	return m

func _mat_dark_wood() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.32, 0.20, 0.11)
	m.roughness    = 0.90
	return m

func _mat_stone() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.55, 0.52, 0.48)
	m.roughness    = 0.95
	return m

func _mat_roof() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.62, 0.38, 0.28)
	m.roughness    = 0.92
	return m
