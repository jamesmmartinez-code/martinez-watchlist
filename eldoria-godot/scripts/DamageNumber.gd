extends Label3D

# Floating damage / XP popup. Drifts upward, fades out, frees itself.
# Attach via .set_script(load("res://scripts/DamageNumber.gd")) — no class_name
# since this is meant to be used as an instance script on a Label3D.

var _t: float = 0.0
# REFINE: combat-feel — longer dwell so players read the number, taller rise for more pop.
var _life: float = 1.18
var _drift: Vector3 = Vector3(0, 1.75, 0)
var _start_pos: Vector3

func _ready() -> void:
	_start_pos = global_position
	# REFINE: combat-feel — wider horizontal scatter so multi-hit numbers don't stack into one blob.
	_drift.x = randf_range(-0.55, 0.55)
	_drift.z = randf_range(-0.55, 0.55)

func _process(delta: float) -> void:
	_t += delta
	var ratio := _t / _life
	if ratio >= 1.0:
		queue_free()
		return
	# REFINE: combat-feel — slightly livelier vertical bobbing.
	global_position = _start_pos + _drift * ratio + Vector3(0, sin(_t * 14.0) * 0.05, 0)
	# REFINE: combat-feel — earlier, snappier punch (peak at 18% of life, +38% scale) so hits land visually before they drift.
	var s: float = 1.0 + (1.0 - abs(ratio - 0.18) * 2.0) * 0.38
	scale = Vector3(s, s, s)
	# REFINE: combat-feel — start fade slightly earlier (55%) for a gentler tail rather than an abrupt cutoff.
	var alpha = 1.0 if ratio < 0.55 else (1.0 - (ratio - 0.55) / 0.45)
	modulate.a = max(0.0, alpha)
