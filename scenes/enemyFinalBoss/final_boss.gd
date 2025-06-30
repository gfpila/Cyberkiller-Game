extends CharacterBody2D

@export var max_health: int = 1000
@export var knockback_force: float = 2000.0
@export var move_speed: float = 300.0
@export var attack_cooldown: float = 0.35
@export var gravity: float = 2000.0

var punchs: int = 0
var health: int
var is_shooting: bool = false

enum State {BEGIN, IDLE, CHASE, PUNCH, FLY_ATTACK, SHOOT, LASER, HURT, DEAD}
enum Phases {FIRST, SECOND}

var current_state: State = State.BEGIN
var target: Node2D = null
var has_target: bool = false
var can_attack: bool = true
var bullet_scene = preload("res://scenes/enemyFinalBoss/boss_bullet.tscn")

var punch_ready: bool = false

@onready var player = $Player
@onready var blast = $Blast
@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var hand_pivot = $HandPivot
@onready var attack_area: Area2D = $HandPivot/SwordArea
@onready var detection_area = $DetectionArea
@onready var audio_nodes = {
	"hit": $Audio/hit,
	"shoot": $Audio/shoot,
	"punch": $Audio/punch,
	"death": $Audio/death,
	"fly_up": $Audio/fly_up,
	"dive": $Audio/dive,
	"impact": $Audio/impact
}

#CHASE
const CHASE_DISTANCE := 50.0
const CHASE_SPEED_MULTIPLIER := 2

#FLY
var fly_peak_position := Vector2(975, 400)
@export var fly_speed: float = 300.0
@export var dive_speed: float = 1800.0
@export var dive_damage: int = 20
@export var fly_pause: float = 1.5
var fly_attack_thresholds := [850, 600, 350, 100]
var current_fly_attack_index := 0
var flying = false


func _ready() -> void:
	
	set_collision_mask_value(3, false)
	health = max_health
	add_to_group("enemies")
	attack_area.monitoring = false
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]
	current_state = State.CHASE
	

func _physics_process(delta: float) -> void:
	
	if current_state == State.DEAD:
		return
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0


	if not flying and current_fly_attack_index < fly_attack_thresholds.size():
		set_collision_mask_value(5, false)
		var threshold = fly_attack_thresholds[current_fly_attack_index]
		if health <= threshold:
			current_fly_attack_index += 1
			current_state = State.FLY_ATTACK




	match current_state:
		State.CHASE:
			await do_chase()
		State.SHOOT:
			await shoot_bullet()
		State.FLY_ATTACK:
			if not flying:
				await fly_attack()


func do_chase() -> void:

	var dir = (target.global_position - global_position).normalized()
	velocity = dir * (move_speed * CHASE_SPEED_MULTIPLIER)
	move_and_slide()
	if punchs == 3:
		current_state = State.SHOOT
		punchs = 0
		return
	
	if not animated_sprite.is_playing() or animated_sprite.animation != "chase":
		animated_sprite.play("chase")
		
	if global_position.distance_to(target.global_position) < CHASE_DISTANCE:
		velocity = Vector2.ZERO
		current_state = State.PUNCH
		await punch_attack()
		current_state = State.CHASE
		
	animated_sprite.flip_h = dir.x < 0


func flip_sprite_towards_target() -> void:
	if target:
		var dir = (target.global_position - global_position).normalized()
		animated_sprite.flip_h = dir.x < 0
		
		
func punch_attack() -> void:
	if not animated_sprite.is_playing() or animated_sprite.animation != "punch":
		flip_sprite_towards_target()
		animated_sprite.play("punch")
		audio_nodes["punch"].play()

		attack_area.monitoring = true

		await get_tree().create_timer(0.6).timeout
		var bodies = attack_area.get_overlapping_bodies()
		if target in bodies:
			target.take_damage(10, global_position)
			attack_area.monitoring = false
			animated_sprite.play('idle')
			current_state = State.IDLE
			await get_tree().create_timer(0.5).timeout
			
		punchs += 1
		current_state = State.CHASE
		
func shoot_bullet() -> void:
	if is_shooting or current_state == State.DEAD or not target:
		return
	current_state = State.IDLE

	for i in range(3):
		flip_sprite_towards_target()
		animated_sprite.play("shoot")
		await animated_sprite.animation_finished
		var bullet = bullet_scene.instantiate()
		bullet.global_position = global_position
		var dir = (target.global_position - global_position).normalized()
		bullet.initialize(dir)
		get_parent().add_child(bullet)
		audio_nodes["shoot"].play()
		await get_tree().create_timer(0.2).timeout

	current_state = State.CHASE

func fly_attack() -> void:
	flying = true
	audio_nodes['fly_up'].play()
	animated_sprite.play("fly_up")
	while global_position.distance_to(fly_peak_position) > 10:
		var dir_up = (fly_peak_position - global_position).normalized()
		velocity = dir_up * fly_speed
		move_and_slide()
		await get_tree().process_frame
	velocity = Vector2.ZERO
	await get_tree().create_timer(fly_pause).timeout

	audio_nodes["dive"].play()
	animated_sprite.play("fly_dive")
	var dive_dir = (target.global_position - global_position).normalized()
	set_collision_mask_value(3, false)
	velocity = dive_dir * dive_speed

	while true:
		var collision = move_and_collide(velocity * get_process_delta_time())
		if collision:
			blast.visible = true
			audio_nodes["impact"].play()
			var bodies = attack_area.get_overlapping_bodies()
			if target in bodies:
				target.take_damage(dive_damage, global_position)
			await get_tree().create_timer(0.8).timeout
			blast.visible = false
			break
		await get_tree().process_frame

	velocity = Vector2.ZERO
	animated_sprite.play("idle")
	flying = false
	current_state = State.CHASE
	

func take_damage(amount: int, attack_origin: Vector2) -> void:
	if current_state == State.DEAD:
		return

	health -= amount
	audio_nodes["hit"].play()
	GameEffects.request_hit_stop(0.4, animated_sprite, global_position)
	if health <= 0:
		die()


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
		

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and current_state == State.PUNCH:
		body.take_damage(10, global_position)
