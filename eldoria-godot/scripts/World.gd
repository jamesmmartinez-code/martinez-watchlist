extends Node3D
class_name World

# Realm of Eldoria — World root.
# Owns: dialogue UI, HUD, day/night cycle, quest UI, death overlay,
# toast helper, full inventory + paperdoll panel, quest catalog (kill + fetch),
# runtime affix-item registry.

@onready var dialogue_panel: Panel = $UI/DialoguePanel
@onready var dialogue_name_label: Label = $UI/DialoguePanel/MarginContainer/VBox/NameLabel
@onready var dialogue_text_label: RichTextLabel = $UI/DialoguePanel/MarginContainer/VBox/TextLabel
@onready var dialogue_close_btn: Button = $UI/DialoguePanel/MarginContainer/VBox/CloseBtn
@onready var sun: DirectionalLight3D = $WorldEnvironment/Sun
@onready var hud: Control = $UI/HUD
@onready var hp_bar: ProgressBar = $UI/HUD/HPBar
@onready var mp_bar: ProgressBar = $UI/HUD/MPBar
@onready var xp_bar: ProgressBar = $UI/HUD/XPBar
@onready var level_label: Label = $UI/HUD/LevelLabel
@onready var gold_label: Label = $UI/HUD/GoldLabel
@onready var quest_panel: Panel = $UI/QuestPanel
@onready var quest_label: Label = $UI/QuestPanel/QuestLabel
@onready var death_overlay: ColorRect = $UI/DeathOverlay
@onready var death_label: Label = $UI/DeathOverlay/DeathLabel

var time_of_day: float = 11.0
var _current_npc_role: String = ""
var _current_npc_name: String = ""


# Inventory UI — built lazily on first open
var inventory_panel: Panel = null
var paperdoll_slots: Dictionary = {}    # slot_name -> Button
var bag_buttons: Array = []             # Array of Button for each bag slot
var stats_label: RichTextLabel = null
var inv_tooltip: Label = null

# Runtime registry for affix-generated items (keys begin with "@")
var _runtime_items: Dictionary = {}

# ────────────────────────────────────────────────────────────────────────
# World-engine runtime state (consequence resolver targets)
# Populated/mutated by apply_consequence(). Read by NPCs, dialogue, quests.
# ────────────────────────────────────────────────────────────────────────
var factions: Dictionary = {
	"briarwood": {"disposition": "friendly", "pressure": 0.0},
	"whisperwood_goblins": {"disposition": "hostile", "pressure": 1.0},
	"dire_wolves": {"disposition": "hostile", "pressure": 0.5},
	"crystal_caves": {"disposition": "hostile", "pressure": 0.0},
}
var world_flags: Dictionary = {}      # flag_name -> Variant (usually bool/int)
var npc_flags: Dictionary = {}        # npc_name -> Array[String]

# Achievement / Title state — read-only externally; mutated only by
# `_check_achievements()` which is invoked at the end of `apply_consequence`
# and once at `_ready` (so a fresh world boot picks up any pre-existing
# state — currently always empty since faction/flag state is per-session,
# but keeps the contract sound for future persistence work).
#   `unlocked_achievements`: Dictionary[String, bool] — keys are IDs in
#       `Achievements.ACHIEVEMENTS`. Bool value is always `true`; the
#       dict shape (rather than Array) makes lookup O(1) and avoids
#       duplicate-detection logic on the unlock path.
#   `current_title`: String — auto-equipped title text drawn above the
#       player's head as a Label3D. "" means no title (default).
var unlocked_achievements: Dictionary = {}
var current_title: String = ""


