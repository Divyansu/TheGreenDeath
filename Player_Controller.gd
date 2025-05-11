extends CharacterBody2D

# Movement
@export var speed := 100.0
@export var acceleration := 0.1
@export var deceleration := 0.1

# Jump
@export var jump_force := -300.0
@export var decelerate_on_jump_release := 0.5

# Dash
@export var dash_speed := 300.0
@export var dash_max_distance := 50.0
@export var dash_cooldown := 0.5
@export var dash_curve : Curve

# Wall Jump/Slide
@export var wall_slide_speed := 40.0
@export var wall_jump_force := Vector2(250, -200)
@export var wall_check_distance := 6.0

# Coyote Time & Jump Buffer
@export var coyote_time := 0.1
@export var jump_buffer_time := 0.1

@onready var animated_sprite = $AnimatedSprite2D

# Internal state
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_dashing = false
var dash_timer = 0.0
var dash_direction := Vector2.ZERO
var dash_start_position := Vector2.ZERO
var can_dash := true

var wall_dir := 0
var is_wall_sliding := false

var survival_time = 0.0
var is_dead := false 

# Timers
var coyote_timer = 0.0
var jump_buffer_timer = 0.0

func _physics_process(delta):
	if not is_dead:
		survival_time += delta
	
	var input_dir = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down") - Input.get_action_strength("up")
	).normalized()

	# === Dash Handling ===
	if Input.is_action_just_pressed("dash") and can_dash and input_dir != Vector2.ZERO:
		can_dash = false
		is_dashing = true
		dash_start_position = global_position
		dash_direction = input_dir
		dash_timer = dash_cooldown
		velocity = dash_direction * dash_speed
		move_and_slide()
		return

	if is_dashing:
		var distance = global_position.distance_to(dash_start_position)
		if distance >= dash_max_distance:
			is_dashing = false
		else:
			# Maintain 8-directional dash velocity with curve
			velocity = dash_direction * dash_speed * dash_curve.sample(distance / dash_max_distance)

		# Move and handle collisions in any direction
		var collision = move_and_slide()
		
		# Handle wall collisions in any direction
		var hit_wall = false
		for i in get_slide_collision_count():
			var collision_info = get_slide_collision(i)
			if collision_info.get_normal().dot(dash_direction) < -0.7:  # Check if colliding in dash direction
				hit_wall = true
				# Adjust position to prevent sticking
				global_position += collision_info.get_normal() * 1.5
				break

		if hit_wall:
			is_dashing = false
			velocity = Vector2.ZERO
			return

	# === Gravity ===
	if not is_on_floor() and not is_dashing:  # Only apply gravity when not dashing
		velocity.y += gravity * delta * 0.60

	# === Timers ===
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta

	# === Wall Detection & Slide ===
	wall_dir = is_touching_wall()
	is_wall_sliding = wall_dir != 0 and !is_on_floor() and velocity.y > 0

	if is_wall_sliding:
		velocity.y = min(velocity.y, wall_slide_speed)

	# === Jump ===
	if jump_buffer_timer > 0:
		if is_on_floor() or coyote_timer > 0:
			velocity.y = jump_force
			jump_buffer_timer = 0
		elif is_wall_sliding:
			velocity = Vector2(-wall_dir * wall_jump_force.x, wall_jump_force.y)
			jump_buffer_timer = 0

	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= decelerate_on_jump_release

	# === Horizontal Movement ===
	var move_input = Input.get_axis("left", "right")
	if move_input != 0:
		velocity.x = move_toward(velocity.x, move_input * speed, speed * acceleration)
		animated_sprite.play("walk")
		animated_sprite.flip_h = move_input < 0
	else:
		velocity.x = move_toward(velocity.x, 0, speed * deceleration)
		animated_sprite.play("Idle")

	# === Dash Reset ===
	if is_on_floor() and !is_dashing:
		can_dash = true

	move_and_slide()

func is_touching_wall() -> int:
	var space_state = get_world_2d().direct_space_state
	var from_pos = global_position

	var left_check = PhysicsRayQueryParameters2D.create(from_pos, from_pos + Vector2(-wall_check_distance, 0))
	var right_check = PhysicsRayQueryParameters2D.create(from_pos, from_pos + Vector2(wall_check_distance, 0))

	var hit_left = space_state.intersect_ray(left_check)
	var hit_right = space_state.intersect_ray(right_check)

	if hit_left:
		return -1
	elif hit_right:
		return 1
	else:
		return 0

func die():
	if is_dead:
		return
	is_dead = true

	set_physics_process(false)
	animated_sprite.play("die")

	var canvas = get_tree().current_scene.get_node("CanvasLayer")
	canvas.get_node("DeathLabel").visible = true
	canvas.get_node("TimeLabel").visible = true
	canvas.get_node("TimeLabel").text = "Time Survived: %.2fs" % survival_time

	await get_tree().create_timer(2.5).timeout
	get_tree().reload_current_scene()
