extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	print( get_viewport().get_visible_rect().size)
	$".".offset = get_viewport().get_visible_rect().size / 2
	$MeshInstance2D.mesh.size = get_viewport().get_visible_rect().size
	pass
