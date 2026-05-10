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
	# duration = desired pause in real-world seconds.
	# Re-entrant: a heavier call mid-freeze extends the remaining window.
	# Lighter calls are ignored so a quick melee can't cut short a heavy-slam freeze.
	if not juice_enabled:
		return
	if duration <= _hitstop_remaining:
		return
	_hitstop_remaining = duration
	if not _hitstop_active:
		_hitstop_active = true
		Engine.time_scale = 0.05
		_run_hitstop()

func _run_hitstop() -> void:
	# Uses Time.get_ticks_msec() (wall-clock, unaffected by Engine.time_scale)
	# so the freeze always ends after exactly the requested real-time seconds.
	# Calling get_process_delta_time() here would return 0.0 because Juice has
	# no _process — that would produce an infinite freeze loop.
	var start_ms := Time.get_ticks_msec()
	while (Time.get_ticks_msec() - start_ms) < int(_hitstop_remaining * 1000.0):
		await get_tree().process_frame
	Engine.time_scale = 1.0
	_hitstop_active   = false
	_hitstop_remaining = 0.0

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

# ── Screen shake ──────────────────────────────────────────────────────────
# Shakes the active Camera3D via h_offset / v_offset so it doesn't fight
# whatever positional logic CameraController already runs.
# Call once for a single burst, or every physics frame for sustained tension
# (subsequent calls just refresh the timer; no new coroutine is spawned).
var _shaking: bool = false
var _shake_timer: float = 0.0
var _shake_intensity: float = 0.0

func screen_shake(intensity: float = 0.15, duration: float = 0.30) -> void:
	if not juice_enabled:
		return
	# Accumulate: keep the stronger intensity and longest remaining time.
	_shake_intensity = maxf(_shake_intensity, intensity)
	_shake_timer     = maxf(_shake_timer, duration)
	if not _shaking:
		_shaking = true
		_run_shake()

func _run_shake() -> void:
	var vp := get_viewport()
	var cam: Camera3D = vp.get_camera_3d() if vp else null
	if not cam or not is_instance_valid(cam):
		_shaking = false
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	while _shake_timer > 0.0:
		cam.h_offset = rng.randf_range(-_shake_intensity, _shake_intensity)
		cam.v_offset = rng.randf_range(-_shake_intensity * 0.4, _shake_intensity * 0.4)
		_shake_timer     -= 0.025       # ≈ 40 ticks per second of shake budget
		_shake_intensity *= 0.94        # natural decay — stops on its own when not refreshed
		await get_tree().process_frame
	# Restore clean camera offsets
	if is_instance_valid(cam):
		cam.h_offset = 0.0
		cam.v_offset = 0.0
	_shaking        = false
	_shake_intensity = 0.0

# ── Debug toggle ──────────────────────────────────────────────────────────
var juice_enabled: bool = true
