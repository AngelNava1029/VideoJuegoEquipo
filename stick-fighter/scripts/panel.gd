extends Panel

func _on_button_pressed():
	print("BOTON PRESIONADO")
	get_tree().paused = false
	get_tree().change_scene_to_file(get_tree().current_scene.scene_file_path)


func _on_button_2_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/credits.tscn")
