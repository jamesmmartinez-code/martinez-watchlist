extends CanvasLayer
# LoadingScene.gd — Phase 26 web-perf loading overlay.
#
# Wiring (do this once in Main.tscn):
#   1. Add a CanvasLayer node as sibling of WorldBuilder, attach this script.
#   2. In the Inspector, set `world_builder` to your WorldBuilder node.
#   3. The overlay appears automatically on build_progress and hides on build_complete.
#
# The CanvasLayer sits at layer 128 so it draws above the 3-D viewport.
#
# Visual hierarchy (all built in _ready — no extra .tscn needed):
#   CanvasLayer (this node, layer=128)
#     └ Panel  (full-screen dark backdrop)
#           ├ VBoxContainer (centred)
#           │     ├ Label  "Realm of Eldoria"  (title)
#           │     ├ Label  _phase_label         (e.g. "Briarwood…")
#           │     └ ProgressBar  _bar
#           └ Label  _tip_label  (bottom-centre tip)

@export var world_builder: NodePath = NodePath("")

# UI refs
var _panel:       Panel       = null
var _phase_label: Label       = null
var _bar:         ProgressBar = null
var _tip_label:   Label       = null
var _tween:       Tween       = null

const TIPS: Array[String] = [
	"Tip: Talk to Mayor Aldric at the plaza for your first quest.",
	"Tip: Rest at the inn to save your progress.",
	"Tip: The Notice Board tracks every active quest.",
	"Tip: Smiths can upgrade your gear — bring iron ingots.",
	"Tip: Nordic fishermen know secrets the village elders won't share.",
	"Tip: Press Esc to open your inventory anywhere.",
	"Tip: Some doors only open after you earn the villagers' trust.",
]

func _ready() -> void:
	layer = 128
	_build_ui()
	_panel.visible = false   # hidden until first build_progress signal

	if world_builder.is_empty():
		# Auto-detect: find WorldBuilder anywhere in the tree
		var wb := _find_world_builder(get_tree().root)
		if wb:
			_connect_to(wb)
		else:
			push_warning("[LoadingScene] No WorldBuilder found — set world_builder path in Inspector.")
	else:
		var wb := get_node_or_null(world_builder)
		if wb:
			_connect_to(wb)
		else:
			push_warning("[LoadingScene] world_builder path invalid: " + str(world_builder))


func _connect_to(wb: Node) -> void:
	if wb.has_signal("build_progress"):
		wb.connect("build_progress", _on_build_progress)
	if wb.has_signal("build_complete"):
		wb.connect("build_complete", _on_build_complete)


func _on_build_progress(phase: String, pct: float) -> void:
	if not _panel.visible:
		_panel.visible = true
		_pick_random_tip()

	_phase_label.text = phase + "…"

	# Smooth bar tween — never jumps backwards
	var target := clampf(pct, _bar.value, 1.0)
	if _tween:
		_tween.kill()
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(_bar, "value", target, 0.35)


func _on_build_complete() -> void:
	_phase_label.text = "Welcome to Eldoria"
	if _tween:
		_tween.kill()
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(_bar, "value", 1.0, 0.25)
	await _tween.finished

	# Fade out overlay
	_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_tween.tween_property(_panel, "modulate:a", 0.0, 0.6)
	await _tween.finished
	_panel.visible = false
	_panel.modulate.a = 1.0   # reset for any future use


# ── UI construction ──────────────────────────────────────────────────────────

func _build_ui() -> void:
	# Full-screen backdrop
	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.04, 0.03, 0.06, 0.94)
	_panel.add_theme_stylebox_override("panel", bg)
	add_child(_panel)

	# Centre container
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.custom_minimum_size = Vector2(480, 140)
	vbox.offset_left   = -240
	vbox.offset_right  =  240
	vbox.offset_top    = -70
	vbox.offset_bottom =  70
	_panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Realm of Eldoria"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.90, 0.80, 0.55))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	vbox.add_child(title)

	# Spacer
	var sp1 := Control.new()
	sp1.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(sp1)

	# Phase label
	_phase_label = Label.new()
	_phase_label.text = "Loading…"
	_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_phase_label.add_theme_font_size_override("font_size", 16)
	_phase_label.add_theme_color_override("font_color", Color(0.75, 0.72, 0.68))
	vbox.add_child(_phase_label)

	# Spacer
	var sp2 := Control.new()
	sp2.custom_minimum_size = Vector2(0, 14)
	vbox.add_child(sp2)

	# Progress bar
	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(440, 14)
	_bar.min_value = 0.0
	_bar.max_value = 1.0
	_bar.value = 0.0
	_bar.show_percentage = false
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.15, 0.12, 0.18)
	bar_bg.corner_radius_top_left     = 6
	bar_bg.corner_radius_top_right    = 6
	bar_bg.corner_radius_bottom_left  = 6
	bar_bg.corner_radius_bottom_right = 6
	_bar.add_theme_stylebox_override("background", bar_bg)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.78, 0.58, 0.28)
	bar_fill.corner_radius_top_left     = 6
	bar_fill.corner_radius_top_right    = 6
	bar_fill.corner_radius_bottom_left  = 6
	bar_fill.corner_radius_bottom_right = 6
	_bar.add_theme_stylebox_override("fill", bar_fill)
	vbox.add_child(_bar)

	# Tip label — bottom-centre
	_tip_label = Label.new()
	_tip_label.text = ""
	_tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip_label.custom_minimum_size = Vector2(560, 0)
	_tip_label.add_theme_font_size_override("font_size", 13)
	_tip_label.add_theme_color_override("font_color", Color(0.55, 0.54, 0.52))
	_tip_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_tip_label.offset_top    = -52
	_tip_label.offset_left   = 0
	_tip_label.offset_right  = 0
	_tip_label.offset_bottom = -12
	_panel.add_child(_tip_label)


func _pick_random_tip() -> void:
	if TIPS.is_empty():
		return
	_tip_label.text = TIPS[randi() % TIPS.size()]


# ── WorldBuilder auto-detect ─────────────────────────────────────────────────

func _find_world_builder(node: Node) -> Node:
	if node.get_script() != null:
		# Match by class name so we don't need a hard reference
		if node.get_script().get_global_name() == "WorldBuilder":
			return node
	for child in node.get_children():
		var found := _find_world_builder(child)
		if found:
			return found
	return null
