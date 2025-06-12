extends Sprite2D

var original_position := Vector2()
var float_amplitude := 10
var float_speed := 2.5
var time := 0.0

func _ready():
	original_position = position

func _process(delta):
	time += delta
	position.y = original_position.y + sin(time * float_speed) * float_amplitude
