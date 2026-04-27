extends CanvasLayer

signal spawn_requested(unit_index: int)

var TOTAL_SLOTS: int:
	get: return GameManager.get_max_units()

const UNIT_COLORS := [
	Color.CORNFLOWER_BLUE,
	Color(0.88, 0.28, 0.18),
	Color(0.22, 0.65, 0.30),
	Color(0.8, 0.8, 0.8)
]

var buttons: Dictionary = {}

@onready var pause_overlay  : Control       = $PauseOverlay
@onready var confirm_panel  : PanelContainer = $PauseOverlay/ConfirmPanel
@onready var music_slider   : HSlider       = $PauseOverlay/Panel/VBox/MusicRow/MusicSlider
@onready var sfx_slider     : HSlider       = $PauseOverlay/Panel/VBox/SFXRow/SFXSlider

func _ready() -> void:
	if $BottomBar/ButtonRow:
		for child in $BottomBar/ButtonRow.get_children():
			child.queue_free()
		for i in range(GameManager.active_deck.size()):
			var unit_id = GameManager.active_deck[i]
			var btn = _create_unit_button(unit_id, i)
			buttons[unit_id] = btn
			$BottomBar/ButtonRow.add_child(btn)
		for i in range(GameManager.active_deck.size(), TOTAL_SLOTS):
			$BottomBar/ButtonRow.add_child(_create_empty_slot())

	# Restaurar volúmenes guardados
	music_slider.value = GameManager.music_volume
	sfx_slider.value   = GameManager.sfx_volume
	_apply_music_volume(GameManager.music_volume)
	_apply_sfx_volume(GameManager.sfx_volume)

	GameManager.money_changed.connect(_on_money_changed)
	_on_money_changed(GameManager.money)

func _input(event: InputEvent) -> void:
	# Teclas numéricas para spawnear
	if not pause_overlay.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode >= KEY_1 and event.keycode <= KEY_5:
				var idx = event.keycode - KEY_1
				if idx < GameManager.active_deck.size():
					var unit_id = GameManager.active_deck[idx]
					if GameManager.can_afford(GameManager.UNIT_COSTS[unit_id]):
						spawn_requested.emit(unit_id)

	# ESC abre/cierra el menú de pausa
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if confirm_panel.visible:
			_on_no_pressed()
		else:
			_toggle_pause()

# ─── Pausa ────────────────────────────────────────────────────────────────────
func _toggle_pause() -> void:
	pause_overlay.visible = !pause_overlay.visible
	confirm_panel.visible = false
	get_tree().paused = pause_overlay.visible

func _on_retirada_button_pressed() -> void:
	_toggle_pause()

func _on_continuar_pressed() -> void:
	_toggle_pause()

func _on_retirada_confirm_pressed() -> void:
	confirm_panel.visible = true

func _on_si_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/StageSelection.tscn")

func _on_no_pressed() -> void:
	confirm_panel.visible = false

# ─── Volumen ──────────────────────────────────────────────────────────────────
func _on_music_volume_changed(value: float) -> void:
	GameManager.music_volume = value
	_apply_music_volume(value)

func _on_sfx_volume_changed(value: float) -> void:
	GameManager.sfx_volume = value
	_apply_sfx_volume(value)

func _apply_music_volume(value: float) -> void:
	var idx := AudioServer.get_bus_index("Music")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(value) if value > 0.01 else -80.0)
		AudioServer.set_bus_mute(idx, value <= 0.01)

func _apply_sfx_volume(value: float) -> void:
	var idx := AudioServer.get_bus_index("SFX")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(value) if value > 0.01 else -80.0)
		AudioServer.set_bus_mute(idx, value <= 0.01)

# ─── Dinero ───────────────────────────────────────────────────────────────────
func _on_money_changed(amount: float) -> void:
	if not is_instance_valid(self): return
	$BottomBar/MoneyLabel.text = "€ %d" % int(amount)
	for unit_id in buttons.keys():
		var btn = buttons[unit_id]
		if is_instance_valid(btn):
			btn.modulate = Color.WHITE if GameManager.can_afford(GameManager.UNIT_COSTS[unit_id]) else Color(0.45, 0.45, 0.45)

# ─── Botones de unidad ────────────────────────────────────────────────────────
func _create_unit_button(unit_id: int, deck_pos: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(90, 95)
	btn.pressed.connect(func():
		if GameManager.can_afford(GameManager.UNIT_COSTS[unit_id]):
			spawn_requested.emit(unit_id)
	)

	var visual_script = preload("res://scripts/unit_visual.gd")
	var preview = visual_script.new()
	preview.unit_type  = unit_id
	preview.color      = UNIT_COLORS[unit_id]
	preview.is_walking = false
	preview.scale      = Vector2(0.72, 0.72)
	preview.position   = Vector2(45, 66)  # pies centrados, zona media del botón
	btn.add_child(preview)

	var key_label := Label.new()
	key_label.text = str(deck_pos + 1)
	key_label.position = Vector2(5, 4)
	key_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(key_label)

	var cost_label := Label.new()
	cost_label.text = "€%d" % GameManager.UNIT_COSTS[unit_id]
	cost_label.size = Vector2(80, 20)
	cost_label.position = Vector2(5, 70)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(cost_label)

	return btn

func _create_empty_slot() -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(90, 90)
	btn.disabled = true
	return btn
