extends Node2D

var dragging = false
var last_mouse_pos = Vector2()

@onready var camera = $Camera2D
@onready var bg = $Background

func _ready():
	# Zoom agresivo para que el mapa se sienta inmenso
	camera.zoom = Vector2(2.5, 2.5)
	
	# Forzamos que el fondo sea el doble de grande
	if bg is Sprite2D:
		bg.scale = Vector2(2.0, 2.0)
	elif bg is ColorRect:
		bg.size = Vector2(2816, 1536) * 2.0
		if has_node("StonePath"):
			$StonePath.scale = Vector2(2.0, 2.0)
	
	# Posicionamos la cámara inicialmente y aplicamos límites
	_update_camera_limits()

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			last_mouse_pos = event.position
			
	if event is InputEventMouseMotion and dragging:
		var delta = (last_mouse_pos - event.position) / camera.zoom
		camera.position += delta
		last_mouse_pos = event.position
		_update_camera_limits()

func _update_camera_limits():
	var map_size = Vector2(2816, 1536)
	if bg is Sprite2D and bg.texture:
		map_size = bg.texture.get_size()
	
	# Tamaño real tras la escala
	var final_size = map_size * bg.scale
	
	var screen_size = get_viewport_rect().size / camera.zoom
	var half_screen = screen_size / 2.0
	
	camera.position.x = clamp(camera.position.x, half_screen.x, final_size.x - half_screen.x)
	camera.position.y = clamp(camera.position.y, half_screen.y, final_size.y - half_screen.y)

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/StageSelection.tscn")
