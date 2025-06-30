extends Area2D

@export var charge_duration: float = 1.0
@export var beam_duration: float = 3.0
@export var damage: int = 50
var player
@onready var sprite = $AnimatedSprite2D
@onready var collision = $CollisionShape2D
var damaged_bodies := []
var active := false

func _ready():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		sprite.flip_h = player.global_position.x < global_position.x
		
	var sprite: AnimatedSprite2D = get_node("AnimatedSprite2D")
	sprite.play("charge")
	collision.disabled = true
	await sprite.animation_finished  # espera o "charge" terminar
	position += Vector2(-350, 0)
	sprite.play("feixe")
	collision.disabled = false
	active = true

	await get_tree().create_timer(beam_duration).timeout
	queue_free()

func _on_body_entered(body):
	if not active:
		return
	if body.is_in_group("player") and body not in damaged_bodies:
		body.take_damage(damage, global_position)
		damaged_bodies.append(body)
