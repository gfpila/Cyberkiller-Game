extends Area2D

func _ready():
	connect("body_entered", Callable(self, "_on_area_body_entered"))
	
func _on_area_body_entered(body):
	if body.is_in_group("player"):
		$"../Audio".play()
		body.heal(10)
		queue_free()
