extends Node
class_name GameEffect

static func request_hit_stop(duration: float = 0.2, node: CanvasItem = null) -> void:
	if Engine.time_scale < 1.0:
		return
	
	# Salva a escala de tempo original
	var original_time_scale = Engine.time_scale
	Engine.time_scale = 0.001
	
	var original_modulate: Color
	if node != null:
		original_modulate = node.modulate
		node.modulate = Color.WHITE
	
	# O timer precisa ser ajustado porque o time_scale afeta ele
	var adjusted_duration = duration * Engine.time_scale
	await node.get_tree().create_timer(adjusted_duration, false).timeout
	
	if node != null:
		node.modulate = original_modulate
	
	Engine.time_scale = original_time_scale
