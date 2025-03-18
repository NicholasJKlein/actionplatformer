extends Control

# Handles the pause menu, which is only enabled with an input action in a game level.

# By default, the pause menu is not shown.
func _ready() -> void:
	self.hide()

# Unpause the game and hide the pause menu.
func resume():
	get_tree().paused = false
	self.hide()

# Pause the game and show the pause menu.
func pause():
	get_tree().paused = true
	self.show()

# Unpause the game.
func _on_resume_pressed() -> void:
	resume()

# Unpause the game, then switch scenes to the main menu.
func _on_main_menu_pressed() -> void:
	resume()
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

# Quit the application.
func _on_quit_pressed() -> void:
	get_tree().quit()

# Whenever the pause input is pressed, switch the paused status of the game.
func _process(_delta):
	if Input.is_action_just_pressed("Pause") and !get_tree().paused:
		pause()
	elif Input.is_action_just_pressed("Pause") and get_tree().paused:
		resume()
