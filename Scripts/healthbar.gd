extends ProgressBar

# Get references to relevant nodes.
@onready var timer: Timer = $Timer
@onready var damage_bar: ProgressBar = $DamageBar

signal move_damage
signal done_smoothing

# Health is 0 to start.
var health = 0 : set = _set_health

# Set the health to a new value.
func _set_health(new_health):
	
	# Keep track of the previous health.
	var prev_health = health
	
	# Make sure health doesn't go over the max.
	health = min(max_value, new_health)
	value = health
	
	# If the enemy is dead and the damage bar is caught up, remove node.
	if health <= 0 and damage_bar.value <= 0:
		queue_free()
	
	# If the enemy lost health, start the countdown for moving the damage bar.
	if health < prev_health:
		timer.start()
	else:
		damage_bar.value = health

# Initialize the health to a given maximum value
func init_health(_health):
	health = _health
	max_value = health
	value = health
	
	# Make sure the damage bar is also at the maximum.
	damage_bar.max_value = health
	damage_bar.value = health

# Decreases the damage bar value by a very small amount.
# This function is called within the physics process function of the enemy,
# so it will smoothly go down over a short period of time.
func smooth_damage() -> void:
	if damage_bar.value > health:
		damage_bar.value -= 0.1
	else:
		done_smoothing.emit()

# Signal to start smoothing the damage.
func _on_timer_timeout() -> void:
	move_damage.emit()

# Set the damage value (white bar) to 0.
func zero_damage() -> void:
	damage_bar.value = 0
