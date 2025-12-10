extends CharacterBody2D

@export var speed: float = 220.0
@export var gravity: float = 1400.0
@export var jump_force: float = -800.0

@export var attack_range_min: float = 90.0
@export var attack_range_max: float = 150.0
@export var attack_interval: float = 0.9
@export var jump_chance: float = 0.08   # SALTO REDUCIDO A 1/3

var attack_timer: float = 0.0
var direction: int = 1
var is_attacking: bool = false
var player: Node2D = null

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox


func _ready():
	player = get_tree().get_first_node_in_group("player")
	hitbox.monitoring = false
	hitbox.set_deferred("monitorable", true)


func _physics_process(delta):
	if player == null:
		return

	var dist := global_position.distance_to(player.global_position)

	_try_jump()

	_move_smart(dist)

	attack_timer += delta
	if dist <= attack_range_max and dist >= attack_range_min:
		if attack_timer >= attack_interval:
			attack_timer = 0.0
			_do_attack()

	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()
	_update_animation()


# -------------------- IA MOVIMIENTO --------------------

func _move_smart(dist: float) -> void:
	if is_attacking:
		velocity.x = 0
		return

	direction = sign(player.global_position.x - global_position.x)
	sprite.flip_h = direction < 0

	if dist > attack_range_max:
		velocity.x = direction * speed
	elif dist < attack_range_min:
		velocity.x = -direction * speed * 0.4
	else:
		velocity.x = direction * randf_range(-20, 20)


# -------------------- SALTO REDUCIDO --------------------

func _try_jump() -> void:
	if not is_on_floor():
		return

	# Saltará solo 1/3 de lo que hacía antes
	if randf() < jump_chance:
		velocity.y = jump_force
		sprite.play("jump")


# -------------------- ATAQUES --------------------

func _do_attack():
	if is_attacking or not is_on_floor():
		return

	is_attacking = true

	var attack = "punch"
	if randf() < 0.5:
		attack = "kick"

	sprite.play(attack)

	hitbox.monitoring = true
	hitbox.position.x = 20 * direction

	await sprite.animation_finished

	hitbox.monitoring = false
	is_attacking = false


# -------------------- ANIMACIONES --------------------

func _update_animation():
	if is_attacking:
		return

	if not is_on_floor():
		sprite.play("jump")
		return

	if abs(velocity.x) > 10:
		sprite.play("walk")
		return

	sprite.play("idle")


# -------------------- DAÑO RECIBIDO --------------------

func take_damage(amount: int) -> void:
	if sprite.has_animation("hit"):
		sprite.play("hit")
		await sprite.animation_finished
