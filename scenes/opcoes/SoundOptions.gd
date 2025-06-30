extends CanvasLayer

@onready var mute_button = $ButtonMute
@onready var unmute_button = $ButtonUnmute

func _ready():
	mute_button.pressed.connect(_on_mute_pressed)
	unmute_button.pressed.connect(_on_unmute_pressed)

func _on_mute_pressed():
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
	mute_button.visible = false
	unmute_button.visible = true
	get_tree().change_scene_to_file("res://scenes/main-menu/main_menu.tscn")

func _on_unmute_pressed():
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
	mute_button.visible = true
	unmute_button.visible = false
	get_tree().change_scene_to_file("res://scenes/main-menu/main_menu.tscn")	
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://scenes/main-menu/main_menu.tscn")
