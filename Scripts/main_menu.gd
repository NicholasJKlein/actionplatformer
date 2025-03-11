extends Control

@onready var you_died_screen: AnimationPlayer = $YouDiedScreen/AnimationPlayer

func _ready() -> void:
	if !GameManager.menuing:
		you_died_screen.get_parent().get_node("Reset").color.a = 255
		you_died_screen.play("ResumeLight")
		GameManager.menuing = true

func _on_play_game_pressed() -> void:
	you_died_screen.play("CoverUp")
	await you_died_screen.animation_finished
	GameManager.menuing = false
	get_tree().change_scene_to_file("res://Scenes/game.tscn")

func _on_controls_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/controls_menu.tscn")
	
func _on_options_pressed() -> void:
	pass # Replace with function body.

func _on_quit_pressed() -> void:
	get_tree().quit()
