extends Node2D

@onready var spawn_point := $SpawnPoint
var heal_scene := preload("res://scenes/player/heal_area.tscn") # Caminho da sua cena

func spawn_heals(amount: int, offset := Vector2(60, 0)):
	for i in range(amount):
		var heal_instance = heal_scene.instantiate()
		add_child(heal_instance)
		heal_instance.position = spawn_point.position + offset * i
