extends CharacterBody2D

@export var speed: float = 500.0
@export var jump_force: float = 550.0
@export var gravity: float = 1000.0

@onready var anim: AnimationPlayer = $AnimationPlayer

var was_running := false

func _physics_process(delta: float) -> void:
	var input_vector = Vector2.ZERO

	# Movimiento izquierda / derecha
	if Input.is_action_pressed("ui_left"):
		input_vector.x = -1
	elif Input.is_action_pressed("ui_right"):
		input_vector.x = 1
	was_running = input_vector.x != 0

	velocity.x = input_vector.x * speed

	# Gravedad
	if not is_on_floor():
		velocity.y += gravity * delta

	# Saltar
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = -jump_force

	# --- REPRODUCIR ANIMACIÓN DE GOLPE UNA SOLA VEZ ---
	if Input.is_action_just_pressed("attack_w"):
		anim.play("punch")
		move_and_slide()
		return  # No sobrescribir el punch este frame

	# Mover
	move_and_slide()

	# --- NO interrumpir punch mientras se reproduce ---
	if anim.current_animation == "punch" and anim.is_playing():
		return

	# --- Cuando punch termina, volver a idle o run ---
	if was_running:
		anim.play("run")
	else:
		anim.play("idle")
