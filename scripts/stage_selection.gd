extends Control

func _on_story_pressed():
	get_tree().change_scene_to_file("res://scenes/MapStory.tscn")

func _on_legend_pressed():
	get_tree().change_scene_to_file("res://scenes/MapLegend.tscn")

func _on_future_pressed():
	get_tree().change_scene_to_file("res://scenes/MapFuture.tscn")

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")
