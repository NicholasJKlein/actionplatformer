extends CharacterBody2D

# Handles the slime enemy.

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
@onready var hit_sfx: AudioStreamPlayer2D = $HitSFX

signal enemy_death(experience: int, currency: int)

# Initial stats for slime enemy.
@export var health : int = 3
@export var SPEED : int = 40
@export var experience : int = 7
@export var currency : int = 10

var start_position : Vector2
var direction : Vector2

# State checkers.
var target : Player = null
var in_hit : bool = false
var initial_hit : bool = false
var in_death : bool = false
var hit_stun : bool = false
var knockback : float = 3.0
var smooth_damage : bool = false

# Record the starting position and initialize the healthbar UI.
func _ready() -> void:
	start_position = global_position
	healthbar.init_health(health)
	healthbar.hide()

# Handles movement and enemy updates.
func _physics_process(delta: float) -> void:
	
	# Decrease the enemy damage bar if needed.
	if smooth_damage:
		healthbar.smooth_damage()
	
	# Death check.
	if health <= 0:
		if !in_death:
			in_death = true
			healthbar.zero_damage()
			die()
	
	# Sets velocity to 0 if enemy is dying or hit the player.
	if hit_stun or in_death:
		velocity = Vector2.ZERO
		return
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		move_and_slide()
		return
	
	# When the player is not in vision range, start slowly moving back towards the spawn point.
	if !target:
		
		# If it's close enough to the spawn point, don't move.
		# Otherwise it rapidly moves back and forth and looks weird visually.
		var home_check : float = position.x - start_position.x
		
		if abs(home_check) < 5.0:
			return
		
		# Move slowly back to the spawn point.
		direction = position.direction_to(start_position).normalized()
		velocity = Vector2(direction.x * SPEED * 0.25, 0)
	
	# When the player is in vision range, start moving towards the player.
	else:
		
		# Move towards player.
		direction = position.direction_to(target.position).normalized()
		
		# Make sure direction is either -1 or 1.
		# Otherwise, the boss will slow down as it gets closer to the player.
		if direction.x < 0:
			direction.x = -1
		else:
			direction.x = 1
			
		velocity = Vector2(direction.x * SPEED, 0)
	
	# Flip the sprite to face the direction the enemy is moving.
	if velocity.x < 0:
		animated_sprite.flip_h = true
	elif velocity.x > 0:
		animated_sprite.flip_h = false
	
	# Upon receiving a hit, send the enemy moving backwards relative
	# to where it got hit from.
	if in_hit:
		velocity.x = 0
		velocity = hurtbox.get_knockback() * knockback
	else:
		
		# Default animation (same while standing still and moving).
		animated_sprite.play("Idle")
		
		# Don't move further if the enemy sees a ledge.
		if !ray_cast_down_left.is_colliding() and velocity.x < 0:
			return
		elif !ray_cast_down_right.is_colliding() and velocity.x > 0:
			return
	
	# Ensure knockback moves the correct way
	if !animated_sprite.flip_h and in_hit:
		velocity.x *= -1
	
	move_and_slide()

# Enemy sees the player.
func _on_follow_area_body_entered(body: Node2D) -> void:
	target = body

# Enemy no longer sees the player.
func _on_follow_area_body_exited(_body: Node2D) -> void:
	target = null

# Whenever the enemy's hurtbox takes damage, updates UI and necessary states.
func _on_hurtbox_received_damage(damage: int) -> void:
	
	# If the enemy is dying, ignore the damage and return immediately.
	if health <= 0:
		return
	
	# Display the enemy healthbar and start the damage process.
	healthbar.show()
	health -= damage
	healthbar._set_health(health)
	in_hit = true
	got_hit_wait.start()
	
	# Play the animation and audio of getting hit.
	animated_sprite.play("ReceiveHit")
	hit_sfx.play()
	
	# Show the floating damage numbers.
	DamageNumbers.display_number(damage, damage_numbers_origin.global_position)
	
	# Ensure that health isn't negative.
	if health <= 0:
		health = 0

# No longer in the animation from receiving a hit.
func _on_got_hit_wait_timeout() -> void:
	in_hit = false

# No longer in hitstun.
func _on_hit_stun_timer_timeout() -> void:
	hit_stun = false

# Called when the enemy dies.
func die() -> void:
	
	# Play the death animations and remove its hitbox.
	animated_sprite.play("Death")
	animation_player.play("RemoveHitbox")
	
	# Emit a signal that tells the game how much loot the player gets.
	enemy_death.emit(experience, currency)
	await animated_sprite.animation_finished
	
	# Remove the node.
	queue_free()

# When the enemy hits the player, stop its movement momentarily.
func _on_hitbox_made_contact() -> void:
	hit_stun = true
	hit_stun_timer.start()

# Begin moving the damage bar to match the enemy's health.
func _on_healthbar_move_damage() -> void:
	smooth_damage = true

# If damage bar is caught up to health, wait two seconds, then
# hide the enemy health bar.
func _on_healthbar_done_smoothing() -> void:
	smooth_damage = false
	await get_tree().create_timer(2).timeout
	healthbar.hide()
