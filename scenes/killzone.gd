extends Area2D

func _on_body_entered(body):
	if body.name == "Player":
		print("Player Died!!!!")
		if body.has_method("die"):
			body.die()