# ────────────────────────────────────────────────────────────────────────
# Quest catalog — every quest available in the realm
# ────────────────────────────────────────────────────────────────────────
const QUEST_CATALOG := {
	"whisperwood_cleansing": {
		"giver": "Elder Maeve",
		"actor": "Elder Maeve",
		"role": "quest",
		"kind": "kill",
		"target": "goblin",
		"needed": 5,
		"title": "Whisperwood Cleansing",
		"text": "Slay 5 goblins in the Whisperwood",
		"xp_reward": 80,
		"gold_reward": 60,
		"motivation": "duty",
		"location": "Whisperwood",
		"urgency": "rising",
		"world_trigger": {"kind": "player_level", "value": 1},
		"consequence": {
			"faction": "whisperwood_goblins",
			"pressure_delta": -0.2,
			"npc_flag": ["Elder Maeve", "first_quest_done"],
			"world_flag": "whisperwood_safer",
			"toast": "🌿 The Whisperwood feels a little safer.",
		},
	},
	"pelt_for_lyra": {
		"giver": "Herbalist Lyra",
		"actor": "Herbalist Lyra",
		"role": "alchemy",
		"kind": "fetch",
		"item": "wolf_pelt",
		"needed": 4,
		"title": "Pelts for the Salve",
		"text": "Bring 4 Wolf Pelts to Herbalist Lyra",
		"xp_reward": 70,
		"gold_reward": 45,
		"reward_item": "hp_potion_l",
		"reward_item_qty": 2,
		"motivation": "craft",
		"location": "Briarwood",
		"urgency": "calm",
		"world_trigger": {"kind": "player_level", "value": 1},
		"consequence": {
			"faction": "dire_wolves",
			"pressure_delta": -0.1,
			"npc_flag": ["Herbalist Lyra", "trusts_player"],
			"world_flag": "lyra_potion_brew",
			"toast": "🌱 Lyra trusts you with rarer reagents now.",
		},
	},
	"ears_for_mara": {
		"giver": "Mara the Merchant",
		"actor": "Mara the Merchant",
		"role": "shop",
		"kind": "fetch",
		"item": "goblin_ear",
		"needed": 6,
		"title": "Bounty on Goblin Ears",
		"text": "Mara pays well for proof of slain goblins — bring 6 ears",
		"xp_reward": 60,
		"gold_reward": 90,
		"motivation": "greed",
		"location": "Briarwood",
		"urgency": "calm",
		"world_trigger": {"kind": "player_level", "value": 1},
		"consequence": {
			"faction": "whisperwood_goblins",
			"pressure_delta": -0.15,
			"npc_flag": ["Mara the Merchant", "good_customer"],
			"world_flag": "mara_bounty_paid",
			"toast": "🪙 Word spreads: Mara pays for goblin trophies.",
		},
	},
}


# Returns the role->quest mapping for fast NPC lookup
func _quest_for_role(role: String) -> Dictionary:
	for k in QUEST_CATALOG:
		if QUEST_CATALOG[k].role == role:
			return QUEST_CATALOG[k]
	return {}

# ────────────────────────────────────────────────────────────────────────
# Consequence resolver — single entry point that mutates world state when
# a quest completes. Per QUEST_GRAMMAR.md: faction pressure, world flags,
# npc flags, and an optional toast. This is THE compound multiplier — every
# downstream system (dialogue, spawning, difficulty) reads the state it
# writes.
# ────────────────────────────────────────────────────────────────────────
func apply_consequence(consequence: Dictionary) -> void:
	if consequence.is_empty():
		return
	# Step 1: faction pressure, clamped to [0.0, 1.0].
	var faction_id: String = consequence.get("faction", "")
	if faction_id != "" and factions.has(faction_id):
		var delta: float = float(consequence.get("pressure_delta", 0.0))
		var faction_entry: Dictionary = factions[faction_id]
		var current: float = float(faction_entry.get("pressure", 0.0))
		faction_entry["pressure"] = clamp(current + delta, 0.0, 1.0)
		factions[faction_id] = faction_entry
	# Step 2: world flag, defaults to true.
	var world_flag: String = consequence.get("world_flag", "")
	if world_flag != "":
		world_flags[world_flag] = consequence.get("world_flag_value", true)
	# Step 3: NPC flag, appended not overwritten so dialogue can stack memories.
	var npc_flag: Variant = consequence.get("npc_flag", null)
	if npc_flag is Array and npc_flag.size() >= 2:
		var npc_name: String = String(npc_flag[0])
		var flag_name: String = String(npc_flag[1])
		var existing: Array = npc_flags.get(npc_name, [])
		if not existing.has(flag_name):
			existing.append(flag_name)
		npc_flags[npc_name] = existing
	# Step 4: optional toast.
	var toast: String = consequence.get("toast", "")
	if toast != "":
		_show_toast(toast)
	# Step 5: re-evaluate achievements against the freshly-mutated state.
	# Pure read of factions/world_flags/npc_flags — no further mutation.
	# Owen + Alden see toast on unlock, and the auto-equipper updates the
	# title floating above the player's head.
	_check_achievements()

# Read accessors used by dialogue/spawning/difficulty (queryable schema)
func faction_pressure(faction_id: String) -> float:
	if not factions.has(faction_id):
		return 0.0
	var entry: Dictionary = factions[faction_id]
	return float(entry.get("pressure", 0.0))

func has_world_flag(name: String) -> bool:
	return world_flags.has(name) and bool(world_flags[name])

func npc_has_flag(npc_name: String, flag_name: String) -> bool:
	var arr: Array = npc_flags.get(npc_name, [])
	return arr.has(flag_name)

