extends CharacterBody2D

@export var speed: float = 300.0
@export var gravity: float = 1400.0
@export var attack_damage: int = 10

# IA
@export var patrol_time: float = 2.0
@export var detection_range: float = 1000.0     # distancia para detectar al jugador
@export var attack_range: float = 200.0         # distancia para atacar
@export var attack_interval: float = 1.0       # cada cuánto puede atacar

var direction: int = 1
var patrol_timer: float = 0.0
var attack_timer: float = 0.0

var is_attacking: bool = false
var current_attack: String = ""

var player: Node2D = null


func _ready() -> void:
	# Busca al jugador en la escena
	player = get_tree().get_first_node_in_group("player")

	$Hitbox.monitoring = false
	$Hitbox.set_deferred("monitorable", true)


func _physics_process(delta: float) -> void:

	if player == null:
		_patrol(delta)
	else:
		var dist = global_position.distance_to(player.global_position)

		if dist > detection_range:
			_patrol(delta)
		elif dist > attack_range:
			_chase_player(delta)
		else:
			_attack_player(delta)

	# Gravedad
	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()

	_update_animation()


# ------------------------------------------------------
#                  IA: PATRULLA
# ------------------------------------------------------
func _patrol(delta: float) -> void:
	if is_attacking:
		velocity.x = 0
		return

	patrol_timer += delta
	if patrol_timer >= patrol_time:
		patrol_timer = 0.0
		direction *= -1

	velocity.x = direction * speed
	$AnimatedSprite2D.flip_h = (direction == -1)


# ------------------------------------------------------
#                  IA: PERSEGUIR
# ------------------------------------------------------
func _chase_player(delta: float) -> void:
	if is_attacking:
		velocity.x = 0
		return

	direction = sign(player.global_position.x - global_position.x)
	velocity.x = direction * speed

	$AnimatedSprite2D.flip_h = (direction == -1)


# ------------------------------------------------------
#                  IA: ATAQUE
# ------------------------------------------------------
func _attack_player(delta: float) -> void:
	attack_timer += delta
	velocity.x = 0

	if is_attacking:
		return

	if attack_timer >= attack_interval:
		attack_timer = 0.0

		# Elegir ataque
		var type := "punch" if randf() < 0.5 else "kick"
		_start_attack(type)


# ------------------------------------------------------
#                  ANIMACIONES
# ------------------------------------------------------
func _update_animation() -> void:
	if is_attacking:
		return

	if not is_on_floor():
		$AnimatedSprite2D.play("jump")
		return

	if abs(velocity.x) > 10:
		$AnimatedSprite2D.play("walk")
		return

	$AnimatedSprite2D.play("idle")


# ------------------------------------------------------
#                SISTEMA DE ATAQUES
# ------------------------------------------------------
func _start_attack(type: String) -> void:
	if is_attacking:
		return

	is_attacking = true
	current_attack = type

	$AnimatedSprite2D.play(type)

	# activar hitbox al frente
	$Hitbox.monitoring = true
	$Hitbox.position.x = 20 * direction

	await $AnimatedSprite2D.animation_finished

	$Hitbox.monitoring = false
	is_attacking = false
	current_attack = ""


# ------------------------------------------------------
#                   DAÑO RECIBIDO
# ------------------------------------------------------
func take_damage(amount: int) -> void:
	print("Enemigo recibió daño: ", amount)
