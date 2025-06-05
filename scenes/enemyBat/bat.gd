extends CharacterBody2D

@export var move_speed: float = 150.0
@export var move_range: float = 100.0
@export var damage: int = 10

var start_position: Vector2
var direction: int = 1

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

func _ready() -> void:
	start_position = global_position
	$Area2D.body_entered.connect(_on_body_entered)
	animated_sprite.play("idle") # Troque se quiser outra animação
	add_to_group("enemies_static")

func _physics_process(delta: float) -> void:
	velocity = Vector2.ZERO
	velocity.y = move_speed * direction
	move_and_slide()

	# Inverta direção se ultrapassar o limite
	if abs(global_position.y - start_position.y) >= move_range:
		direction *= -1

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.take_damage(damage, global_position, false)
