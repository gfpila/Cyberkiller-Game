extends Node2D

@onready var player = $Player
@onready var exit_area = $ExitArea
@onready var exit_sprite = $ExitArea/AnimatedSprite2D
@onready var audio = $ExitArea/AudioStreamPlayer2D
var music_player
var end = false

func _ready():
	exit_sprite.visible = false
	exit_area.body_entered.connect(_on_exit_area_entered)
	var main = get_tree().root.get_node("Main")
	music_player = main.get_node("LevelMusic")
	music_player.stream = load("res://Music/menu/in-game-hustle-cyberpunk-music-230632.mp3")
	music_player.volume_db = +5
	music_player.play()

func _process(delta):
	# só dispara a ativação DA SAÍDA uma única vez
	if all_enemies_defeated() and not end:
		end = true
		await activate_exit()

func all_enemies_defeated() -> bool:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() == 0:
		return true
	else:
		if end == true:
			return true
		return false

func activate_exit():
	music_player.stop()
	var main = get_tree().root.get_node("Main")
	var hud = main.get_node("HUD")
	hud.visible = false
	var game_over_scene = preload("res://scenes/victory/texture_rect.tscn")
	var game_over_instance = game_over_scene.instantiate()
	get_tree().root.add_child(game_over_instance)
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	player.queue_free()
	await get_tree().create_timer(20).timeout
	if is_instance_valid(game_over_instance):
		game_over_instance.queue_free()
	if is_instance_valid(get_tree()) and get_tree().root and is_inside_tree():
		get_tree().change_scene_to_file("res://scenes/main-menu/main_menu.tscn")

func _on_exit_area_entered(body):
	# Só permite avançar se o player tocar na saída E ela estiver ativa
	if (body.name == "Player" or body.is_in_group("player")) and exit_sprite.visible:
		get_tree().root.get_node("Main").go_to_level('2')
