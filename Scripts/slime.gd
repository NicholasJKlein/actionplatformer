extends CharacterBody2D

# Get references to all of the relevant children nodes
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_cast_down_right: RayCast2D = $RayCastDownRight
@onready var ray_cast_down_left: RayCast2D = $RayCastDownLeft
@onready var damage_numbers_origin: Node2D = $DamageNumbersOrigin
@onready var healthbar: ProgressBar = $Healthbar
@onready var got_hit_wait: Timer = $GotHitWait
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox
@onready var hit_stun_timer: Timer = $HitStunTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collide_world: CollisionShape2D = $CollisionShape2D

signal enemy_death(experience: int, currency: int)

@export var health : int = 3
@export var SPEED : int = 40
@export var experience : int = 9
@export var currency : int = 10

var start_position : Vector2
var direction : Vector2

var target : Player = null
var in_hit : bool = false
var initial_hit : bool = false
var in_death : bool = false
var hit_stun : bool = false
var knockback : float = 3.0
var smooth_damage : bool = false

func _ready() -> void:
	start_position = global_position
	healthbar.init_health(health)
	healthbar.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if smooth_damage:
		healthbar.smooth_damage()
	
	if health <= 0:
		if !in_death:
			in_death = true
			healthbar.zero_damage()
			die()
	
	if hit_stun or in_death:
		velocity = Vector2.ZERO
		return
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		move_and_slide()
		return
	
	if !target:
		var home_check : float = position.x - start_position.x
		if abs(home_check) < 5.0:
			return
		
		direction = position.direction_to(start_position).normalized()
		velocity = Vector2(direction.x * SPEED * 0.25, 0)
	else:
		direction = position.direction_to(target.position).normalized()
		if direction.x < 0:
			direction.x = -1
		else:
			direction.x = 1
		velocity = Vector2(direction.x * SPEED, 0)
	
	if velocity.x < 0:
		animated_sprite.flip_h = true
	elif velocity.x > 0:
		animated_sprite.flip_h = false
	
	if in_hit:
		velocity.x = 0
		velocity = hurtbox.get_knockback() * knockback
	else:
		animated_sprite.play("Idle")
		if !ray_cast_down_left.is_colliding() and velocity.x < 0:
			return
		elif !ray_cast_down_right.is_colliding() and velocity.x > 0:
			return
	
	if !animated_sprite.flip_h and in_hit:
		velocity.x *= -1
	
	move_and_slide()

func _on_follow_area_body_entered(body: Node2D) -> void:
	target = body

func _on_follow_area_body_exited(_body: Node2D) -> void:
	target = null

func _on_hurtbox_received_damage(damage: int) -> void:
	if health <= 0:
		return
	
	healthbar.show()
	health -= damage
	healthbar._set_health(health)
	in_hit = true
	got_hit_wait.start()
	
	animated_sprite.play("ReceiveHit")
	DamageNumbers.display_number(damage, damage_numbers_origin.global_position)
	if health <= 0:
		health = 0


func _on_got_hit_wait_timeout() -> void:
	in_hit = false

func _on_hit_stun_timer_timeout() -> void:
	hit_stun = false


func die() -> void:
	animated_sprite.play("Death")
	animation_player.play("RemoveHitbox")
	enemy_death.emit(experience, currency)
	await animated_sprite.animation_finished
	queue_free()


func _on_hitbox_made_contact() -> void:
	hit_stun = true
	hit_stun_timer.start()


func _on_healthbar_move_damage() -> void:
	smooth_damage = true


func _on_healthbar_done_smoothing() -> void:
	smooth_damage = false
	await get_tree().create_timer(2).timeout
	healthbar.hide()
