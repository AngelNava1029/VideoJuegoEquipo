extends CharacterBody2D

@export var speed: float = 300.0
@export var gravity: float = 1400.0
@export var attack_interval: float = 1.0
@export var jump_chance: float = 0.02
@export var jump_force: float = -800.0

@export var detection_range: float = 1000.0
@export var attack_range: float = 200.0

var direction := 1
var patrol_timer := 0.0
var attack_timer := 0.0

var is_attacking := false
var is_hit := false
var current_attack := ""

@onready var sprite := $AnimatedSprite2D
@onready var hitbox := $Hitbox
@onready var hurtbox := $Hurtbox

var player: Node2D = null

func _ready():
	player = get_tree().get_first_node_in_group("player")
	hitbox.monitoring = false
	hitbox.set_deferred("monitorable", true)

	hurtbox.area_entered.connect(_on_hurtbox_hit)


func _physics_process(delta):
	# --- SI ESTÁ EN HIT: bloquear todo excepto gravedad ---
	if is_hit:
		velocity.x = 0
		if not is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()
		return

	_try_jump(delta)

	if player:
		var dist = global_position.distance_to(player.global_position)

		if dist > detection_range:
			_patrol(delta)
		elif dist > attack_range:
			_chase(delta)
		else:
			_attack(delta)
	else:
		_patrol(delta)

	# Gravedad
	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()
	_update_animation()


# ------------------------------------------------------
# SALTO RARO
# ------------------------------------------------------
func _try_jump(delta):
	if is_on_floor() and randf() < jump_chance * delta:
		velocity.y = jump_force
		sprite.play("jump")


# ------------------------------------------------------
# PATRULLA
# ------------------------------------------------------
func _patrol(delta):
	if is_attacking:
		return
	patrol_timer += delta
	if patrol_timer >= 2.0:
		patrol_timer = 0.0
		direction *= -1
	velocity.x = direction * speed
	sprite.flip_h = (direction == -1)


# ------------------------------------------------------
# PERSEGUIR
# ------------------------------------------------------
func _chase(delta):
	if is_attacking:
		return
	direction = sign(player.global_position.x - global_position.x)
	velocity.x = direction * speed
	sprite.flip_h = (direction == -1)


# ------------------------------------------------------
# ATAQUE
# ------------------------------------------------------
func _attack(delta):
	attack_timer += delta
	velocity.x = 0

	if is_attacking:
		return

	if attack_timer >= attack_interval:
		attack_timer = 0.0

		var type := "punch" if randf() < 0.5 else "kick"
		_start_attack(type)


# ------------------------------------------------------
# ANIMACIONES
# ------------------------------------------------------
func _update_animation():
	# 1: Estado hit tiene máxima prioridad
	if is_hit:
		return

	# 2: Si está atacando, no cambiar animación
	if is_attacking:
		return

	# 3: Si no está en el piso, reproducir animación de salto
	if not is_on_floor():
		if sprite.animation != "jump":
			sprite.play("jump")
		return

	# 4: Movimiento en piso
	if abs(velocity.x) > 10:
		if sprite.animation != "walk":
			sprite.play("walk")
		return

	# 5: Idle por defecto
	if sprite.animation != "idle":
		sprite.play("idle")

# ------------------------------------------------------
# ATAQUE
# ------------------------------------------------------
func _start_attack(type: String):
	is_attacking = true
	sprite.play(type)

	hitbox.monitoring = true
	hitbox.position.x = 20 * direction

	await sprite.animation_finished

	hitbox.monitoring = false
	is_attacking = false


# ------------------------------------------------------
# RECIBIR DAÑO
# ------------------------------------------------------
func _on_hurtbox_hit(area):
	if area.name != "Hitbox":
		return

	take_damage(10)


func take_damage(amount: int):
	if is_hit:
		return

	is_hit = true
	is_attacking = false
	hitbox.monitoring = false

	# Animación hit SIEMPRE existe, si no, usa idle temporal
	if sprite.has_animation("hit"):
		sprite.play("hit")
	else:
		sprite.play("idle")

	# Esperar a que termine animación SOLO si existe
	if sprite.has_animation("hit"):
		await sprite.animation_finished
	else:
		await get_tree().create_timer(0.2).timeout

	is_hit = false
