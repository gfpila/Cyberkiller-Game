extends Node2D

@onready var player = $Player
@onready var exit_area = $ExitArea
@onready var exit_sprite = $ExitArea/AnimatedSprite2D
@onready var audio = $ExitArea/AudioStreamPlayer2D

@onready var spawner1 = $EnemySpawner
@onready var spawner2 = $EnemySpawner2
@onready var spawner3 = $EnemySpawner3

var waves_done = false

func _ready():
	exit_sprite.visible = false
	exit_area.body_entered.connect(_on_exit_area_entered)
	var main = get_tree().root.get_node("Main")
	var music_player = main.get_node("LevelMusic")
	music_player.stream = load("res://Music/partida/2 eletro battle.mp3")
	music_player.volume_db = -8
	music_player.play()
	run_waves()

func _process(delta):
	if waves_done and all_enemies_defeated():
		activate_exit()

func all_enemies_defeated() -> bool:
	var enemies = get_tree().get_nodes_in_group("enemies")
	return enemies.size() == 0

func activate_exit():
	if not exit_sprite.visible:
		exit_sprite.visible = true
		exit_sprite.play("default")
		audio.play()

func _on_exit_area_entered(body):
	# Só permite avançar se o player tocar na saída E ela estiver ativa
	if (body.name == "Player" or body.is_in_group("player")) and exit_sprite.visible:
		get_tree().root.get_node("Main").go_to_level('7')

func run_waves() -> void:
	await get_tree().process_frame  # Aguarda tudo carregar

	# Leva 1: dois bats (um em cada portal)
	await spawner1.start_wave(["nightBorne"])
	await spawner2.start_wave(["nightBorne"])
	await spawner3.start_wave(["nightBorne"])
	await spawner1.wave_finished
	await spawner2.wave_finished
	await spawner3.wave_finished
	

	# Leva 2: nightBorne em um portal, blackDog no outro
	audio.play()
	await spawner1.start_wave(["nightBorne"])
	await spawner2.start_wave(["blackDog"])
	await spawner3.start_wave(["NightBorne"])
	await spawner1.wave_finished
	await spawner2.wave_finished
	await spawner3.wave_finished
	
	# Leva 3: nightBorne em um portal, blackDog no outro
	audio.play()
	await spawner1.start_wave(["nightBorne"])
	await spawner2.start_wave(["blackDog"])
	await spawner3.start_wave(["blackDog"])
	await spawner1.wave_finished
	await spawner2.wave_finished
	await spawner3.wave_finished


	waves_done = true
