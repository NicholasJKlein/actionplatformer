class_name Hurtbox extends Area2D

signal received_damage(damage: int)

@export var health: int

var knockback : Vector2 = Vector2.ZERO

func _ready() -> void:
	connect("area_entered", _on_area_entered)

func _on_area_entered(hitbox: Hitbox) -> void:
	if hitbox and hitbox.get_parent() != get_parent():
		knockback = global_position - hitbox.global_position
		health -= hitbox.damage
		received_damage.emit(hitbox.damage)
		hitbox.made_contact.emit()
		
func get_knockback() -> Vector2:
	return knockback
