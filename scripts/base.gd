extends Area2D

@export var max_health: int = 1000
@export var is_player_base: bool = true

var current_health: int

signal base_destroyed(is_player: bool)

@onready var sprite: Sprite2D = $Sprite2D
@onready var health_label: Label = $HealthLabel

func _ready() -> void:
	current_health = max_health

	if is_player_base:
		collision_layer = 1
		collision_mask = 0
		sprite.texture = load("res://assets/base_1.png")
		health_label.add_theme_color_override("font_color", Color(0.1, 0.25, 0.85))
	else:
		collision_layer = 2
		collision_mask = 0
		sprite.texture = load("res://assets/enemigo_1.png")
		health_label.add_theme_color_override("font_color", Color(0.85, 0.1, 0.1))

	sprite.scale = Vector2(0.12, 0.12)
	sprite.position = Vector2(0, -90)
	health_label.add_theme_font_size_override("font_size", 16)
	_update_label()

func _update_label() -> void:
	health_label.text = "%d / %d" % [current_health, max_health]

func take_damage(amount: int) -> void:
	current_health -= amount
	_update_label()
	if current_health <= 0:
		base_destroyed.emit(is_player_base)
		queue_free()
