extends HBoxContainer

@export var heart_texture: Texture2D
var player: Node = null

func set_player(new_player):
	if player:
		player.health_changed.disconnect(_on_health_changed)
	player = new_player
	player.health_changed.connect(_on_health_changed)
	_on_health_changed(player.health, player.max_health)

func _on_health_changed(current: int, max: int) -> void:
	for child in get_children():
		child.queue_free()

	var total_hearts = max / 10
	var full_hearts = current / 10

	for i in range(total_hearts):
		var heart = TextureRect.new()
		heart.custom_minimum_size = Vector2(64, 64)
		heart.texture = heart_texture
		heart.expand = true
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

		if i >= full_hearts:
			heart.modulate = Color(1, 1, 1, 0.3)

		add_child(heart)
