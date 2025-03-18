extends Node2D

# Handles the game level, deals with currency and XP signals.

@onready var player: Player = $Player

# When the player is dead, reload the current level.
func _on_player_death() -> void:
	get_tree().reload_current_scene()

# Add XP to the player.
func add_XP(amount: int) -> void:
	player.receive_XP(amount)

# Add currency to the player.
func add_money(amount: int) -> void:
	player.add_currency(amount)

# When a slime enemy dies, give the player the corresponding loot.
func _on_slime_enemy_death(experience: int, currency: int) -> void:
	add_XP(experience)
	add_money(currency)

# When a boss slime enemy dies, give the player the corresponding loot.
func _on_boss_slime_enemy_death(experience: int, currency: int) -> void:
	add_XP(experience)
	add_money(currency)
