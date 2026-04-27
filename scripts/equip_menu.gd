extends Control

const _UNIT_COLORS := [
	Color.CORNFLOWER_BLUE,
	Color(0.88, 0.28, 0.18),
	Color(0.22, 0.65, 0.30),
	Color(0.8, 0.8, 0.8),
]

var _visual_script = preload("res://scripts/unit_visual.gd")

@onready var grid = $ScrollContainer/GridContainer
@onready var back_button = $BackButton

func _ready() -> void:
	_refresh_ui()

func _refresh_ui() -> void:
	for child in grid.get_children():
		child.queue_free()

	for i in range(GameManager.UNIT_STATS.size()):
		if not GameManager.owned_units.has(i):
			continue

		var unit: Dictionary = GameManager.UNIT_STATS[i]

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(150, 195)
		btn.add_theme_font_size_override("font_size", 13)
		btn.text = "%s\nNv.%d\n€%d" % [unit.name, GameManager.unit_levels[i], GameManager.UNIT_COSTS[i]]

		var visual = _visual_script.new()
		visual.unit_type = i
		visual.color = _UNIT_COLORS[i]
		visual.is_walking = false
		visual.scale = Vector2(1.5, 1.5)
		visual.position = Vector2(75, 158)
		btn.add_child(visual)

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
