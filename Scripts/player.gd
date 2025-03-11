class_name Player extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Hitbox = $Marker2D/Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox_collision: CollisionShape2D = $Marker2D/Hitbox/CollisionShape2D
@onready var combo_timer: Timer = $ComboTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var player_health: ProgressBar = $CanvasLayer/PlayerHealth
@onready var player_xp: TextureProgressBar = $CanvasLayer/PlayerXP
@onready var get_hit_timer: Timer = $GetHitTimer
@onready var invul_timer: Timer = $InvulTimer
@onready var you_died_screen: AnimationPlayer = $Transition/YouDiedScreen/AnimationPlayer
@onready var dash_timer: Timer = $DashTimer
@onready var dash_cooldown: Timer = $DashCooldown
@onready var dash_effect_timer: Timer = $DashEffect
@onready var currency_counter: Control = $CanvasLayer/CurrencyCounter
@onready var level_animate: AnimationPlayer = $CanvasLayer/level_animate

signal death

var SPEED : float = 120.0
var JUMP_VELOCITY : float = -300.0
var DASH_SPEED : int = 3
var knockback : float = 10.0

var MAX_HEALTH : int = 5
var ATTACK : int = 1

var level : int = 1
var current_XP : int = 0
var total_XP : int = 0
var max_XP: int = get_max_XP(level + 1)

var currency : int = 0

var in_combo : bool = false
var in_hit : bool = false
var initial_hit : bool = false
var is_invul : bool = false
var smooth_damage : bool = false
var smooth_heal : bool = false
var dying : bool = false
var dashing : bool = false
var can_dash : bool = true

var health : int

func _ready() -> void:
	health = MAX_HEALTH
	formulate_attack()
	
	player_health.init_health(health)
	player_xp.initialize(current_XP, max_XP, level)
	you_died_screen.get_parent().get_node("Reset").color.a = 255
	you_died_screen.play("ResumeLight")

func _physics_process(delta: float) -> void:	
	if dying:
		return
	
	if health <= 0:
		die()
	
	if in_hit:
		if !initial_hit:
			velocity = hurtbox.get_knockback() * knockback
			initial_hit = true
		if is_on_floor():
			velocity.y = 0
		velocity += get_gravity() * delta
		move_and_slide()
		return
	
	initial_hit = false
	
	if smooth_damage:
		player_health.smooth_damage()
		
	if smooth_heal and (player_health.value < health):
		player_health.smooth_heal(health)
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
 	
	# Handle jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if Input.is_action_just_pressed("Dash") and !dashing and can_dash:
		hitbox_collision.disabled = true
		animated_sprite.play("Run")
		dashing = true
		can_dash = false
		dash_timer.start()
		dash_effect_timer.start()
		dash_cooldown.start()
	
	if dashing:
		velocity.y = 0
		velocity.x = SPEED * DASH_SPEED
		if animated_sprite.flip_h:
			velocity.x *= -1
		move_and_slide()
		return
	
	dash_effect_timer.stop()
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("MoveLeft", "MoveRight")
	
	if !animation_player.is_playing() and Input.is_action_just_pressed("Attack"):
		if !animated_sprite.flip_h:
			animation_player.play("AttackRight")
		else:
			animation_player.play("AttackLeft")
		if !in_combo:
			animated_sprite.play("Attack")
			combo_timer.start()
			in_combo = true
		else:
			animated_sprite.play("Attack2")
	
	if !animation_player.is_playing() and !dashing:
		if is_on_floor():
			if direction == 0:
				animated_sprite.play("Idle")
			else:
				animated_sprite.play("Run")
		else:
			animated_sprite.play("Jump")
	
	# Flip the sprite to match the direction of movement
		if direction > 0:
			animated_sprite.flip_h = false
		elif direction < 0:
			animated_sprite.flip_h = true
	
	# Apply movement
	if direction and animation_player.is_playing():
		velocity.x = direction * SPEED * 0.4
	elif direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()


func _on_combo_timer_timeout() -> void:
	in_combo = false
	
func _on_hurtbox_received_damage(damage: int) -> void:
	if health <= 0 or is_invul or dashing:
		return
	
	is_invul = true
	invul_timer.start()
	
	health -= damage
	player_health.lose_health(health)
	
	if player_health.need_catchup():
		player_health.reset_damage()
	
	in_hit = true
	get_hit_timer.start()
	animated_sprite.play("GetHit")
	
	if health <= 0:
		health = 0
		die()


func die():
	dying = true
	get_tree().paused = true
	animated_sprite.play("Die")
	await get_tree().create_timer(0.5).timeout
	you_died_screen.play("YouDied")
	await you_died_screen.animation_finished
	await get_tree().create_timer(1).timeout
	you_died_screen.play("CoverUp")
	await you_died_screen.animation_finished
	get_tree().paused = false
	death.emit()

func _on_get_hit_timer_timeout() -> void:
	in_hit = false

func _on_invul_timer_timeout() -> void:
	is_invul = false
	
func _on_dash_timer_timeout() -> void:
	dashing = false

func _on_player_health_move_damage() -> void:
	smooth_damage = true

func _on_player_health_done_smoothing() -> void:
	smooth_damage = false

func _on_player_health_done_healing() -> void:
	smooth_heal = false
	
func instant_kill() -> void:
	health = 0
	player_health.set_health(health)

func dash_effect() -> void:
	var visual_copy: AnimatedSprite2D = $AnimatedSprite2D.duplicate()
	var animation_time = dash_timer.wait_time / DASH_SPEED
	var fade_steps : int = 3
	var fade_amount : float = 0.1
	
	get_parent().add_child(visual_copy)
	visual_copy.global_position = get_node("AnimatedSprite2D").global_position
	visual_copy.modulate.a -= 0.7
	
	for i in range(fade_steps):
		await get_tree().create_timer(animation_time).timeout
		visual_copy.modulate.a -= fade_amount
	
	visual_copy.queue_free()


func _on_dash_cooldown_timeout() -> void:
	can_dash = true


func _on_dash_effect_timeout() -> void:
	dash_effect()

func get_max_XP(new_level: int) -> int:
	return round(pow(new_level, 1.6) + (new_level * 3) + 11)
	
func receive_XP(amount: int) -> void:
	total_XP += amount
	current_XP += amount
	player_xp.set_remaining(amount)
	while current_XP >= max_XP:
		current_XP -= max_XP
		player_xp.adding_level()
		level_up()

func level_up() -> void:
	level += 1
	ATTACK += 1
	MAX_HEALTH += 1
	formulate_attack()
	max_XP = get_max_XP(level + 1)
	health = MAX_HEALTH
	player_health.enlarge()
	player_health.set_health(health)
	smooth_heal = true
	
func add_currency(amount: int) -> void:
	currency += amount
	currency_counter.set_currency(currency)
	
func spend_currency(amount: int) -> void:
	currency -= amount
	if currency < 0:
		currency = 0
	currency_counter.set_currency(currency)
	
func formulate_attack() -> void:
	hitbox.set_damage(ATTACK)


func _on_player_xp_level_noti() -> void:
	level_animate.play("LevelUp")
