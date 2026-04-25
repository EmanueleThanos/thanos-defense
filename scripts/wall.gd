extends Area2D

@export var max_health: int = 350
var current_health: int

func _ready() -> void:
	current_health = max_health
	collision_layer = 1
	collision_mask = 0

func take_damage(amount: int) -> void:
	current_health -= amount
	if current_health <= 0:
		queue_free()
