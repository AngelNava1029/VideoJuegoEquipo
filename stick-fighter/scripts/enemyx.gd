extends CharacterBody2D

@export var speed: float = 250.0
@export var gravity: float = 1400.0
@export var attack_damage: int = 10

@export var detection_range: float = 600.0
@export var attack_range: float = 160.0
@export var attack_interval: float = 1.0

var direction: int = 1
var attack_timer: float = 0.0
var is_attacking: bool = false
var is_hit: bool = false
var hit_recover: float = 0.0
var player: Node2D = null


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	$Hitbox.monitoring = false
	$Hitbox.set_deferred("monitorable", true)


func _physics_process(delta: float) -> void:
	if player == null:
		return

	# Gravedad general
	velocity.y += gravity * delta

	# ------------------------
	#     ESTADO DE HIT
	# ------------------------
	if is_hit:
		move_and_slide()

		# Ahora sí la física ya actualizó is_on_floor()
		if is_on_floor():
			is_hit = false
			$AnimatedSprite2D.play("idle")
		else:
			$AnimatedSprite2D.play("jump")

		return

	# ------------------------
	#     DISTANCIA A PLAYER
	# ------------------------
	var dist: float = global_position.distance_to(player.global_position)
	print("DIST:", dist, "  RANGE:", attack_range)

	# ------------------------
	#     IA
	# ------------------------
	if dist > detection_range:
		velocity.x = 0
	elif dist > attack_range:
		_chase()
	else:
		_attack(delta)

	move_and_slide()
	_update_animation()


# ------------------------
#     PERSEGUIR
# ------------------------
func _chase() -> void:
	if is_attacking:
		velocity.x = 0
		return

	direction = sign(player.global_position.x - global_position.x)
	velocity.x = speed * direction
	$AnimatedSprite2D.flip_h = (direction == -1)


# ------------------------
#        ATAQUE
# ------------------------
func _attack(delta: float) -> void:
	velocity.x = 0
	attack_timer += delta

	if is_attacking:
		return

	if attack_timer >= attack_interval:
		attack_timer = 0.0

		var type: String = "punch"
		if randi() % 2 == 0:
			type = "kick"

		_start_attack(type)


# ------------------------
#     INICIAR ATAQUE
# ------------------------
func _start_attack(type: String) -> void:
	is_attacking = true

	$AnimatedSprite2D.play(type)
	$Hitbox.monitoring = true
	$Hitbox.position.x = 20 * direction

	await $AnimatedSprite2D.animation_finished

	$Hitbox.monitoring = false
	is_attacking = false


# ------------------------
#      ANIMACIONES
# ------------------------
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


# ------------------------
#      DAÑO RECIBIDO
# ------------------------
func take_damage(amount: int, attacker: Node2D) -> void:
	print("Enemy recibió daño:", amount)

	is_hit = true
	hit_recover = 0.25

	$AnimatedSprite2D.play("hit")

	var dir: int = sign(global_position.x - attacker.global_position.x)
	velocity.x = dir * 200
	velocity.y = -300
