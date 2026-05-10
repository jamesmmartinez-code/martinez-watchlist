extends Area3D
class_name WatcherBolt

# Realm of Eldoria — slow arcing bolt fired by Watcher enemies.
# Travels in a straight line at SPEED, expires after LIFETIME seconds.
# No AoE — single target, but harder to dodge than a melee swing.
# Spawned by Enemy._fire_watcher_bolt().

var speed:    float = 9.0
var damage:   int   = 7
var attacker: Node  = null

var _direction: Vector3 = Vector3.FORWARD
var _lifetime:  float   = 4.0
var _hit:       bool    = false

func launch(dir: Vector3, dmg: int, src: Node) -> void:
	_direction = dir.normalized()
	damage     = dmg
	attacker   = src

func _ready() -> void:
	collision_layer = 8
	collision_mask  = 1 | 2   # world (1) + player (2)

	var cs  := CollisionShape3D.new()
	var sp  := SphereShape3D.new()
	sp.radius = 0.22
	cs.shape  = sp
	add_child(cs)

	# Glowing violet orb — threat-readable colour distinct from Fireball orange
	var mi  := MeshInstance3D.new()
	var sm  := SphereMesh.new()
	sm.radius = 0.18
	sm.height = 0.36
	mi.mesh   = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color              = Color(0.70, 0.20, 1.0)
	mat.emission_enabled          = true
	mat.emission                  = Color(0.55, 0.10, 0.90)
	mat.emission_energy_multiplier = 4.0
	mi.material_override = mat
	add_child(mi)

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
	if body.has_method("take_damage"):
		body.take_damage(damage)
	# Small flash then free
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3(2.0, 2.0, 2.0), 0.06).set_trans(Tween.TRANS_EXPO)
	tw.tween_callback(queue_free)
