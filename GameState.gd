extends Node

var player: Node2D
var saved_player_position: Vector2 = Vector2.ZERO
var has_saved_position: bool = false

func _ready():
	if has_node("Player"):
		player = $Player
	else:
		push_error("Player node not found!")

	# Si on a une position sauvegardée, respawn le joueur
	if has_saved_position:
		player.global_position = saved_player_position

func _physics_process(_delta):
	if Input.is_action_just_pressed("Option_In_Game") and player != null:
		# Sauvegarde la position avant de passer à Options
		saved_player_position = player.global_position
		has_saved_position = true
		get_tree().change_scene_to_file("res://scene/Option_In_Game_Folder/Option_In_Game.tscn")
