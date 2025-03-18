extends Control

# Get the sliders for the different audio buses
@onready var master_slide: HSlider = $VBoxContainer/MasterSlide
@onready var music_slide: HSlider = $VBoxContainer/MusicSlide
@onready var sfx_slide: HSlider = $VBoxContainer/SFXSlide

# Called when the node enters the scene tree for the first time.
# Set the slider values equal to the value of the actual audio buses
func _ready() -> void:
	master_slide.value = db_to_linear(AudioServer.get_bus_volume_db(0))
	music_slide.value = db_to_linear(AudioServer.get_bus_volume_db(1))
	sfx_slide.value = db_to_linear(AudioServer.get_bus_volume_db(2))

# When releasing the mouse from moving slider, save position
func _on_master_slide_mouse_exited() -> void:
	release_focus()

func _on_music_slide_mouse_exited() -> void:
	release_focus()

func _on_sfx_slide_mouse_exited() -> void:
	release_focus()
