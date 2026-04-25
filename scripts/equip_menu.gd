extends Control

@onready var grid = $ScrollContainer/GridContainer
@onready var back_button = $BackButton

func _ready():
	_refresh_ui()

func _refresh_ui():
	# Limpiar grid actual
	for child in grid.get_children():
		child.queue_free()
	
	# Crear un botón por cada unidad del juego
	for i in range(GameManager.UNIT_STATS.size()):
		var btn = Button.new()
		var unit = GameManager.UNIT_STATS[i]
		
		btn.custom_minimum_size = Vector2(150, 150)
		btn.text = unit.name + "\n" + str(GameManager.UNIT_COSTS[i])
		
		# Si no la tenemos, desactivar o poner color oscuro
		if not GameManager.owned_units.has(i):
			btn.disabled = true
			btn.modulate = Color(0.3, 0.3, 0.3)
		else:
			# Si está en el deck activo, marcarla
			if GameManager.active_deck.has(i):
				btn.modulate = Color(1, 1, 0) # Amarillo para equipadas
			
			btn.pressed.connect(_on_unit_selected.bind(i))
		
		grid.add_child(btn)

func _on_unit_selected(unit_id):
	if GameManager.active_deck.has(unit_id):
		GameManager.remove_from_deck(unit_id)
	else:
		GameManager.add_to_deck(unit_id)
	_refresh_ui()

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")
