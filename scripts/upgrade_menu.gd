extends Control

@onready var mp_label: Label       = $Header/MPLabel
@onready var content: VBoxContainer = $ScrollContainer/VBox

func _ready() -> void:
	GameManager.mp_changed.connect(_on_mp_changed)
	_refresh()

func _on_mp_changed(_amount: int) -> void:
	_refresh()

# ─── Rebuild ──────────────────────────────────────────────────────────────────
func _refresh() -> void:
	mp_label.text = "MP: %d" % GameManager.mp
	for child in content.get_children():
		child.queue_free()

	_add_header("── UNIDADES ──")
	for i in GameManager.UNIT_STATS.size():
		if GameManager.owned_units.has(i):
			_add_unit_row(i)

	_add_header("── BASE ──")
	_add_base_row(
		"Vida Base", "HP",
		GameManager.base_hp_level, 50,
		"%d" % GameManager.get_player_max_hp(),
		"%d" % (GameManager.get_player_max_hp() + 250),
		GameManager.upgrade_cost_base_hp(GameManager.base_hp_level),
		func() -> void: GameManager.try_upgrade_base_hp()
	)
	_add_base_row(
		"Producción", "MP/s",
		GameManager.production_level, 100,
		"%.1f" % GameManager.get_money_rate(),
		"%.1f" % _next_rate(),
		GameManager.upgrade_cost_production(GameManager.production_level),
		func() -> void: GameManager.try_upgrade_production()
	)
	_add_base_row(
		"Slots de mazo", "Slots",
		GameManager.max_units_level, 8,
		"%d" % GameManager.get_max_units(),
		"%d" % (GameManager.get_max_units() + (1 if GameManager.max_units_level < 8 else 0)),
		GameManager.upgrade_cost_max_units(GameManager.max_units_level),
		func() -> void: GameManager.try_upgrade_max_units()
	)

func _next_rate() -> float:
	var nxt := GameManager.production_level + 1
	if nxt >= 100: return 1000.0
	return 15.0 + (485.0 / 98.0) * (nxt - 1)

# ─── Row builders ─────────────────────────────────────────────────────────────
func _add_header(title: String) -> void:
	var lbl := Label.new()
	lbl.text = title
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	lbl.add_theme_constant_override("margin_top", 18)
	content.add_child(lbl)

func _add_unit_row(unit_id: int) -> void:
	var stats: Dictionary = GameManager.UNIT_STATS[unit_id]
	var lvl: int  = GameManager.unit_levels[unit_id]
	var cost: int = GameManager.upgrade_cost_unit(lvl)
	var mult_cur  := 1.0 + 0.25 * (lvl - 1)
	var mult_nxt  := 1.0 + 0.25 * lvl
	var at_max    := lvl >= 100

	var info := "%s  |  Nv.%d/100  |  Daño: %d → %d  |  HP: %d → %d" % [
		stats["name"], lvl,
		int(stats["damage"] * mult_cur), int(stats["damage"] * mult_nxt),
		int(stats["health"] * mult_cur), int(stats["health"] * mult_nxt),
	]
	_add_row(info, cost, at_max, func() -> void: GameManager.try_upgrade_unit(unit_id))

func _add_base_row(name: String, unit: String, lvl: int, max_lvl: int,
				   cur_val: String, nxt_val: String, cost: int,
				   upgrade_fn: Callable) -> void:
	var at_max := lvl >= max_lvl
	var info := "%s  |  Nv.%d/%d  |  %s: %s → %s" % [
		name, lvl, max_lvl, unit, cur_val, nxt_val
	]
	_add_row(info, cost, at_max, upgrade_fn)

func _add_row(info: String, cost: int, at_max: bool, upgrade_fn: Callable) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	hbox.custom_minimum_size = Vector2(0, 52)

	var lbl := Label.new()
	lbl.text = info
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 16)
	hbox.add_child(lbl)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(160, 0)
	btn.add_theme_font_size_override("font_size", 15)
	if at_max:
		btn.text = "MAX"
		btn.disabled = true
	else:
		btn.text = "MEJORAR  %d MP" % cost
		btn.disabled = GameManager.mp < cost
		btn.pressed.connect(func() -> void:
			upgrade_fn.call()
		)
	hbox.add_child(btn)
	content.add_child(hbox)

	# Separador
	var sep := HSeparator.new()
	content.add_child(sep)

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")
