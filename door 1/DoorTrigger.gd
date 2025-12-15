extends Node2D
@onready var door_sprite = $Door
@onready var door_collision = $StaticBody2D/Collision
@onready var trigger_area = $Trigger_Area
var box_player_in = 0

func _ready():
	door_sprite.visible = false
	door_collision.set_deferred("disabled", true)
	trigger_area.body_entered.connect(_on_trigger_area_body_entered)

func _on_trigger_area_body_entered(body):
	# NO while loop! Just check once:
	if body.is_in_group("player") and box_player_in == 0:
		door_sprite.visible = true
		door_sprite.modulate.a = 0
		var tween = create_tween()
		tween.tween_property(door_sprite, "modulate:a", 1.0, 0.5)
		door_sprite.play("close")
		door_collision.set_deferred("disabled", false)
		box_player_in = 1

func unlock_door():
	door_sprite.visible = false
	door_collision.set_deferred("disabled", true)
	box_player_in = 0  # Reset the flag
