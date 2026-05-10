extends Area3D
class_name Fireball

# Realm of Eldoria — Fireball projectile spawned by Player skill 3.
# Flies in _direction at speed, deals damage + AoE splash on first collision.
# Self-destructs on impact or after _lifetime seconds.
#
# Spawned via Player._spawn_fireball():
#   var fb := Area3D.new()
#   fb.set_script(FIREBALL_SCRIPT)
#   fb.global_position = ...
#   get_tree().current_scene.add_child(fb)
#   fb.launch(direction, damage, attacker)

var speed:    float = 16.0
var damage:   int   = 20
var attacker: Node  = null

var _direction: Vector3 = Vector3.FORWARD
var _lifetime:  float   = 3.5
var _hit:       bool    = false

# AoE radius — enemies within this range take 65% damage on splash
const AOE_RADIUS: float = 2.5
const AOE_MULT:   float = 0.65

func launch(dir: Vector3, dmg: int, src: Node) -> void:
	_direction = dir.normalized()
	damage     = dmg
	attacker   = src

func _ready() -> void:
	collision_layer = 8       # projectile layer (unused by other scanners)
	collision_mask  = 1 | 4   # world (1) + enemies (4)

	# Sphere collider
	var cs   := CollisionShape3D.new()
	var sp   := SphereShape3D.new()
	sp.radius = 0.35
	cs.shape  = sp
	add_child(cs)

	# Glowing ember mesh — no shader needed, pure StandardMaterial3D emission
	var mi  := MeshInstance3D.new()
	var sm  := SphereMesh.new()
	sm.radius = 0.30
	sm.height = 0.60
	mi.mesh   = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color              = Color(1.0, 0.45, 0.08)
	mat.emission_enabled          = true
	mat.emission                  = Color(1.0, 0.28, 0.04)
	mat.emission_energy_multiplier = 5.0
	mi.material_override = mat
	add_child(mi)

	# Connect hit signal
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _hit:
		return
	position  += _direction * speed * delta
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if _hit:
		return
	_hit = true

	# Direct hit on the colliding body (if it's an enemy)
	if body.has_method("take_damage"):
		body.take_damage(damage, attacker)

	# AoE splash — all enemies within AOE_RADIUS take reduced damage
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		if enemy == body:
			continue   # already got full damage above
		var dist: float = (enemy.global_position - global_position).length()
		if dist <= AOE_RADIUS and enemy.has_method("take_damage"):
			enemy.take_damage(int(float(damage) * AOE_MULT), attacker)

	# Impact visual: brief scale-out flash before freeing
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3(2.5, 2.5, 2.5), 0.08).set_trans(Tween.TRANS_EXPO)
	tw.tween_callback(queue_free)
