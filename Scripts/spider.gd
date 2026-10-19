class_name Spider
extends CharacterBody2D

signal died


const SPEED = 140.0
const KNOCKBACK_SPEED = 700.0
# How quickly knockback bleeds off, in px/s per second.
const KNOCKBACK_FRICTION = 2800.0
const HURT_TIME = 0.25
# Stop closing in once this close, so the spider doesn't grind into the player.
const STOP_DISTANCE = 90.0
# Bites the player when this close, at most once per BITE_COOLDOWN.
const BITE_RANGE = 130.0
const BITE_COOLDOWN = 1.0
const BITE_DAMAGE = 1

@export var max_health := 3
# Who to chase. If empty, falls back to the first node in the "player" group.
@export var target: Node2D
# If above 0, the spider stays still (e.g. hidden behind a tree) until the
# player comes within this distance, or it gets hit.
@export var ambush_range := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var health: int
var hurt_timer := 0.0
var knockback := Vector2.ZERO
var facing := "left"
var hiding := false
var bite_timer := 0.0


func _ready() -> void:
	health = max_health
	sprite.play("walk_left")
	hiding = ambush_range > 0.0
	if hiding:
		sprite.pause()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player") as Node2D

	if hurt_timer > 0.0:
		hurt_timer -= delta
		knockback = knockback.move_toward(Vector2.ZERO, KNOCKBACK_FRICTION * delta)
		velocity = knockback
		move_and_slide()
		if hurt_timer <= 0.0:
			sprite.play("walk_" + facing)
		return

	bite_timer = maxf(bite_timer - delta, 0.0)
	if hiding:
		if target and global_position.distance_to(target.global_position) < ambush_range:
			hiding = false
		else:
			return

	velocity = Vector2.ZERO
	if target:
		var to_target := target.global_position - global_position
		if to_target.length() < BITE_RANGE and bite_timer <= 0.0 and target.has_method("take_damage"):
			target.take_damage(BITE_DAMAGE, global_position)
			bite_timer = BITE_COOLDOWN
		if to_target.length() > STOP_DISTANCE:
			velocity = to_target.normalized() * SPEED
		if to_target.x != 0.0:
			facing = "right" if to_target.x > 0.0 else "left"
	move_and_slide()

	sprite.play("walk_" + facing)
	if velocity == Vector2.ZERO:
		sprite.pause()


func take_damage(amount: int, from_position: Vector2) -> void:
	hiding = false
	health -= amount
	if health <= 0:
		Sound.play("spider_die", 0.1)
		died.emit()
		queue_free()
		return

	var away := global_position - from_position
	if away == Vector2.ZERO:
		away = Vector2.RIGHT if facing == "left" else Vector2.LEFT
	knockback = away.normalized() * KNOCKBACK_SPEED
	Sound.play("spider_hurt", 0.1)
	hurt_timer = HURT_TIME
	sprite.play("damaged")
