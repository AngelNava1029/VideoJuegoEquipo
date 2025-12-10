extends Node

const MAIN_SCENE := "res://scenes/Main.tscn"

@onready var press_label: Label = $PressLabel

var visible_time := 0.5   # tiempo visible
var hidden_time := 0.5    # tiempo oculto
var timer := 0.0

func _ready():
	set_process_input(true)


func _process(delta):
	# Animación de parpadeo
	timer += delta
	
	if press_label.visible and timer >= visible_time:
		press_label.visible = false
		timer = 0.0
	elif not press_label.visible and timer >= hidden_time:
		press_label.visible = true
		timer = 0.0


func _input(event):
	# Cambiar a la escena principal cuando presionas cualquier botón
	if event.is_pressed() and not event.is_echo():
		get_tree().change_scene_to_file(MAIN_SCENE)
