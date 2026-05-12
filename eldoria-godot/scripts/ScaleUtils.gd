extends Node
# ScaleUtils — single enforced scale law for Realm of Eldoria
# 1 Godot unit = 1 metre. All assets normalised to these targets.
# [CANON-APPROVED: 2026-05-11] — replaces per-NPC NPC_SCALES hacks
# class_name removed — autoload singleton name collision fix 2026-05-11

# ── Canonical height targets (metres) ─────────────────────────────────────────
const HEIGHT_PLAYER:    float = 0.85   # child hero (Alden/Owen)
const HEIGHT_NPC:       float = 1.65   # adult villager
const HEIGHT_ENEMY:     float = 1.55   # standard enemy
const HEIGHT_BOSS:      float = 2.80   # standard boss
const HEIGHT_BOSS_HUGE: float = 4.00   # gargantuan (Crystal Guardian, Mountain Ogre)
const HEIGHT_PET:       float = 0.55   # fox/squirrel/owl
const HEIGHT_WOLF:      float = 1.00   # wolf / large animal
const HEIGHT_HORSE:     float = 1.60   # stable horse

# ── Scale a Node3D so its tallest VisualInstance3D AABB = target_height ───────
# Safe to call immediately after instance() — retries if AABB not ready yet.
static func to_height(node: Node3D, target_height: float, retries: int = 0) -> void:
	var aabb := _measure(node)
	if aabb.size.y <= 0.001:
		if retries < 5:
			node.get_tree().create_timer(0.3 * (retries + 1)).timeout.connect(
				func(): to_height(node, target_height, retries + 1))
		return
	var s: float = clamp(target_height / aabb.size.y, 0.001, 100.0)
	node.scale = Vector3(s, s, s)

# ── Measure the combined AABB of all VisualInstance3D children ────────────────
static func _measure(node: Node3D) -> AABB:
	var aabb := AABB()
	var has: bool = false
	for c in node.find_children("*", "VisualInstance3D", true):
		var v := c as VisualInstance3D
		if not v: continue
		var par := v.get_parent()
		if par is BoneAttachment3D: continue   # skip gear
		var a := v.get_aabb()
		a = v.global_transform * a
		if not has: aabb = a; has = true
		else: aabb = aabb.merge(a)
	return aabb

# ── Clamp: ensure node never exceeds max_height (emergency shrink only) ───────
static func clamp_height(node: Node3D, max_height: float) -> void:
	var aabb := _measure(node)
	if aabb.size.y <= max_height or aabb.size.y <= 0.001:
		return
	var s: float = clamp(max_height / aabb.size.y, 0.001, 1.0)
	node.scale = node.scale * Vector3(s, s, s)
