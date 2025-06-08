extends Node2D

@onready var player = $Main/Player
@onready var exit_area = $ExitArea
@onready var exit_sprite = $ExitArea/AnimatedSprite2D
@onready var audio = $ExitArea/AudioStreamPlayer2D
@onready var hint_image = $CanvasLayer/Hint
@onready var hint_showed = false

func _ready():
	exit_sprite.visible = false
	exit_area.body_entered.connect(_on_exit_area_entered)
	var main = get_tree().root.get_node("Main")
	player = main.get_node('Player')
	var music_player = main.get_node("LevelMusic")
	music_player.stream = load("res://Music/partida/The Story Continues.ogg")
	music_player.play()

func _process(delta):
	if player.position.x > 900 and hint_showed == false:
		activate_exit()
		

func activate_exit() -> void:
	if not exit_sprite.visible:
		await show_hint()
		exit_sprite.visible = true
		exit_sprite.play("default")

func _on_exit_area_entered(body):
	# Só permite avançar se o player tocar na saída E ela estiver ativa
	if (body.name == "Player" or body.is_in_group("player")) and exit_sprite.visible:
		get_tree().root.get_node("Main").go_to_level('6')

func show_hint():
	hint_showed = true
	await get_tree().create_timer(0.8, true).timeout
	hint_image.visible = true
	get_tree().paused = true  # Pausa o jogo
	await get_tree().create_timer(1.5, true).timeout
	hint_image.visible = false
	get_tree().paused = false  # Retoma o jogo
	await get_tree().create_timer(4,true).timeout
	audio.play()
	
	
	
