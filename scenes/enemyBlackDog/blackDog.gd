extends CharacterBody2D

@export var max_health: int = 80
@export var knockback_force: float = 3000.0
@export var friction: float = 0.8
@export var move_speed: float = 300.0
@export var attack_range: float = 150.0
@export var detection_range: float = 500.0
@export var attack_cooldown: float = 0.5
@export var gravity: float = 2000.0
@export var knockback_duration: float = 0.25
@export var vertical_knockback_factor: float = 0.45
@export var separation_distance: float = 80.0
@export var separation_strength: float = 350.0


var health: int
enum State { IDLE, CHASE, ATTACK, HURT, DEAD }
var current_state: State = State.IDLE
var base_move_speed: float
var speed_variation_timer: float = 0.0
var random_offset: float = 0.0
var target: Node2D = null
var has_target: bool = false
var knockback: Vector2 = Vector2.ZERO
var can_attack: bool = true
var random_direction_offset: Vector2

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var hand_pivot = $HandPivot
@onready var attack_area: Area2D = $HandPivot/SwordArea
@onready var detection_area = $DetectionArea
@onready var audio_nodes = {
	"hit": $Audio/hit,
	"attack": $Audio/attack,
	"death": $Audio/death
}

func _ready() -> void:
	set_collision_mask_value(3, false)
	health = max_health
	add_to_group("enemies")
	setup_detection_area()
	animated_sprite.flip_h
	attack_area.monitoring = false
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	
	current_state = State.IDLE
	animated_sprite.play("idle")
	
	# Inicializar valores para variação
	random_offset = randf_range(0.0, TAU)
	base_move_speed = move_speed + randf_range(-60.0, 60.0)

	# Gera um pequeno vetor de desvio aleatório
	random_direction_offset = Vector2(randf_range(-0.5, 0.5), 0).normalized()

func setup_detection_area() -> void:
	var shape = CircleShape2D.new()
	shape.radius = detection_range
	detection_area.get_node("CollisionShape2D").shape = shape
	detection_area.body_entered.connect(_on_detection_area_body_entered)

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return
		
	#Variação de movimento
	speed_variation_timer += delta
	var sin_factor = sin(speed_variation_timer * 2.0 + random_offset) * 0.2 + 1.0
	move_speed = base_move_speed * sin_factor + 800
	
	#Aplicar gravidade
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	if current_state == State.ATTACK:
		move_and_slide()
		return

	if knockback != Vector2.ZERO:
		handle_knockback(delta)
	elif has_target and is_instance_valid(target):
		handle_combat()
	else:
		current_state = State.IDLE
		velocity.x = 0

	handle_animations()
	move_and_slide()


func handle_animations() -> void:
	match current_state:
		State.DEAD:
			animated_sprite.play("death")
		State.HURT:
			animated_sprite.play("hurt")
		State.ATTACK:
			animated_sprite.play("attack")
		State.CHASE:
			if not is_on_floor():
				animated_sprite.play("jump")
			elif abs(velocity.x) > 0:
				animated_sprite.play("run")
			else:
				animated_sprite.play("idle")
		State.IDLE:
			if not is_on_floor():
				animated_sprite.play("jump")
			elif abs(velocity.x) > 0:
				animated_sprite.play("run")
			else:
				animated_sprite.play("idle")


func handle_knockback(delta: float) -> void:
	velocity = knockback
	velocity.y += gravity * delta
	knockback *= friction
	
	# Interromper knockback se colidir com parede ou força for pequena
	if knockback.length() < 50 or is_on_wall():
		knockback = Vector2.ZERO
		if health > 0:
			current_state = State.CHASE if has_target else State.IDLE


func apply_separation_force() -> Vector2:
	var separation_force = Vector2.ZERO
	var enemies = get_tree().get_nodes_in_group("enemies")

	for other in enemies:
		if other == self:
			continue
		if not other is CharacterBody2D:
			continue
		if other.knockback != Vector2.ZERO or other.current_state == State.HURT:
			continue  # Ignora inimigos em knockback ou em estado de dano

		var distance = global_position.distance_to(other.global_position)
		if distance < separation_distance and distance > 0:
			var push_dir = (global_position - other.global_position).normalized()
			var strength = (separation_distance - distance) / separation_distance
			separation_force += push_dir * strength

	return separation_force.normalized() * separation_strength


func handle_combat() -> void:
	var direction = (target.global_position - global_position).normalized()
	direction += random_direction_offset * 0.4  # Adiciona leve desvio
	direction = direction.normalized()
	var distance = global_position.distance_to(target.global_position)

	animated_sprite.flip_h = direction.x > 0
	update_attack_area_position()

	if distance <= attack_range and can_attack:
		start_attack()
	else:
		current_state = State.CHASE
		var separation = apply_separation_force()
		var final_direction = (direction + separation).normalized()
		velocity.x = final_direction.x * move_speed


func take_damage(amount: int, attack_origin: Vector2) -> void:
	if current_state == State.DEAD:
		return

	# Calcular direção do knockback
	var knockback_dir = (global_position - attack_origin).normalized()
	knockback_dir.y *= vertical_knockback_factor
	knockback = knockback_dir * knockback_force

	health -= amount
	current_state = State.HURT
	audio_nodes["hit"].play()
	GameEffects.request_hit_stop(0.4, animated_sprite, global_position)
	
	# Tempo mínimo de knockback
	var knockback_timer = get_tree().create_timer(knockback_duration)
	await knockback_timer.timeout
	
	knockback = Vector2.ZERO
	
	if health <= 0:
		die()
	else:
		current_state = State.CHASE if has_target else State.IDLE


func start_attack() -> void:
	if !can_attack: 
		return

	can_attack = false
	current_state = State.ATTACK
	audio_nodes["attack"].play()
	await get_tree().create_timer(0.15).timeout
	

	update_attack_area_position()
	attack_area.monitoring = true

	await animated_sprite.animation_finished
	attack_area.monitoring = false
	current_state = State.CHASE if has_target else State.IDLE
	
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true


func update_attack_area_position() -> void:
	var offset = Vector2(attack_range * 0.8, 0)  # Ajuste fino na posição
	attack_area.position = offset if not animated_sprite.flip_h else -offset


func die() -> void:
	audio_nodes["death"].play()
	collision_shape.set_deferred("disabled", true)
	current_state = State.DEAD
	animated_sprite.play("death")
	await animated_sprite.animation_finished
	queue_free()


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target = body
		has_target = true
		current_state = State.CHASE


func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and current_state == State.ATTACK:
		body.take_damage(20, global_position)
