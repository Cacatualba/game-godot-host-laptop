extends Control

func _ready():
	$VBoxContainer/Quit.grab_click_focus()

func _on_quit_pressed():
	print("credits button work3")
	get_tree().change_scene_to_file("res://scene/menu/menu.tscn")
	print("credits button work4")
