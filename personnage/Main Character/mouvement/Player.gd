extends CharacterBody2D

@export var speed := 400.0
@export var jump_force := 900.0
@export var gravity := 2000.0

var player  # déclaration obligatoire

func _ready():
	if has_node("Player"):
		player = $Player
	else:
		print("Player node not found!")

func _physics_process(delta):
	var direction = 0

	if Input.is_action_pressed("ui_left"):
		direction -= 1
	if Input.is_action_pressed("ui_right"):
		direction += 1

	velocity.x = direction * speed
	velocity.y += gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = -jump_force

	move_and_slide()
