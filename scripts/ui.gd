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
	
	GameManager.money_changed.connect(_on_money_changed)
	_on_money_changed(GameManager.money)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_5:
			var idx = event.keycode - KEY_1
			if idx < GameManager.active_deck.size():
				var unit_id = GameManager.active_deck[idx]
				if GameManager.can_afford(GameManager.UNIT_COSTS[unit_id]):
					spawn_requested.emit(unit_id)

func _on_money_changed(amount: float) -> void:
	if not is_instance_valid(self): return
	$BottomBar/MoneyLabel.text = "€ %d" % int(amount)
	for unit_id in buttons.keys():
		var btn = buttons[unit_id]
		if is_instance_valid(btn):
			var affordable := GameManager.can_afford(GameManager.UNIT_COSTS[unit_id])
			btn.modulate = Color.WHITE if affordable else Color(0.45, 0.45, 0.45)

func _create_unit_button(unit_id: int, deck_pos: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(90, 90)
	btn.pressed.connect(func():
		if GameManager.can_afford(GameManager.UNIT_COSTS[unit_id]):
			spawn_requested.emit(unit_id)
	)

	var preview := ColorRect.new()
	preview.color = UNIT_COLORS[unit_id]
	preview.size = Vector2(28, 44)
	preview.position = Vector2(31, 14)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(preview)

	var key_label := Label.new()
	key_label.text = str(deck_pos + 1)
	key_label.position = Vector2(5, 4)
	key_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(key_label)

	var cost_label := Label.new()
	cost_label.text = "€%d" % GameManager.UNIT_COSTS[unit_id]
	cost_label.size = Vector2(80, 20)
	cost_label.position = Vector2(5, 68)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(cost_label)

	return btn

func _create_empty_slot() -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(90, 90)
	btn.disabled = true
	return btn
