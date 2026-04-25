extends CanvasLayer

var title_label: Label
var sub_label: Label

func _ready() -> void:
	layer = 10
	visible = false
	_build_ui()

func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.72)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var panel := Panel.new()
	panel.position = Vector2(390, 175)
	panel.size = Vector2(500, 340)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.07, 0.07, 0.14, 0.97)
	panel_style.set_corner_radius_all(18)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.3, 0.3, 0.5)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	title_label = Label.new()
	title_label.position = Vector2(0, 55)
	title_label.size = Vector2(500, 90)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 58)
	panel.add_child(title_label)

	sub_label = Label.new()
	sub_label.position = Vector2(0, 155)
	sub_label.size = Vector2(500, 36)
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.add_theme_font_size_override("font_size", 17)
	sub_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	panel.add_child(sub_label)

	var retry_btn := Button.new()
	retry_btn.text = "Reintentar"
	retry_btn.position = Vector2(25, 225)
	retry_btn.size = Vector2(205, 58)
	retry_btn.add_theme_font_size_override("font_size", 20)
	var s_normal := StyleBoxFlat.new()
	s_normal.bg_color = Color(0.18, 0.40, 0.82)
	s_normal.set_corner_radius_all(10)
	retry_btn.add_theme_stylebox_override("normal", s_normal)
	var s_hover := StyleBoxFlat.new()
	s_hover.bg_color = Color(0.28, 0.52, 0.95)
	s_hover.set_corner_radius_all(10)
	retry_btn.add_theme_stylebox_override("hover", s_hover)
	var s_pressed := StyleBoxFlat.new()
	s_pressed.bg_color = Color(0.12, 0.30, 0.65)
	s_pressed.set_corner_radius_all(10)
	retry_btn.add_theme_stylebox_override("pressed", s_pressed)
	retry_btn.add_theme_color_override("font_color", Color.WHITE)
	retry_btn.pressed.connect(func(): get_tree().reload_current_scene())
	panel.add_child(retry_btn)

	var menu_btn := Button.new()
	menu_btn.text = "Menú Principal"
	menu_btn.position = Vector2(270, 225)
	menu_btn.size = Vector2(205, 58)
	menu_btn.add_theme_font_size_override("font_size", 20)
	var m_normal := StyleBoxFlat.new()
	m_normal.bg_color = Color(0.20, 0.20, 0.20)
	m_normal.set_corner_radius_all(10)
	menu_btn.add_theme_stylebox_override("normal", m_normal)
	var m_hover := StyleBoxFlat.new()
	m_hover.bg_color = Color(0.35, 0.35, 0.35)
	m_hover.set_corner_radius_all(10)
	menu_btn.add_theme_stylebox_override("hover", m_hover)
	var m_pressed := StyleBoxFlat.new()
	m_pressed.bg_color = Color(0.12, 0.12, 0.12)
	m_pressed.set_corner_radius_all(10)
	menu_btn.add_theme_stylebox_override("pressed", m_pressed)
	menu_btn.add_theme_color_override("font_color", Color.WHITE)
	menu_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Menu.tscn"))
	panel.add_child(menu_btn)

func show_result(player_won: bool) -> void:
	visible = true
	if player_won:
		title_label.text = "¡VICTORIA!"
		title_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.1))
		sub_label.text = "Has destruido la base enemiga"
	else:
		title_label.text = "DERROTA"
		title_label.add_theme_color_override("font_color", Color.INDIAN_RED)
		sub_label.text = "Tu base ha sido destruida"
