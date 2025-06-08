extends Sprite2D

var skew_direction := 1
@export var skew_speed := 2.5  # velocidade de mudança
var skew_value := 0.0

func _process(delta):
	skew_value += delta * skew_speed * skew_direction

	if abs(skew_value) >= PI / 1.5:
		skew_value = clamp(skew_value, -PI / 2, PI / 2)
		skew_value = -1
		flip_v = !flip_v

	skew = skew_value
