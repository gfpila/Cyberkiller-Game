extends CharacterBody2D

@export var move_speed: float = 2000.0
@export var damage: int = 10
@export var gravity: float = 2000.0

@export var chase_duration: float = 0.4
@export var pause_duration: float = 5

var target: Node2D = null
var has_target: bool = false
var is_paused: bool = true
@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var pause_timer = $Timer

func _ready() -> void:
	$Area2D.body_entered.connect(_on_body_entered)
	pause_timer.timeout.connect(_on_pause_timer_timeout)
	animated_sprite.play("idle")
	add_to_group("enemies_static")
	find_player()

func _physics_process(delta: float) -> void:
	if is_paused:
		velocity.x = 0
		animated_sprite.play("idle")
	else:
		if not is_on_floor():
			velocity.y += gravity * delta
		else:
			velocity.y = 0

		if has_target and is_instance_valid(target):
			var direction = (target.global_position - global_position).normalized()
			velocity.x = direction.x * move_speed
			animated_sprite.flip_h = direction.x < 0
		else:
			velocity.x = 0

	move_and_slide()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not is_paused:
		body.take_damage(damage, global_position, true)

func _on_pause_timer_timeout() -> void:
	is_paused = !is_paused
	if is_paused:
		pause_timer.start(pause_duration)  # Tempo parado
	else:
		$Audio.play()
		pause_timer.start(chase_duration)  # Tempo perseguindo

func find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]
		has_target = true
		pause_timer.start(chase_duration)  # Começa perseguindo
