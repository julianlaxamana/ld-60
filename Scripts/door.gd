extends Area2D

# Walking into this door loads target_scene and places the player at the
# Marker2D named target_spawn in that scene.

@export_file("*.tscn") var target_scene: String
@export var target_spawn: String
# If set, the door only opens when Day.can_pass(lock) is true. Otherwise
# walking into it plays Day.lines(lock + "_locked").
@export var lock := ""

# Survives the scene change so the next room knows where to put the player.
static var next_spawn := ""

var used := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if next_spawn != "" and get_parent().has_node(next_spawn):
		var player := get_parent().get_node("CharacterBody2D") as Node2D
		var spawn := get_parent().get_node(next_spawn) as Node2D
		player.global_position = spawn.global_position
		var camera := get_parent().get_node_or_null("Camera2D") as Node2D
		if camera:
			camera.global_position = spawn.global_position
		next_spawn = ""


func _on_body_entered(body: Node2D) -> void:
	if used or body.name != "CharacterBody2D":
		return
	if lock != "" and not Day.can_pass(lock):
		Dialogue.start(Day.lines(lock + "_locked"))
		return
	used = true
	next_spawn = target_spawn
	get_tree().call_deferred("change_scene_to_file", target_scene)
