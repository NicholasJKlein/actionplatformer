extends CharacterBody2D

# Get references to relevant nodes.
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
@onready var hit_sfx: AudioStreamPlayer2D = $HitSFX

signal enemy_death(experience: int, currency: int)

# Set values for unique stats and name.
@export var boss_name : String = "Glorpus, the Slimy"
@export var health : int = 20
@export var SPEED : int = 30
@export var experience : int = 40
@export var currency : int = 100

# Vectors regarding movement.
var start_position : Vector2
var direction : Vector2

# Other variables, mostly to keep track of various states.
var target : Player = null
var in_hit : bool = false
var initial_hit : bool = false
var in_death : bool = false
var hit_stun : bool = false
var knockback : float = 3.0
var smooth_damage : bool = false

# On creation, get the position in the world and create the corresponding boss UI.
func _ready() -> void:
	start_position = global_position
	boss_bar.initialize(boss_name, health)
	boss_bar.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# If the boss has no health, start the dying process.
	if health <= 0:
		if !in_death:
			in_death = true
			die()
	
	# If the damage bar is signaled to catch up, start smoothly moving
	# it towards the health value.
	if smooth_damage and boss_bar:
		boss_bar.smooth_damage()
	
	# When hitting the player or dying, make sure the velocity is 0.
	if hit_stun or in_death:
		velocity = Vector2.ZERO
		return
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		move_and_slide()
		return
	
	# Get the difference between current position and its spawn.
	var home_check : float = position.x - start_position.x
	
	# When the player is not in vision range or the boss is too far away from spawn,
	# start slowly moving back towards the spawn point.
	if !target or home_check > 200:
		
		# If it's close enough to the spawn point, don't move.
		# Otherwise it rapidly moves back and forth and looks weird visually.
		if abs(home_check) < 5.0:
			return
		
		# Move slowly back to spawn point.
		direction = position.direction_to(start_position).normalized()
		velocity = Vector2(direction.x * SPEED * 0.25, 0)
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
	
	# If player is in aggro range, show the boss health UI.
	# Otherwise, wait for 2 seconds, then hide the UI.
	if !target and boss_bar.visible:
		await get_tree().create_timer(2).timeout
		boss_bar.hide()
	elif !boss_bar.visible:
		boss_bar.show()
	
	# Flip the sprite to face the direction the boss is moving.
	if velocity.x < 0:
		animated_sprite.flip_h = true
	elif velocity.x > 0:
		animated_sprite.flip_h = false
	
	# Upon receiving a hit, send the boss moving backwards relative
	# to where it got hit from.
	if in_hit:
		velocity.x = 0
		velocity = hurtbox.get_knockback() * knockback
		
		# Ensure that boss doesn't get lifted off of ground.
		if is_on_floor():
			velocity.y = 0
	else:
		
		# Default animation (same while standing still and moving).
		animated_sprite.play("Idle")
		
		# Don't move further if the boss sees a ledge.
		if !ray_cast_down_left.is_colliding() and velocity.x < 0:
			return
		elif !ray_cast_down_right.is_colliding() and velocity.x > 0:
			return
	
	# Ensure knockback moves the correct way
	if !animated_sprite.flip_h and in_hit:
		velocity.x *= -1
	
	move_and_slide()

# When player enters vision range, set the target to the player
func _on_follow_area_body_entered(body: Node2D) -> void:
	target = body

# When player leaves vision range, set there to be no target	
func _on_follow_area_body_exited(_body: Node2D) -> void:
	target = null

# When the boss takes a hit
func _on_hurtbox_received_damage(damage: int) -> void:
	
	# Do nothing if already dead
	if health <= 0:
		return
	
	# Play the hit sound, adjust health as necessary.
	# Enter hitstun animation.
	hit_sfx.play()
	health -= damage
	boss_bar._set_health(health)
	in_hit = true
	got_hit_wait.start()
	
	animated_sprite.play("ReceiveHit")
	
	# Make sure the boss doesn't have negative health.
	if health <= 0:
		health = 0

# Remove hitstun (on boss hit).
func _on_got_hit_wait_timeout() -> void:
	in_hit = false

# Remove hitstun (on player hit).
func _on_hit_stun_timer_timeout() -> void:
	hit_stun = false

# On death, play the corresponding animation, remove the hitbox,
# emit a signal with the boss drops, and remove the node from the game.
func die() -> void:
	animated_sprite.play("Death")
	animation_player.play("RemoveHitbox")
	await animated_sprite.animation_finished
	enemy_death.emit(experience, currency)
	queue_free()

# When hitting player, enter hitstun state.
func _on_hitbox_made_contact() -> void:
	hit_stun = true
	hit_stun_timer.start()

# Make the boss health UI start moving damage bar value.
func _on_boss_bar_boss_move_damage() -> void:
	smooth_damage = true

# Stop moving the boss health UI's damage bar value.
func _on_boss_bar_done_smoothing() -> void:
	smooth_damage = false
