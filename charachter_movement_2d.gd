extends CharacterBody2D

@export var speed := 200.0

func _physics_process(_delta):
	var direction = Vector2.ZERO

	var r = Input.is_action_pressed("ui_right")
	var r2 = Input.is_action_pressed("ui_d")
	var l = Input.is_action_pressed("ui_left")
	var l2 = Input.is_action_pressed("ui_a")
	var d = Input.is_action_pressed("ui_down")
	var d2 = Input.is_action_pressed("ui_s")
	var u = Input.is_action_pressed("ui_up")
	var u2 = Input.is_action_pressed("ui_w")

	# debug input
	if r or r2 or l or l2 or d or d2 or u or u2:
		print("input:", "R" if r else "-","R2" if r2 else "-", " L" if l else "-",  " L2" if l2 else "-"," D" if d else "-"," D2" if d2 else "-", " U" if u else "-", " U2" if u2 else "-")

	if r:
		direction.x += 1
	if r2:
		direction.x += 1
	if l:
		direction.x -= 1
	if l2:
		direction.x -= 1
	if d:
		direction.y += 1
	if d2:
		direction.y += 1
	if u:
		direction.y -= 1
	if u2:
		direction.y -= 1

	if direction != Vector2.ZERO:
		direction = direction.normalized()

	velocity = direction * speed

	# debug velocity
	print("velocity:", velocity)

	move_and_slide()
