extends ProgressBar

@onready var player_damage: ProgressBar = $PlayerDamage
@onready var texture_rect: TextureRect = $PlayerDamage/TextureRect
@onready var timer: Timer = $Timer

signal move_damage
signal done_smoothing
signal done_healing

const increment : float = 26.8

func enlarge() -> void:
	size.x += increment
	texture_rect.size.x += increment

func lose_health(new_health: int) -> void:
	value = min(max_value, new_health)
	
	if value <= 0:
		queue_free()
	
	timer.start()

func set_health(new_health: int) -> void:
	max_value = new_health
	player_damage.max_value = new_health

func init_health(health: int) -> void:
	value = health
	max_value = health
	
	player_damage.max_value = health
	player_damage.value = health

func smooth_damage() -> void:
	if player_damage.value > value:
		player_damage.value -= 0.05
	else:
		done_smoothing.emit()
		
func smooth_heal(health: int) -> void:
	if value < health:
		value += 0.05
		player_damage.value += 0.05
	else:
		done_healing.emit()

func need_catchup() -> bool:
	return (player_damage.value < value)
	
func reset_damage() -> void:
	player_damage.value = max_value
	timer.start()
	
func _on_timer_timeout() -> void:
	move_damage.emit()
