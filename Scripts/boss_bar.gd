extends ProgressBar

@onready var timer: Timer = $Timer
@onready var damage_bar: ProgressBar = $DamageBar
@onready var boss_name: Label = $BossName
@onready var damaged: Label = $Damaged

signal boss_move_damage
signal done_smoothing

var health = 0 : set = _set_health
var damaged_num : int = 0

func initialize(bossname: String, max_health : int):
	health = max_health
	boss_name.text = bossname
	
	damaged.text = str(damaged_num)
	damaged.hide()
	
	value = health
	max_value = health
	damage_bar.max_value = health
	damage_bar.value = health

func _set_health(new_health):
	var prev_health = health
	health = min(max_value, new_health)
	value = health
	
	if health <= 0 and damage_bar.value <= 0:
		queue_free()
	
	if health < prev_health:
		damaged.show()
		damaged_num += prev_health - health
		damaged.text = str(damaged_num)
		timer.start()
	else:
		damage_bar.value = health

func smooth_damage() -> void:
	if damage_bar.value > health:
		damage_bar.value -= 0.1
	else:
		damaged.hide()
		damaged_num = 0
		damaged.text = str(damaged_num)
		done_smoothing.emit()

func _on_timer_timeout() -> void:
	boss_move_damage.emit()
