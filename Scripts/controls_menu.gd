extends Control

# When the back button is pressed, go back to main menu.
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