# Direct world-flag write — sister to apply_consequence's flag step but with
# no faction / npc / toast side-effects. Used when an emergent runtime event
# (e.g. Boss.gd's intro sting firing for the first time, Boss._die landing the
# kill) needs to mark a world fact that downstream READERS consume — today
# DialogueDB's `boss_alive` / `boss_slain` / future seasonal calendar keys.
# Re-runs `_check_achievements()` so any future "Met the Warlord" or
# "Warlord Slain" achievement keyed on world_flags lights up automatically
# the moment the flag flips. Same fail-soft pattern as the rest of this
# class — value defaults to true so the common-case write is one token shorter
# at the callsite (`world.set_world_flag("seen_warlord")`).
func set_world_flag(name: String, value: Variant = true) -> void:
	if name == "":
		return
	world_flags[name] = value
	_check_achievements()

# Runtime item registry helpers ────────────────────────────────────────────
func register_runtime_item(item: Dictionary) -> String:
	if not item.has("runtime_id"):
		return ""
	_runtime_items[item.runtime_id] = item
	return item.runtime_id

func get_runtime_item(id: String) -> Dictionary:
	return _runtime_items.get(id, {})

# ────────────────────────────────────────────────────────────────────────
# Achievements & Title — pure read of world state; on diff, toast and
# auto-equip the highest-priority unlocked title. Safe to call any time;
# fail-soft if `Achievements.gd` ever fails to load (returns no unlocks,
# no crash).
# ────────────────────────────────────────────────────────────────────────
func _check_achievements() -> void:
	var unlocked_now: Array = Achievements.evaluate(self)
	# Diff against `unlocked_achievements` to find newly-unlocked IDs.
	var newly_unlocked: Array[String] = []
	for id_variant in unlocked_now:
		var id: String = String(id_variant)
		if not unlocked_achievements.has(id):
			unlocked_achievements[id] = true
			newly_unlocked.append(id)
	# Toast each newly-unlocked achievement with its icon + name + desc.
	# Spaces them out by 0.6s if multiple unlock at once so kids can read
	# each one (rare but happens at run-end "warden" trip).
	var stagger: float = 0.0
	for id in newly_unlocked:
		var entry: Dictionary = Achievements.ACHIEVEMENTS.get(id, {})
		if entry.is_empty():
			continue
		var icon: String = String(entry.get("icon", "🏆"))
		var aname: String = String(entry.get("name", id))
		var adesc: String = String(entry.get("desc", ""))
		var msg: String = "🏆 %s %s — %s" % [icon, aname, adesc]
		if stagger <= 0.0:
			_show_toast(msg)
		else:
			# Defer subsequent toasts so they do not stomp each other.
			get_tree().create_timer(stagger).timeout.connect(_show_toast.bind(msg))
		stagger += 0.6
	# Auto-equip the highest-priority unlocked title. Stable across runs.
	var new_title: String = Achievements.best_title(unlocked_achievements.keys())
	if new_title != current_title:
		current_title = new_title
		_apply_title_to_player(new_title)
		# A separate, smaller toast for title changes so they read as a
		# distinct event from achievement unlocks (which often fire on the
		# same frame).
		if new_title != "":
			get_tree().create_timer(0.3).timeout.connect(
				_show_toast.bind("✨ Title equipped: %s" % new_title))

# Read-only external accessor — UI panels and future autoload achievements
# panel can call this without poking the dict directly.
func has_achievement(id: String) -> bool:
	return unlocked_achievements.has(id)

# Pushes the current title down to the Player node, if present and ready.
# Player.gd builds a Label3D nameplate at _ready; this just calls its
# `set_title` method. Safe before player exists (no-op).
func _apply_title_to_player(t: String) -> void:
	var player := get_node_or_null("Player")
	if player and player.has_method("set_title"):
		player.set_title(t)

func _ready() -> void:
	add_to_group("world")
	add_to_group("audio_listeners")
	if dialogue_panel: dialogue_panel.visible = false
	if death_overlay: death_overlay.visible = false
	if quest_panel: quest_panel.visible = false
	if dialogue_close_btn: dialogue_close_btn.pressed.connect(close_dialogue)
	# Hook up player stats + inventory listeners
	var player := get_node_or_null("Player")
	if player:
		player.stats_changed.connect(_refresh_hud)
		if player.inventory:
			player.inventory.inventory_changed.connect(_refresh_inventory_ui)
			player.inventory.equipment_changed.connect(_refresh_inventory_ui)
		_refresh_hud()
	_setup_dialogue_actions()
	# Start village ambient theme
	call_deferred("play_music", "village")
	# Bootstrap achievement check — empty on a fresh world, but means future
	# persistence work (saving factions / flags) "just works" without a
	# special-case load path. Also pushes any pre-loaded title onto the
	# player nameplate after a single frame, once Player._ready ran.
	call_deferred("_check_achievements")

