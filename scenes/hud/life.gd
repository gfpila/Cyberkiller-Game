extends HBoxContainer

@export var heart_texture: Texture2D

var player: Node = null

func _ready():
	# Aguarda o Player aparecer na árvore
	await get_tree().process_frame
	player = get_tree().get_root().get_node("Level/Player") # Ajuste o caminho conforme sua estrutura
	player.health_changed.connect(_on_health_changed)
	_on_health_changed(player.health, player.max_health)

func _on_health_changed(current: int, max: int) -> void:
	# Limpa os corações antigos
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
			heart.modulate = Color(1, 1, 1, 0.3)  # Apagado

		add_child(heart)
