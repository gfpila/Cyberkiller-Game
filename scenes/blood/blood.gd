extends Sprite2D

func _ready():
	# Auto-destrói após meio segundo
	await get_tree().create_timer(0.2).timeout
	queue_free()