func _setup_dialogue_actions() -> void:
	if not dialogue_panel: return
	var vbox := dialogue_panel.get_node_or_null("MarginContainer/VBox")
	if not vbox: return
	if not vbox.has_node("Actions"):
		var actions := HBoxContainer.new()
		actions.name = "Actions"
		actions.alignment = BoxContainer.ALIGNMENT_END
		var accept := Button.new()
		accept.name = "AcceptQuestBtn"
		accept.text = "Accept Quest"
		accept.visible = false
		accept.pressed.connect(_on_accept_quest)
		actions.add_child(accept)
		var turn_in := Button.new()
		turn_in.name = "TurnInQuestBtn"
		turn_in.text = "Turn In Quest"
		turn_in.visible = false
		turn_in.pressed.connect(_on_turn_in_quest)
		actions.add_child(turn_in)
		vbox.add_child(actions)
		var close_btn := vbox.get_node_or_null("CloseBtn")
		if close_btn:
			vbox.move_child(close_btn, vbox.get_child_count() - 1)


var _zone_check_timer: float = 0.0

func _process(delta: float) -> void:
	# Zone music check (every 1.5 sec)
	_zone_check_timer -= delta
	if _zone_check_timer <= 0:
		_zone_check_timer = 1.5
		_check_zone_music()
	# Day/night — full cycle in ~6 minutes
	time_of_day = fposmod(time_of_day + delta * (24.0 / 360.0), 24.0)
	if sun:
		var elev := sin((time_of_day - 6.0) * PI / 12.0)
		var azim := (time_of_day - 6.0) / 24.0 * TAU
		sun.rotation = Vector3(-elev * 0.9, azim, 0)
		sun.light_energy = clamp(0.2 + elev * 1.6, 0.05, 1.9)
		if elev < 0.18 and elev > -0.05:
			sun.light_color = Color(1.0, 0.62, 0.30)
		elif elev <= -0.05:
			sun.light_color = Color(0.30, 0.45, 0.80)
		else:
			sun.light_color = Color(1.0, 0.95, 0.78)

# ════════════════════════════════════════════════════════════════════════
# Dialogue
# ════════════════════════════════════════════════════════════════════════
func show_dialogue(speaker: String, text: String, role: String = "") -> void:
	if not dialogue_panel: return
	dialogue_name_label.text = speaker
	dialogue_text_label.text = "[i]\"%s\"[/i]" % text
	_current_npc_role = role
	_current_npc_name = speaker
	var accept_btn = dialogue_panel.get_node_or_null("MarginContainer/VBox/Actions/AcceptQuestBtn")
	var turn_in_btn = dialogue_panel.get_node_or_null("MarginContainer/VBox/Actions/TurnInQuestBtn")
	var player = get_node_or_null("Player")
	var has_active_quest = player and player.active_quest.size() > 0
	var npc_quest = _quest_for_role(role)
	var npc_offers_quest = not npc_quest.is_empty()
	# Show accept if this NPC offers a quest and we don't have one
	if accept_btn:
		accept_btn.visible = (npc_offers_quest and not has_active_quest)
	# Show turn-in if active quest's giver matches this NPC and it's ready
	if turn_in_btn:
		var ready_to_turn_in = false
		if has_active_quest:
			var q = player.active_quest
			if q.get("giver", "") == speaker and player.is_quest_ready_to_turn_in():
				ready_to_turn_in = true
		turn_in_btn.visible = ready_to_turn_in
	dialogue_panel.visible = true

func close_dialogue() -> void:
	if dialogue_panel:
		dialogue_panel.visible = false

# ════════════════════════════════════════════════════════════════════════
# Quests
# ════════════════════════════════════════════════════════════════════════
func _on_accept_quest() -> void:
	var player := get_node_or_null("Player")
	if not player: return
	var npc_quest = _quest_for_role(_current_npc_role)
	if npc_quest.is_empty(): return
	player.accept_quest(npc_quest)
	play_sfx("quest_accept")
	close_dialogue()


func _on_turn_in_quest() -> void:
	var player := get_node_or_null("Player")
	if not player: return
	var quest_title: String = player.active_quest.get("title", "Quest")
	var gold_r: int = int(player.active_quest.get("gold_reward", 0))
	var xp_r: int = int(player.active_quest.get("xp_reward", 0))
	# Capture consequence BEFORE complete_quest_if_done() wipes active_quest.
	var consequence_dict: Dictionary = player.active_quest.get("consequence", {})
	if player.complete_quest_if_done():
		_show_toast("✨ %s complete! +%d gold, +%d XP" % [quest_title, gold_r, xp_r])
		quest_panel.visible = false
		# Apply downstream world-state mutations (factions, flags, NPC memory)
		apply_consequence(consequence_dict)
	close_dialogue()

