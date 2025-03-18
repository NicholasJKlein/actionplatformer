class_name Hurtbox extends Area2D

# Defines an area that is dealt damage by hitboxes on that layer.

signal received_damage(damage: int)

@export var health: int

var knockback : Vector2 = Vector2.ZERO

# Makes the hurtbox of whatever character this is a child of connect to
# the _on_area_entered function of this class.
func _ready() -> void:
	connect("area_entered", _on_area_entered)

# When a hitbox enters the area of this hurtbox, calculate the vector
# of the knockback (based on where the hitbox collided).
# Emit signals to put damage on the parent, and that the hitbox made contact.
func _on_area_entered(hitbox: Hitbox) -> void:
	if hitbox and hitbox.get_parent() != get_parent():
		knockback = global_position - hitbox.global_position
		health -= hitbox.damage
		received_damage.emit(hitbox.damage)
		hitbox.made_contact.emit()

# Return the knockback vector
func get_knockback() -> Vector2:
	return knockback
