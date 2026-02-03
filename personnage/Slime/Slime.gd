extends CharacterBody2D
class_name Ennemy1

# ================= CONSTANTS =================
const SPEED := 100.0
const GRAVITY := 300.0
const KNOCKBACK_FORCE := 300.0
const EDGE_CHECK_DISTANCE := 25.0
const EDGE_CHECK_DROP := 30.0

const HIT_STUN_TIME := 0.2
const DAMAGE_COOLDOWN := 1.0
const DEATH_DURATION := 1.0
const EDGE_CHECK_COOLDOWN := 0.1
const DIRECTION_CHANGE_COOLDOWN := 0.5

# ================= STATE =================
@export var health := 80
@export var damage := 1

var is_dead := false
var is_chasing := false
var is_hit_stunned := false
var direction := 1.0
var last_edge_check_time := 0.0
var last_direction_change_time := 0.0

# DEBUG
var debug_frame_count := 0
var last_debug_time := 0.0

# Track which players are currently in contact (for continuous damage)
var players_in_contact: Dictionary = {}

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
	direction = 1.0 if randf() > 0.5 else -1.0
	print("=== ENEMY SPAWNED: ", name, " ===")
	print("  Initial direction: ", direction)
	print("  Position: ", global_position)
	
	# Play walk animation and set initial sprite direction
	if sprite:
		sprite.play("walk")
		update_sprite_direction()
	
	# Start direction timer if it exists
	if dir_timer:
		dir_timer.wait_time = 10.0
		dir_timer.start()
		if not dir_timer.timeout.is_connected(_on_direction_timer_timeout):
			dir_timer.timeout.connect(_on_direction_timer_timeout)
	else:
		push_warning("Ennemy1: No direction timer found. Random direction changes disabled.")

	# Connect signals
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
	debug_frame_count += 1

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

	# Get current time
	var current_time := Time.get_ticks_msec() / 1000.0
	var should_check_edge := (current_time - last_edge_check_time) >= EDGE_CHECK_COOLDOWN
	var can_change_direction := (current_time - last_direction_change_time) >= DIRECTION_CHANGE_COOLDOWN

	# DEBUG: Print every 2 seconds
	if current_time - last_debug_time >= 2.0:
		print("\n=== DEBUG [", name, "] Frame: ", debug_frame_count, " ===")
		print("  🧭 direction: ", direction)
		print("  🏃 velocity: ", velocity)
		print("  📍 position: ", global_position)
		print("  🟢 is_on_floor: ", is_on_floor())
		print("  👤 is_chasing: ", is_chasing)
		print("  😵 is_hit_stunned: ", is_hit_stunned)
		print("  ⏱️ should_check_edge: ", should_check_edge)
		print("  🔄 can_change_direction: ", can_change_direction)
		print("  ⏰ last_direction_change: ", current_time - last_direction_change_time, "s ago")
		
		# Check edges in both directions
		var left_edge = is_edge_ahead(-1.0)
		var right_edge = is_edge_ahead(1.0)
		print("  ⬅️ LEFT edge detected: ", left_edge)
		print("  ➡️ RIGHT edge detected: ", right_edge)
		
		last_debug_time = current_time

	# Store old direction for comparison
	var old_direction = direction

	# Movement logic
	if is_chasing and is_instance_valid(player):
		print("  [CHASE MODE]")
		var dir: float = sign(player.global_position.x - global_position.x)
		
		# Check for edge before moving while chasing
		if should_check_edge and is_edge_ahead(dir):
			last_edge_check_time = current_time
			velocity.x = 0
			print("  ❌ CHASE BLOCKED by edge at dir: ", dir)
			# Stop chasing if player is across a gap
			if abs(player.global_position.x - global_position.x) > EDGE_CHECK_DISTANCE * 3:
				is_chasing = false
				player = null
				print("  👋 Stopped chasing - player too far")
		else:
			velocity.x = dir * SPEED
			direction = dir
			print("  ✅ CHASE velocity set: ", velocity.x)
	else:
		# Patrol mode - only check edges when on floor
		print("  [PATROL MODE]")
		
		# Set velocity first
		velocity.x = direction * SPEED
		print("    ➡️ Setting velocity.x = ", direction, " * ", SPEED, " = ", velocity.x)
		
		# Only check for edges/walls when on the floor and able to change direction
		if is_on_floor() and should_check_edge and can_change_direction:
			var edge_detected = is_edge_ahead(direction)
			print("    🔍 Checking edge in direction ", direction, ": ", edge_detected)
			
			if edge_detected:
				last_edge_check_time = current_time
				last_direction_change_time = current_time
				direction = -direction
				velocity.x = direction * SPEED
				print("    🔄 DIRECTION CHANGED from ", old_direction, " to ", direction)

	# Update sprite direction based on movement
	update_sprite_direction()
	
	# Process continuous damage for all players in contact
	process_continuous_damage()
	
	# Store velocity before move_and_slide
	var velocity_before = velocity.x
	
	move_and_slide()
	
	# Check if we hit a wall (velocity was stopped by collision)
	if is_on_floor() and abs(velocity_before) > 0.1 and abs(velocity.x) < 0.1:
		var current_time_now := Time.get_ticks_msec() / 1000.0
		if (current_time_now - last_direction_change_time) >= DIRECTION_CHANGE_COOLDOWN:
			print("  🧱 HIT WALL! Changing direction from ", direction, " to ", -direction)
			last_direction_change_time = current_time_now
			direction = -direction
	
	# Check if velocity changed after move_and_slide
	if abs(velocity.x - velocity_before) > 0.1:
		print("  ⚠️ Velocity changed by move_and_slide!")
		print("    Before: ", velocity_before)
		print("    After: ", velocity.x)

