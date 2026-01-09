extends CharacterBody2D
class_name Ennemy1

# Constants
const SPEED = 100
const GRAVITY = 800
const KNOCKBACK_FORCE = 200

# Health
var health: int = 80
var health_max: int = 80
var health_min: int = 0
var dead: bool = false
var taking_damage: bool = false

# Combat
var damage_to_deal: int = 20
var is_dealing_damage: bool = false

# Movement
var is_chasing: bool = false
var is_roaming: bool = true
var dir: Vector2 = Vector2.ZERO

# References
var player: CharacterBody2D
var detection_area: Area2D
var direction_timer: Timer
var anim_sprite: AnimatedSprite2D

func _ready():
	setup_references()
	connect_signals()

func setup_references():
	# Cache node references
	detection_area = get_node_or_null("detection_area")
	direction_timer = get_node_or_null("DirectionTimer")
	anim_sprite = get_node_or_null("AnimatedSprite2D")
	
	if detection_area == null:
		push_error("detection_area not found!")
	if direction_timer == null:
		push_error("DirectionTimer not found!")
	if anim_sprite == null:
		push_error("AnimatedSprite2D not found!")

func connect_signals():
	if detection_area:
		if !detection_area.body_entered.is_connected(_on_detection_area_body_entered):
			detection_area.body_entered.connect(_on_detection_area_body_entered)
		if !detection_area.body_exited.is_connected(_on_detection_area_body_exited):
			detection_area.body_exited.connect(_on_detection_area_body_exited)
	
	if direction_timer and !direction_timer.timeout.is_connected(_on_direction_timer_timeout):
		direction_timer.timeout.connect(_on_direction_timer_timeout)

func _process(delta):
	apply_gravity(delta)
	find_player()
	move(delta)
	handle_animation()
	move_and_slide()

func apply_gravity(delta):
	if !is_on_floor():
		velocity.y += GRAVITY * delta
		velocity.x = 0

func find_player():
	if player == null:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]

func move(delta):
	if dead:
		velocity.x = 0
		return
	
	if is_chasing and player and !taking_damage:
		chase_player()
	elif !is_chasing:
		roam(delta)

func chase_player():
	var direction = position.direction_to(player.position)
	velocity.x = direction.x * SPEED
	velocity.y = 0

func roam(delta):
	velocity += dir * SPEED * delta

func handle_animation():
	if !anim_sprite:
		return
	
	if dead:
		handle_death_animation()
	elif taking_damage:
		handle_damage_animation()
	else:
		handle_walk_animation()

func handle_walk_animation():
	anim_sprite.play("walk")
	
	if is_chasing and player:
		anim_sprite.flip_h = velocity.x < 0
	else:
		anim_sprite.flip_h = dir.x < 0

func handle_damage_animation():
	anim_sprite.play("hurt")
	await get_tree().create_timer(0.8).timeout
	taking_damage = false

func handle_death_animation():
	if is_roaming:
		is_roaming = false
		anim_sprite.play("death")
		await get_tree().create_timer(1.0).timeout
		queue_free()

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		is_chasing = true

func _on_detection_area_body_exited(body):
	if body.is_in_group("player"):
		is_chasing = false

func _on_direction_timer_timeout():
	if direction_timer:
		direction_timer.wait_time = randf_range(1.0, 2.5)
	
	if !is_chasing:
		dir = Vector2.RIGHT if randf() > 0.5 else Vector2.LEFT
		velocity.x = 0

func take_damage(amount: int):
	if dead:
		return
	
	health -= amount
	taking_damage = true
	
	if health <= health_min:
		dead = true
