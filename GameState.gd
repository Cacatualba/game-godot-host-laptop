extends Node

const SAVE_PATH = "user://variable.save"

var player: Node2D
var slime: Node2D  # ← En minuscule (convention Godot)

var saved_data := {
	"player_position": Vector2.ZERO,
	"player_exists": false,
}

# Positions de spawn par défaut des ennemis
const ENEMY_DEFAULT_SPAWNS = {
	"Slime": Vector2( 5566.0, 1827.0),
	"Slime2": Vector2(2446.0, 2636.0),
	"Slime3": Vector2(6127.0, 1834.0),
}

func _ready():
	load_data()
	spawn_enemies_at_default_positions()
	setup_entities()
	
func _process(_delta):
	if $AudioStreamPlayer1.playing == false:
		$AudioStreamPlayer1.play()
		
	
pass

func spawn_enemies_at_default_positions():
	print("=== SPAWNING ENEMIES ===")
	for enemy_name in ENEMY_DEFAULT_SPAWNS.keys():
		var enemy_pos = ENEMY_DEFAULT_SPAWNS[enemy_name]
		
		var enemy = get_node_or_null(enemy_name)
		if enemy == null:
			push_warning("Enemy '", enemy_name, "' not found in scene - skipping")
			continue
		
		# Vérifier si on a une position sauvegardée pour cet ennemi
		var saved_key = enemy_name.to_lower() + "_position"
		if saved_data.has(saved_key):
			enemy.global_position = saved_data[saved_key]
			print("✅ Spawned ", enemy_name, " at SAVED position: ", saved_data[saved_key])
		else:
			enemy.global_position = enemy_pos
			print("✅ Spawned ", enemy_name, " at DEFAULT position: ", enemy_pos)
		
		# ← AJOUTE CES LIGNES DE DEBUG
		print("  📍 Enemy actual position: ", enemy.global_position)
		print("  👁️ Enemy visible: ", enemy.visible)
		print("  📦 Enemy Z-index: ", enemy.z_index)
		print("  🎨 Enemy modulate: ", enemy.modulate)
		if enemy.has_node("AnimatedSprite2D"):
			var sprite = enemy.get_node("AnimatedSprite2D")
			print("  🖼️ Sprite visible: ", sprite.visible)
			print("  🎬 Sprite playing: ", sprite.is_playing())
	
	print("========================")
func setup_entities():
	# Setup Player
	player = get_node_or_null("Player")
	if player == null:
		push_error("Player node not found!")
		return
	
	if saved_data.has("player_position") and saved_data.player_exists:
		player.global_position = saved_data.player_position
		print("✅ Player spawned at SAVED position: ", saved_data.player_position)
	else:
		print("✅ Player at default position: ", player.global_position)
	
	# Cache Slime reference
	slime = get_node_or_null("Slime")

func _physics_process(_delta):
	if Input.is_action_just_pressed("Option_In_Game") and player != null:
		save_and_transition()

func save_and_transition():
	save_all_positions()
	save()
	get_tree().change_scene_to_file("res://scene/Option_In_Game_Folder/Option_In_Game.tscn")

func save_all_positions():
	# Save player
	saved_data.player_position = player.global_position
	saved_data.player_exists = true
	
	# Save ALL enemies
	print("💾 Saving all entity positions...")
	for enemy_name in ENEMY_DEFAULT_SPAWNS.keys():
		var enemy = get_node_or_null(enemy_name)
		if enemy != null:
			var key = enemy_name.to_lower() + "_position"
			saved_data[key] = enemy.global_position
			print("  - ", enemy_name, ": ", enemy.global_position)

func save():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to save data!")
		return
	
	file.store_var(saved_data)
	file.close()
	print("✅ Data saved successfully!")

func load_data():
	if !FileAccess.file_exists(SAVE_PATH):
		print("No save file found - starting fresh")
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to load save data!")
		return
	
	var loaded_data = file.get_var()
	file.close()
	
	if loaded_data is Dictionary:
		saved_data.merge(loaded_data)  # ← Merge au lieu de remplacer
		print("✅ Save data loaded successfully!")
	else:
		migrate_old_format(loaded_data)

func migrate_old_format(first_var):
	print("⚠️ Migrating old save format...")
	saved_data.player_position = first_var
	saved_data.player_exists = true
	save()
