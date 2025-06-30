extends Control


func _on_jogar_pressed() -> void:
	$Audio/botao.play()
	await get_tree().create_timer(0.675).timeout
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")

func _on_sair_pressed() -> void:
	$Audio/botao.play()
	await get_tree().create_timer(0.675).timeout
	get_tree().quit()

func _on_opcoes_pressed() -> void:
	$Audio/botao.play()
	await get_tree().create_timer(0.675).timeout
	get_tree().change_scene_to_file("res://scenes/opcoes/opcoes.tscn")
