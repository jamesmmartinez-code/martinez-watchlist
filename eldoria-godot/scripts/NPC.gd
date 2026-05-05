extends StaticBody3D
class_name NPC

@export var npc_name: String = "Villager"
@export var npc_role: String = "villager"
@export var dialogue: String = "Hail, traveler. Stay close to the village walls."
# REFINE: mood-dependent variants by time-of-day (morning / midday / evening / night).
# Falls back to single `dialogue` line above if this array is empty. WorldBuilder.gd
# populates these per-NPC so each villager has a small personality detail.
@export var dialogue_variants: PackedStringArray = PackedStringArray()

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
	var line: String = dialogue
	if not dialogue_variants.is_empty():
		var w = get_tree().get_first_node_in_group("world")
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
		bucket = min(bucket, dialogue_variants.size() - 1)
		line = dialogue_variants[bucket]
	# Emit a dialog signal that the World scene picks up to show UI
	get_tree().call_group("world", "show_dialogue", npc_name, line, npc_role)
