extends CharacterBody2D

const SPEED = 500.0
const JUMP_VELOCITY = -900.0
const GRAVITY = 2000.0
const ATTACK_DURATION = 0.4
const ATTACK_COOLDOWN = 0.4
const DASH_COOLDOWN = 0.45

@export var max_health: int = 50
@export var knockback_force: float = 2800.0
@export var knockback_friction: float = 0.85
@export var vertical_knockback_factor: float = 0.25
@export var knockback_duration: float = 0.4
@export var invulnerability_time: float = 0.4
@export var double_attack_unlocked: bool = false

var can_attack: bool = true
var is_invulnerable: bool = false
var knockback: Vector2 = Vector2.ZERO
var knockback_timer: float = 0.0
var dead = false
var attack_area: Area2D
var health: int = max_health
var is_dash_attack: bool = false
var dash_speed: float = 1800
var dash_duration: float = 0.3
var can_dash: bool = true

@onready var aura = $Aura
@onready var animated_sprite = $AnimatedSprite2D
@onready var audio_nodes = {
	"jump": $Audio/jump,
	"attack": $Audio/attack,
	"rise": $Audio/rise,
	"hurt": $Audio/hurt,
	"special_attack": $Audio/special_attack
}

signal knockback_finished
signal health_changed(current: int, max: int)

func _ready() -> void:
	z_index = 10
	health = max_health
	attack_area = $HandPivot/SwordArea
	add_to_group("player")
	attack_area.monitoring = false
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	play_audio("rise")

func _physics_process(delta: float) -> void:
	if dead:
		return

	if knockback != Vector2.ZERO:
		knockback_timer += delta
		handle_knockback(delta)
		return

	handle_movement(delta)
	handle_actions()
	update_animations()
	move_and_slide()

	if position.y > 1200:
		die()

func handle_knockback(delta: float) -> void:
	velocity = knockback
	velocity.y += GRAVITY * delta
	knockback *= knockback_friction
	move_and_slide()
	if knockback_timer >= knockback_duration or knockback.length() < 50 or is_on_wall():
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

	if Input.is_action_just_pressed("special_attack") and can_attack and can_dash:
		await perform_dash_attack()

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

	var cooldown_timer = get_tree().create_timer(ATTACK_COOLDOWN)
	await get_tree().create_timer(ATTACK_DURATION - 0.2).timeout
	attack_area.monitoring = false
	await cooldown_timer.timeout
	can_attack = true

func perform_dash_attack() -> void:
	if not double_attack_unlocked:
		return
	can_attack = false
	play_audio("special_attack")
	is_dash_attack = true
	attack_area.monitoring = true
	var direction = -1 if animated_sprite.flip_h else 1
	var dash_velocity = Vector2(dash_speed * direction, 0)
	var dash_timer = 0.0
	aura.visible = true

	while dash_timer < dash_duration:
		play_animation('dash_attack')
		velocity = dash_velocity
		move_and_slide()
		await get_tree().process_frame
		dash_timer += get_process_delta_time()

	attack_area.monitoring = false
	velocity = Vector2.ZERO
	is_dash_attack = false
	aura.visible = false
	can_attack = true
	can_dash = false
	await get_tree().create_timer(DASH_COOLDOWN).timeout
	can_dash = true  # libera dash novamente
	

func take_damage(amount: int, attack_origin: Vector2, knockback := true) -> void:
	if is_invulnerable or dead:
		return

	health -= amount
	emit_signal("health_changed", health, max_health)
	GameEffects.request_hit_stop(0.4, animated_sprite, global_position)
	if knockback:
		init_knockback(attack_origin)
		play_audio("hurt")
		await knockback_finished
	else:
		play_audio("hurt")

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

	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(1, 0.5, 0.5), 0.1)
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.1)
	tween.set_loops(4)

	await tween.finished
	is_invulnerable = false

func heal(amount: int) -> void:
	health = min(health + amount, max_health)
	emit_signal("health_changed", health, max_health)

func die() -> void:
	dead = true
	remove_from_group("player")
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = true
	# Para música de fundo
	if $"../LevelMusic".playing:
		$"../LevelMusic".stop()

	# Toca música da morte
	if $"../DeathSong":
		$"../DeathSong".play()
		
	animated_sprite.modulate = Color.WHITE
	set_collision_mask_value(1, false)
	animated_sprite.play("death")

	var tween = create_tween()
	for i in range(3):
		tween.tween_property(animated_sprite, "modulate", Color(2, 2, 2), 0.05)
		tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.05)
	tween.tween_property(animated_sprite, "modulate:a", 0.0, 2)
	await tween.finished

	var game_over_scene = preload("res://scenes/gameOver/gameOver.tscn")
	var game_over_instance = game_over_scene.instantiate()
	get_tree().root.add_child(game_over_instance)
	var main = get_tree().root.get_node("Main")
	var hud = main.get_node("HUD")
	hud.visible = false
	await get_tree().create_timer(3).timeout

	if is_instance_valid(get_tree()) and get_tree().root and is_inside_tree():
		get_tree().change_scene_to_file("res://scenes/main-menu/main_menu.tscn")

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
		var damage = 30 if is_dash_attack else 10
		body.take_damage(damage, global_position)
