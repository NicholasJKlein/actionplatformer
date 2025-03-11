extends ProgressBar

@onready var timer: Timer = $Timer
@onready var damage_bar: ProgressBar = $DamageBar

signal move_damage
signal done_smoothing

var health = 0 : set = _set_health

func _set_health(new_health):
	var prev_health = health
	health = min(max_value, new_health)
	value = health
	
	if health <= 0 and damage_bar.value <= 0:
		queue_free()
	
	if health < prev_health:
		timer.start()
	else:
		damage_bar.value = health

func init_health(_health):
	health = _health
	max_value = health
	value = health
	
	damage_bar.max_value = health
	damage_bar.value = health

func smooth_damage() -> void:
	if damage_bar.value > health:
		damage_bar.value -= 0.1
	else:
		done_smoothing.emit()

func _on_timer_timeout() -> void:
	move_damage.emit()

func zero_damage() -> void:
	damage_bar.value = 0
