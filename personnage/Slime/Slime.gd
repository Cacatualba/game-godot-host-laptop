extends CharacterBody2D
class_name Ennemy1

# Constants
const SPEED = 100
const GRAVITY = 300
const KNOCKBACK_FORCE = 300

# Health
@export var health: int = 80
@export var health_max: int = 80
var dead: bool = false
var taking_damage: bool = false

# Combat
@export var damage_to_deal: int = 20
@export var damage_cooldown: float = 1.0  # Time between damage ticks
var last_damage_time: float = 0.0

# Movement
var is_chasing: bool = false
var dir: Vector2 = Vector2.RIGHT

# References
var player: CharacterBody2D
@onready var detection_area: Area2D = $detection_area
@onready var damage_area: Area2D = $damage_area
@onready var direction_timer: Timer = $DirectionTimer
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	rotation_degrees = 0
	setup_damage_area()
	connect_signals()
	initialize_enemy()

func initialize_enemy():
	if anim_sprite:
		anim_sprite.play("walk")
	
	dir = Vector2.RIGHT if randf() > 0.5 else Vector2.LEFT
	direction_timer.start()

func setup_damage_area():
	# Create damage area if it doesn't exist
	if !damage_area:
		damage_area = Area2D.new()
		damage_area.name = "damage_area"
		damage_area.collision_layer = 0  # Don't collide with anything
		damage_area.collision_mask = 2  # Only detect player layer (adjust if needed)
		add_child(damage_area)
		
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 25  # Circular area covering the slime
		collision.shape = shape
		collision.position = Vector2.ZERO  # Centered on the slime
		damage_area.add_child(collision)

func connect_signals():
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)
	
	if damage_area:
		damage_area.body_entered.connect(_on_damage_area_body_entered)
	
	if direction_timer:
		direction_timer.timeout.connect(_on_direction_timer_timeout)

func _physics_process(delta):
	rotation = 0
	
	find_player()
	apply_gravity(delta)
	
	if is_on_floor() and !is_chasing:
		check_edge()
	
	check_player_contact()
	move()
	update_sprite_direction()
	move_and_slide()

func apply_gravity(delta):
	if !is_on_floor():
		velocity.y += GRAVITY * delta

func check_edge():
	var space_state = get_world_2d().direct_space_state
	var check_pos = position + Vector2(dir.x * 20, 0)
	
	var query = PhysicsRayQueryParameters2D.create(
		check_pos,
		check_pos + Vector2(0, 30)
	)
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	
	if result.is_empty():
		dir = -dir
		velocity.x = 0

func check_player_contact():
	if !damage_area or !player or dead:
		return
	
	var overlapping_bodies = damage_area.get_overlapping_bodies()
	for body in overlapping_bodies:
		if body.is_in_group("player"):
			apply_damage_to_player(body)
			return

func find_player():
	if !player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]

func move():
	if dead:
		velocity.x = 0
		return
	
	if is_chasing and player and !taking_damage:
		var direction = (player.position - position).normalized()
		velocity.x = direction.x * SPEED
		dir.x = sign(direction.x) if direction.x != 0 else dir.x
	else:
		velocity.x = dir.x * SPEED

func update_sprite_direction():
	if anim_sprite and velocity.x != 0:
		anim_sprite.flip_h = velocity.x < 0

func _process(_delta):
	if !anim_sprite or dead:
		return
	
	if taking_damage:
		anim_sprite.play("hurt")
	else:
		anim_sprite.play("walk")

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		is_chasing = true

func _on_detection_area_body_exited(body):
	if body.is_in_group("player"):
		is_chasing = false

func _on_damage_area_body_entered(body):
	if body.is_in_group("player") and !dead:
		apply_damage_to_player(body)

func apply_damage_to_player(player_body):
	if dead:
		return
	
	# Check cooldown
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_damage_time < damage_cooldown:
		return
	
	last_damage_time = current_time
	
	if player_body.has_method("take_damage"):
		player_body.take_damage(damage_to_deal)
	
	apply_knockback_to_player(player_body)

func apply_knockback_to_player(player_body):
	# Calculate horizontal knockback direction
	var knockback_dir_x = sign(player_body.global_position.x - global_position.x)
	
	# If player is exactly at center, use slime's facing direction
	if knockback_dir_x == 0:
		knockback_dir_x = dir.x
	
	# Add upward component for knockback
	var knockback_vector = Vector2(knockback_dir_x * KNOCKBACK_FORCE, -KNOCKBACK_FORCE * 0.5)
	
	if player_body.has_method("apply_knockback"):
		player_body.apply_knockback(knockback_vector)
	elif player_body is CharacterBody2D:
		player_body.velocity = knockback_vector

func _on_direction_timer_timeout():
	if !is_chasing:
		dir.x = 1 if randf() > 0.5 else -1
		velocity.x = 0

func take_damage(amount: int):
	if dead:
		return
	
	health -= amount
	taking_damage = true
	
	if health <= 0:
		dead = true
		if anim_sprite:
			anim_sprite.play("death")
		await get_tree().create_timer(1.0).timeout
		queue_free()
	else:
		await get_tree().create_timer(0.8).timeout
		taking_damage = false
