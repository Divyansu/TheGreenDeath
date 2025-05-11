extends Area2D

@export var rise_speed := 6.0 # pixels per second

func _process(delta):
	position.y -= rise_speed * delta

