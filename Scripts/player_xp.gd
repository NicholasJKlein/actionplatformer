extends TextureProgressBar

@onready var label: Label = $Label
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var timer: Timer = $Timer

signal level_noti

var level : int = 1
var remaining : int = 0
var updating : bool = false
var level_to_go : int = 0

func _ready() -> void:
	animation_player.play("Hide")

func initialize(current: int, maximum: int, curr_level: int) -> void:
	value = current
	max_value = maximum
	level = curr_level
	
func _physics_process(_delta: float) -> void:
	if animation_player.is_playing():
		return
	if remaining > 0:
		add_to_XP()
	elif timer.is_stopped() and updating:
		timer.start()
	update_text()
	
func set_remaining(new_value: int) -> void:
	remaining += new_value
	updating = true
	timer.start()
	animation_player.play("XPShow")

func add_to_XP() -> void:
	timer.start()
	value += 1
	remaining -= 1
	if value == max_value:
		if level_to_go > 0:
			level_to_go -= 1
			level_noti.emit()
		value = 0
		level += 1
		max_value = round(pow(level + 1, 1.6) + ((level + 1) * 3) + 11)
	
func update_text() -> void:
	label.text = (str(value) + " / " + str(max_value))

func _on_timer_timeout() -> void:
	animation_player.play("XPHide")
	updating = false
	
func adding_level() -> void:
	level_to_go += 1
