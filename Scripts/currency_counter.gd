extends Control

@onready var label: Label = $Label
@onready var plus: Label = $Plus
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var timer: Timer = $Timer

var display : int = 0
var currency : int = 0
var gained : int = 0
var updating : bool = false

func initialize(got_currency: int) -> void:
	display = got_currency
	currency = got_currency
	
func _physics_process(_delta: float) -> void:
	if animation_player.is_playing():
		return
	if display < currency:
		display += 1
		gained += 1
		timer.start()
	elif timer.is_stopped() and updating:
		timer.start()
	label.text = str(display)
	plus.text = str("+" + str(gained))
	
func set_currency(new_value: int) -> void:
	currency = new_value
	updating = true
	timer.start()
	animation_player.play("ShowMoney")

func _on_timer_timeout() -> void:
	animation_player.play("HideMoney")
	updating = false
	await animation_player.animation_finished
	gained = 0
