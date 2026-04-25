extends Control

func _ready():
	_update_tickets_display(GameManager.tickets)
	GameManager.tickets_changed.connect(_update_tickets_display)

func _update_tickets_display(amount):
	$TicketsLabel.text = "Tickets: " + str(amount)

func _on_battle_button_pressed():
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_gacha_button_pressed():
	get_tree().change_scene_to_file("res://scenes/Gacha.tscn")

func _on_equip_button_pressed():
	get_tree().change_scene_to_file("res://scenes/Equip.tscn")
