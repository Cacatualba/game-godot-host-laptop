
func _ready():
	var button_discord = Button.new()
	

	button_discord.pressed.connect(on_start_game_pressed)

func on_start_game_pressed():
	print("")
