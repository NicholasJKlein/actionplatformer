extends Control

# Get references to relevant nodes.
@onready var label: Label = $Label
@onready var plus: Label = $Plus
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var timer: Timer = $Timer

# Set the variables to their initial states.
var display : int = 0
var currency : int = 0
var gained : int = 0
var updating : bool = false

# Set the starting values.
func initialize(got_currency: int) -> void:
	display = got_currency
	currency = got_currency

# Handle the number displayed on the currency counter, making sure it's constantly updated.
func _physics_process(_delta: float) -> void:
	
	# If the UI is becoming more or less transparent (hiding or showing),
	# wait to update the values
	if animation_player.is_playing():
		return
	
	# If the number displayed is less than the actual amount of currency
	# the player has, tick up the display by 1 per physics frame (60 per second).
	if display < currency:
		display += 1
		gained += 1
		timer.start()
	
	# If the number finished going up, start the timer to hide the UI.
	elif timer.is_stopped() and updating:
		timer.start()
	
	# Update the number the counter displays.
	label.text = str(display)
	
	# Update the number under the total counter, which shows how much currency
	# the player has gained since recently.
	plus.text = str("+" + str(gained))

# Set the total currency to a new amount.
# Show the UI and begin updating.
func set_currency(new_value: int) -> void:
	currency = new_value
	updating = true
	timer.start()
	animation_player.play("ShowMoney")

# One second after the counter is done updating, hide the UI and reset
# the recently gained value.
func _on_timer_timeout() -> void:
	animation_player.play("HideMoney")
	updating = false
	await animation_player.animation_finished
	gained = 0
