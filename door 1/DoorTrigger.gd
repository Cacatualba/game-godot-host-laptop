extends Node2D
@onready var door_sprite = $Door
@onready var door_collision = $StaticBody2D/Collision
@onready var trigger_area = $Trigger_Area

func _ready():
	door_sprite.visible = false  # Door INVISIBLE at start
	door_collision.set_deferred("disabled", true)
	trigger_area.body_entered.connect(_on_trigger_area_body_entered)

func _on_trigger_area_body_entered(body):
	if body.is_in_group("player"):
		door_sprite.visible = true
		door_sprite.modulate.a = 0  # Start transparent
		# Create a fade-in tween
		var tween = create_tween()
		tween.tween_property(door_sprite, "modulate:a", 1.0, 0.5)  # Fade in over 0.5 seconds
		door_sprite.play("close")
		door_collision.set_deferred("disabled", false)

func unlock_door():
	door_sprite.visible = false  # Door becomes INVISIBLE again
	door_collision.set_deferred("disabled", true)
