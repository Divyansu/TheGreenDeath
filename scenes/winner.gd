extends Area2D



func _on_body_entered(body):
	if body.name == "Player":
		print("won")
		if body.has_method("won"):
			body.won()
