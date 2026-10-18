extends Camera2D

func _physics_process(delta: float) -> void:
	$".".global_position = lerp($"../CharacterBody2D".position, global_position, 0.95)
