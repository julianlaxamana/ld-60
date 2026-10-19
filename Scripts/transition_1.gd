extends Node2D

const NEXT_SCENE = "res://Scenes/map.tscn"

var leaving := false


func _on_timer_timeout() -> void:
	leave()


# Any key, mouse button, or gamepad button skips the wait.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed() and not event.is_echo() and not event is InputEventMouseMotion:
		leave()


func leave() -> void:
	if leaving:
		return
	leaving = true
	get_tree().change_scene_to_file.call_deferred(NEXT_SCENE)
