extends ProgressBar

# Handles the UI for the player's health bar.

@onready var player_damage: ProgressBar = $PlayerDamage
@onready var texture_rect: TextureRect = $PlayerDamage/TextureRect
@onready var timer: Timer = $Timer

signal move_damage
signal done_smoothing
signal done_healing

const increment : float = 26.8

# Upon the player leveling up, the size of the bar will increase by this horizontally.
func enlarge() -> void:
	size.x += increment
	texture_rect.size.x += increment

# Upon the player losing health, set the value of the health bar (red) to the new value.
func lose_health(new_health: int) -> void:
	value = min(max_value, new_health)
	
	# If the player is dead, remove the UI from the screen.
	if value <= 0:
		queue_free()
	
	timer.start()

# Set the max health of the player to a new value.
# Also called upon leveling up.
func set_health(new_health: int) -> void:
	max_value = new_health
	player_damage.max_value = new_health

# Initialize the health and damage bars to their maximum.
func init_health(health: int) -> void:
	value = health
	max_value = health
	
	player_damage.max_value = health
	player_damage.value = health

# Decreases the damage bar value by a very small amount.
# This function is called within the physics process function of the player,
# so it will smoothly go down over a short period of time.
func smooth_damage() -> void:
	if player_damage.value > value:
		player_damage.value -= 0.05
	else:
		done_smoothing.emit()

# Increases the health and damage bar values by a very small amount.
# This function is called within the physics process function of the player,
# so it will smoothly go up over a short period of time.
# Currently only called upon leveling up, which restores the player health to its new max.
func smooth_heal(health: int) -> void:
	if value < health:
		value += 0.05
		player_damage.value += 0.05
	else:
		done_healing.emit()

# Returns whether the player damage bar needs to catch up to the health bar.
func need_catchup() -> bool:
	return (player_damage.value < value)

# Resets the damage bar value to the max.
func reset_damage() -> void:
	player_damage.value = max_value
	timer.start()

# Signal to start moving the damage bar.
func _on_timer_timeout() -> void:
	move_damage.emit()
