extends Control

# Handles the main menu of the game (which is the default start screen).

@onready var you_died_screen: AnimationPlayer = $YouDiedScreen/AnimationPlayer

# If the player is just booting up the game or quit to main menu, play the scene transition.
# If the player is coming from another menu, don't play the transition.
func _ready() -> void:
	if !GameManager.menuing:
		you_died_screen.get_parent().get_node("Reset").color.a = 255
		you_died_screen.play("ResumeLight")
		GameManager.menuing = true

# When the Play button is pressed, play scene transition, and switch to the game level scene.
func _on_play_game_pressed() -> void:
	you_died_screen.play("CoverUp")
	await you_died_screen.animation_finished
	GameManager.menuing = false
	get_tree().change_scene_to_file("res://Scenes/game.tscn")

# Switch scenes to the controls menu.
func _on_controls_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/controls_menu.tscn")

# Switch scenes to the options menu.
func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/options_menu.tscn")

# Quit the application.
func _on_quit_pressed() -> void:
	get_tree().quit()

# Switch scenes to the credits page
func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/credits.tscn")