func on_quest_accepted(quest: Dictionary) -> void:
	if quest_panel:
		quest_panel.visible = true
	_update_quest_label()
	_show_toast("📜 New quest: %s" % quest.get("title", ""))

func on_quest_progress(_quest: Dictionary) -> void:
	_update_quest_label()

func _update_quest_label() -> void:
	var player := get_node_or_null("Player")
	if not player or player.active_quest.size() == 0:
		if quest_panel: quest_panel.visible = false
		return
	var q = player.active_quest
	var done: bool = player.is_quest_ready_to_turn_in()
	var status = " ✓ READY TO TURN IN" if done else ""
	var progress_text = ""
	match q.get("kind", "kill"):
		"kill":
			progress_text = "%d/%d" % [q.get("killed", 0), q.get("needed", 0)]
		"fetch":
			var have: int = 0
			if player.inventory:
				have = player.inventory.count_item(q.get("item", ""))
			progress_text = "%d/%d" % [have, q.get("needed", 0)]
	quest_label.text = "%s\n%s — %s%s" % [q.get("title", ""), q.get("text", ""), progress_text, status]

# ════════════════════════════════════════════════════════════════════════
# HUD
# ════════════════════════════════════════════════════════════════════════
func _refresh_hud() -> void:
	var player := get_node_or_null("Player")
	if not player: return
	var hp_extra = 0; var mp_extra = 0
	if player.inventory:
		hp_extra = player.inventory.bonus_hp()
		mp_extra = player.inventory.bonus_mp()
	if hp_bar:
		hp_bar.max_value = player.max_hp + hp_extra
		hp_bar.value = player.hp
	if mp_bar:
		mp_bar.max_value = player.max_mp + mp_extra
		mp_bar.value = player.mp
	if xp_bar:
		xp_bar.max_value = player.xp_for_next_level()
		xp_bar.value = player.xp
	if level_label:
		level_label.text = "Lv " + str(player.level)
	if gold_label:
		gold_label.text = "Gold: %d" % player.gold
	_update_quest_label()

# ════════════════════════════════════════════════════════════════════════
# Death overlay
# ════════════════════════════════════════════════════════════════════════
func show_death_overlay() -> void:
	if death_overlay:
		death_overlay.visible = true
	if death_label:
		death_label.text = "You have fallen.\nReturning to Briarwood…"

func hide_death_overlay() -> void:
	if death_overlay:
		death_overlay.visible = false


# ════════════════════════════════════════════════════════════════════════
# Audio (music + SFX)
# ════════════════════════════════════════════════════════════════════════
const MUSIC_TRACKS = {
	"village":     "res://assets/audio/music/village_theme.wav",
	"whisperwood": "res://assets/audio/music/whisperwood_theme.wav",
	"battle":      "res://assets/audio/music/battle_theme.wav",
}
const SFX = {
	"sword_swing":   "res://assets/audio/sfx/sword_swing.wav",
	"sword_hit":     "res://assets/audio/sfx/sword_hit.wav",
	"damage_taken":  "res://assets/audio/sfx/damage_taken.wav",
	"enemy_death":   "res://assets/audio/sfx/enemy_death.wav",
	"loot_pickup":   "res://assets/audio/sfx/loot_pickup.wav",
	"level_up":      "res://assets/audio/sfx/level_up.wav",
	"quest_accept":  "res://assets/audio/sfx/quest_accept.wav",
	"chest_open":    "res://assets/audio/sfx/chest_open.wav",
	"player_death":  "res://assets/audio/sfx/player_death.wav",
	"boss_intro":    "res://assets/audio/sfx/boss_intro.wav",
}
var _current_music: String = ""

func play_music(zone: String) -> void:
	var path = MUSIC_TRACKS.get(zone, "")
	if path == "" or _current_music == zone:
		return
	if not ResourceLoader.exists(path):
		return
	var mp = get_node_or_null("Audio/MusicPlayer")
	if not mp: return
	var stream = load(path)
	mp.stream = stream
	if stream and "loop" in stream:
		stream.loop = true
	mp.play()
	_current_music = zone

func play_sfx(name: String) -> void:
	var path = SFX.get(name, "")
	if path == "" or not ResourceLoader.exists(path):
		return
	var sp = get_node_or_null("Audio/SFXPlayer")
	if not sp: return
	sp.stream = load(path)
	sp.play()

