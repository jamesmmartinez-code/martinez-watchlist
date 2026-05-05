extends Label3D

# Floating damage / XP popup. Drifts upward, fades out, frees itself.
# Attach via .set_script(load("res://scripts/DamageNumber.gd")) — no class_name
# since this is meant to be used as an instance script on a Label3D.

var _t: float = 0.0
var _life: float = 1.0
var _drift: Vector3 = Vector3(0, 1.4, 0)
var _start_pos: Vector3

func _ready() -> void:
	_start_pos = global_position
	# Slight random horizontal drift
	_drift.x = randf_range(-0.4, 0.4)
	_drift.z = randf_range(-0.4, 0.4)

func _process(delta: float) -> void:
	_t += delta
	var ratio := _t / _life
	if ratio >= 1.0:
		queue_free()
		return
	global_position = _start_pos + _drift * ratio + Vector3(0, sin(_t * 12) * 0.04, 0)
	# Quick scale punch up then down
	var s: float = 1.0 + (1.0 - abs(ratio - 0.2) * 2.0) * 0.25
	scale = Vector3(s, s, s)
	# Fade out in last third
	var alpha = 1.0 if ratio < 0.6 else (1.0 - (ratio - 0.6) / 0.4)
	modulate.a = max(0.0, alpha)
