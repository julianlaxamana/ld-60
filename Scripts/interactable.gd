class_name Interactable
extends Area2D

# Attach to an Area2D (with a CollisionShape2D child) around an object or NPC.
# When the player is inside it and presses Interact, the lines play.

@export_multiline var lines: Array[String] = []
# If set, plays Day.lines(day_key) instead, so the text changes each day.
@export var day_key := ""
# If true, only plays the first time.
@export var once := false

var _player_inside := false
var _done := false

# Every interactable joins this group. When the player stands in more than one
# at once, only the closest answers the press, so one E never fires two things.
const GROUP := "interactables"


# True if `area` is the nearest interactable the player is currently inside.
static func is_closest(area: Area2D) -> bool:
	var player: Node2D = null
	for body in area.get_overlapping_bodies():
		if body is Player:
			player = body
	if player == null:
		return true
	var mine := player.global_position.distance_squared_to(area.global_position)
	for other in area.get_tree().get_nodes_in_group(GROUP):
		if other == area or other.is_queued_for_deletion() or not other.is_processing():
			continue
		if not other.get("_player_inside") or other.get("_done"):
			continue
		if player.global_position.distance_squared_to(other.global_position) < mine:
			return false
	return true


func _ready() -> void:
	add_to_group(GROUP)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if not _player_inside or _done or Dialogue.is_busy():
		return
	if Input.is_action_just_pressed("Interact") and Interactable.is_closest(self):
		Dialogue.start(Day.lines(day_key) if day_key != "" else lines)
		if once:
			_done = true


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_inside = true


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_inside = false
