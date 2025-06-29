extends CharacterBody2D

enum State {
	DESCEND,
	SHOOT,
	ASCEND,
	IDLE,
	DEAD
}

@export var descend_speed: float = 400.0
@export var ascend_speed: float = 400.0
@export var shoot_cooldown: float = 0.1
@export var shoot_delay: float = 0.25
@export var align_threshold: float = 5.0
@export var attack_cooldown: float = 0.35

var bullet_scene = preload("res://scenes/enemyDrone/bulltet.tscn")
var start_y: float
var top_y: float = 300.0
var current_state: State = State.IDLE
var can_shoot: bool = true
var is_pausing_in_air: bool = false
var knockback: Vector2 = Vector2.ZERO

@onready var player: Node2D = null
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var audio_nodes = {
	"death": $Audio/death,
	"attack": $Audio/attack,
}


func _ready() -> void:
	add_to_group("enemies")
	start_y = global_position.y
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	current_state = State.ASCEND

func play_animation(anim_name: String) -> void:
	if sprite.animation != anim_name:
		sprite.play(anim_name)

func _physics_process(delta: float) -> void:
	if player:
		sprite.flip_h = player.global_position.x < global_position.x
		
	if current_state == State.DEAD:
		velocity = Vector2.ZERO
		play_animation("death")
		await get_tree().create_timer(2.0).timeout
		queue_free()
		return
		
	if sprite.animation not in ["attack", "death"]:
		play_animation("idle")
		
	match current_state:
		State.DESCEND:
			_handle_descend(delta)
		State.SHOOT:
			_handle_shoot(delta)
		State.ASCEND:
			_handle_ascend(delta)
		State.IDLE:
			velocity = Vector2.ZERO
			move_and_slide()

func _handle_ascend(delta: float) -> void:
	if current_state == State.DEAD:
		return
	if is_pausing_in_air:
		return
	velocity = Vector2(0, -ascend_speed)
	var collision = move_and_collide(velocity * delta)
	if collision:
		global_position.y = collision.position.y
		current_state = State.DESCEND
		return

	if global_position.y <= top_y:
		global_position.y = top_y
		current_state = State.IDLE
		is_pausing_in_air = true
		_pause_in_air() 
		return

	move_and_slide()

func _handle_descend(delta: float) -> void:
	if current_state == State.DEAD:
		return
	velocity = Vector2(0, descend_speed)
	var collision = move_and_collide(velocity * delta)
	if collision:
		var collider = collision.get_collider()
		if collider and collider.collision_layer == 2:
			current_state = State.SHOOT
			play_animation("attack")
			await sprite.animation_finished
			return
	move_and_slide()

func _handle_shoot(delta: float) -> void:
	if current_state == State.DEAD:
		return
	velocity = Vector2.ZERO
	move_and_slide()
	if can_shoot:
		can_shoot = false
		await get_tree().create_timer(0.15).timeout
		_shoot()
		await get_tree().create_timer(0.25).timeout
		current_state = State.ASCEND
		can_shoot = true

func _shoot() -> void:
	if current_state == State.DEAD:
		return
	if not player:
		return
	await get_tree().create_timer(shoot_delay).timeout
	play_audio('attack')
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	var dir = (player.global_position - global_position).normalized()
	bullet.initialize(dir)
	get_parent().add_child(bullet)

func _pause_in_air() -> void:
	if current_state == State.DEAD:
		return
	await get_tree().create_timer(1.0).timeout
	is_pausing_in_air = false
	current_state = State.DESCEND

func take_damage(amount: int, attack_origin: Vector2) -> void:
	current_state = State.DEAD
	play_audio('death')
	await get_tree().create_timer(1.0).timeout
	return
	
func play_audio(audio: String) -> void:
	if audio_nodes.has(audio):
		audio_nodes[audio].play()
