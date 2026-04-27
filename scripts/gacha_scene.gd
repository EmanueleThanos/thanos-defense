extends Control

@onready var ball             = $Ball
@onready var light            = $PrizeLight
@onready var prize_display    = $PrizeDisplay
@onready var result_label     = $ResultLabel
@onready var back_button      = $BackButton
@onready var draw_button      = $DrawButton
@onready var multi_5_button   = $MultiDraw5Button
@onready var multi_12_button  = $MultiDrawButton
@onready var multi_100_button = $MultiDraw100Button
@onready var tickets_label    = $TicketsLabel

var is_animating    := false
var _result_container: Control = null
var _choice_container: Control = null
var _pending_results: Array    = []
var _sell_set: Array           = []

func _ready() -> void:
	prize_display.hide()
	light.hide()
	ball.show()
	result_label.text = "¡Pulsa para abrir una bola!"
	back_button.show()
	_update_tickets(GameManager.tickets)
	GameManager.tickets_changed.connect(_update_tickets)

func _update_tickets(amount: int) -> void:
	tickets_label.text = "🎟 Tickets: %d" % amount
	multi_5_button.visible   = amount >= 5
	multi_12_button.visible  = amount >= 12
	multi_100_button.visible = amount >= 100

func _cleanup_result() -> void:
	if _result_container:
		_result_container.queue_free()
		_result_container = null
	if _choice_container:
		_choice_container.queue_free()
		_choice_container = null

func _show_main_buttons() -> void:
	draw_button.show()
	_update_tickets(GameManager.tickets)

# ─── Tirada individual ────────────────────────────────────────────────────────
func _on_draw_button_pressed() -> void:
	if is_animating or GameManager.tickets <= 0: return
	is_animating = true
	back_button.hide()
	ball.show()
	prize_display.hide()
	_cleanup_result()
	result_label.text = "Abriendo..."

	var tw = create_tween()
	tw.tween_property(ball, "rotation_degrees",  15.0, 0.1)
	tw.tween_property(ball, "rotation_degrees", -15.0, 0.1)
	tw.tween_property(ball, "rotation_degrees",  15.0, 0.1)
	tw.tween_property(ball, "rotation_degrees",   0.0, 0.1)
	await tw.finished

	var result = GameManager.draw_gacha()
	var result_id: int = result["unit_id"]
	ball.hide()
	light.show()
	light.emitting = true
	await get_tree().create_timer(0.5).timeout

	prize_display.show()
	prize_display.color = result["color"]

	if result["is_duplicate"]:
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
	multi_5_button.hide()
	multi_12_button.hide()

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)

	var lv_btn := Button.new()
	lv_btn.custom_minimum_size = Vector2(185, 55)
	lv_btn.add_theme_font_size_override("font_size", 17)
	if at_max:
		lv_btn.text = "Nv. MAX"
		lv_btn.disabled = true
	else:
		lv_btn.text = "Subir a Nv.%d" % (GameManager.unit_levels[unit_id] + 1)
		lv_btn.pressed.connect(func():
			GameManager.level_up_unit(unit_id)
			_resolve_single_choice()
		)
	hbox.add_child(lv_btn)

	var sell_btn := Button.new()
	sell_btn.custom_minimum_size = Vector2(185, 55)
	sell_btn.add_theme_font_size_override("font_size", 17)
	sell_btn.text = "Vender %d MP" % GameManager.get_sell_price(unit_id)
	sell_btn.pressed.connect(func():
		GameManager.sell_gacha_duplicate(unit_id)
		_resolve_single_choice()
	)
	hbox.add_child(sell_btn)

	add_child(hbox)
	_choice_container = hbox
	hbox.position = Vector2((1280 - 390) / 2.0, 590)

func _resolve_single_choice() -> void:
	if _choice_container:
		_choice_container.queue_free()
		_choice_container = null
	is_animating = false
	back_button.show()
	_show_main_buttons()

# ─── Tiradas múltiples ────────────────────────────────────────────────────────
func _on_multi_5_pressed() -> void:
	_start_multi_draw(5)

func _on_multi_12_pressed() -> void:
	_start_multi_draw(12)

func _on_multi_100_pressed() -> void:
	_start_multi_draw(100)

func _start_multi_draw(count: int) -> void:
	if is_animating or GameManager.tickets < count: return
	is_animating = true
	back_button.hide()
	draw_button.hide()
	multi_5_button.hide()
	multi_12_button.hide()
	multi_100_button.hide()
	ball.show()
	prize_display.hide()
	_cleanup_result()
	result_label.text = "Abriendo %d bolas..." % count

	var tw = create_tween()
	tw.tween_property(ball, "rotation_degrees", 360.0, 0.6)\
	  .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tw.finished

	var results := GameManager.draw_gacha_multi_preview(count)
	ball.hide()
	light.show()
	light.emitting = true
	result_label.text = "Toca las cartas que quieras vender"

	await get_tree().create_timer(0.35).timeout
	_show_interactive_grid(results)

