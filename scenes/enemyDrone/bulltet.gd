extends Area2D

@export var speed: float = 1400.0
var direction: Vector2 = Vector2.ZERO
var is_hit: bool = false
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func initialize(dir: Vector2) -> void:
	direction = dir
	direction = Vector2(dir.x, 0).normalized()
	var sprite: AnimatedSprite2D = get_node("AnimatedSprite2D")
	sprite.flip_h = dir.x > 0
	sprite.play("shot")

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
	global_position = body.global_position
	sprite.play("hit")
	await sprite.animation_finished
	var damage = 10
	body.take_damage(damage, global_position, false)
	queue_free()
