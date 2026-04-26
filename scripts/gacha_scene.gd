extends Control

@onready var ball = $Ball
@onready var light = $PrizeLight
@onready var prize_display = $PrizeDisplay
@onready var result_label = $ResultLabel
@onready var back_button = $BackButton
@onready var draw_button = $DrawButton
@onready var multi_draw_button = $MultiDrawButton
@onready var tickets_label = $TicketsLabel

var is_animating := false
var _result_container: Control = null
var _choice_container: Control = null

func _ready() -> void:
	prize_display.hide()
	light.hide()
	ball.show()
	result_label.text = "¡Pulsa para abrir una bola!"
	back_button.show()
	_update_tickets(GameManager.tickets)
	GameManager.tickets_changed.connect(_update_tickets)

func _update_tickets(amount: int) -> void:
	tickets_label.text = "Tickets: %d" % amount
	multi_draw_button.visible = amount >= 12

func _cleanup_result() -> void:
	if _result_container:
		_result_container.queue_free()
		_result_container = null
	if _choice_container:
		_choice_container.queue_free()
		_choice_container = null

func _on_draw_button_pressed() -> void:
	if is_animating or GameManager.tickets <= 0: return

	is_animating = true
	back_button.hide()
	ball.show()
	prize_display.hide()
	_cleanup_result()
	result_label.text = "Abriendo..."

	var tween = create_tween()
	tween.tween_property(ball, "rotation_degrees", 15.0, 0.1)
	tween.tween_property(ball, "rotation_degrees", -15.0, 0.1)
	tween.tween_property(ball, "rotation_degrees", 15.0, 0.1)
	tween.tween_property(ball, "rotation_degrees", 0.0, 0.1)
	await tween.finished

	var draw = GameManager.draw_gacha()
	var result_id: int = draw["unit_id"]
	ball.hide()
	light.show()
	light.emitting = true

	await get_tree().create_timer(0.5).timeout

	prize_display.show()
	prize_display.color = draw["color"]

	if draw["is_duplicate"]:
		var unit_name: String = GameManager.UNIT_STATS[result_id].name
		var at_max := GameManager.unit_levels[result_id] >= 100
		result_label.text = "¡Ya tienes %s!" % unit_name
		_show_duplicate_choice(result_id, at_max)
	else:
		result_label.text = "¡Has conseguido: " + GameManager.UNIT_STATS[result_id].name + "!"
		await get_tree().create_timer(1.0).timeout
		is_animating = false
		back_button.show()

func _show_duplicate_choice(unit_id: int, at_max: bool) -> void:
	draw_button.hide()
	multi_draw_button.hide()

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)

	var level_btn := Button.new()
	level_btn.custom_minimum_size = Vector2(185, 55)
	level_btn.add_theme_font_size_override("font_size", 17)
	if at_max:
		level_btn.text = "Nv. MAX"
		level_btn.disabled = true
	else:
		level_btn.text = "Subir a Nv.%d" % (GameManager.unit_levels[unit_id] + 1)
		level_btn.pressed.connect(func():
			GameManager.level_up_unit(unit_id)
			_resolve_choice()
		)
	hbox.add_child(level_btn)

	var sell_btn := Button.new()
	sell_btn.custom_minimum_size = Vector2(185, 55)
	sell_btn.add_theme_font_size_override("font_size", 17)
	sell_btn.text = "Vender %d MP" % GameManager.get_sell_price(unit_id)
	sell_btn.pressed.connect(func():
		GameManager.sell_gacha_duplicate(unit_id)
		_resolve_choice()
	)
	hbox.add_child(sell_btn)

	add_child(hbox)
	_choice_container = hbox

	# 185 + 20 (separación) + 185 = 390px de ancho total
	hbox.position = Vector2((1280 - 390) / 2.0, 590)

func _resolve_choice() -> void:
	if _choice_container:
		_choice_container.queue_free()
		_choice_container = null
	is_animating = false
	back_button.show()
	draw_button.show()

func _on_multi_draw_button_pressed() -> void:
	if is_animating or GameManager.tickets < 12: return

	is_animating = true
	back_button.hide()
	draw_button.hide()
	multi_draw_button.hide()
	ball.show()
	prize_display.hide()
	_cleanup_result()
	result_label.text = "Abriendo 12 bolas..."

	var tween = create_tween()
	tween.tween_property(ball, "rotation_degrees", 360.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	var results = GameManager.draw_gacha_multi(12)
	ball.hide()
	light.show()
	light.emitting = true
	result_label.text = ""

	await get_tree().create_timer(0.4).timeout

	_show_result_grid(results)

	await get_tree().create_timer(2.0).timeout
	is_animating = false
	back_button.show()
	draw_button.show()

func _show_result_grid(results: Array) -> void:
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)

	for draw in results:
		grid.add_child(_create_result_cell(draw))

	add_child(grid)
	_result_container = grid

	var grid_w := 110 * 4 + 8 * 3
	var grid_h := 80 * 3 + 8 * 2
	grid.position = Vector2((1280 - grid_w) / 2.0, (720 - grid_h) / 2.0 - 40)

func _create_result_cell(draw: Dictionary) -> Control:
	var unit: Dictionary = GameManager.UNIT_STATS[draw["unit_id"]]

	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(110, 80)

	var style := StyleBoxFlat.new()
	style.bg_color = draw["color"].darkened(0.35)
	style.set_corner_radius_all(8)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = draw["color"]
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)

	if draw["leveled_up"]:
		label.text = unit.name + "\n¡Nv." + str(draw["new_level"]) + "!"
		label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		label.text = unit.name + "\n¡NUEVA!"
		label.add_theme_color_override("font_color", Color.WHITE)

	panel.add_child(label)
	return panel

func _on_back_button_pressed() -> void:
	_cleanup_result()
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")
