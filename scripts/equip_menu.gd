extends Control

@onready var grid = $ScrollContainer/GridContainer
@onready var back_button = $BackButton

func _ready() -> void:
	_refresh_ui()

func _refresh_ui() -> void:
	for child in grid.get_children():
		child.queue_free()

	for i in range(GameManager.UNIT_STATS.size()):
		var unit: Dictionary = GameManager.UNIT_STATS[i]
		var owned := GameManager.owned_units.has(i)

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(150, 150)
		btn.text = "%s\nNv.%d\n€%d" % [unit.name, GameManager.unit_levels[i], GameManager.UNIT_COSTS[i]]

		if not owned:
			btn.disabled = true
			btn.modulate = Color(0.3, 0.3, 0.3)
		else:
			if GameManager.active_deck.has(i):
				btn.modulate = Color(1, 1, 0)
			btn.pressed.connect(_on_unit_selected.bind(i))

		grid.add_child(btn)

func _on_unit_selected(unit_id: int) -> void:
	if GameManager.active_deck.has(unit_id):
		GameManager.remove_from_deck(unit_id)
	else:
		GameManager.add_to_deck(unit_id)
	_refresh_ui()

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")
