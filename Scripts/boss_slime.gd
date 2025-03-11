extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox
@onready var follow_area: Area2D = $FollowArea
@onready var boss_bar: ProgressBar = $CanvasLayer/BossBar
@onready var ray_cast_down_right: RayCast2D = $RayCastDownRight
@onready var ray_cast_down_left: RayCast2D = $RayCastDownLeft
@onready var got_hit_wait: Timer = $GotHitWait
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hit_stun_timer: Timer = $HitStunTimer

signal enemy_death(experience: int, currency: int)

@export var boss_name : String = "Glorpus, the Slimy"
@export var health : int = 20
@export var SPEED : int = 30
@export var experience : int = 30
@export var currency : int = 100

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
	boss_bar.initialize(boss_name, health)
	boss_bar.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if health <= 0:
		if !in_death:
			in_death = true
			die()
	
	if smooth_damage and boss_bar:
		boss_bar.smooth_damage()
	
	if hit_stun or in_death:
		velocity = Vector2.ZERO
		return
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		move_and_slide()
		return
	
	var home_check : float = position.x - start_position.x
	
	if !target or home_check > 200:
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
	
	if !target and boss_bar.visible:
		await get_tree().create_timer(2).timeout
		boss_bar.hide()
	elif !boss_bar.visible:
		boss_bar.show()
	
	if velocity.x < 0:
		animated_sprite.flip_h = true
	elif velocity.x > 0:
		animated_sprite.flip_h = false
	
	if in_hit:
		velocity.x = 0
		velocity = hurtbox.get_knockback() * knockback
		if is_on_floor():
			velocity.y = 0
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
	
	health -= damage
	boss_bar._set_health(health)
	in_hit = true
	got_hit_wait.start()
	
	animated_sprite.play("ReceiveHit")
	if health <= 0:
		health = 0


func _on_got_hit_wait_timeout() -> void:
	in_hit = false

func _on_hit_stun_timer_timeout() -> void:
	hit_stun = false


func die() -> void:
	animated_sprite.play("Death")
	animation_player.play("RemoveHitbox")
	await animated_sprite.animation_finished
	enemy_death.emit(experience, currency)
	queue_free()


func _on_hitbox_made_contact() -> void:
	hit_stun = true
	hit_stun_timer.start()


func _on_boss_bar_boss_move_damage() -> void:
	smooth_damage = true


func _on_boss_bar_done_smoothing() -> void:
	smooth_damage = false
