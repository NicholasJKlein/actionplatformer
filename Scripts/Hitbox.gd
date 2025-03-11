class_name Hitbox extends Area2D

@export var damage : int = 1

signal made_contact

func set_damage(value : int) -> void:
	damage = value
	
func get_damage() -> int:
	return damage
	
func this_made_contact() -> void:
	made_contact.emit()
