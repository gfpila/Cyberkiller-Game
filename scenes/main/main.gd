extends Node2D

@export var levels = {
	'1': "res://scenes/level/level.tscn",
	'2': "res://scenes/level2/level_2.tscn",
	'3': "res://scenes/level3/level_3.tscn",
	'4': "res://scenes/level4/level_4.tscn",
	'5': "res://scenes/level5/level_5.tscn",
	'6': "res://scenes/level6/level_6.tscn",
	'7': "res://scenes/level7/level_7.tscn",
	'8': "res://scenes/level8/level_8.tscn",
	'9': "res://scenes/level9/level_9.tscn",
	'10': "res://scenes/level10/level_10.tscn"
}

var current_level = null
var player = null
var double_attack_unlocked = false

@onready var level_container = $LevelContainer
@onready var hud = $HUD/Life

var player_health = 50
var player_max_health = 50

func _ready():
	load_level(levels['10'])

func load_level(path):
	# Limpa level anterior
	if current_level:
		# 1. Remove todos os filhos do container (incluindo o nível)
		for child in level_container.get_children():
			child.queue_free()
		
		await get_tree().process_frame
		current_level = null
	
	# Carrega novo level e instancia no container
	var level_scene = load(path)
	current_level = level_scene.instantiate()
	level_container.add_child(current_level)
	
	# Encontra o player dentro do novo level
	player = $Player
	player.double_attack_unlocked = double_attack_unlocked
	# Move o player para o ponto de início do novo level
	var spawn_point = current_level.get_node_or_null("PlayerStart")
	if spawn_point:
		player.global_position = spawn_point.global_position
	
	# Atualiza status do player
	player.health = player_health
	player.max_health = player_max_health
	
	# Conecta sinal para manter estado sincronizado
	#player.health_changed.disconnect_all()
	player.health_changed.connect(_on_player_health_changed)

	hud.set_player(player)
	hud._on_health_changed(player.health, player.max_health)

func _on_player_health_changed(current, max):
	player_health = current
	player_max_health = max
	
	if current <= 0:
		stop_enemies_attack()

func go_to_level(value):
	load_level(levels[value])
	
func unlock_double_attack():
	double_attack_unlocked = true
	if player:
		$WeaponUpgrade.play()
		player.double_attack_unlocked = true
		

func stop_enemies_attack():
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
			if enemy.attack_cooldown:
				enemy.attack_cooldown = 9999  # Valor grande para congelar ataques
