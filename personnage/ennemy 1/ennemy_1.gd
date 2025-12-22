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

func _ready():
	print("=== ENNEMY INITIALIZED ===")
	print("Ennemy position: ", position)
	print("Looking for detection_area...")
	
	if has_node("detection_area"):
		print("✅ detection_area FOUND!")
		var area = get_node("detection_area")
		print("Area position: ", area.position)
		
		# Vérifier si les signaux sont connectés
		if !area.body_entered.is_connected(_on_detection_area_body_entered):
			print("⚠️ WARNING: body_entered NOT CONNECTED! Connecting now...")
			area.body_entered.connect(_on_detection_area_body_entered)
		else:
			print("✅ body_entered is connected")
			
		if !area.body_exited.is_connected(_on_detection_area_body_exited):
			print("⚠️ WARNING: body_exited NOT CONNECTED! Connecting now...")
			area.body_exited.connect(_on_detection_area_body_exited)
		else:
			print("✅ body_exited is connected")
	else:
		print("❌ ERROR: detection_area NOT FOUND!")
	
	# Vérifier le DirectionTimer
	if has_node("DirectionTimer"):
		print("✅ DirectionTimer found")
		if !$DirectionTimer.timeout.is_connected(_on_direction_timer_timeout):
			print("⚠️ Connecting DirectionTimer...")
			$DirectionTimer.timeout.connect(_on_direction_timer_timeout)
	else:
		print("❌ DirectionTimer NOT FOUND!")
	
	print("=========================")

func _process(delta):
	if !is_on_floor():
		velocity.y += gravity * delta
		velocity.x = 0
	
	# Debug: Chercher le joueur
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		if player == null:
			print("🎮 PLAYER FOUND IN GROUP!")
		player = players[0]
	else:
		if Engine.get_frames_drawn() % 60 == 0:  # Afficher chaque seconde
			print("⚠️ NO PLAYER IN 'player' GROUP!")
	
	move(delta)
	handle_animation()
	move_and_slide()

func move(delta):
	if !dead:
		if !is_Ennemy1_chase:
			# Mode roaming
			velocity += dir * speed * delta
		elif is_Ennemy1_chase and !taking_damage:
			# Mode chase
			if player:
				var dir_to_player = position.direction_to(player.position) * speed
				velocity.x = dir_to_player.x
				velocity.y = 0
				
				# Debug chase
				if Engine.get_frames_drawn() % 30 == 0:  # Toutes les 0.5 secondes
					print("🏃 CHASING PLAYER!")
					print("  - Ennemy pos: ", position)
					print("  - Player pos: ", player.position)
					print("  - Velocity.x: ", velocity.x)
					print("  - Distance: ", position.distance_to(player.position))
			else:
				print("❌ is_Ennemy1_chase=true but player is NULL!")
		is_roaming = true
	elif dead:
		velocity.x = 0

func _on_detection_area_body_entered(body):
	print("=================================================================================================================================================")
	print("🚨 BODY ENTERED DETECTION AREA!")
	print("  - Body name: ", body.name)
	print("  - Body class: ", body.get_class())
	print("  - Body groups: ", body.get_groups())
	
	if body.is_in_group("player"):
		print("✅ IT'S THE PLAYER! Starting chase!")
		is_Ennemy1_chase = true
		print("  - is_Ennemy1_chase = ", is_Ennemy1_chase)
	else:
		print("❌ Not the player (not in 'player' group)")
	print("=================================================================================================================================================")

func _on_detection_area_body_exited(body):
	print("=================================================================================================================================================")
	print("👋 BODY EXITED DETECTION AREA!")
	print("  - Body name: ", body.name)
	
	if body.is_in_group("player"):
		print("✅ Player left! Stopping chase")
		is_Ennemy1_chase = false
		print("  - is_Ennemy1_chase = ", is_Ennemy1_chase)
	print("=================================================================================================================================================")

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
		print("🔄 Direction changed: ", dir)

func choose(array):
	array.shuffle()
	return array.front()
