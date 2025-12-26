extends Node

var save_path = "user://variable.save"
var player: Node2D
var saved_player_position: Vector2 = Vector2.ZERO
var has_saved_position: bool = false
var slime: Node2D
var saved_slime_position: Vector2 = Vector2.ZERO
var slime_has_saved_position: bool = false

func _ready():
	load_data()
	
	if has_node("Ennemy1"):
		slime = $Ennemy1
	else:
		push_error("Slime not found!")
		
	if slime != null and slime_has_saved_position:
		slime.global_position = saved_slime_position
		
	if has_node("Player"):
		player = $Player
	else:
		push_error("Player node not found!")
		return
	
	# Si on a une position sauvegardée, respawn le joueur
	if has_saved_position:
		player.global_position = saved_player_position

func _physics_process(_delta):
	if Input.is_action_just_pressed("Option_In_Game") and player != null:
		# Sauvegarde la position avant de passer à Options
		saved_player_position = player.global_position
		has_saved_position = true
		
		# Sauvegarder la position du slime seulement s'il existe
		if slime != null:
			saved_slime_position = slime.global_position
			slime_has_saved_position = true
		
		save()  # Sauvegarde avant de changer de scène
		get_tree().change_scene_to_file("res://scene/Option_In_Game_Folder/Option_In_Game.tscn")

func save():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_var(saved_player_position)
	file.store_var(has_saved_position)
	file.store_var(saved_slime_position)
	file.store_var(slime_has_saved_position)
	file.close()

func load_data():
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		
		# Lire les données du joueur (toujours présentes)
		saved_player_position = file.get_var()
		has_saved_position = file.get_var()
		
		# Vérifier s'il y a plus de données (nouveau format)
		if file.get_position() < file.get_length():
			saved_slime_position = file.get_var()
			slime_has_saved_position = file.get_var()
		else:
			# Ancien format - pas de données pour le slime
			saved_slime_position = Vector2.ZERO
			slime_has_saved_position = false
			print("Old save format detected - slime data not found")
		
		file.close()
	else:
		print("no data saved")
		has_saved_position = false
		slime_has_saved_position = false
