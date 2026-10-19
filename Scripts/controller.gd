class_name Player
extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const KNIFE_DAMAGE = 1
const KNIFE_REACH = 80.0
# Frame of the attack animation where the knife actually connects.
const STRIKE_FRAME = 2
const MAX_HEALTH = 5
# Seconds of invulnerability after being hit.
const HURT_COOLDOWN = 1.0
const KNOCKBACK_SPEED = 600.0
const KNOCKBACK_TIME = 0.15

# Set by picking up the knife in the kitchen. Static so it carries over
# between rooms, since each room has its own copy of the player.
static var has_knife := false
# Static for the same reason. Read by the HUD.
static var health := MAX_HEALTH

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var knife_hitbox: Area2D = $KnifeHitbox

var facing := "down"
var attacking := false
# Turned off by cutscenes.
var can_move := true
var hurt_timer := 0.0
var knockback := Vector2.ZERO
var knockback_timer := 0.0


func _ready() -> void:
	# Enemies without an explicit target look the player up by this group.
	add_to_group("player")
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.frame_changed.connect(_on_frame_changed)


func _physics_process(delta: float) -> void:
	if hurt_timer > 0.0:
		hurt_timer -= delta
		# Blink while invulnerable.
		sprite.visible = hurt_timer <= 0.0 or int(hurt_timer * 15.0) % 2 == 0

	if knockback_timer > 0.0:
		knockback_timer -= delta
		velocity = knockback
		move_and_slide()
		if knockback_timer <= 0.0:
			update_animation(0, 0)
		return

	if Dialogue.is_busy() or not can_move:
		attacking = false
		velocity = Vector2.ZERO
		move_and_slide()
		update_animation(0, 0)
		return

	if attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if has_knife and Input.is_action_just_pressed("Attack"):
		attack()
		return

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var directionX := Input.get_axis("ui_left", "ui_right")
	var directionY := Input.get_axis("ui_up", "ui_down")
	if directionX:
		velocity.x = directionX * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	if directionY:
		velocity.y = directionY * SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED)

	move_and_slide()
	update_animation(directionX, directionY)


func update_animation(directionX: float, directionY: float) -> void:
	# Horizontal wins on diagonals so the side-walk shows when moving at an angle.
	if directionX:
		facing = "right" if directionX > 0 else "left"
	elif directionY:
		facing = "down" if directionY > 0 else "up"

	Sound.footsteps(directionX != 0 or directionY != 0)
	var prefix := "knife_" if has_knife else ""
	if directionX or directionY:
		sprite.play(prefix + "walk_" + facing)
	else:
		sprite.play(prefix + "idle_" + facing)


func attack() -> void:
	attacking = true
	Sound.footsteps(false)
	velocity = Vector2.ZERO
	knife_hitbox.position = facing_vector() * KNIFE_REACH
	sprite.play("attack_" + facing)


func facing_vector() -> Vector2:
	match facing:
		"up": return Vector2.UP
		"left": return Vector2.LEFT
		"right": return Vector2.RIGHT
	return Vector2.DOWN


func _on_frame_changed() -> void:
	if attacking and sprite.frame == STRIKE_FRAME:
		hit_targets()


# Anything in the hitbox with a take_damage(amount, from_position) method gets hit.
func hit_targets() -> void:
	var targets: Array = []
	targets.append_array(knife_hitbox.get_overlapping_bodies())
	targets.append_array(knife_hitbox.get_overlapping_areas())
	for target in targets:
		if target == self:
			continue
		if target.has_method("take_damage"):
			target.take_damage(KNIFE_DAMAGE, global_position)


func take_damage(amount: int, from_position: Vector2) -> void:
	if hurt_timer > 0.0 or health <= 0:
		return
	health -= amount
	Sound.play("hurt", 0.05)
	if health <= 0:
		die()
		return
	hurt_timer = HURT_COOLDOWN
	attacking = false
	var away := global_position - from_position
	knockback = away.normalized() * KNOCKBACK_SPEED if away != Vector2.ZERO else Vector2.ZERO
	knockback_timer = KNOCKBACK_TIME
	sprite.modulate = Color(1, 0.4, 0.4)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.3)


# Dies no matter what, even while invulnerable. Used by the boss's last shot.
func kill() -> void:
	if health <= 0:
		return
	health = 0
	Sound.play("hurt")
	sprite.modulate = Color(1, 0.3, 0.3)
	die()


# Dying ends the day. The next one starts back in bed.
func die() -> void:
	can_move = false
	Day.end_day()


func _on_animation_finished() -> void:
	if attacking:
		attacking = false
		update_animation(0, 0)
