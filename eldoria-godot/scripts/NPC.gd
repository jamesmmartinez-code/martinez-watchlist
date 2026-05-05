extends StaticBody3D
class_name NPC

@export var npc_name: String = "Villager"
@export var npc_role: String = "villager"
@export var dialogue: String = "Hail, traveler. Stay close to the village walls."
# REFINE: mood-dependent variants by time-of-day (morning / midday / evening / night).
# Falls back to single `dialogue` line above if this array is empty. WorldBuilder.gd
# populates these per-NPC so each villager has a small personality detail.
@export var dialogue_variants: PackedStringArray = PackedStringArray()
# INTEGRATE (pattern A): when this NPC has earned a memory flag from a quest
# consequence (Maeve→first_quest_done, Lyra→trusts_player, Mara→good_customer),
# their lines should warm. `warmed_flag` names the flag to consult on World;
# `warmed_dialogue_variants` is the same morning/midday/evening/night structure
# as `dialogue_variants`, used only when the flag is set. Empty = no change.
@export var warmed_flag: String = ""
@export var warmed_dialogue_variants: PackedStringArray = PackedStringArray()

@onready var label_3d: Label3D = $Label3D
@onready var interact_area: Area3D = $InteractArea
@onready var anim: AnimationPlayer = get_node_or_null("AnimationPlayer")

var player_in_range: bool = false

func _ready() -> void:
	if label_3d:
		label_3d.text = npc_name
		label_3d.visible = false
	if interact_area:
		interact_area.body_entered.connect(_on_body_entered)
		interact_area.body_exited.connect(_on_body_exited)
	# Idle anim if available
	if anim and anim.has_animation("Idle"):
		anim.play("Idle")

func _process(_delta: float) -> void:
	# Show name label only when player is in range
	if label_3d:
		label_3d.visible = player_in_range

func _on_body_entered(body: Node) -> void:
	if body is Player:
		player_in_range = true
		(body as Player).interact_pressed.connect(_on_interact)

func _on_body_exited(body: Node) -> void:
	if body is Player:
		player_in_range = false
		if (body as Player).interact_pressed.is_connected(_on_interact):
			(body as Player).interact_pressed.disconnect(_on_interact)

func _on_interact() -> void:
	if not player_in_range:
		return
	# REFINE: choose a mood-dependent line by time-of-day when variants exist;
	# otherwise emit the single fallback `dialogue` line as before.
	# INTEGRATE (pattern A): if a `warmed_flag` is set and the World records
	# that this NPC carries it, prefer the warmed variants of the same shape.
	# Quest consequences write these flags via World.apply_consequence().
	var line: String = dialogue
	var w = get_tree().get_first_node_in_group("world")
	var variants: PackedStringArray = dialogue_variants
	if warmed_flag != "" and not warmed_dialogue_variants.is_empty() and w and w.has_method("npc_has_flag"):
		if w.npc_has_flag(npc_name, warmed_flag):
			variants = warmed_dialogue_variants
	if not variants.is_empty():
		var tod: float = 11.0
		if w and ("time_of_day" in w):
			tod = float(w.time_of_day)
		var bucket: int = 0
		if tod >= 5.0 and tod < 11.0:
			bucket = 0   # dawn / morning
		elif tod >= 11.0 and tod < 17.0:
			bucket = 1   # midday
		elif tod >= 17.0 and tod < 21.0:
			bucket = 2   # evening
		else:
			bucket = 3   # night
		bucket = min(bucket, variants.size() - 1)
		line = variants[bucket]
	# Emit a dialog signal that the World scene picks up to show UI
	get_tree().call_group("world", "show_dialogue", npc_name, line, npc_role)
