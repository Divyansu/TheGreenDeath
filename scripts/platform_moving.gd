extends AnimatableBody2D

@export var speed: float = 100.0
@export var direction: Vector2 = Vector2.RIGHT

func _physics_process(delta):
	var motion = direction.normalized() * speed * delta
	var collision = move_and_collide(motion)

	if collision:
		# Only reverse if the collision is NOT the player
		if not collision.get_collider().is_in_group("Player"):
			direction = -direction
