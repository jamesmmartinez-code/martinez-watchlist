extends StaticBody3D
class_name Chest

# Realm of Eldoria — Treasure Chest.
# Procedurally built (no external GLB required). Approach within 2.5m and press
# E to open. Drops 2-4 items rolled from chest_common or chest_rare loot pool.
# Once opened, the lid stays raised and the chest cannot be opened again.

@export var loot_pool: String = "chest_common"   # "chest_common" | "chest_rare"
@export var item_count: int = 3                  # number of items to roll
@export var glow_color: Color = Color(1.0, 0.85, 0.30)

var _opened: bool = false
var _lid: Node3D
var _glow_light: OmniLight3D
var _player_in_range: bool = false
var _player: Node = null

const DAMAGE_NUMBER_SCRIPT = preload("res://scripts/DamageNumber.gd")

func _ready() -> void:
	add_to_group("chests")
	collision_layer = 1
	collision_mask = 0
	_build_visuals()
	_build_interact_area()

func _build_visuals() -> void:
	# Wooden body — box with slight bevel via two stacked boxes
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.2, 0.8, 0.8)
	body.mesh = bm
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.42, 0.26, 0.14)
	wood.roughness = 0.85
	body.material_override = wood
	body.position = Vector3(0, 0.4, 0)
	add_child(body)

	# Iron banding (3 vertical strips)
	var iron := StandardMaterial3D.new()
	iron.albedo_color = Color(0.30, 0.27, 0.25)
	iron.metallic = 0.7
	iron.roughness = 0.4
	for x in [-0.5, 0.0, 0.5]:
		var strip := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(0.06, 0.82, 0.82)
		strip.mesh = sm
		strip.material_override = iron
		strip.position = Vector3(x, 0.4, 0)
		add_child(strip)

	# Lid (tilts up when opened)
	_lid = Node3D.new()
	_lid.name = "Lid"
	_lid.position = Vector3(0, 0.8, -0.4)
	add_child(_lid)
	var lid_mesh := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(1.22, 0.18, 0.85)
	lid_mesh.mesh = lm
	lid_mesh.material_override = wood
	lid_mesh.position = Vector3(0, 0.09, 0.4)
	_lid.add_child(lid_mesh)
	# Lock plate
	var lock := MeshInstance3D.new()
	var lkm := BoxMesh.new()
	lkm.size = Vector3(0.18, 0.20, 0.05)
	lock.mesh = lkm
	var gold_mat := StandardMaterial3D.new()
	gold_mat.albedo_color = Color(0.95, 0.78, 0.25)
	gold_mat.metallic = 0.85; gold_mat.roughness = 0.25
	gold_mat.emission_enabled = true
	gold_mat.emission = Color(1.0, 0.7, 0.2)
	gold_mat.emission_energy_multiplier = 0.4
	lock.material_override = gold_mat
	lock.position = Vector3(0, 0.40, 0.43)
	add_child(lock)

	# Glow (subtle, until opened)
	_glow_light = OmniLight3D.new()
	_glow_light.light_color = glow_color
	_glow_light.light_energy = 1.2
	_glow_light.omni_range = 4.5
	_glow_light.position = Vector3(0, 0.7, 0)
	add_child(_glow_light)

	# Collision (so player can't walk through it)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.25, 0.85, 0.85)
	col.shape = box
	col.position.y = 0.42
	add_child(col)


func _build_interact_area() -> void:
	var area := Area3D.new()
	area.name = "InteractArea"
	area.collision_layer = 0
	area.collision_mask = 2  # detect player layer
	add_child(area)
	var col := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 2.5
	col.shape = sph
	col.position.y = 0.5
	area.add_child(col)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

	# Floating "Press E to open" label, hidden until in range
	var label := Label3D.new()
	label.name = "Hint"
	label.text = "Press E to open"
	label.font_size = 24
	label.outline_size = 5
	label.outline_modulate = Color(0, 0, 0)
	label.modulate = glow_color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = Vector3(0, 1.6, 0)
	label.visible = false
	add_child(label)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not _opened:
		_player_in_range = true
		_player = body
		var hint := get_node_or_null("Hint") as Label3D
		if hint: hint.visible = true
		# Connect E key
		if body.has_signal("interact_pressed") and not body.interact_pressed.is_connected(_on_interact):
			body.interact_pressed.connect(_on_interact)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		var hint := get_node_or_null("Hint") as Label3D
		if hint: hint.visible = false
		if body.has_signal("interact_pressed") and body.interact_pressed.is_connected(_on_interact):
			body.interact_pressed.disconnect(_on_interact)

func _on_interact() -> void:
	if _opened or not _player_in_range or _player == null:
		return
	_open_chest()


func _open_chest() -> void:
	_opened = true
	get_tree().call_group("world", "play_sfx", "chest_open")
	# Animate lid opening
	var t := create_tween()
	t.tween_property(_lid, "rotation:x", -1.4, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Burst of light
	var burst := OmniLight3D.new()
	burst.light_color = glow_color
	burst.light_energy = 6.0
	burst.omni_range = 8.0
	burst.position = Vector3(0, 1.0, 0)
	add_child(burst)
	var t2 := create_tween()
	t2.tween_property(burst, "light_energy", 0.0, 1.6)
	t2.tween_callback(burst.queue_free)

	# Hide hint
	var hint := get_node_or_null("Hint") as Label3D
	if hint: hint.visible = false

	# Roll loot
	var rng := RandomNumberGenerator.new(); rng.randomize()
	var rolls = Items.roll_chest_loot(loot_pool, rng, item_count)
	var world = get_tree().current_scene
	var inv = _player.get("inventory")
	if inv == null:
		return
	for r in rolls:
		# Affix-generated items carry their registry payload alongside the id
		if r.has("registry") and world and world.has_method("register_runtime_item"):
			world.register_runtime_item(r.registry)
		inv.add_item(r.id, r.qty)
		var item = Items.get_item(r.id)
		if item.is_empty() and world and world.has_method("get_runtime_item"):
			item = world.get_runtime_item(r.id)
		_spawn_loot_popup(item, r.qty)

	# Soft glow fades
	if _glow_light:
		var t3 := create_tween()
		t3.tween_property(_glow_light, "light_energy", 0.25, 1.2)

	# Toast
	if world and world.has_method("_show_toast"):
		world._show_toast("✨ Treasure!")

func _spawn_loot_popup(item: Dictionary, qty: int) -> void:
	if item.is_empty():
		return
	var color: Color = Items.RARITY_COLORS.get(item.get("rarity", "common"), Color.WHITE)
	var pop := Label3D.new()
	pop.set_script(DAMAGE_NUMBER_SCRIPT)
	pop.text = "+ %s%s" % [item.get("name", "?"), (" x%d" % qty) if qty > 1 else ""]
	pop.font_size = 30
	pop.outline_size = 5
	pop.outline_modulate = Color(0, 0, 0)
	pop.modulate = color
	pop.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	pop.no_depth_test = true
	pop.position = global_position + Vector3(randf_range(-0.5, 0.5), 1.6, randf_range(-0.3, 0.3))
	get_tree().current_scene.add_child(pop)

# Subtle idle bob when not opened
func _process(delta: float) -> void:
	if _opened or _glow_light == null: return
	var t = Time.get_ticks_msec() / 1000.0
	_glow_light.light_energy = 1.0 + sin(t * 2.4) * 0.25
