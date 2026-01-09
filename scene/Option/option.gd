extends Control

var save_path = "user://variable.save"

func _ready():
	$quit1/quit2.grab_click_focus()


func _on_quit_2_pressed():
	print("credits button work3")
	get_tree().change_scene_to_file("res://scene/menu/menu.tscn")
	print("credits button work4")


func _on_button_1_pressed() -> void:
	delete_save_data()

func delete_save_data():
	var save_path = "user://variable.save"
	
	if FileAccess.file_exists(save_path):
		var dir = DirAccess.open("user://")
		if dir:
			var error = dir.remove(save_path)
			if error == OK:
				print("✅ Save data deleted successfully!")
			else:
				push_error("❌ Failed to delete save data. Error: " + str(error))
		else:
			push_error("❌ Failed to access user directory!")
	else:
		print("⚠️ No save data found to delete")
