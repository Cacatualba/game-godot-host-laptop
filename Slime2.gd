extends CharacterBody2D
class_name Ennemy2

# ================= CONSTANTS =================
const SPEED := 100.0
const GRAVITY := 300.0
const KNOCKBACK_FORCE := 300.0
const EDGE_CHECK_DISTANCE := 20.0
const EDGE_CHECK_DROP := 30.0

const HIT_STUN_TIME := 0.2
const DAMAGE_COOLDOWN := 1.0
const DEATH_DURATION := 1.0

# ================= STATE =================
@export var health := 80
@export var damage := 1

var is_dead := false
var is_chasing := false
var is_hit_stunned := false
var direction := Vector2.RIGHT

# Track which players are currently in contact (for continuous damage)
var players_in_contact: Dictionary = {}  # player -> last_damage_time

# ================= REFERENCES =================
var player: CharacterBody2D
@onready var detection_area: Area2D = get_node_or_null("DetectionArea2D") if has_node("DetectionArea2D") else get_node_or_null("detection_area")
@onready var damage_area: Area2D = get_node_or_null("DamageArea2D") if has_node("DamageArea2D") else get_node_or_null("damage_area")
@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") if has_node("AnimatedSprite2D") else get_node_or_null("Sprite2D")
@onready var dir_timer: Timer = get_node_or_null("DirectionTimer") if has_node("DirectionTimer") else get_node_or_null("Timer")

# ================= READY =================
func _ready() -> void:
	add_to_group("enemies")
	
	# Set initial direction
	direction = Vector2.RIGHT if randf() > 0.5 else Vector2.LEFT
	
	# Play walk animation and set initial sprite direction
	if sprite:
		sprite.play("walk")
		update_sprite_direction()
	
	# Start direction timer if it exists
	if dir_timer:
		dir_timer.start()
		# Connect timer signal only if not already connected
		if not dir_timer.timeout.is_connected(_on_direction_timer_timeout):
			dir_timer.timeout.connect(_on_direction_timer_timeout)
	else:
		push_warning("Ennemy1: No direction timer found. Random direction changes disabled.")

	# Connect signals only if nodes exist and not already connected
	if detection_area:
		if not detection_area.body_entered.is_connected(_on_player_detected):
			detection_area.body_entered.connect(_on_player_detected)
		if not detection_area.body_exited.is_connected(_on_player_lost):
			detection_area.body_exited.connect(_on_player_lost)
	else:
		push_warning("Ennemy1: No detection_area found. Player detection disabled.")
	
	if damage_area:
		if not damage_area.body_entered.is_connected(_on_player_entered_damage_zone):
			damage_area.body_entered.connect(_on_player_entered_damage_zone)
		if not damage_area.body_exited.is_connected(_on_player_exited_damage_zone):
			damage_area.body_exited.connect(_on_player_exited_damage_zone)
	else:
		push_warning("Ennemy1: No damage_area found. Damage system disabled.")

# ================= PHYSICS =================
func _physics_process(delta: float) -> void:
	rotation = 0

	# Apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Handle death state
	if is_dead:
		velocity.x = 0
		move_and_slide()
		return

	# Handle hit stun
	if is_hit_stunned:
		velocity.x = 0
		move_and_slide()
		return

	# Movement logic
	if is_chasing and is_instance_valid(player):
		var dir: float = sign(player.global_position.x - global_position.x)
		velocity.x = dir * SPEED
		direction.x = dir
	else:
		velocity.x = direction.x * SPEED
		check_edge()

	# Update sprite direction based on movement
	update_sprite_direction()
	
	# Process continuous damage for all players in contact
	process_continuous_damage()
	
	move_and_slide()

# ================= SPRITE DIRECTION =================
func update_sprite_direction() -> void:
	"""Update sprite facing direction based on movement direction"""
	if not sprite:
		return
	
	# Flip sprite based on direction (flip_h = true means facing LEFT)
	if direction.x > 0:
		sprite.flip_h = false  # Face RIGHT
	elif direction.x < 0:
		sprite.flip_h = true   # Face LEFT

# ================= EDGE CHECK =================
func check_edge() -> void:
	if not is_on_floor():
		return

	var space := get_world_2d().direct_space_state
	var start := global_position + Vector2(direction.x * EDGE_CHECK_DISTANCE, 0)
	var end := start + Vector2(0, EDGE_CHECK_DROP)

	var query := PhysicsRayQueryParameters2D.create(start, end)
	query.exclude = [self]
	query.collision_mask = 1

	if space.intersect_ray(query).is_empty():
		direction = -direction
		velocity.x = 0

