extends Area2D

@export var speed: float = 1500.0
var direction: Vector2 = Vector2.ZERO
var is_hit: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func initialize(dir: Vector2) -> void:
	var sprite: AnimatedSprite2D = get_node("AnimatedSprite2D")
	direction = Vector2(dir.x, dir.y).normalized()
	sprite.flip_h = dir.x > 0
	sprite.play("shoot")

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_hit"))

func _process(delta: float) -> void:
	if is_hit:
		return
	position += direction * speed * delta

func _on_hit(body: Node2D) -> void:
	if is_hit or not body.is_in_group("player"):
		return
	is_hit = true
	body.take_damage(10, global_position)
	queue_free()
