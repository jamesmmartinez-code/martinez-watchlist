extends CanvasLayer
# Realm of Eldoria — DebugHUD
#
# Lightweight runtime dashboard showing key system metrics.
# Attach this script to a CanvasLayer node in any scene.
# Toggle with F3 (or set _visible_override = true permanently while tuning).
#
# Shows: EnemyDirector intensity/wave state, enemy count, corruption, day/time,
#        faction strength, active nemeses, active quests.
#
# This node creates its own Label child so it requires no .tscn — just:
#   1. Add a CanvasLayer to World.tscn
#   2. Set layer = 10 (so it's always on top)
#   3. Attach this script

const UPDATE_INTERVAL: float = 0.25   # refresh every quarter second

var _label: Label
var _timer: float = 0.0
var _visible_override: bool = false   # set true in editor to always show

func _ready() -> void:
	layer = 10
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_label.position = Vector2(8, 8)
	_label.size = Vector2(320, 500)
	_label.add_theme_font_size_override("font_size", 13)
	_label.add_theme_color_override("font_color", Color(0.85, 1.0, 0.70))
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	_label.label_settings = null   # use inline theme overrides
	_label.clip_text = false
	add_child(_label)
	# Start hidden — toggle with F3
	_label.visible = _visible_override

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			_label.visible = not _label.visible

func _process(delta: float) -> void:
	if not _label.visible:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = UPDATE_INTERVAL
	_label.text = _build_text()

func _build_text() -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("─── DEBUG HUD (F3) ────────")

	# EnemyDirector
	if is_instance_valid(EnemyDirector):
		var wave := EnemyDirector.get_wave_state_name() if EnemyDirector.has_method("get_wave_state_name") else "?"
		lines.append("DIRECTOR")
		lines.append("  intensity : %.2f  [%s]" % [EnemyDirector.intensity, wave])
		lines.append("  dc enemies: %d / %d" % [EnemyDirector._dc_count, 6])
		var total: int = get_tree().get_nodes_in_group("enemies").size()
		lines.append("  total ene : %d" % total)

	# WorldState
	if is_instance_valid(WorldState):
		lines.append("WORLD")
		lines.append("  day %d  %02d:%02d  [%s]" % [
			WorldState.day,
			int(WorldState.time_of_day),
			int(fmod(WorldState.time_of_day, 1.0) * 60.0),
			WorldState.season
		])
		lines.append("  corruption: %.2f  stage %d" % [
			WorldState.corruption_level,
			WorldState.evolution_stage
		])

	# FactionSystem
	if is_instance_valid(FactionSystem):
		lines.append("FACTIONS")
		var dominant := FactionSystem.get_dominant_faction()
		if not dominant.is_empty():
			lines.append("  dominant: " + dominant)
		var zone_count := FactionSystem.zone_control.size()
		lines.append("  zones controlled: %d" % zone_count)

	# NemesisSystem
	if is_instance_valid(NemesisSystem):
		lines.append("NEMESES: %d active" % NemesisSystem.nemeses.size())
		var i := 0
		for id: String in NemesisSystem.nemeses:
			if i >= 3: break
			var nd: NemesisData = NemesisSystem.nemeses[id] as NemesisData
			if nd:
				lines.append("  Lv%d %s  [%s]" % [
					nd.level, nd.nemesis_name, ", ".join(nd.traits) if nd.traits.size() > 0 else "no traits"
				])
			i += 1

	# QuestSystem
	if is_instance_valid(QuestSystem):
		lines.append("QUESTS: %d active" % QuestSystem.active_quests.size())
		var qi := 0
		for id: String in QuestSystem.active_quests:
			if qi >= 3: break
			var q = QuestSystem.active_quests[id]
			if q and q.get("title") != null:
				lines.append("  • " + str(q.title).left(34))
			qi += 1

	lines.append("──────────────────────────")
	return "\n".join(lines)
