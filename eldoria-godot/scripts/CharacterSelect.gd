extends Control
class_name CharacterSelect

# Realm of Eldoria — Character Select screen.
# Shows two options (Alden Pathfinder, Owen Vanguard), persists the kid's
# pick under user://char_choice + the cloud KV (per-user save), then loads
# the main scene with that hero GLB swapped in.
#
# Why a full scene instead of a popup: kids need a clear "this is MY guy"
# moment. Big portrait, name, class, color, hover/highlight on focus.
# Per-realm hero dialogue later in the game keys off this choice.

const MAIN_SCENE_PATH := "res://scenes/Main.tscn"
const SAVE_KEY        := "user://char_choice.cfg"
const KV_USER_KEY_T   := "char_choice"  # KV slot name

# THEME §3 sunset-gold palette
const COL_TITLE     := Color(1.00, 0.85, 0.42)
const COL_BG        := Color(0.12, 0.10, 0.18)
const COL_PICK_FRAME_HOT := Color(1.00, 0.85, 0.42)
const COL_ALDEN     := Color(0.55, 0.95, 0.65)   # mint
const COL_OWEN      := Color(1.00, 0.50, 0.00)   # McLaren orange #FF8000

var _hovered: int = -1   # 0 = Alden, 1 = Owen, -1 = none

func _ready() -> void:
	# Always-process so panic keys still work even if scene tree pauses
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Build the UI procedurally so this scene is one .gd file + a one-line
	# wrapper .tscn — easier to maintain than a hand-edited tres tree.
	mouse_filter = Control.MOUSE_FILTER_STOP
	anchor_left = 0; anchor_top = 0; anchor_right = 1; anchor_bottom = 1
	offset_left = 0; offset_top = 0; offset_right = 0; offset_bottom = 0

	var bg := ColorRect.new()
	bg.color = COL_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "Choose Your Hero"
	title.modulate = COL_TITLE
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 8)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 60
	title.offset_bottom = 140
	add_child(title)

	# Subtitle
	var sub := Label.new()
	sub.text = "Click your character to begin"
	sub.modulate = Color(0.85, 0.82, 0.74)
	sub.add_theme_font_size_override("font_size", 24)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	sub.offset_top = 145
	sub.offset_bottom = 180
	add_child(sub)

	# Cards container
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 80)
	hbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	hbox.offset_left = -800; hbox.offset_right = 800
	hbox.offset_top = -250;  hbox.offset_bottom = 350
	add_child(hbox)

	hbox.add_child(_make_hero_card("alden", "Alden", "Pathfinder", "Bow & wits", COL_ALDEN, "🐸"))
	hbox.add_child(_make_hero_card("owen",  "Owen",  "Vanguard",   "Sword & shield", COL_OWEN, "🏎️"))

	# Footer
	var footer := Label.new()
	footer.text = "(Esc to skip — uses last saved character)"
	footer.modulate = Color(0.6, 0.6, 0.6)
	footer.add_theme_font_size_override("font_size", 18)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -60
	footer.offset_bottom = -30
	add_child(footer)


func _make_hero_card(id: String, name_str: String, class_str: String, weapons: String, accent: Color, emoji: String) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(560, 700)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.18, 0.14, 0.22, 0.95)
	sb.border_color = accent
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(20)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 10
	card.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	card.add_child(vbox)

	# Big emoji avatar (placeholder until hero portrait images ship)
	var avatar := Label.new()
	avatar.text = emoji
	avatar.add_theme_font_size_override("font_size", 220)
	avatar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar.custom_minimum_size = Vector2(0, 320)
	vbox.add_child(avatar)

	var nm := Label.new()
	nm.text = name_str
	nm.modulate = accent
	nm.add_theme_font_size_override("font_size", 56)
	nm.add_theme_color_override("font_outline_color", Color.BLACK)
	nm.add_theme_constant_override("outline_size", 6)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(nm)

	var cls := Label.new()
	cls.text = class_str
	cls.add_theme_font_size_override("font_size", 32)
	cls.modulate = COL_TITLE
	cls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(cls)

	var wp := Label.new()
	wp.text = weapons
	wp.add_theme_font_size_override("font_size", 22)
	wp.modulate = Color(0.85, 0.82, 0.74)
	wp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(wp)

	var btn := Button.new()
	btn.text = "Choose %s" % name_str
	btn.add_theme_font_size_override("font_size", 28)
	btn.custom_minimum_size = Vector2(380, 80)
	btn.pressed.connect(func(): _on_pick(id))
	var btn_box := HBoxContainer.new()
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_box.add_child(btn)
	vbox.add_child(btn_box)

	return card


func _on_pick(id: String) -> void:
	# Persist locally
	var cfg := ConfigFile.new()
	cfg.set_value("char", "id", id)
	cfg.set_value("char", "picked_at", Time.get_datetime_string_from_system())
	cfg.save(SAVE_KEY)

	# Persist to cloud KV (best-effort, non-blocking).
	# Worker route: POST /api/save with {user, slot, data}. The kid's user
	# name = the picked id. This means Alden and Owen each get their own
	# saved progress separated by character.
	if OS.has_feature("web"):
		_push_to_kv(id)

	# Stash globally so Main.tscn's Player.gd::_ready can read it
	Engine.set_meta("char_choice", id)

	# Load main scene
	get_tree().change_scene_to_file(MAIN_SCENE_PATH)


func _push_to_kv(id: String) -> void:
	var url := "https://eldoria-api.james-m-martinez.workers.dev/api/save"
	var body := JSON.stringify({
		"user": id,
		"slot": "char_choice",
		"data": {"id": id, "ts": Time.get_unix_time_from_system()},
	})
	var req := HTTPRequest.new()
	add_child(req)
	req.timeout = 5.0
	req.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)
	# Fire-and-forget — request_completed signal not connected; we don't block
	# the scene change on cloud round-trip success.


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			# Skip — load main with whatever was last picked (or default Hero.glb)
			var cfg := ConfigFile.new()
			if cfg.load(SAVE_KEY) == OK:
				Engine.set_meta("char_choice", str(cfg.get_value("char", "id", "alden")))
			else:
				Engine.set_meta("char_choice", "alden")
			get_tree().change_scene_to_file(MAIN_SCENE_PATH)
