extends Node2D

@onready var player = $Player
@onready var exit_area = $ExitArea
@onready var exit_sprite = $ExitArea/AnimatedSprite2D
@onready var audio = $ExitArea/AudioStreamPlayer2D


func _ready():
	exit_sprite.visible = false
	exit_area.body_entered.connect(_on_exit_area_entered)

func _process(delta):
	if all_enemies_defeated():
		activate_exit()
		
func all_enemies_defeated() -> bool:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() == 0:
		return true
	else:
		return false
	
func activate_exit():
	if not exit_sprite.visible:
		exit_sprite.visible = true
		exit_sprite.play("default")
		audio.play()

func _on_exit_area_entered(body):
	# Só permite avançar se o player tocar na saída E ela estiver ativa
	if (body.name == "Player" or body.is_in_group("player")) and exit_sprite.visible:
		get_tree().root.get_node("Main").go_to_level('13')
