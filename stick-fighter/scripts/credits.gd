extends Control

@export var scroll_speed: float = 50.0 # Pixels por segundo

var start_position: Vector2

func _ready():
	# Guardamos la posición inicial
	start_position = $VBoxContainer.position
	# Opcional: reiniciar por si la escena se recarga
	$VBoxContainer.position = start_position

func _process(delta):
	# Mover hacia arriba
	$VBoxContainer.position.y -= scroll_speed * delta
	
	# Cuando salga completamente de la pantalla, puedes cambiar de escena si quieres
	if $VBoxContainer.position.y + $VBoxContainer.size.y < 0:
		get_tree().change_scene_to_file("res://scenes/Menu.tscn")  # Cambia la ruta si deseas
