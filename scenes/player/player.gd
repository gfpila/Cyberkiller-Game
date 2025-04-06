extends CharacterBody2D

const SPEED = 400  # Velocidade de movimento
const JUMP_VELOCITY = -700  # Força do pulo
const GRAVITY = 2000  # Gravidade aplicada ao personagem

func _physics_process(delta: float) -> void:
	# Aplica gravidade
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Obtém a direção horizontal do movimento
	var direction := Input.get_axis("left", "right")
	velocity.x = direction * SPEED

	# Se pressionar pulo e estiver no chão, aplica a força do pulo
	if Input.is_action_just_pressed("jump") and is_on_floor():
		$Audio/jump.play()
		velocity.y = JUMP_VELOCITY

	# Atualiza a posição do personagem com colisão
	move_and_slide()

	# Se a animação de ataque ainda estiver rodando, não muda a animação
	if $AnimatedSprite2D.animation == "attack_animation" and $AnimatedSprite2D.is_playing():
		return 

	# Se pressionar ataque, prioriza a animação de ataque
	if Input.is_action_just_pressed("attack"):
		$Audio/attack.play()
		$AnimatedSprite2D.play("attack_animation")

	# Se estiver no ar, toca a animação de pulo
	elif not is_on_floor():
		$AnimatedSprite2D.play("jump")

	# Se estiver se movendo, toca a animação de corrida
	elif direction != 0:
		$AnimatedSprite2D.play("run")

		# Flip da sprite baseado na direção do movimento
		$AnimatedSprite2D.flip_h = direction < 0
	else:
		$AnimatedSprite2D.play("default")
