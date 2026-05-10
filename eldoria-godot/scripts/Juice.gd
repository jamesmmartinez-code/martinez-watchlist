extends Node
# Realm of Eldoria — Juice (autoload singleton)
#
# One place for all game-feel feedback: hit-stop, screen flash, particle
# impulses, and scale-priority tiers.  Any script can call Juice.hit_stop()
# without importing or locating the camera — it just works.
#
# Registered as autoload "Juice" in project.godot [autoload].

# ── Hit-stop ─────────────────────────────────────────────────────────────
# Freeze Engine.time_scale briefly so impacts feel weighty.
# Priority: heavy (≥20 dmg) > medium (8-19) > light (<8).
# Re-entrant: a heavier call mid-stop extends the remaining duration.
var _hitstop_remaining: float = 0.0
var _hitstop_active: bool = false

func hit_stop(duration: float = 0.06) -> void:
	# Don't allow a lighter stop to cut short a heavier one already running.
	var scaled := duration * 0.05   # actual real-time at time_scale 0.05
	if scaled <= _hitstop_remaining:
		return
	_hitstop_remaining = scaled
	if not _hitstop_active:
		_hitstop_active = true
		Engine.time_scale = 0.05
		_run_hitstop()

func _run_hitstop() -> void:
	# Uses unscaled time so it ends even while the game is frozen.
	while _hitstop_remaining > 0.0:
		await get_tree().process_frame
		_hitstop_remaining -= get_process_delta_time()
	Engine.time_scale = 1.0
	_hitstop_active = false

func hit_stop_tier(damage: int) -> void:
	if damage >= 20:
		hit_stop(0.10)
	elif damage >= 8:
		hit_stop(0.06)
	else:
		hit_stop(0.03)

# ── Screen flash ──────────────────────────────────────────────────────────
# Flashes a full-viewport color rect and fades out.  Useful for big hits,
# death screens, and phase transitions.  Uses a CanvasLayer at layer 127
# so it always draws on top of everything else.
var _flash_rect: ColorRect = null
var _flash_layer: CanvasLayer = null

func screen_flash(color: Color = Color(1, 1, 1, 0.45), duration: float = 0.12) -> void:
	_ensure_flash_rect()
	_flash_rect.color = color
	_flash_rect.visible = true
	var tw := create_tween()
	tw.tween_property(_flash_rect, "color:a", 0.0, duration).set_trans(Tween.TRANS_EXPO)
	tw.tween_callback(func() -> void: _flash_rect.visible = false)

func _ensure_flash_rect() -> void:
	if _flash_layer and is_instance_valid(_flash_layer):
		return
	_flash_layer = CanvasLayer.new()
	_flash_layer.layer = 127
	_flash_layer.name = "JuiceFlashLayer"
	get_tree().current_scene.call_deferred("add_child", _flash_layer)
	_flash_rect = ColorRect.new()
	_flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash_rect.color = Color.WHITE
	_flash_rect.visible = false
	_flash_layer.call_deferred("add_child", _flash_rect)

# ── Squash & stretch helper ───────────────────────────────────────────────
# Call on any Node3D (enemy, player, prop) for tactile impact feedback.
# Squash: wide + short → spring back elastic.
func squash(node: Node3D, power: float = 0.20) -> void:
	if not node or not is_instance_valid(node):
		return
	var tw := create_tween()
	var sq := 1.0 + power
	var st := 1.0 - power * 0.65
	tw.tween_property(node, "scale", Vector3(sq, st, sq), 0.055).set_trans(Tween.TRANS_SINE)
	tw.tween_property(node, "scale", Vector3.ONE, 0.14).set_trans(Tween.TRANS_ELASTIC)

# Stretch: tall + narrow (used on jumps / launches).
func stretch(node: Node3D, power: float = 0.18) -> void:
	if not node or not is_instance_valid(node):
		return
	var tw := create_tween()
	tw.tween_property(node, "scale", Vector3(1.0 - power * 0.5, 1.0 + power, 1.0 - power * 0.5), 0.06).set_trans(Tween.TRANS_EXPO)
	tw.tween_property(node, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_ELASTIC)

# ── Debug toggle ──────────────────────────────────────────────────────────
var juice_enabled: bool = true
