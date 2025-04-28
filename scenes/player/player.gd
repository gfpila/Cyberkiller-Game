extends CharacterBody2D

const SPEED = 500.0
const JUMP_VELOCITY = -700.0
const GRAVITY = 2000.0
const ATTACK_DURATION = 0.35

@export var max_health: int = 30
@export var knockback_force: float = 2800.0
@export var knockback_friction: float = 0.85
@export var vertical_knockback_factor: float = 0.25
@export var knockback_duration: float = 0.4
@export var invulnerability_time: float = 0.5

var health: int
var can_attack: bool = true
var is_invulnerable: bool = false
var knockback: Vector2 = Vector2.ZERO
var knockback_timer: float = 0.0
var dead = false
var attack_area: Area2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var audio_nodes = {
	"jump": $Audio/jump,
	"attack": $Audio/attack,
	"rise": $Audio/rise,
	"hurt": $Audio/hurt
}

signal knockback_finished

func _ready() -> void:
	health = max_health
	attack_area = $HandPivot/SwordArea
	add_to_group("player")
	attack_area.monitoring = false
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	play_audio("rise")

func _physics_process(delta: float) -> void:
	if dead == true:
		return
	
	if knockback != Vector2.ZERO:
		knockback_timer += delta
		handle_knockback(delta)
		return
	
	handle_movement(delta)
	handle_actions()
	update_animations()
	move_and_slide()

func handle_knockback(delta: float) -> void:
	velocity = knockback
	velocity.y += GRAVITY * delta
	knockback *= knockback_friction
	
	move_and_slide()
	
	if knockback_timer >= knockback_duration || knockback.length() < 50 || is_on_wall():
		end_knockback()

func handle_movement(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0
	
	var direction = Input.get_axis("left", "right")
	velocity.x = direction * SPEED

func handle_actions() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		play_audio("jump")
	
	if Input.is_action_just_pressed("attack") and can_attack:
		start_attack()

func update_animations() -> void:
	var direction = Input.get_axis("left", "right")
	
	if is_invulnerable:
		animated_sprite.modulate = Color.RED
	else:
		animated_sprite.modulate = Color.WHITE
	
	if animated_sprite.animation == "attack_animation" and animated_sprite.is_playing():
		return
	
	if not is_on_floor():
		play_animation("jump")
	elif direction != 0:
		play_animation("run")
	else:
		play_animation("default")
	
	if direction != 0 and animated_sprite.animation != "attack_animation":
		animated_sprite.flip_h = direction < 0
		update_attack_area_position()

func start_attack() -> void:
	can_attack = false
	play_audio("attack")
	play_animation("attack_animation")
	update_attack_area_position()
	
	attack_area.monitoring = true
	await get_tree().create_timer(ATTACK_DURATION).timeout
	attack_area.monitoring = false
	can_attack = true

func take_damage(amount: int, attack_origin: Vector2) -> void:
	if is_invulnerable or dead:
		return
		
	health -= amount
	GameEffects.request_hit_stop(0.4, animated_sprite)
	init_knockback(attack_origin)
	play_audio("hurt")
	await knockback_finished
	if health <= 0:
		die()
		return
	apply_invulnerability()
	


func init_knockback(attack_origin: Vector2) -> void:
	var knockback_dir = (global_position - attack_origin).normalized()
	knockback_dir.y *= vertical_knockback_factor
	knockback = knockback_dir * knockback_force
	knockback_timer = 0.0
	animated_sprite.play('knockback')

func end_knockback() -> void:
	knockback = Vector2.ZERO
	knockback_timer = 0.0
	velocity = Vector2.ZERO
	emit_signal("knockback_finished")

func apply_invulnerability() -> void:
	is_invulnerable = true
	
	# Sistema de piscar corrigido
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(1, 0.5, 0.5), 0.1)
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.1)
	tween.set_loops(4)  # Configura loops no Tween principal
	
	await tween.finished
	is_invulnerable = false

func die() -> void:
	dead = true
	animated_sprite.modulate = Color.WHITE
	set_collision_mask_value(1, false)
	animated_sprite.play("death")
	
	#Primeiro: piscadas fortes
	var tween = create_tween()
	for i in range(3):
		tween.tween_property(animated_sprite, "modulate", Color(2, 2, 2), 0.05)
		tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.05) 
	
	tween.tween_property(animated_sprite, "modulate:a", 0.0, 2)
	
	await tween.finished
	queue_free()

func update_attack_area_position() -> void:
	var offset = Vector2(50, 0) if !animated_sprite.flip_h else Vector2(-50, 0)
	attack_area.position = offset

func play_animation(anim_name: String) -> void:
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)

func play_audio(audio: String) -> void:
	if audio_nodes.has(audio):
		audio_nodes[audio].play()

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		body.take_damage(10, global_position)
