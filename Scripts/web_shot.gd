class_name WebShot
extends Area2D

# A glob of web spat by the boss spider. Flies in a straight line (or homes in,
# for the last shot), hurts the player on contact, and breaks on trees.

const TEXTURE := preload("res://Sprites/web.png")
const LIFETIME = 4.0
const TURN_SPEED = 3.0

var velocity := Vector2.ZERO
var damage := 1
# The boss's last shot: follows the player and always kills.
var lethal := false
var shooter: Node

var _age := 0.0


func _init(size := 2.0) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = TEXTURE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(size, size)
	add_child(sprite)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 9.0 * size
	shape.shape = circle
	add_child(shape)


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if Dialogue.is_busy():
		return
	_age += delta
	if _age > LIFETIME and not lethal:
		queue_free()
		return
	if lethal:
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player:
			var want := (player.global_position - global_position).normalized() * velocity.length()
			velocity = velocity.lerp(want, minf(TURN_SPEED * delta, 1.0))
	position += velocity * delta
	rotation += 6.0 * delta


func _on_body_entered(body: Node2D) -> void:
	if body == shooter:
		return
	if body is Player:
		if lethal:
			body.kill()
		else:
			body.take_damage(damage, global_position)
		queue_free()
	elif body is StaticBody2D and not lethal:
		queue_free()