# Auto-switch zone music based on player location
func _check_zone_music() -> void:
	var player = get_node_or_null("Player")
	if not player: return
	var dist = player.global_position.length()
	# In a boss fight? Check for any active boss in range
	for boss in get_tree().get_nodes_in_group("bosses"):
		if boss.has_method("get") and boss.global_position.distance_to(player.global_position) < 30.0:
			play_music("battle")
			return
	if dist > 22.0:
		play_music("whisperwood")
	else:
		play_music("village")

# ════════════════════════════════════════════════════════════════════════
# Generic toast
# ════════════════════════════════════════════════════════════════════════
var _toast: Label = null
func _show_toast(text: String) -> void:
	if _toast and is_instance_valid(_toast):
		_toast.queue_free()
	_toast = Label.new()
	_toast.text = text
	_toast.add_theme_font_size_override("font_size", 28)
	_toast.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	_toast.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_toast.add_theme_constant_override("outline_size", 6)
	_toast.anchor_left = 0.5; _toast.anchor_right = 0.5
	_toast.anchor_top = 0.3
	_toast.offset_left = -360; _toast.offset_right = 360
	_toast.offset_top = 0; _toast.offset_bottom = 60
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$UI.add_child(_toast)
	var t = create_tween()
	t.tween_interval(2.0)
	t.tween_property(_toast, "modulate:a", 0.0, 1.0)
	t.tween_callback(_toast.queue_free)

# ════════════════════════════════════════════════════════════════════════
# Inventory & Paperdoll UI — built lazily on first toggle.
# Uses click-to-equip semantics (kid-friendly). Keys: I = toggle.
# ════════════════════════════════════════════════════════════════════════
const SLOT_LAYOUT := [
	{"slot":"weapon",  "label":"⚔ Weapon",  "x":24,  "y":36},
	{"slot":"armor",   "label":"🛡 Armor",   "x":24,  "y":120},
	{"slot":"trinket", "label":"💍 Trinket", "x":24,  "y":204},
]

func toggle_inventory() -> void:
	if inventory_panel == null:
		_build_inventory_ui()
	inventory_panel.visible = not inventory_panel.visible
	# Free the mouse when the inventory is open so the player can click
	if inventory_panel.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_refresh_inventory_ui()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE  # camera uses right-drag, so keep visible
		if inv_tooltip and is_instance_valid(inv_tooltip):
			inv_tooltip.visible = false


func _build_inventory_ui() -> void:
	# Root panel — centered, 720 x 460
	inventory_panel = Panel.new()
	inventory_panel.name = "InventoryPanel"
	inventory_panel.anchor_left = 0.5; inventory_panel.anchor_right = 0.5
	inventory_panel.anchor_top = 0.5;  inventory_panel.anchor_bottom = 0.5
	inventory_panel.offset_left = -360
	inventory_panel.offset_right = 360
	inventory_panel.offset_top = -240
	inventory_panel.offset_bottom = 240
	inventory_panel.visible = false
	$UI.add_child(inventory_panel)

	# Title bar
	var title := Label.new()
	title.text = "🎒  Inventory & Equipment"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	title.add_theme_constant_override("outline_size", 4)
	title.position = Vector2(20, 8)
	title.size = Vector2(700, 32)
	inventory_panel.add_child(title)

	# Close button
	var close := Button.new()
	close.text = "✕"
	close.position = Vector2(680, 8)
	close.size = Vector2(36, 30)
	close.pressed.connect(toggle_inventory)
	inventory_panel.add_child(close)

	# Paperdoll column (left side, 200px wide)
	var pd_title := Label.new()
	pd_title.text = "— Equipped —"
	pd_title.position = Vector2(20, 50)
	pd_title.size = Vector2(220, 24)
	pd_title.add_theme_font_size_override("font_size", 16)
	pd_title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	inventory_panel.add_child(pd_title)

	for entry in SLOT_LAYOUT:
		var slot_name = entry.slot
		var btn := Button.new()
		btn.name = "Slot_" + slot_name
		btn.position = Vector2(entry.x, 80 + (84 * SLOT_LAYOUT.find(entry)))
		btn.size = Vector2(220, 76)
		btn.text = entry.label + "\n(empty)"
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(_on_paperdoll_slot_pressed.bind(slot_name))
		btn.mouse_entered.connect(_on_paperdoll_hover.bind(slot_name))
		btn.mouse_exited.connect(_hide_tooltip)
		inventory_panel.add_child(btn)
		paperdoll_slots[slot_name] = btn

	# Stats card below paperdoll
	stats_label = RichTextLabel.new()
	stats_label.position = Vector2(20, 332)
	stats_label.size = Vector2(220, 100)
	stats_label.bbcode_enabled = true
	stats_label.fit_content = true
	stats_label.add_theme_font_size_override("normal_font_size", 13)
	inventory_panel.add_child(stats_label)


	# Bag grid (right side) — 6 cols x 4 rows = 24 slots, slot = 70x70
	var bag_title := Label.new()
	bag_title.text = "— Bag (24 slots) —"
	bag_title.position = Vector2(260, 50)
	bag_title.size = Vector2(440, 24)
	bag_title.add_theme_font_size_override("font_size", 16)
	bag_title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	inventory_panel.add_child(bag_title)

	bag_buttons.clear()
	var slot_size := 70
	var pad := 4
	for i in 24:
		var col := i % 6
		var row := i / 6
		var btn := Button.new()
		btn.name = "Bag_%d" % i
		btn.position = Vector2(260 + col * (slot_size + pad), 80 + row * (slot_size + pad))
		btn.size = Vector2(slot_size, slot_size)
		btn.text = ""
		btn.add_theme_font_size_override("font_size", 22)
		btn.pressed.connect(_on_bag_slot_pressed.bind(i))
		btn.mouse_entered.connect(_on_bag_slot_hover.bind(i))
		btn.mouse_exited.connect(_hide_tooltip)
		inventory_panel.add_child(btn)
		bag_buttons.append(btn)

	# Footer hint
	var hint := Label.new()
	hint.text = "Click bag item to use/equip  •  Click equipped slot to unequip  •  I to close  •  Q to drink potion"
	hint.position = Vector2(20, 432)
	hint.size = Vector2(700, 24)
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.65))
	inventory_panel.add_child(hint)

	# Tooltip (single shared label, follows mouse)
	inv_tooltip = Label.new()
	inv_tooltip.name = "InvTooltip"
	inv_tooltip.visible = false
	inv_tooltip.add_theme_font_size_override("font_size", 13)
	inv_tooltip.add_theme_color_override("font_color", Color(1, 1, 1))
	inv_tooltip.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	inv_tooltip.add_theme_constant_override("outline_size", 4)
	inv_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inv_tooltip.size = Vector2(320, 100)
	inv_tooltip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	$UI.add_child(inv_tooltip)


