extends ProgressBar

# Get references to necessary nodes
@onready var timer: Timer = $Timer
@onready var damage_bar: ProgressBar = $DamageBar
@onready var boss_name: Label = $BossName
@onready var damaged: Label = $Damaged

signal boss_move_damage
signal done_smoothing

var health = 0 : set = _set_health
var damaged_num : int = 0

# When created, set the label to the name of the boss,
# and set the maximum value of the health bar to the health of the boss.
func initialize(bossname: String, max_health : int):
	health = max_health
	boss_name.text = bossname
	
	# Instead of the floating damage numbers on normal enemies,
	# have a fixed damage counter on the right side of the bar.
	damaged.text = str(damaged_num)
	damaged.hide()
	
	# Set the values to the max
	value = health
	max_value = health
	damage_bar.max_value = health
	damage_bar.value = health

# Called when the boss loses health (or gains health, but that's not implemented in practice yet).
func _set_health(new_health):
	
	# Save the previous health, make sure health isn't over the maximum.
	var prev_health = health
	health = min(max_value, new_health)
	value = health
	
	# Remove node when boss has no health.
	if health <= 0 and damage_bar.value <= 0:
		queue_free()
	
	# Handle the value of the damage label.
	# If still visible when taking more damage, increase the value.
	if health < prev_health:
		damaged.show()
		damaged_num += prev_health - health
		damaged.text = str(damaged_num)
		timer.start()
	else:
		damage_bar.value = health

# Smoothly decrease the damage bar (white) behind the health bar (green).
# Once the damage bar catches up to the health bar, hide and reset the
# damage number label.
func smooth_damage() -> void:
	if damage_bar.value > health:
		damage_bar.value -= 0.1
	else:
		damaged.hide()
		damaged_num = 0
		damaged.text = str(damaged_num)
		done_smoothing.emit()

# When timer runs out, send out signal to start smoothing damage.
func _on_timer_timeout() -> void:
	boss_move_damage.emit()
