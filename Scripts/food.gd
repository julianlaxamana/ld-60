extends Area2D

# The plate Mom left on the kitchen table. Interacting picks it up; it gets
# eaten on the couch in front of the TV. The plate looks worse every day.

@onready var sprite: Sprite2D = $Sprite2D

var _player_inside := false


func _ready() -> void:
	add_to_group(Interactable.GROUP)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	sprite.texture = Day.food_texture()
	if Day.has_food or Day.ate or sprite.texture == null:
		sprite.hide()


func _process(_delta: float) -> void:
	if not _player_inside or Dialogue.is_busy():
		return
	if Input.is_action_just_pressed("Interact") and Interactable.is_closest(self):
		if not sprite.visible:
			Dialogue.start(Day.lines("table_empty"))
			return
		Day.has_food = true
		Sound.play("item")
		sprite.hide()
		Dialogue.start(Day.lines("food_take"))


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_inside = true


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_inside = false
