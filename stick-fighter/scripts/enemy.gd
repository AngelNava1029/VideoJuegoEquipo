extends CharacterBody2D

@export var speed := 300.0
@export var gravity := 1400.0
@export var attack_damage := 10

@export var patrol_time := 2.0
@export var detection_range := 1000.0
@export var attack_range := 200.0
@export var attack_interval := 1.0

@export var max_health := 100
var health := 100

var direction := 1
var patrol_timer := 0.0
var attack_timer := 0.0

var is_attacking := false
var is_stunned := false
var is_dead := false
var current_attack := ""

var player: CharacterBody2D = null

func _ready():
	health = max_health
	add_to_group("enemigo")

	player = get_tree().get_first_node_in_group("player")

	$Hitbox.monitoring = false
	$Hitbox.set_deferred("monitorable", true)

	_update_health_bar()

func _physics_process(delta):
	if is_dead:
		return

	if player == null:
		_patrol(delta)
	else:
		var dist := global_position.distance_to(player.global_position)

		if dist > detection_range:
			_patrol(delta)
		elif dist > attack_range:
			_chase_player(delta)
		else:
			_attack_player(delta)

	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()
	_update_animation()

func _patrol(delta):
	if is_attacking or is_stunned:
		velocity.x = 0
		return

	patrol_timer += delta
	if patrol_timer >= patrol_time:
		patrol_timer = 0
		direction *= -1

	velocity.x = direction * speed
	$AnimatedSprite2D.flip_h = (direction == -1)

func _chase_player(delta):
	if is_attacking or is_stunned:
		velocity.x = 0
		return

	direction = sign(player.global_position.x - global_position.x)
	velocity.x = direction * speed
	$AnimatedSprite2D.flip_h = (direction == -1)

func _attack_player(delta):
	attack_timer += delta
	velocity.x = 0

	if is_attacking or is_stunned:
		return

	if attack_timer >= attack_interval:
		attack_timer = 0
		_start_attack("punch" if randf() < 0.5 else "kick")

func _start_attack(type):
	if is_attacking:
		return

	is_attacking = true
	current_attack = type

	$AnimatedSprite2D.play(type)
	$Hitbox.position.x = 25 * direction
	$Hitbox.monitoring = true

	await get_tree().create_timer(0.10).timeout
	_try_hit_player()

	# ⭐ NUEVO: esperar a que termine la animación real
	await $AnimatedSprite2D.animation_finished

	$Hitbox.monitoring = false
	is_attacking = false
	current_attack = ""

func _try_hit_player():
	if player and global_position.distance_to(player.global_position) <= attack_range:
		if player.has_method("take_damage"):
			player.take_damage(attack_damage, direction)

			if player.health <= 0:
				play_win()

func take_damage(amount: int, from_dir: int):
	if is_dead:
		return

	health -= amount
	_update_health_bar()

	# --- FIX: cancelar ataque si estaba golpeando ---
	is_attacking = false
	current_attack = ""
	$Hitbox.monitoring = false

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

	if player:
		player.play_win()

func play_win():
	is_dead = true
	is_attacking = false
	is_stunned = false
	velocity = Vector2.ZERO
	$AnimatedSprite2D.play("win")
	set_physics_process(false)

func _update_animation():
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
	if abs(velocity.x) > 10:
		$AnimatedSprite2D.play("walk")
		return
	$AnimatedSprite2D.play("idle")

func _update_health_bar():
	$CanvasLayer/HealthBar.value = health
