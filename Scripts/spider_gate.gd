extends StaticBody2D

# Webs blocking a path. They clear once every node in `group` is gone
# (e.g. all the spiders in the area are dead), and stay cleared after
# leaving and coming back.

@export var group := "gate_spiders"

# Gates that have been cleared, by scene path + node name.
static var _cleared := {}

var _opening := false


func _ready() -> void:
	if _cleared.has(_key()):
		for enemy in get_tree().get_nodes_in_group(group):
			enemy.queue_free()
		queue_free()


func _process(_delta: float) -> void:
	if _opening:
		return
	for enemy in get_tree().get_nodes_in_group(group):
		if not enemy.is_queued_for_deletion():
			return
	_opening = true
	Sound.play("gate")
	_cleared[_key()] = true
	$CollisionShape2D.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	tween.tween_callback(queue_free)


func _key() -> String:
	return get_tree().current_scene.scene_file_path + ":" + name
