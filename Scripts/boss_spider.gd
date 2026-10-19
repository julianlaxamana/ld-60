class_name BossSpider
extends CharacterBody2D

# The big spider at the farm gate. Sleeps until the player comes close, then
# keeps its distance and spits webs. Once it's been hurt enough it stops,
# winds up, and fires one last shot that always kills, which ends the day.
# She never gets past the farm.

enum State { SLEEPING, FIGHTING, FINAL, DONE }

const SPEED = 90.0
# Tries to stay about this far from the player.
const KEEP_DISTANCE = 380.0
const BITE_RANGE = 170.0
const BITE_COOLDOWN = 1.2
const SHOT_SPEED = 430.0
const SHOT_COOLDOWN = 1.6
# Webs per volley, fanned out by SPREAD radians.
const SHOTS_PER_VOLLEY = 3
const SPREAD = 0.3
const FINAL_SHOT_SPEED = 650.0
const WIND_UP_TIME = 1.4
const HURT_TIME = 0.2

@export var max_health := 12
# Below this health it gives up fighting fair and fires the last shot.
@export var final_at := 6
@export var wake_range := 800.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var health: int
var state := State.SLEEPING
var target: Node2D
var facing := "left"
var shot_timer := SHOT_COOLDOWN
var bite_timer := 0.0
var hurt_timer := 0.0


func _ready() -> void:
	health = max_health
	sprite.play("walk_left")
	sprite.pause()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player") as Node2D
	if target == null or Dialogue.is_busy() or Day.is_busy():
		return

	match state:
		State.SLEEPING:
			if global_position.distance_to(target.global_position) < wake_range:
				_wake()
		State.FIGHTING:
			_fight(delta)


func _wake() -> void:
	state = State.FIGHTING
	Sound.play("boss_roar")
	sprite.play("walk_" + facing)
	Dialogue.start(Day.lines("boss"))


func _fight(delta: float) -> void:
	if hurt_timer > 0.0:
		hurt_timer -= delta
		if hurt_timer <= 0.0:
			sprite.play("walk_" + facing)
		return

	var to_target := target.global_position - global_position
	var distance := to_target.length()
	if to_target.x != 0.0:
		facing = "right" if to_target.x > 0.0 else "left"

	# Close in when far, back off when the player gets too close.
	velocity = Vector2.ZERO
	if distance > KEEP_DISTANCE + 60.0:
		velocity = to_target.normalized() * SPEED
	elif distance < KEEP_DISTANCE - 60.0:
		velocity = -to_target.normalized() * SPEED * 0.6
	move_and_slide()
	sprite.play("walk_" + facing)

	bite_timer = maxf(bite_timer - delta, 0.0)
	if distance < BITE_RANGE and bite_timer <= 0.0:
		target.take_damage(1, global_position)
		bite_timer = BITE_COOLDOWN

	shot_timer -= delta
	if shot_timer <= 0.0:
		shot_timer = SHOT_COOLDOWN
		_volley(to_target.angle())


func _volley(angle: float) -> void:
	for i in SHOTS_PER_VOLLEY:
		var offset := (i - (SHOTS_PER_VOLLEY - 1) / 2.0) * SPREAD
		_shoot(Vector2.from_angle(angle + offset) * SHOT_SPEED, 2.0, false)
	Sound.play("spider_hurt", 0.3)


func _shoot(shot_velocity: Vector2, size: float, lethal: bool) -> void:
	var shot := WebShot.new(size)
	shot.velocity = shot_velocity
	shot.lethal = lethal
	shot.shooter = self
	shot.global_position = global_position
	get_parent().add_child(shot)


func take_damage(amount: int, _from_position: Vector2) -> void:
	if state == State.SLEEPING:
		_wake()
		return
	if state != State.FIGHTING:
		return
	health -= amount
	Sound.play("spider_hurt", 0.1)
	hurt_timer = HURT_TIME
	sprite.play("damaged")
	if health <= final_at:
		_final_shot()


# Stops, shakes, and fires a homing web that always kills.
func _final_shot() -> void:
	state = State.FINAL
	velocity = Vector2.ZERO
	sprite.play("damaged")
	Sound.play("boss_laugh")
	var tween := create_tween().set_loops(int(WIND_UP_TIME / 0.1))
	tween.tween_property(sprite, "position:x", 6.0, 0.05)
	tween.tween_property(sprite, "position:x", -6.0, 0.05)
	await tween.finished
	sprite.position.x = 0.0
	sprite.play("walk_" + facing)
	Sound.play("boss_roar")
	var aim := (target.global_position - global_position).normalized()
	_shoot(aim * FINAL_SHOT_SPEED, 5.0, true)
	state = State.DONE
