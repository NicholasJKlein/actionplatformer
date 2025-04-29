extends Control

# Handles the win screen, which is jumped to after beating the level

func _on_texture_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
