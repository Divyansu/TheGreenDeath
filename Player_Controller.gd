extends CharacterBody2D


@export var SPEED = 300.0
@export_range(0,1) var deceleration = 0.1
@export_range(0,1) var acceleration = 0.1

@export var wall_slide_speed = 50.0
@export var wall_jump_pushback = 200.0

@export var jump_force = -400
@export_range(0,1) var decelerate_on_jump_release = 0.5

@export var dash_speed = 1000
@export var dash_max_distance = 300
@export var dash_cooldown = 1
@export var dash_curve : Curve
#const JUMP_VELOCITY = -400.0
@onready var animated_sprite = $AnimatedSprite2D
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var is_dashing = false
var dash_start_position = 0
var dash_direction = 0
var dash_timer = 0



func _physics_process(delta):
	var wall_sliding = false
	var wall_direction = 0  # -1 for right wall, 1 for left wall

	# Gravity + Wall Slide
	if not is_on_floor():
		if is_on_wall() and velocity.y > 0:
			velocity.y = min(velocity.y + gravity * delta, wall_slide_speed)
			wall_sliding = true

			# Determine which wall we're on using test_move
			var left_check = test_move(global_transform, Vector2(-1, 0))
			var right_check = test_move(global_transform, Vector2(1, 0))
			if left_check:
				wall_direction = 1  # wall is on left, jump right
			elif right_check:
				wall_direction = -1  # wall is on right, jump left
		else:
			velocity.y += gravity * delta

	# Jump
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = jump_force
		elif wall_sliding:
			velocity.y = jump_force * 0.6
			velocity.x = wall_jump_pushback * wall_direction  # jump away from wall

	# Jump release shortens jump
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= decelerate_on_jump_release

	# Horizontal Movement
	var direction = Input.get_axis("left", "right")
	if direction:
		velocity.x = move_toward(velocity.x, direction * SPEED, SPEED * acceleration)
		animated_sprite.play("walk")
		animated_sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * deceleration)
		animated_sprite.play("Idle")

	# Dash
	if Input.is_action_pressed("dash") and direction and not is_dashing and dash_timer <= 0:
		is_dashing = true
		dash_start_position = position.x
		dash_direction = direction
		dash_timer = dash_cooldown

	if is_dashing:
		var current_distance = abs(position.x - dash_start_position)
		if current_distance >= dash_max_distance or is_on_wall():
			is_dashing = false
		else:
			velocity.x = dash_direction * dash_speed * dash_curve.sample(current_distance / dash_max_distance)
			velocity.y = 0

	if dash_timer > 0:
		dash_timer -= delta

	move_and_slide()
