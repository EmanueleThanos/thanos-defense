extends Node2D

var entity_scene = preload("res://scenes/Entity.tscn")

func _ready() -> void:
	GameManager.reset_battle()
	var diff := GameManager.get_stage_difficulty()
	$EnemyBase.init_health(diff.get("enemy_hp", 1000))
	$PlayerBase.init_health(GameManager.get_player_max_hp())

const PLAYER_SPAWN_X := 195.0
const ENEMY_SPAWN_X := 1080.0
const SPAWN_Y := 600.0

# --- Player spawning ---

func _on_spawn_requested(unit_index: int) -> void:
	GameManager.spend(GameManager.UNIT_COSTS[unit_index])
	_spawn_unit(unit_index, true)

# --- Enemy AI ---

# Weights per unit type: normal is most common, tank is rarest
const AI_WEIGHTS := [4, 2, 1]

func _on_enemy_spawn_timer_timeout() -> void:
	var affordable: Array[int] = []
	# El enemigo usa las unidades 0, 1 y 2
	for i in range(3):
		if GameManager.enemy_can_afford(GameManager.UNIT_COSTS[i]):
			affordable.append(i)

	var delay: float
	if affordable.is_empty():
		delay = 0.5
	else:
		var choice := _weighted_choice(affordable)
		GameManager.enemy_spend(GameManager.UNIT_COSTS[choice])
		_spawn_unit(choice, false)
		delay = randf_range(1.0, 3.5)

	$EnemySpawnTimer.wait_time = delay
	$EnemySpawnTimer.start()

func _weighted_choice(affordable: Array[int]) -> int:
	var total := 0.0
	for idx in affordable:
		total += AI_WEIGHTS[idx]
	var roll := randf() * total
	var cumulative := 0.0
	for idx in affordable:
		cumulative += AI_WEIGHTS[idx]
		if roll <= cumulative:
			return idx
	return affordable[-1]

# --- Shared spawn logic ---

func _spawn_unit(type_index: int, player: bool) -> void:
	var stats: Dictionary = GameManager.UNIT_STATS[type_index]
	var mult := GameManager.get_stat_multiplier(type_index) if player else GameManager.get_enemy_level_multiplier()
	var entity = entity_scene.instantiate()
	entity.unit_type = type_index
	entity.speed = stats["speed"]
	entity.max_health = int(stats["health"] * mult)
	entity.damage = int(stats["damage"] * mult)
	entity.attack_cooldown = stats["cooldown"]
	entity.attack_range = stats["range"]
	entity.is_area_attack = stats["area"]
	entity.is_player_unit = player
	entity.position = Vector2(PLAYER_SPAWN_X if player else ENEMY_SPAWN_X, SPAWN_Y)
	add_child(entity)

# --- Game end ---

func _end_game(player_won: bool) -> void:
	$EnemySpawnTimer.stop()
	if player_won:
		GameManager.complete_stage(GameManager.current_chapter, GameManager.current_stage)
		GameManager.reward_win()
	$GameOverOverlay.show_result(player_won)

func _on_player_base_base_destroyed(_is_player: bool) -> void:
	_end_game(false)

func _on_enemy_base_base_destroyed(_is_player: bool) -> void:
	_end_game(true)
