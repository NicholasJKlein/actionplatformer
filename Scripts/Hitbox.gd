class_name Hitbox extends Area2D

# Defines an area that deals damage to any hurtboxes on that layer.

@export var damage : int = 1

signal made_contact

# Change the damage the hitbox deals.
func set_damage(value : int) -> void:
	damage = value

# Retruns the damage the hitbox deals.
func get_damage() -> int:
	return damage

# Signals that the hitbox made contact with a hurtbox.
func this_made_contact() -> void:
	made_contact.emit()
