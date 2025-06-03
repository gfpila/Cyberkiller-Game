extends Node2D

@onready var player = $Player
@onready var exit_area = $ExitArea

func _ready():
	exit_area.body_entered.connect(_on_exit_area_entered)

func _on_exit_area_entered(body):
	if body == player:
		# Envia sinal para o Main para trocar o nível
		get_tree().root.get_node("Main").go_to_level2()
