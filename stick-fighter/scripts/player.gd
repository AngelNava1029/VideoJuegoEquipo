extends CharacterBody2D

@export var speed: float = 450.0
@export var jump_force: float = -800.0
@export var gravity: float = 1400.0
@export var attack_damage: int = 10

@export var max_health: int = 100
var health: int

var is_attacking: bool = false
var is_crouching: bool = false
var is_stunned: bool = false
var is_dead: bool = false
var current_attack: String = ""
var direction: int = 1

var already_hit := []

func _ready():
	health = max_health
	add_to_group("player")

	$Hitbox.monitoring = false
	$Hitbox.set_deferred("monitorable", true)

	_update_health_bar()

func _physics_process(delta):
	if is_dead:
		return
	
	var input_x := 0.0
	is_crouching = Input.is_action_pressed("crouch")

	if not is_attacking and not is_crouching and not is_stunned:
		if Input.is_action_pressed("move_left"):
			input_x -= 1
		if Input.is_action_pressed("move_right"):
			input_x += 1
		velocity.x = input_x * speed
	else:
		velocity.x = 0

	if input_x != 0:
		direction = sign(input_x)
		$AnimatedSprite2D.flip_h = (direction == -1)

	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching and not is_stunned:
		velocity.y = jump_force

	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()

	if Input.is_action_just_pressed("punch") and not is_stunned:
		_start_attack("punch")

	if Input.is_action_just_pressed("kick") and not is_stunned:
		_start_attack("kick")

	_update_animation(input_x)

func _update_animation(input_x: float):
	if is_dead:
		return
	if is_stunned:
		$AnimatedSprite2D.play("hit")
		return
	if is_attacking:
		return

	if not is_on_floor():
		$AnimatedSprite2D.play("jump")
		return

	if is_crouching:
		$AnimatedSprite2D.play("crouch")
		return

	if input_x != 0:
		$AnimatedSprite2D.play("walk")
		return

	$AnimatedSprite2D.play("idle")

func _start_attack(type: String):
	if is_attacking:
		return

	is_attacking = true
	already_hit.clear()

	var anim := type
	if is_crouching and is_on_floor():
		anim = type + "_crouch"
	elif not is_on_floor():
		anim = type + "_air"

	current_attack = anim
	$AnimatedSprite2D.play(anim)

	if type == "punch":
		$Punch.play()
	if type == "kick":
		$Kick.play()

	$Hitbox.position.x = 25 * direction
	$Hitbox.monitoring = true

	await get_tree().create_timer(0.10).timeout
	_check_hitbox_hits()

	await get_tree().create_timer(0.20).timeout
	$Hitbox.monitoring = false

	is_attacking = false
	current_attack = ""

func _check_hitbox_hits():
	for b in $Hitbox.get_overlapping_bodies():
		if b and b.is_in_group("enemigo") and b.has_method("take_damage") and not b in already_hit:
			b.take_damage(attack_damage, direction)
			already_hit.append(b)

# -----------------------------------
#        DAÑO + HIT + PUSHBACK
# -----------------------------------

func take_damage(amount: int, from_dir: int):
	if is_dead:
		return

	health -= amount
	_update_health_bar()

	is_stunned = true
	$AnimatedSprite2D.play("hit")

	velocity.x = 300 * -from_dir
	velocity.y = -200

	await get_tree().create_timer(0.25).timeout
	is_stunned = false

	if health <= 0:
		_die()

func _die():
	is_dead = true
	velocity = Vector2.ZERO
	$AnimatedSprite2D.play("lose")
	set_physics_process(false)

# -----------------------------------
#           WIN + CAMBIO NIVEL
# -----------------------------------

func play_win():
	is_dead = true
	velocity = Vector2.ZERO
	$AnimatedSprite2D.play("win")
	set_physics_process(false)

	# Esperar 3 segundos y cambiar de escena
	await get_tree().create_timer(3).timeout
	get_tree().change_scene_to_file("res://scenes/Stage_Arena.tscn")

func _update_health_bar():
	$CanvasLayer/HealthBar.value = health
