extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	$VBoxContainer/StartButton.grab_click_focus()


func _on_start_button_pressed():
	print("BUTTON WORKS1")
	get_tree().change_scene_to_file("res://scene/scene 1/scene1.tscn")
	print("BUTTON WORK2S")

func _on_options_button_pressed():
	print("option button work")
	get_tree().change_scene_to_file("res://scene/Option/Option.tscn")
	print("option button work2")

func _on_quit_button_pressed():
	get_tree().quit()

func _on_credits_pressed():
	print("option button work")
	get_tree().change_scene_to_file("res://scene/Credits/Credits.tscn")
	print("option button work2")
