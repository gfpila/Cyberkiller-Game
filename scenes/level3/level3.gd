extends Node2D

@onready var player = $Player
@onready var exit_area = $ExitArea

func _ready():
	exit_area.body_entered.connect(_on_exit_area_entered)

func _on_exit_area_entered(body):
	if body.is_in_group("player") or body.name == "Player":
		# Dispara a mudança de nível
		get_tree().root.get_node("Main").go_to_level2()
