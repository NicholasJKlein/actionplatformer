extends Control

func _ready() -> void:
	self.hide()

func resume():
	get_tree().paused = false
	self.hide()
	
func pause():
	get_tree().paused = true
	self.show()

func _on_resume_pressed() -> void:
	resume()
		
func _on_main_menu_pressed() -> void:
	resume()
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
	
func _process(_delta):
	if Input.is_action_just_pressed("Pause") and !get_tree().paused:
		pause()
	elif Input.is_action_just_pressed("Pause") and get_tree().paused:
		resume()
