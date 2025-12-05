extends CharacterBody2D

@export var health := 100

func _ready():
	$Hurtbox.area_entered.connect(_on_hurtbox_hit)

func _on_hurtbox_hit(area):
	if area.name == "Hitbox":
		health -= 10
		print("Enemigo golpeado! HP:", health)
		_react_hit()

func _react_hit():
	if $Sprite.sprite_frames.has_animation("hit"):
		$Sprite.play("hit")
