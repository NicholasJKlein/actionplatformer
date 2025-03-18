extends Node

# When an enemy (not boss) takes damage, display a number on screen corresponding to
# the amount of damage dealt.
func display_number(value: int, position: Vector2):
	
	# Create the label that displays the damage number from the given position.
	var number = Label.new()
	number.global_position = position
	number.text = str(value)
	number.z_index = 5
	number.label_settings = LabelSettings.new()
	
	# Make text white so it stands out.
	var color = "#FFF"
	
	# If no damage was actually dealt, make label transparent so it doesn't show.
	if value == 0:
		color = "#FFF8"
	
	# Set additional font parameters for the text.
	number.label_settings.font_color = color
	number.label_settings.font_size = 12
	number.label_settings.outline_color = "#000"
	number.label_settings.outline_size = 1
	
	# Add the label as a child of the global damage numbers node
	call_deferred("add_child", number)
	
	# Set the pivot offset to the middle once it's in the scene.
	await number.resized
	number.pivot_offset = Vector2(number.size / 2)
	
	# Handle animation.
	# Number should go up, then go down, then fade out and be removed.
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(number, "position:y", number.position.y - 24, 0.25).set_ease(Tween.EASE_OUT)
	tween.tween_property(number, "position:y", number.position.y, 0.5).set_ease(Tween.EASE_IN).set_delay(0.25)
	tween.tween_property(number, "scale", Vector2.ZERO, 0.25).set_ease(Tween.EASE_IN).set_delay(0.5)
	
	await tween.finished
	number.queue_free()
	
