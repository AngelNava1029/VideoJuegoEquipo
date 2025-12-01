extends CharacterBody2D

@export var speed: float = 350.0
@export var jump_force: float = -800.0
@export var gravity: float = 1400.0
@export var attack_damage: int = 10

var is_attacking: bool = false
var is_crouching: bool = false
var current_attack: String = ""
var direction: int = 1

func _ready() -> void:
	# Hitbox desactivado al inicio
	$Hitbox.monitoring = false
	$Hitbox.set_deferred("monitorable", true)

func _physics_process(delta: float) -> void:
	var input_x: float = 0.0
	is_crouching = Input.is_action_pressed("crouch")

	# --- MOVIMIENTO ---
	if not is_attacking and not is_crouching:
		if Input.is_action_pressed("move_left"):
			input_x -= 1
		if Input.is_action_pressed("move_right"):
			input_x += 1
		velocity.x = input_x * speed
	else:
		# Bloqueo lateral si está atacando o agachado
		velocity.x = 0

	# Voltear sprite según dirección
	if input_x != 0:
		direction = sign(input_x)
		$AnimatedSprite2D.flip_h = (direction == -1)

	# --- SALTO ---
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		velocity.y = jump_force

	# --- GRAVEDAD ---
	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()

	# --- ATAQUES ---
	if Input.is_action_just_pressed("punch"):
		_start_attack("punch")
	if Input.is_action_just_pressed("kick"):
		_start_attack("kick")

	# --- ANIMACIONES ---
	_update_animation(input_x)

# --- ANIMACIONES ---
func _update_animation(input_x: float) -> void:
	if is_attacking:
		return

	if not is_on_floor():
		if is_crouching:
			$AnimatedSprite2D.play("crouch")
		else:
			$AnimatedSprite2D.play("jump")
		return

	if is_crouching:
		$AnimatedSprite2D.play("crouch")
		return

	if input_x != 0:
		$AnimatedSprite2D.play("walk")
		return

	$AnimatedSprite2D.play("idle")

# --- ATAQUES ---
func _start_attack(type: String) -> void:
	if is_attacking:
		return

	is_attacking = true

	var anim: String = type
	if is_crouching and is_on_floor():
		anim = type + "_crouch"
	elif not is_on_floor():
		anim = type + "_air"

	current_attack = anim
	$AnimatedSprite2D.play(anim)
	$Hitbox.monitoring = true
	$Hitbox.position.x = 20 * direction

	# Esperar a que termine la animación
	await $AnimatedSprite2D.animation_finished

	$Hitbox.monitoring = false
	is_attacking = false
	current_attack = ""

func take_damage(amount: int) -> void:
	print("Player recibió daño: ", amount)
