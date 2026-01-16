extends CharacterBody2D
class_name Player

# Movement Constants
@export_group("Movement")
@export var speed: float = 400.0
@export var acceleration: float = 2000.0
@export var friction: float = 1500.0
@export var air_resistance: float = 200.0

# Jump Constants
@export_group("Jump")
@export var jump_force: float = 900.0
@export var jump_cut_multiplier: float = 0.5  # How much to reduce velocity when releasing jump early
@export var jump_buffer_time: float = 0.15  # Time to buffer jump input before landing
@export var coyote_time: float = 0.15  # Time after leaving ground where you can still jump
@export var gravity: float = 2000.0
@export var fall_gravity_multiplier: float = 1.5  # Faster falling feels better

# Jump state tracking
var jump_buffer_timer: float = 0.0
var coyote_timer: float = 0.0
var is_jumping: bool = false
var was_on_floor: bool = false

# Health
@export_group("Health")
@export var health: int = 4
@export var health_max: int = 10
var is_taking_damage: bool = false

# Knockback
@export_group("Knockback")
@export var knockback_decay: float = 0.85
@export var knockback_threshold: float = 10.0
var knockback_velocity: Vector2 = Vector2.ZERO

# Visual Feedback
const DAMAGE_FLASH_DURATION: float = 0.1
const DAMAGE_IMMUNITY_DURATION: float = 0.5

func _ready() -> void:
	"""Initialize player"""
	# Add to player group for enemy detection
	add_to_group("player")
	
	# Clamp initial health
	health = clamp(health, 0, health_max)

func _physics_process(delta: float) -> void:
	"""Main physics update"""
	# Track if we were on floor last frame
	var was_on_floor_last_frame: bool = is_on_floor()
	
	# Apply knockback with decay
	apply_knockback_physics()
	
	# Handle input and movement
	handle_movement_input(delta)
	
	# Apply gravity with variable fall speed
	apply_smooth_gravity(delta)
	
	# Handle jump with smooth mechanics
	handle_smooth_jump(delta)
	
	# Move the character
	move_and_slide()
	
	# Update coyote time
	update_coyote_time(delta, was_on_floor_last_frame)
	
	# Clamp health to valid range
	health = clamp(health, 0, health_max)
	
	# Check for death
	if health <= 0:
		die()

func apply_knockback_physics() -> void:
	"""Apply and decay knockback velocity"""
	if knockback_velocity.length() > knockback_threshold:
		# Apply knockback directly to velocity (replacing current velocity)
		velocity.x = knockback_velocity.x
		velocity.y = knockback_velocity.y
		
		# Decay knockback
		knockback_velocity *= knockback_decay
	else:
		# Stop knockback when too weak
		knockback_velocity = Vector2.ZERO

func handle_movement_input(delta: float) -> void:
	"""Handle horizontal movement with smooth acceleration"""
	# Don't allow input during strong knockback
	if knockback_velocity.length() > knockback_threshold:
		return
	
	var direction: float = Input.get_axis("ui_left", "ui_right")
	
	if direction != 0:
		# Accelerate towards target speed
		var target_speed: float = direction * speed
		var accel: float = acceleration if is_on_floor() else air_resistance
		velocity.x = move_toward(velocity.x, target_speed, accel * delta)
	else:
		# Apply friction when no input
		var friction_value: float = friction if is_on_floor() else air_resistance
		velocity.x = move_toward(velocity.x, 0, friction_value * delta)

func apply_smooth_gravity(delta: float) -> void:
	"""Apply gravity with faster falling for better feel"""
	if not is_on_floor():
		var gravity_to_apply: float = gravity
		
		# Apply stronger gravity when falling (not jumping or moving upward)
		if velocity.y > 0:
			gravity_to_apply *= fall_gravity_multiplier
		
		velocity.y += gravity_to_apply * delta
		velocity.y = min(velocity.y, gravity * 2)  # Cap fall speed

func handle_smooth_jump(delta: float) -> void:
	"""Handle jump with buffering, coyote time, and variable height"""
	# Can't jump during knockback
	if knockback_velocity.length() > knockback_threshold:
		return
	
	# Update jump buffer timer
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	
	# Check for jump input
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = jump_buffer_time
	
	# Can we jump? (on floor OR within coyote time)
	var can_jump: bool = is_on_floor() or coyote_timer > 0
	
	# Execute jump if buffered and able
	if jump_buffer_timer > 0 and can_jump and not is_jumping:
		perform_jump()
	
	# Variable jump height - cut jump short if button released early
	if Input.is_action_just_released("ui_accept") and velocity.y < 0 and is_jumping:
		velocity.y *= jump_cut_multiplier
	
	# Reset jumping state when landing
	if is_on_floor():
		is_jumping = false

func perform_jump() -> void:
	"""Execute the jump"""
	velocity.y = -jump_force
	is_jumping = true
	jump_buffer_timer = 0
	coyote_timer = 0  # Reset coyote time after jumping

func update_coyote_time(delta: float, was_on_floor_last_frame: bool) -> void:
	"""Update coyote time for jump grace period"""
	if was_on_floor_last_frame and not is_on_floor() and not is_jumping:
		# Just walked off a ledge (didn't jump) - start coyote time
		coyote_timer = coyote_time
	elif coyote_timer > 0:
		coyote_timer -= delta
	
	# Reset coyote time when landing
	if is_on_floor():
		coyote_timer = 0

# Combat Methods

func take_damage(amount: int) -> void:
	"""Take damage with immunity period"""
	if is_taking_damage:
		return
	
	health -= amount
	is_taking_damage = true
	
	print("🩸 Player took ", amount, " damage! Health: ", health, "/", health_max)
	
	# Visual feedback
	show_damage_feedback()
	
	# Reset immunity after duration
	await get_tree().create_timer(DAMAGE_IMMUNITY_DURATION).timeout
	is_taking_damage = false

func show_damage_feedback() -> void:
	"""Show visual damage feedback"""
	modulate = Color.RED
	await get_tree().create_timer(DAMAGE_FLASH_DURATION).timeout
	modulate = Color.WHITE

func apply_knockback(force: Vector2) -> void:
	"""Apply knockback force to player"""
	knockback_velocity = force
	
	# Reset horizontal velocity to prevent accumulation
	velocity.x = 0
	
	print("💫 Player received knockback: ", force)

func heal(amount: int) -> void:
	"""Heal the player"""
	var old_health: int = health
	health = min(health + amount, health_max)
	var actual_heal: int = health - old_health
	
	print("💚 Player healed ", actual_heal, " HP! Health: ", health, "/", health_max)

func die() -> void:
	"""Handle player death"""
	print("💀 Player died!")
	
	# Optional: Add death animation or delay here
	# await get_tree().create_timer(1.0).timeout
	
	# Restart the level
	get_tree().reload_current_scene()

# Utility Methods

func get_health_percentage() -> float:
	"""Get health as a percentage (0.0 to 1.0)"""
	return float(health) / float(health_max)

func is_alive() -> bool:
	"""Check if player is alive"""
	return health > 0

func is_full_health() -> bool:
	"""Check if player is at full health"""
	return health >= health_max
