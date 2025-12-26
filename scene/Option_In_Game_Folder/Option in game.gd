extends Control

# Variables assignées depuis la scène principale
var saved_player_position: Vector2
var came_from_main: bool = false

func _ready():
	if has_node("ReturnButton"):
		$ReturnButton.pressed.connect(_on_return_button_pressed)

func _on_return_button_pressed():
	get_tree().change_scene_to_file("res://scene/scene 1/scene1.tscn")
