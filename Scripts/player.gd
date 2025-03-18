class_name Player extends CharacterBody2D

# Handles the player character and information related to it.

# Get references to the relevant nodes.
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

# Initial stats for the player character.
var SPEED : float = 120.0
var JUMP_VELOCITY : float = -350.0
var DASH_SPEED : int = 3
var knockback : float = 10.0

var MAX_HEALTH : int = 5
var ATTACK : int = 1

var level : int = 1
var current_XP : int = 0
var total_XP : int = 0
var max_XP: int = get_max_XP(level + 1)

var currency : int = 0

# State checkers
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

# Initialize health, attack, XP, and make the screen transition.
func _ready() -> void:
	health = MAX_HEALTH
	formulate_attack()
	
	player_health.init_health(health)
	player_xp.initialize(current_XP, max_XP, level)
	you_died_screen.get_parent().get_node("Reset").color.a = 255
	you_died_screen.play("ResumeLight")

# Handles movement and player updates.
func _physics_process(delta: float) -> void:	
	# If in dying animation, ignore all other physics processes.
	if dying:
		return
	
	# Death check.
	if health <= 0:
		die()
	
	# Checks if the player got hit. If yes, don't do the physics processes after.
	if in_hit:
		
		# If it's the first contact, apply knockback.
		if !initial_hit:
			velocity = hurtbox.get_knockback() * knockback
			initial_hit = true
		
		# If the player is on the floor, make sure it stays on floor.
		# Without this, the slimes would send the player back and upwards, probably
		# due to their hitbox being lower in position than the player's hurtbox.
		if is_on_floor():
			velocity.y = 0
			
		# Apply gravity.
		velocity += get_gravity() * delta
		
		move_and_slide()
		
		return
	
	# Can be hit and have knockback applied again.
	initial_hit = false
	
	# Decrease the player damage bar if needed.
	if smooth_damage:
		player_health.smooth_damage()
	
	# Increase the player health bar if needed.
	if smooth_heal and (player_health.value < health):
		player_health.smooth_heal(health)
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
 	
	# Handle jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Handle initial dash input.
	if Input.is_action_just_pressed("Dash") and !dashing and can_dash:
		
		# Cancel attack animation if applicable.
		hitbox_collision.disabled = true
		
		# Play run animation and set appropriate states.
		animated_sprite.play("Run")
		dashing = true
		can_dash = false
		
		# Start relevant timers.
		dash_timer.start()
		dash_effect_timer.start()
		dash_cooldown.start()
	
	# If still dashing (not just the initial input)
	if dashing:
		
		# Stop vertical movement, set horizontal velocity to the dashing velocity.
		velocity.y = 0
		velocity.x = SPEED * DASH_SPEED
		
		# If facing left, velocity should also go to the left.
		if animated_sprite.flip_h:
			velocity.x *= -1
		
		move_and_slide()
		
		return
	
	# Dash is over, so stop the dash effects.
	dash_effect_timer.stop()
	
	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_axis("MoveLeft", "MoveRight")
	
	# If the player wasn't attacking and the input for attack was pressed, proceed.
	if !animation_player.is_playing() and Input.is_action_just_pressed("Attack"):
		
		# Make sure the animation is playing in the correct direction.
		if !animated_sprite.flip_h:
			animation_player.play("AttackRight")
		else:
			animation_player.play("AttackLeft")
		
		# Checks if another attack was pressed recently, so it plays a different animation.
		# Just makes animation smoother.
		if !in_combo:
			animated_sprite.play("Attack")
			combo_timer.start()
			in_combo = true
		else:
			animated_sprite.play("Attack2")
	
	# If the player isn't attacking or dashing, proceed.
	if !animation_player.is_playing() and !dashing:
		
		# If player is grounded.
		if is_on_floor():
			
			# No directional input detected.
			if direction == 0:
				animated_sprite.play("Idle")
			else:
				animated_sprite.play("Run")
		
		# If player is in air, play jump animation.
		else:
			animated_sprite.play("Jump")
	
	# Flip the sprite to match the direction of movement
		if direction > 0:
			animated_sprite.flip_h = false
		elif direction < 0:
			animated_sprite.flip_h = true
	
	# Change the horizontal velocity.
	
	# If input to move and player is attacking.
	if direction and animation_player.is_playing():
		velocity.x = direction * SPEED * 0.4
	
	# If player is moving.
	elif direction:
		velocity.x = direction * SPEED
	
	# Player isn't moving.
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

# Pressing the attack input will no longer play Attack2. Resets to Attack.
func _on_combo_timer_timeout() -> void:
	in_combo = false

