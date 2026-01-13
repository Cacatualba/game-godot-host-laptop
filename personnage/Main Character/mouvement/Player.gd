extends CharacterBody2D

# Movement
@export var speed := 400.0
@export var jump_force := 900.0
@export var gravity := 2000.0

# Health
@export var health: int = 100
@export var health_max: int = 100
var is_taking_damage: bool = false

# Knockback
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_decay: float = 0.85

var player  # déclaration obligatoire

func _ready():
	# Make sure player is in the "player" group
	add_to_group("player")
	
	if has_node("Player"):
		player = $Player
	else:
		print("Player node not found!")

func _physics_process(delta):
	# Apply knockback
	if knockback_velocity.length() > 0:
		velocity += knockback_velocity
		knockback_velocity *= knockback_decay
		
		# Stop knockback when it's weak enough
		if knockback_velocity.length() < 10:
			knockback_velocity = Vector2.ZERO
	
	# Movement input
	var direction = 0
	if Input.is_action_pressed("ui_left"):
		direction -= 1
	if Input.is_action_pressed("ui_right"):
		direction += 1
	
	velocity.x = direction * speed
	velocity.y += gravity * delta
	
	# Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = -jump_force
	
	move_and_slide()
	
	# Clamp health
	health = clamp(health, 0, health_max)
	
	# Check for death
	if health <= 0:
		die()

func take_damage(amount: int):
	if is_taking_damage:
		return
	
	health -= amount
	is_taking_damage = true
	
	print("🩸 Player took ", amount, " damage! Health: ", health, "/", health_max)
	
	# Visual feedback - flash red
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE
	
	await get_tree().create_timer(0.5).timeout
	is_taking_damage = false

func apply_knockback(force: Vector2):
	knockback_velocity = force
	print("💫 Player received knockback: ", force)

func die():
	print("💀 Player died!")
	# Restart the level
	get_tree().reload_current_scene()

func heal(amount: int):
	health = min(health + amount, health_max)
	print("💚 Player healed ", amount, " HP! Health: ", health, "/", health_max)