# ================= DETECTION =================
func _on_player_detected(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		is_chasing = true

func _on_player_lost(body: Node2D) -> void:
	if body == player:
		is_chasing = false
		player = null

# Backward compatibility for scene connections
func _on_detection_area_body_entered(body: Node2D) -> void:
	_on_player_detected(body)

func _on_detection_area_body_exited(body: Node2D) -> void:
	_on_player_lost(body)

func _on_direction_timer_timeout() -> void:
	if not is_chasing:
		direction.x = 1.0 if randf() > 0.5 else -1.0

# ================= UNIFIED DAMAGE SYSTEM =================
func _on_player_entered_damage_zone(body: Node2D) -> void:
	"""Player entered damage area - register them and deal immediate damage"""
	if not body.is_in_group("player") or is_dead or is_hit_stunned:
		return
	
	# Register this player in our tracking dictionary
	players_in_contact[body] = 0.0  # Initialize with 0 so first damage is immediate
	
	# Deal immediate damage on contact
	attempt_damage_player(body)

func _on_player_exited_damage_zone(body: Node2D) -> void:
	"""Player left damage area - stop tracking them"""
	if body in players_in_contact:
		players_in_contact.erase(body)

func process_continuous_damage() -> void:
	"""Process damage for all players currently in contact (called every frame)"""
	if is_dead or is_hit_stunned:
		return
	
	var current_time := Time.get_ticks_msec() / 1000.0
	
	# Check each player in contact
	for body in players_in_contact.keys():
		if not is_instance_valid(body):
			players_in_contact.erase(body)
			continue
		
		var last_damage_time: float = players_in_contact[body]
		
		# Check if cooldown has passed
		if current_time - last_damage_time >= DAMAGE_COOLDOWN:
			attempt_damage_player(body)

func attempt_damage_player(body: Node) -> void:
	"""Single unified function to deal damage to player"""
	if is_dead or is_hit_stunned:
		return
	
	if not is_instance_valid(body):
		return
	
	# Update last damage time
	var current_time := Time.get_ticks_msec() / 1000.0
	players_in_contact[body] = current_time
	
	# Enter hit stun
	is_hit_stunned = true
	velocity.x = 0
	
	# Deal damage
	if body.has_method("take_damage"):
		body.take_damage(damage)
	
	# Apply knockback to player
	apply_knockback(body)
	
	# Push enemy back slightly to prevent stacking
	if body is CharacterBody2D:
		var push_dir: float = -sign(body.global_position.x - global_position.x)
		if push_dir == 0:
			push_dir = -direction.x
		velocity.x = push_dir * SPEED * 0.5  # Half speed pushback
	
	# Exit hit stun after delay
	await get_tree().create_timer(HIT_STUN_TIME).timeout
	is_hit_stunned = false

# ================= KNOCKBACK =================
func apply_knockback(body: Node) -> void:
	"""Apply knockback force to player"""
	if not body is CharacterBody2D:
		return
	
	var dir: float = sign(body.global_position.x - global_position.x)
	if dir == 0:
		dir = direction.x
	
	# Horizontal knockback only - no vertical component
	var knock := Vector2(dir * KNOCKBACK_FORCE, 0)
	
	if body.has_method("apply_knockback"):
		body.apply_knockback(knock)
	else:
		body.velocity.x = knock.x

# ================= DAMAGE TAKEN =================
func take_damage(amount: int) -> void:
	"""Enemy takes damage"""
	if is_dead:
		return
	
	health -= amount
	
	# Play hurt animation
	if sprite and sprite.sprite_frames.has_animation("hurt"):
		sprite.play("hurt")
		# Return to walk animation after hurt animation
		await get_tree().create_timer(0.3).timeout
		if sprite and not is_dead:
			sprite.play("walk")
	
	# Check for death
	if health <= 0:
		die()

# ================= DEATH =================
func die() -> void:
	"""Handle enemy death"""
	is_dead = true
	velocity = Vector2.ZERO
	
	# Play death animation if it exists
	if sprite:
		if sprite.sprite_frames.has_animation("death"):
			sprite.play("death")
		else:
			# Fallback visual effect if no death animation
			sprite.modulate = Color(1, 0, 0, 0.5)  # Red tint
	
	# Disable collisions
	set_collision_layer(0)
	set_collision_mask(0)
	
	# Disable areas
	if detection_area:
		detection_area.monitoring = false
	if damage_area:
		damage_area.monitoring = false
	
	# Clear player tracking
	players_in_contact.clear()
	
	# Remove after death animation
	await get_tree().create_timer(DEATH_DURATION).timeout
	queue_free()