# Whenever the player's hurtbox takes damage, updates UI and necessary states.
func _on_hurtbox_received_damage(damage: int) -> void:
	
	# If one of these conditions is true, ignore the damage and return immediately.
	if health <= 0 or is_invul or dashing:
		return
	
	# Make the player invulnerable for a short while so they can't be chain-hit.
	is_invul = true
	invul_timer.start()
	
	# Apply damage.
	health -= damage
	player_health.lose_health(health)
	
	# Sets the damage bar to the max if it's lower than the health.
	# Currently only happens when the player is healing from leveling up, then
	# takes damage.
	if player_health.need_catchup():
		player_health.reset_damage()
	
	# Play the hit animation and set the hit state to true.
	in_hit = true
	get_hit_timer.start()
	animated_sprite.play("GetHit")
	
	# Death check, prevent health from being negative.
	if health <= 0:
		health = 0
		die()

# Called when the player character dies.
func die():
	dying = true
	
	# Pause the game so that nothing except the animated sprite and death screen play.
	get_tree().paused = true
	animated_sprite.play("Die")
	
	# Play the animations corresponding to the death screen.
	await get_tree().create_timer(0.5).timeout
	you_died_screen.play("YouDied")
	
	await you_died_screen.animation_finished
	await get_tree().create_timer(1).timeout
	
	you_died_screen.play("CoverUp")
	await you_died_screen.animation_finished
	
	# Resume the game and signal that the player death process is complete.
	get_tree().paused = false
	death.emit()

# Player is no longer in hitstun.
func _on_get_hit_timer_timeout() -> void:
	in_hit = false

# Player is no longer invulnerable.
func _on_invul_timer_timeout() -> void:
	is_invul = false

# Player is no longer dashing.
func _on_dash_timer_timeout() -> void:
	dashing = false

# Begin moving the damage bar to match the player's health.
func _on_player_health_move_damage() -> void:
	smooth_damage = true

# The player's damage bar value is equal to the health value,
# so stop the bar's movement.
func _on_player_health_done_smoothing() -> void:
	smooth_damage = false

# The player's health bar value is equal to its true value,
# so stop the bar's movement.
func _on_player_health_done_healing() -> void:
	smooth_heal = false

# Directly set the player health to 0, killing them.
# Used with killzones.
func instant_kill() -> void:
	health = 0
	player_health.set_health(health)

# Creates a semi-transparent afterimage of the player sprite.
func dash_effect() -> void:
	
	# Create a visual clone of the player sprite and set up its initial values.
	var visual_copy: AnimatedSprite2D = $AnimatedSprite2D.duplicate()
	var animation_time = dash_timer.wait_time / DASH_SPEED
	var fade_steps : int = 3
	var fade_amount : float = 0.1
	
	# Add the clone as a child of the player, set its position to match, and
	# make it more transparent.
	get_parent().add_child(visual_copy)
	visual_copy.global_position = get_node("AnimatedSprite2D").global_position
	visual_copy.modulate.a -= 0.7
	
	# Slowly lower the visibility of the clone.
	for i in range(fade_steps):
		await get_tree().create_timer(animation_time).timeout
		visual_copy.modulate.a -= fade_amount
	
	# Free the copy after the dash has finished.
	visual_copy.queue_free()

# Make the player able to dash again.
func _on_dash_cooldown_timeout() -> void:
	can_dash = true

# Create an afterimage during the dash.
func _on_dash_effect_timeout() -> void:
	dash_effect()

# Return the max XP value for the passed in level.
func get_max_XP(new_level: int) -> int:
	return round(pow(new_level, 1.6) + (new_level * 3) + 11)

# Add a specified amount to the player's XP values.
func receive_XP(amount: int) -> void:
	total_XP += amount
	current_XP += amount
	player_xp.set_remaining(amount)
	
	# Keep leveling up while the player has the necessary XP.
	while current_XP >= max_XP:
		current_XP -= max_XP
		player_xp.adding_level()
		level_up()

# Called whenever the player levels up.
func level_up() -> void:
	
	# Add to the player's stats.
	level += 1
	ATTACK += 1
	MAX_HEALTH += 1
	formulate_attack()
	max_XP = get_max_XP(level + 1)
	
	# Reset the appropriate UI elements.
	health = MAX_HEALTH
	player_health.enlarge()
	player_health.set_health(health)
	smooth_heal = true

# Adds a specified amount to the player's currency.
func add_currency(amount: int) -> void:
	currency += amount
	currency_counter.set_currency(currency)

# Subtracts a specified amount from the player's currency.
# Currently no trigger in game, just set up for later.
func spend_currency(amount: int) -> void:
	currency -= amount
	if currency < 0:
		currency = 0
	currency_counter.set_currency(currency)

# Set the damage of the hitbox.
# Currently is just equal to the attack, but set up so that it can take
# any formula later.
func formulate_attack() -> void:
	hitbox.set_damage(ATTACK)

# When the XP bar fills up and "resets", a signal will be seen to play
# an animation of a "LEVEL UP" label appearing below the bar.
func _on_player_xp_level_noti() -> void:
	level_animate.play("LevelUp")
