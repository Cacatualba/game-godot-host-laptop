extends CharacterBody2D
class_name Ennemy1
const speed = 100
var is_Ennemy1_chase: bool = false
var health = 80
var health_max = 80
var health_min = 0
var dead: bool = false
var taking_damage: bool = false
var damage_to_deal = 20
var is_dealing_damage: bool = false
var dir: Vector2
const gravity = 800
var knockback_force = 200
var is_roaming: bool = true
var player: CharacterBody2D
var player_in_area = false

# ← ENLÈVE func _ready() complètement!

func _process(delta):
	if !is_on_floor():
		velocity.y += gravity * delta
		velocity.x = 0
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	
	move(delta)
	handle_animation()
	move_and_slide()

func move(delta):
	if !dead:
		if !is_Ennemy1_chase:
			velocity += dir * speed * delta
		elif is_Ennemy1_chase and !taking_damage:
			if player:
				var dir_to_player = position.direction_to(player.position) * speed
				velocity.x = dir_to_player.x
				velocity.y = 0
		is_roaming = true
	elif dead:
		velocity.x = 0

func _on_detection_area_body_entered(body):
	print("Body entered: ", body.name)
	if body.is_in_group("player"):
		print("Player detected! Chase = true")
		is_Ennemy1_chase = true

func _on_detection_area_body_exited(body):
	print("Body exited: ", body.name)
	if body.is_in_group("player"):
		print("Player left! Chase = false")
		is_Ennemy1_chase = false

func handle_animation():
	var anim_sprite = $AnimatedSprite2D
	if !dead and !taking_damage and !is_dealing_damage:
		anim_sprite.play("walk")
		if is_Ennemy1_chase and player:
			anim_sprite.flip_h = velocity.x < 0
		else:
			if dir.x == -1:
				anim_sprite.flip_h = true
			elif dir.x == 1:
				anim_sprite.flip_h = false
	elif !dead and taking_damage and !is_dealing_damage:
		anim_sprite.play("hurt")
		await get_tree().create_timer(0.8).timeout
		taking_damage = false
	elif dead and is_roaming:
		is_roaming = false
		anim_sprite.play("death")
		await get_tree().create_timer(1.0).timeout
		handle_death()

func handle_death():
	self.queue_free()

func _on_direction_timer_timeout():
	$DirectionTimer.wait_time = choose([1.0, 1.5, 2.0, 2.5])
	if !is_Ennemy1_chase:
		dir = choose([Vector2.RIGHT, Vector2.LEFT])
		velocity.x = 0

func choose(array):
	array.shuffle()
	return array.front()
