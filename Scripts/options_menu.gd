extends Control

# Makes sure the slider values are applied to the actual audio values.

@onready var master_slide: HSlider = $Audio/VBoxContainer/MasterSlide
@onready var music_slide: HSlider = $Audio/VBoxContainer/MusicSlide
@onready var sfx_slide: HSlider = $Audio/VBoxContainer/SFXSlide

# Set the Audio bus volumes to match those the player chose.
func _on_apply_button_pressed() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(master_slide.value))
	AudioServer.set_bus_volume_db(1, linear_to_db(music_slide.value))
	AudioServer.set_bus_volume_db(2, linear_to_db(sfx_slide.value))

# Switch scenes to the main menu.
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
