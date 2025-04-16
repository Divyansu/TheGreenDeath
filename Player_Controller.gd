extends CharacterBody2D


@export var SPEED = 300.0
@export_range(0,1) var deceleration = 0.1
@export_range(0,1) var acceleration = 0.1

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
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and (is_on_floor() or  is_on_wall()):
		velocity.y = jump_force

	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= decelerate_on_jump_release

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("left", "right")
	if direction:
		velocity.x = move_toward(velocity.x, direction * SPEED, SPEED * acceleration) 
		animated_sprite.play("walk")
		animated_sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * deceleration)
		animated_sprite.play ("Idle")
	
	#Dash Activation
	if Input.is_action_pressed("dash") and direction and not is_dashing and dash_timer <= 0:
		is_dashing = true
		dash_start_position = position.x
		dash_direction = direction
		dash_timer = dash_cooldown 

	#perform dash
	if is_dashing:
		var current_distance = abs(position.x - dash_start_position)
		if current_distance >= dash_max_distance or is_on_wall():
			is_dashing = false
		else:
			velocity.x = dash_direction * dash_speed * dash_curve.sample(current_distance / dash_max_distance)
			velocity.y = 0
	
	#reduce dash timer
	if dash_timer > 0:
		dash_timer -= delta

	move_and_slide()
