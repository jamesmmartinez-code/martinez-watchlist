extends StaticBody3D
class_name NPC

@export var npc_name: String = "Villager"
@export var npc_role: String = "villager"
@export var dialogue: String = "Hail, traveler. Stay close to the village walls."

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
	# Emit a dialog signal that the World scene picks up to show UI
	get_tree().call_group("world", "show_dialogue", npc_name, dialogue, npc_role)
