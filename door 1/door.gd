extends Node2D

func _ready():
	# Make the door invisible at start
	$player.visible = false

func _on_trigger_area_door_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		$player.visible = true  # Show door when player enters
		open_door()

func _on_trigger_area_door_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		close_door()
		$player.visible = false  # Hide door when player leaves

func open_door():
	$player.play("open")
	$collision.disabled = true

func close_door():
	$player.play("close")
	$collision.disabled = false
