extends Node2D

@onready var player: Player = $Player

func _on_player_death() -> void:
	get_tree().reload_current_scene()

func add_XP(amount: int) -> void:
	player.receive_XP(amount)

func add_money(amount: int) -> void:
	player.add_currency(amount)
	
func _on_slime_enemy_death(experience: int, currency: int) -> void:
	add_XP(experience)
	add_money(currency)
	
func _on_boss_slime_enemy_death(experience: int, currency: int) -> void:
	print(experience)
	print(currency)
	add_XP(experience)
	add_money(currency)
