extends CharacterBody2D

@export var speed := 400.0
@export var jump_force := 900.0
@export var gravity := 2000.0

func _physics_process(delta):
	var direction = 0

	# Horizontal input
	if Input.is_action_pressed("ui_left"):
		direction -= 1
	if Input.is_action_pressed("ui_right"):
		direction += 1

	velocity.x = direction * speed

	# Apply gravity manually
	velocity.y += gravity * delta

	# Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = -jump_force

	# Move the character
	move_and_slide()