# ── Click handlers ───────────────────────────────────────────────────────
func _on_paperdoll_slot_pressed(slot_name: String) -> void:
	var player := get_node_or_null("Player")
	if not player or not player.inventory: return
	if player.inventory.equipped.get(slot_name, "") != "":
		player.inventory.unequip(slot_name)

func _on_bag_slot_pressed(idx: int) -> void:
	var player := get_node_or_null("Player")
	if not player or not player.inventory: return
	if idx < 0 or idx >= player.inventory.bag.size():
		return
	player.inventory.use_item(idx, player)

# ── Hover / tooltip ──────────────────────────────────────────────────────
func _on_paperdoll_hover(slot_name: String) -> void:
	var player := get_node_or_null("Player")
	if not player or not player.inventory: return
	var id = player.inventory.equipped.get(slot_name, "")
	if id == "":
		_hide_tooltip()
		return
	var item = Items.get_item(id)
	if item.is_empty():
		item = get_runtime_item(id)
	_show_tooltip_for(item)

func _on_bag_slot_hover(idx: int) -> void:
	var player := get_node_or_null("Player")
	if not player or not player.inventory: return
	if idx < 0 or idx >= player.inventory.bag.size():
		_hide_tooltip()
		return
	var slot = player.inventory.bag[idx]
	var item = Items.get_item(slot.id)
	if item.is_empty():
		item = get_runtime_item(slot.id)
	_show_tooltip_for(item)

func _show_tooltip_for(item: Dictionary) -> void:
	if item.is_empty() or inv_tooltip == null: return
	var rarity = item.get("rarity", "common")
	var rcol: Color = Items.RARITY_COLORS.get(rarity, Color.WHITE)
	var lines: Array = []
	lines.append("[color=#%s][b]%s[/b][/color]" % [rcol.to_html(false), item.get("name", "?")])
	lines.append("[i]%s · %s[/i]" % [item.get("type", ""), rarity])
	if item.has("damage"):    lines.append("⚔ +%d damage" % item.damage)
	if item.has("armor"):     lines.append("🛡 +%d armor" % item.armor)
	if item.has("hp_bonus"):  lines.append("❤ +%d max HP" % item.hp_bonus)
	if item.has("mp_bonus"):  lines.append("✦ +%d max MP" % item.mp_bonus)
	if item.has("crit_bonus"):lines.append("✦ +%d%% crit" % int(item.crit_bonus * 100))
	if item.has("heal"):      lines.append("Heals %d HP" % item.heal)
	if item.has("mana"):      lines.append("Restores %d MP" % item.mana)
	if item.has("value"):     lines.append("[color=#cccccc]Worth %d gold[/color]" % item.value)
	# Use a RichTextLabel-style tooltip via Label is awkward; we'll use plain text
	var plain := ""
	plain += item.get("name", "?") + "\n"
	plain += "%s · %s\n" % [item.get("type", ""), rarity]
	if item.has("damage"):    plain += "⚔ +%d damage\n" % item.damage
	if item.has("armor"):     plain += "🛡 +%d armor\n" % item.armor
	if item.has("hp_bonus"):  plain += "❤ +%d max HP\n" % item.hp_bonus
	if item.has("mp_bonus"):  plain += "✦ +%d max MP\n" % item.mp_bonus
	if item.has("crit_bonus"):plain += "✦ +%d%% crit\n" % int(item.crit_bonus * 100)
	if item.has("heal"):      plain += "Heals %d HP\n" % item.heal
	if item.has("mana"):      plain += "Restores %d MP\n" % item.mana
	if item.has("value"):     plain += "Worth %d gold" % item.value
	inv_tooltip.text = plain
	inv_tooltip.add_theme_color_override("font_color", rcol)
	inv_tooltip.position = get_viewport().get_mouse_position() + Vector2(16, 16)
	inv_tooltip.visible = true

