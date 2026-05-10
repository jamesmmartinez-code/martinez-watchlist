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

# ── FOV punch ─────────────────────────────────────────────────────────────
# Briefly compresses the camera's field-of-view inward then springs back.
# Gives heavy hits and kills a "lens impact" that reads even on a small screen.
# Default amount=8° — comfortable; crank to 14 for boss kills.
func camera_fov_punch(amount: float = 8.0, spring_duration: float = 0.22) -> void:
	if not juice_enabled:
		return
	var vp := get_viewport()
	var cam: Camera3D = vp.get_camera_3d() if vp else null
	if not cam or not is_instance_valid(cam):
		return
	var base_fov := cam.fov
	var tw := create_tween()
	tw.tween_property(cam, "fov", base_fov - amount, 0.04).set_trans(Tween.TRANS_EXPO)
	tw.tween_property(cam, "fov", base_fov + amount * 0.30, 0.05)
	tw.tween_property(cam, "fov", base_fov, spring_duration).set_trans(Tween.TRANS_SPRING)

# ── Directional shake ─────────────────────────────────────────────────────
# Shoves the camera OPPOSITE the hit direction (recoil), then springs back.
# dir is world-space (typically: attacker→target normalized).
# Composites with any running screen_shake — the spring tween restores to 0.
func directional_shake(dir: Vector3, intensity: float = 0.18) -> void:
	if not juice_enabled:
		return
	var vp := get_viewport()
	var cam: Camera3D = vp.get_camera_3d() if vp else null
	if not cam or not is_instance_valid(cam):
		return
	# Map world dir components to camera offsets (h=lateral, v=vertical)
	var push_h: float =  dir.x * intensity
	var push_v: float = -dir.z * intensity * 0.45
	var tw := create_tween().set_parallel(true)
	tw.tween_property(cam, "h_offset", push_h, 0.04).set_trans(Tween.TRANS_EXPO)
	tw.tween_property(cam, "v_offset", push_v, 0.04).set_trans(Tween.TRANS_EXPO)
	var tw2 := create_tween().set_parallel(true)
	tw2.tween_interval(0.04)
	tw2.tween_property(cam, "h_offset", 0.0, 0.18).set_trans(Tween.TRANS_SPRING)
	tw2.tween_property(cam, "v_offset", 0.0, 0.18).set_trans(Tween.TRANS_SPRING)

# ── Persistent tint ───────────────────────────────────────────────────────
# Unlike screen_flash (one-shot), this sets a low-alpha overlay that holds
# for `hold` seconds then fades out over `fade` seconds.
# Used for: low-HP danger (red), high corruption (sickly green), boss aura.
var _tint_rect: ColorRect   = null
var _tint_layer: CanvasLayer = null
var _tint_tween: Tween       = null

func screen_tint(color: Color, hold: float = 0.0, fade: float = 0.6) -> void:
	if not juice_enabled:
		return
	_ensure_tint()
	_tint_rect.color = color
	_tint_rect.visible = true
	if _tint_tween and _tint_tween.is_valid():
		_tint_tween.kill()
	_tint_tween = create_tween()
	if hold > 0.0:
		_tint_tween.tween_interval(hold)
	_tint_tween.tween_property(_tint_rect, "color:a", 0.0, fade).set_trans(Tween.TRANS_SINE)
	_tint_tween.tween_callback(func() -> void: if is_instance_valid(_tint_rect): _tint_rect.visible = false)

func set_ambient_tint(color: Color) -> void:
	# Call every frame for persistent effects (low HP, corruption).
	# Does NOT spawn a new tween — just updates the rect color.
	if not juice_enabled:
		return
	_ensure_tint()
	if _tint_tween and _tint_tween.is_valid():
		_tint_tween.kill()   # cancel any active fade so tint stays visible
	_tint_rect.color = color
	_tint_rect.visible = color.a > 0.0

func clear_ambient_tint(fade: float = 0.5) -> void:
	if not _tint_rect or not is_instance_valid(_tint_rect):
		return
	if _tint_tween and _tint_tween.is_valid():
		_tint_tween.kill()
	_tint_tween = create_tween()
	_tint_tween.tween_property(_tint_rect, "color:a", 0.0, fade).set_trans(Tween.TRANS_SINE)
	_tint_tween.tween_callback(func() -> void: if is_instance_valid(_tint_rect): _tint_rect.visible = false)

func _ensure_tint() -> void:
	if _tint_layer and is_instance_valid(_tint_layer):
		return
	_tint_layer = CanvasLayer.new()
	_tint_layer.layer = 120   # below flash (127) but above HUD (10)
	_tint_layer.name  = "JuiceTintLayer"
	get_tree().current_scene.call_deferred("add_child", _tint_layer)
	_tint_rect = ColorRect.new()
	_tint_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tint_rect.color   = Color(1.0, 0.0, 0.0, 0.0)
	_tint_rect.visible = false
	_tint_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tint_layer.call_deferred("add_child", _tint_rect)

# ── Notification toast ────────────────────────────────────────────────────
# Stacks short-lived text banners on the right side of the screen.
# Slide in, hold, fade out — Alden & Owen love when the game tells them
# what happened ("Nemesis returns!" / "Quest unlocked!").
var _notif_layer: CanvasLayer = null
var _notif_box:   VBoxContainer = null

func show_notification(text: String, color: Color = Color(1.0, 0.90, 0.50)) -> void:
	_ensure_notif()
	var lbl := Label.new()
	lbl.text             = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl.add_theme_font_size_override("font_size", 19)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	lbl.modulate.a = 0.0
	_notif_box.add_child(lbl)
	# Fade in → hold → fade out → free
	var tw := create_tween()
	tw.tween_property(lbl, "modulate:a", 1.0, 0.20).set_trans(Tween.TRANS_EXPO)
	tw.tween_interval(2.40)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.55).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(lbl.queue_free)

func _ensure_notif() -> void:
	if _notif_layer and is_instance_valid(_notif_layer):
		return
	_notif_layer = CanvasLayer.new()
	_notif_layer.layer = 115
	_notif_layer.name  = "JuiceNotifLayer"
	get_tree().current_scene.call_deferred("add_child", _notif_layer)
	_notif_box = VBoxContainer.new()
	_notif_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_notif_box.position = Vector2(-300, 12)
	_notif_box.size     = Vector2(290, 500)
	_notif_box.alignment = BoxContainer.ALIGNMENT_END
	_notif_layer.call_deferred("add_child", _notif_box)

# ── Cinematic lock ────────────────────────────────────────────────────────
# Temporarily disables player input/movement for scripted moments
# (boss intros, cutscene beats, dramatic pauses).
# Broadcasts through the "player" group so no direct node reference needed.
func player_cinematic(duration: float) -> void:
	for p in get_tree().get_nodes_in_group("player"):
		if p.has_method("set_cinematic_lock"):
			p.set_cinematic_lock(true)
	await get_tree().create_timer(duration).timeout
	for p in get_tree().get_nodes_in_group("player"):
		if p.has_method("set_cinematic_lock"):
			p.set_cinematic_lock(false)

# ── Debug toggle ──────────────────────────────────────────────────────────
var juice_enabled: bool = true
