extends Node

const UNIT_COSTS := [75, 100, 150, 25] # ID 0, 1, 2, 3
const KILL_REWARD := 30

const UNIT_STATS := [
	{"name": "Guerrero", "speed": 80.0,  "health": 120, "damage": 18, "cooldown": 0.8, "range": 120.0, "area": false},
	{"name": "Rápido", "speed": 140.0, "health": 60,  "damage": 32, "cooldown": 0.6, "range": 60.0,  "area": true},
	{"name": "Tanque", "speed": 50.0,  "health": 500, "damage": 30, "cooldown": 3.0, "range": 70.0,  "area": false},
	{"name": "Básico", "speed": 90.0,  "health": 80,  "damage": 12, "cooldown": 0.7, "range": 60.0,  "area": false},
]

const STARTING_MONEY := 150.0

var money: float = STARTING_MONEY
var enemy_money: float = STARTING_MONEY
var money_rate: float = 15.0

# --- Sistema de Inventario y Gacha ---
var tickets: int = 5
var owned_units: Array[int] = [3]
var active_deck: Array[int] = [3]
var unit_levels: Array[int] = [1, 1, 1, 1]

signal money_changed(new_amount: float)
signal tickets_changed(new_amount: int)
signal unit_leveled_up(unit_id: int, new_level: int)

func reset_battle() -> void:
	money = STARTING_MONEY
	enemy_money = STARTING_MONEY
	money_changed.emit(money)

func _process(delta: float) -> void:
	if get_tree().current_scene and get_tree().current_scene.name == "Main":
		money += money_rate * delta
		enemy_money += money_rate * delta
		money_changed.emit(money)

func can_afford(cost: int) -> bool:
	return money >= cost

func spend(cost: int) -> void:
	money -= cost
	money_changed.emit(money)

func get_stat_multiplier(unit_id: int) -> float:
	return 1.0 + 0.25 * (unit_levels[unit_id] - 1)

# --- Pool de Gacha ---
# Para añadir una bola nueva: añade una entrada aquí. Nada más cambia.
#   unit_id : índice en UNIT_STATS
#   weight  : peso de probabilidad (más = más común)
#   color   : color del premio al revelar
const GACHA_POOL := [
	{"unit_id": 0, "weight": 40, "color": Color.CORNFLOWER_BLUE},
	{"unit_id": 1, "weight": 25, "color": Color.INDIAN_RED},
	{"unit_id": 2, "weight": 10, "color": Color.DARK_GREEN},
]

func _weighted_gacha_draw() -> Dictionary:
	var total := 0.0
	for entry in GACHA_POOL:
		total += entry["weight"]
	var roll := randf() * total
	var cumulative := 0.0
	for entry in GACHA_POOL:
		cumulative += entry["weight"]
		if roll <= cumulative:
			return entry
	return GACHA_POOL[-1]

# --- Lógica de Gacha ---
func draw_gacha() -> Dictionary:
	if tickets <= 0:
		return {"unit_id": -1, "leveled_up": false, "new_level": 0, "color": Color.WHITE}

	tickets -= 1
	tickets_changed.emit(tickets)

	var entry := _weighted_gacha_draw()
	var result: int = entry["unit_id"]

	if owned_units.has(result):
		unit_levels[result] += 1
		unit_leveled_up.emit(result, unit_levels[result])
		return {"unit_id": result, "leveled_up": true, "new_level": unit_levels[result], "color": entry["color"]}
	else:
		owned_units.append(result)
		return {"unit_id": result, "leveled_up": false, "new_level": 1, "color": entry["color"]}

func reward_win() -> void:
	tickets += 1
	tickets_changed.emit(tickets)

func add_to_deck(unit_id: int):
	if owned_units.has(unit_id) and not active_deck.has(unit_id) and active_deck.size() < 5:
		active_deck.append(unit_id)

func remove_from_deck(unit_id: int):
	if active_deck.has(unit_id) and active_deck.size() > 1:
		active_deck.erase(unit_id)

func enemy_can_afford(cost: int) -> bool:
	return enemy_money >= cost

func enemy_spend(cost: int) -> void:
	enemy_money -= cost

func reward_player_kill() -> void:
	money += KILL_REWARD
	money_changed.emit(money)

func reward_enemy_kill() -> void:
	enemy_money += KILL_REWARD