func _hide_tooltip() -> void:
	if inv_tooltip:
		inv_tooltip.visible = false


# ── Refresh ──────────────────────────────────────────────────────────────
func _refresh_inventory_ui() -> void:
	if inventory_panel == null or not inventory_panel.visible:
		# Still refresh HUD totals
		_refresh_hud()
		return
	var player := get_node_or_null("Player")
	if not player or not player.inventory: return

	# Paperdoll
	for entry in SLOT_LAYOUT:
		var slot_name = entry.slot
		var btn: Button = paperdoll_slots.get(slot_name)
		if btn == null: continue
		var id = player.inventory.equipped.get(slot_name, "")
		if id == "":
			btn.text = entry.label + "\n(empty)"
			btn.modulate = Color(1, 1, 1, 0.85)
		else:
			var item = Items.get_item(id)
			if item.is_empty():
				item = get_runtime_item(id)
			var icon = item.get("icon", "?")
			var name = item.get("name", id)
			btn.text = "%s  %s\n%s" % [icon, entry.label, name]
			var rarity = item.get("rarity", "common")
			btn.modulate = Items.RARITY_COLORS.get(rarity, Color.WHITE)

	# Bag
	for i in bag_buttons.size():
		var btn: Button = bag_buttons[i]
		if i < player.inventory.bag.size():
			var slot = player.inventory.bag[i]
			var item = Items.get_item(slot.id)
			if item.is_empty():
				item = get_runtime_item(slot.id)
			var icon = item.get("icon", "?")
			var qty_txt = "" if slot.qty <= 1 else ("×%d" % slot.qty)
			btn.text = "%s\n%s" % [icon, qty_txt]
			var rarity = item.get("rarity", "common")
			btn.modulate = Items.RARITY_COLORS.get(rarity, Color.WHITE)
		else:
			btn.text = ""
			btn.modulate = Color(1, 1, 1, 0.40)

	# Stats card
	var dmg = player.attack_damage_base + int(player.level * 1.5) + player.inventory.bonus_damage()
	var arm = player.inventory.bonus_armor()
	var hpb = player.inventory.bonus_hp()
	var mpb = player.inventory.bonus_mp()
	var crit = int((player.crit_chance + player.inventory.bonus_crit()) * 100)
	stats_label.text = "[b]Stats[/b]\n⚔ Damage: [color=#ffce5e]%d[/color]\n🛡 Armor: [color=#9bd0ff]%d[/color]\n❤ Max HP: %d (+%d)\n✦ Max MP: %d (+%d)\n✦ Crit: [color=#ffd66b]%d%%[/color]" % [dmg, arm, player.max_hp, hpb, player.max_mp, mpb, crit]

	# Refresh top HUD too (HP/MP cap may have changed)
	_refresh_hud()


# Tooltip follows mouse while visible
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and inv_tooltip and inv_tooltip.visible:
		inv_tooltip.position = get_viewport().get_mouse_position() + Vector2(16, 16)

# Mount toggle stub (Phase 2 item 6 — wire here when Horse.glb mount is added)
func toggle_mount() -> void:
	var player := get_node_or_null("Player")
	if not player: return
	# Simple speed-buff toggle until 3D mount is wired
	if player.mounted:
		player.mounted = false
		player.walk_speed = 5.5
		player.run_speed = 9.0
		_show_toast("🐎 Dismounted")
	else:
		player.mounted = true
		player.walk_speed = 13.0
		player.run_speed = 22.0
		_show_toast("🐎 Mounted! Speed boost engaged")
