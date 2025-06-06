extends Node2D

@onready var sprite = $AnimatedSprite2D
@onready var audio = $Audio
@onready var spawn_timer = $SpawnTimer
@onready var spawn_point = $SpawnPoint

@export var enemy_scenes := {
	"nightBorne": preload("res://scenes/enemy_NightBorne/enemy.tscn"),
	"blackDog": preload("res://scenes/enemyBlackDog/blackDog.tscn"),
}

var current_wave: Array = []
var spawned_enemies: Array = []

signal wave_finished

func _ready():
	sprite.play("default")
	audio.play()
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

func start_wave(wave: Array):
	current_wave = wave.duplicate()
	spawned_enemies.clear()
	spawn_timer.start()

func _on_spawn_timer_timeout():
	if current_wave.is_empty():
		spawn_timer.stop()
		_check_wave_finished()
		return

	var enemy_key = current_wave.pop_front()
	var scene = enemy_scenes.get(enemy_key)
	if not scene:
		push_error("Enemy key '%s' not found in enemy_scenes." % enemy_key)
		_check_wave_finished()
		return

	var enemy = scene.instantiate()
	enemy.global_position = spawn_point.global_position
	get_parent().add_child(enemy)
	enemy.add_to_group("enemies")
	spawned_enemies.append(enemy)

	if enemy.is_inside_tree():
		enemy.tree_exited.connect(_on_enemy_died.bind(enemy), CONNECT_ONE_SHOT)

	if current_wave.is_empty():
		spawn_timer.stop()

	# Verifica logo após spawn (caso o inimigo morra instantaneamente por algum motivo)
	_check_wave_finished()

func _on_enemy_died(enemy):
	spawned_enemies.erase(enemy)
	_check_wave_finished()

func _check_wave_finished():
	# Limpa a lista de inimigos de qualquer referência inválida
	spawned_enemies = spawned_enemies.filter(func(e): return e and e.is_inside_tree())

	if spawned_enemies.is_empty() and current_wave.is_empty():
		wave_finished.emit()
