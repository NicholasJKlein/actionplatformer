extends TextureProgressBar

# UI that handles the player's XP, appears as a blue bar in the top middle of the screen.

@onready var label: Label = $Label
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var timer: Timer = $Timer

signal level_noti

# Initial settings for player state.
var level : int = 1
var remaining : int = 0
var updating : bool = false
var level_to_go : int = 0

# Should not be visible by default.
func _ready() -> void:
	animation_player.play("Hide")

# Initialize the values corresponding to player XP.
func initialize(current: int, maximum: int, curr_level: int) -> void:
	value = current
	max_value = maximum
	level = curr_level


func _physics_process(_delta: float) -> void:
	
	# If the UI is becoming more or less transparent (hiding or showing),
	# wait to update the values
	if animation_player.is_playing():
		return
	
	# If the number displayed is less than the actual amount of currency
	# the player has, tick up the display by 1 per physics frame (60 per second).
	if remaining > 0:
		add_to_XP()
	
	# If the number finished going up, start the timer to hide the UI.
	elif timer.is_stopped() and updating:
		timer.start()
	
	update_text()

# Update the amount of XP left to give to the player, and show the UI.
func set_remaining(new_value: int) -> void:
	remaining += new_value
	updating = true
	timer.start()
	animation_player.play("XPShow")

# Increases the XP displayed in the UI.
func add_to_XP() -> void:
	timer.start()
	value += 1
	remaining -= 1
	
	# If the player's XP matches the max, they have leveled up.
	# Upon level up, reset the value of the XP bar and recalculate the max XP.
	if value == max_value:
		if level_to_go > 0:
			level_to_go -= 1
			level_noti.emit()
		value = 0
		level += 1
		max_value = round(pow(level + 1, 1.6) + ((level + 1) * 3) + 11)

# Update the labels.
func update_text() -> void:
	label.text = (str(value) + " / " + str(max_value))

# After the labels are done updating, hide the UI.
func _on_timer_timeout() -> void:
	animation_player.play("XPHide")
	updating = false

# Increases the counter for how many level ups occurred.
func adding_level() -> void:
	level_to_go += 1
