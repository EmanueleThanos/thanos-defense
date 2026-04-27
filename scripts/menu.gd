extends Control

func _ready() -> void:
	_update_tickets_display(GameManager.tickets)
	_update_mp_display(GameManager.mp)
	GameManager.tickets_changed.connect(_update_tickets_display)
	GameManager.mp_changed.connect(_update_mp_display)
	$VBoxContainer/MejorarButton.visible = GameManager.chapter_progress.get("legend", 0) >= 1

func _update_tickets_display(amount: int) -> void:
	$TicketsLabel.text = "Tickets: %d" % amount

func _update_mp_display(amount: int) -> void:
	$MPLabel.text = "MP: %d" % amount

func _on_battle_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/StageSelection.tscn")

func _on_gacha_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Gacha.tscn")

func _on_equip_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Equip.tscn")

func _on_mejorar_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Upgrade.tscn")
