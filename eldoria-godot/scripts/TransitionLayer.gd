extends CanvasLayer
# Realm of Eldoria — TransitionLayer
#
# Attach to a CanvasLayer node named "TransitionLayer" inside World.tscn.
# Provides fade_out() → (area loads) → fade_in() used by WorldManager.
#
# Scene structure:
#   TransitionLayer (CanvasLayer, layer=100)
#   ├── Bg           (ColorRect, full-rect, Color(0,0,0,1))
#   └── Label        (Label, centered — optional flavour text)
#
# If Bg / Label don't exist the script creates them at runtime.

# ── Settings ──────────────────────────────────────────────────────────────
@export var fade_duration: float = 0.30
@export var bg_color: Color      = Color(0.04, 0.04, 0.08)  # near-black

# ── Runtime nodes ─────────────────────────────────────────────────────────
var _bg:    ColorRect = null
var _label: Label     = null

func _ready() -> void:
	layer = 100
	_bg    = get_node_or_null("Bg")
	_label = get_node_or_null("Label")

	if not _bg:
		_bg = ColorRect.new()
		_bg.name = "Bg"
		_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_bg.color = bg_color
		add_child(_bg)

	if not _label:
		_label = Label.new()
		_label.name = "Label"
		_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		_label.add_theme_font_size_override("font_size", 18)
		_label.text = "…"
		add_child(_label)

	# Start invisible.
	modulate.a = 0.0
	visible    = false

# ==========================================================================
# Public API
# ==========================================================================
func fade_out(text: String = "…") -> void:
	_label.text = text
	visible     = true
	var tw      := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, fade_duration).set_trans(Tween.TRANS_SINE)
	await tw.finished

func fade_in() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, fade_duration).set_trans(Tween.TRANS_SINE)
	await tw.finished
	visible = false

func flash_text(text: String, hold: float = 1.2) -> void:
	# Show a brief lore caption during transition (optional).
	_label.text    = text
	_label.visible = true
	await get_tree().create_timer(hold).timeout
	_label.visible = false
