extends Node
class_name GameEffect

static func request_hit_stop(duration: float = 0.2, node: CanvasItem = null, splatter_position: Vector2 = Vector2.ZERO) -> void:
	if Engine.time_scale < 1.0:
		return
	
	# Salva a escala de tempo original
	var original_time_scale = Engine.time_scale
	Engine.time_scale = 0.001
	
	var original_modulate: Color
	if node != null:
		original_modulate = node.modulate
		node.modulate = Color.WHITE
	
	# Efeito de sangue
	if splatter_position != Vector2.ZERO:
		var splatter_scene = preload("res://scenes/blood/blood.tscn")
		var splatter = splatter_scene.instantiate()
		node.add_child(splatter)
		splatter.global_position = splatter_position
		splatter.rotation = randf() * PI * 2
		var base_scale = randf_range(0.8, 1.3)
		splatter.scale = (Vector2.ONE * base_scale) / node.global_scale

	var adjusted_duration = duration * Engine.time_scale
	await node.get_tree().create_timer(adjusted_duration, false).timeout

	if node != null:
		node.modulate = original_modulate
	
	Engine.time_scale = original_time_scale
