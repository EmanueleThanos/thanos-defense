extends Control

@onready var ball = $Ball
@onready var light = $PrizeLight
@onready var prize_display = $PrizeDisplay
@onready var result_label = $ResultLabel
@onready var back_button = $BackButton

var is_animating = false

func _ready():
	prize_display.hide()
	light.hide()
	result_label.text = "¡Pulsa para abrir una bola!"
	back_button.show()

func _on_draw_button_pressed():
	if is_animating or GameManager.tickets <= 0: return
	
	is_animating = true
	back_button.hide()
	result_label.text = "Abriendo..."
	
	# 1. Animación de la bola vibrando
	var tween = create_tween()
	tween.tween_property(ball, "rotation_degrees", 15.0, 0.1)
	tween.tween_property(ball, "rotation_degrees", -15.0, 0.1)
	tween.tween_property(ball, "rotation_degrees", 15.0, 0.1)
	tween.tween_property(ball, "rotation_degrees", 0.0, 0.1)
	
	await tween.finished
	
	# 2. Explosión de luz
	var result_id = GameManager.draw_gacha()
	ball.hide()
	light.show()
	light.emitting = true
	
	await get_tree().create_timer(0.5).timeout
	
	# 3. Mostrar el premio
	prize_display.show()
	prize_display.color = [Color.CORNFLOWER_BLUE, Color.INDIAN_RED, Color.DARK_GREEN][result_id]
	result_label.text = "¡Has conseguido: " + GameManager.UNIT_STATS[result_id].name + "!"
	
	await get_tree().create_timer(1.0).timeout
	is_animating = false
	back_button.show()

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")