# ================= SPRITE DIRECTION =================
func update_sprite_direction() -> void:
	"""Update sprite facing direction based on movement direction"""
	if not sprite:
		return
	
	if direction > 0:
		sprite.flip_h = false  # Face RIGHT
	elif direction < 0:
		sprite.flip_h = true   # Face LEFT

# ================= EDGE CHECK =================
func is_edge_ahead(dir: float) -> bool:
	"""Check if there's an edge in the given direction. Returns true if edge detected."""
	if not is_on_floor():
		return false
	
	var space := get_world_2d().direct_space_state
	var start := global_position + Vector2(dir * EDGE_CHECK_DISTANCE, 10)
	var end := start + Vector2(0, EDGE_CHECK_DROP)
	
	var query := PhysicsRayQueryParameters2D.create(start, end)
	query.exclude = [self]
	query.collision_mask = 1
	
	# If raycast hits nothing, there's an edge
	var result = space.intersect_ray(query)
	return result.is_empty()

func check_edge() -> void:
	"""Legacy edge check function"""
	var current_time := Time.get_ticks_msec() / 1000.0
	if (current_time - last_edge_check_time) < EDGE_CHECK_COOLDOWN:
		return
	
	if (current_time - last_direction_change_time) < DIRECTION_CHANGE_COOLDOWN:
		return
	
	if is_edge_ahead(direction):
		last_edge_check_time = current_time
		last_direction_change_time = current_time
		direction = -direction

# ================= DETECTION =================
func _on_player_detected(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		is_chasing = true
		print("  🎯 Player detected! Starting chase.")

func _on_player_lost(body: Node2D) -> void:
	if body == player:
		is_chasing = false
		player = null
		print("  👋 Player lost! Returning to patrol.")

func _on_detection_area_body_entered(body: Node2D) -> void:
	_on_player_detected(body)

func _on_detection_area_body_exited(body: Node2D) -> void:
	_on_player_lost(body)

func _on_direction_timer_timeout() -> void:
	if not is_chasing:
		var old_dir = direction
		direction = 1.0 if randf() > 0.5 else -1.0
		print("  ⏰ Timer timeout! Direction changed from ", old_dir, " to ", direction)

# ================= UNIFIED DAMAGE SYSTEM =================
func _on_player_entered_damage_zone(body: Node2D) -> void:
	if not body.is_in_group("player") or is_dead or is_hit_stunned:
		return
	
	players_in_contact[body] = 0.0
	attempt_damage_player(body)

func _on_player_exited_damage_zone(body: Node2D) -> void:
	if body in players_in_contact:
		players_in_contact.erase(body)

func process_continuous_damage() -> void:
	if is_dead or is_hit_stunned:
		return
	
	var current_time := Time.get_ticks_msec() / 1000.0
	
	for body in players_in_contact.keys():
		if not is_instance_valid(body):
			players_in_contact.erase(body)
			continue
		
		var last_damage_time: float = players_in_contact[body]
		
		if current_time - last_damage_time >= DAMAGE_COOLDOWN:
			attempt_damage_player(body)

func attempt_damage_player(body: Node) -> void:
	if is_dead or is_hit_stunned:
		return
	
	if not is_instance_valid(body):
		return
	
	var current_time := Time.get_ticks_msec() / 1000.0
	players_in_contact[body] = current_time
	
	is_hit_stunned = true
	velocity.x = 0
	
	if body.has_method("take_damage"):
		body.take_damage(damage)
	
	apply_knockback(body)
	
	if body is CharacterBody2D:
		var push_dir: float = -sign(body.global_position.x - global_position.x)
		if push_dir == 0:
			push_dir = -direction
		velocity.x = push_dir * SPEED * 0.5
	
	await get_tree().create_timer(HIT_STUN_TIME).timeout
	is_hit_stunned = false

# ================= KNOCKBACK =================
func apply_knockback(body: Node) -> void:
	if not body is CharacterBody2D:
		return
	
	var dir: float = sign(body.global_position.x - global_position.x)
	if dir == 0:
		dir = direction
	
	var knock := Vector2(dir * KNOCKBACK_FORCE, 0)
	
	if body.has_method("apply_knockback"):
		body.apply_knockback(knock)
	else:
		body.velocity.x = knock.x

# ================= DAMAGE TAKEN =================
func take_damage(amount: int) -> void:
	if is_dead:
		return
	
	health -= amount
	
	if sprite and sprite.sprite_frames.has_animation("hurt"):
		sprite.play("hurt")
		await get_tree().create_timer(0.3).timeout
		if sprite and not is_dead:
			sprite.play("walk")
	
	if health <= 0:
		die()

# ================= DEATH =================
func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	
	if sprite:
		if sprite.sprite_frames.has_animation("death"):
			sprite.play("death")
		else:
			sprite.modulate = Color(1, 0, 0, 0.5)
	
	set_collision_layer(0)
	set_collision_mask(0)
	
	if detection_area:
		detection_area.monitoring = false
	if damage_area:
		damage_area.monitoring = false
	
	players_in_contact.clear()
	
	await get_tree().create_timer(DEATH_DURATION).timeout
	queue_free()
