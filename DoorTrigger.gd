extends Node2D

@onready var door_sprite = $door
@onready var door_collision = $collision
@onready var trigger_area = $trigger_area  # ton trigger

func _ready():
	door_sprite.play("close")
	door_collision.disabled = false
	trigger_area.body_entered.connect(_on_trigger_area_body_entered)
	trigger_area.body_exited.connect(_on_trigger_area_body_exited)

func _on_trigger_area_body_entered(body):
	if body.is_in_group("player"):
		door_sprite.play("open")
		door_collision.disabled = true

func _on_trigger_area_body_exited(body):
	if body.is_in_group("player"):
		door_sprite.play("close")
		door_collision.disabled = false
