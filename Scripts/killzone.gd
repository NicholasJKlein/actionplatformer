extends Area2D

# Defines an area that the player dies upon entering.
# Has no defined shape in its own scene, so it can be changed depending
# on what uses it.

@onready var timer: Timer = $Timer

# When then player enters the killzone, set their health to 0 and start their death.
func _on_body_entered(body: Node2D) -> void:
	timer.start()
	if body is Player:
		body.instant_kill()
		body.die()

# After a brief delay, reload the current level.
func _on_timer_timeout() -> void:
	get_tree().reload_current_scene()