# ─── Cuadrícula interactiva ───────────────────────────────────────────────────
func _show_interactive_grid(results: Array) -> void:
	_pending_results = results
	_sell_set = []

	var cols       := 5 if results.size() <= 5 else 4
	var rows       := ceili(float(results.size()) / float(cols))
	var cell_w     := 110
	var cell_h     := 80
	var gap        := 8
	var grid_w     := cols * cell_w + (cols - 1) * gap
	var grid_h     := rows * cell_h + (rows - 1) * gap
	var btn_h      := 52
	var total_h    := grid_h + 14 + btn_h
	var ox: float  = (1280 - grid_w) / 2.0
	var oy: float  = maxf((720 - total_h) / 2.0 - 20.0, 75.0)

	# Contenedor raíz para cleanup fácil
	var wrapper := Control.new()
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wrapper)
	_result_container = wrapper

	var grid := GridContainer.new()
	grid.columns = cols
	grid.add_theme_constant_override("h_separation", gap)
	grid.add_theme_constant_override("v_separation", gap)
	grid.position = Vector2(ox, oy)
	wrapper.add_child(grid)

	for i in results.size():
		grid.add_child(_make_cell(i, results[i], false))

	var collect_btn := Button.new()
	collect_btn.text = "RECOGER TODO"
	collect_btn.add_theme_font_size_override("font_size", 20)
	collect_btn.add_theme_color_override("font_color", Color(0.35, 1.0, 0.55))
	collect_btn.custom_minimum_size = Vector2(grid_w, btn_h)
	collect_btn.position = Vector2(ox, oy + grid_h + 14)
	collect_btn.pressed.connect(_on_collect_all)
	wrapper.add_child(collect_btn)

# ─── Celda de carta ──────────────────────────────────────────────────────────
func _make_cell(idx: int, data: Dictionary, is_sell: bool) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(110, 80)
	btn.pivot_offset = Vector2(55, 40)
	btn.flat = true

	var style_base := StyleBoxFlat.new()
	style_base.set_corner_radius_all(8)
	for s in [0, 1, 2, 3]:
		style_base.set_border_width(s, 2)

	var style_hov := StyleBoxFlat.new()
	style_hov.set_corner_radius_all(8)
	for s in [0, 1, 2, 3]:
		style_hov.set_border_width(s, 2)

	if is_sell:
		style_base.bg_color    = Color(0.55, 0.07, 0.07)
		style_base.border_color = Color(1.0, 0.30, 0.30)
		style_hov.bg_color     = Color(0.68, 0.10, 0.10)
		style_hov.border_color  = Color(1.0, 0.50, 0.50)
	else:
		style_base.bg_color    = data["color"].darkened(0.35)
		style_base.border_color = data["color"]
		style_hov.bg_color     = data["color"].darkened(0.20)
		style_hov.border_color  = data["color"].lightened(0.20)

	btn.add_theme_stylebox_override("normal",   style_base)
	btn.add_theme_stylebox_override("pressed",  style_base)
	btn.add_theme_stylebox_override("hover",    style_hov)
	btn.add_theme_stylebox_override("focus",    style_base)

	var lbl := Label.new()
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if is_sell:
		lbl.text = "VENDER\n%d MP" % data["sell_price"]
		lbl.add_theme_color_override("font_color", Color(1.0, 0.78, 0.78))
	else:
		var unit: Dictionary = GameManager.UNIT_STATS[data["unit_id"]]
		if data["is_duplicate"]:
			lbl.text = "%s\nNv.%d dup." % [unit.name, GameManager.unit_levels[data["unit_id"]]]
			lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 0.40))
		else:
			lbl.text = "%s\n¡NUEVA!" % unit.name
			lbl.add_theme_color_override("font_color", Color(0.45, 1.0, 0.55))

	btn.add_child(lbl)
	btn.pressed.connect(func(): _flip_card(idx, btn, data))
	return btn

# ─── Animación de giro de carta ───────────────────────────────────────────────
func _flip_card(idx: int, btn: Button, data: Dictionary) -> void:
	btn.mouse_filter = Control.MOUSE_FILTER_IGNORE   # bloquear durante animación
	var selling := _sell_set.has(idx)
	var parent  := btn.get_parent()
	var pos     := btn.get_index()

	var t1 := btn.create_tween()
	t1.tween_property(btn, "scale", Vector2(0.0, 1.0), 0.10)
	t1.tween_callback(func():
		if selling:
			_sell_set.erase(idx)
		else:
			_sell_set.append(idx)

		var new_cell := _make_cell(idx, data, not selling)
		new_cell.scale = Vector2(0.0, 1.0)
		parent.add_child(new_cell)
		parent.move_child(new_cell, pos)
		btn.queue_free()

		var t2 := new_cell.create_tween()
		t2.tween_property(new_cell, "scale", Vector2(1.0, 1.0), 0.10)
	)

# ─── Recoger todo ─────────────────────────────────────────────────────────────
func _on_collect_all() -> void:
	GameManager.apply_gacha_results(_pending_results, _sell_set)
	_pending_results = []
	_sell_set = []
	_cleanup_result()
	is_animating = false
	result_label.text = "¡Recogido!"
	back_button.show()
	_show_main_buttons()

func _on_back_button_pressed() -> void:
	_cleanup_result()
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")
