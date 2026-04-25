extends Node

const UNIT_COSTS := [75, 100, 150, 25] # ID 0, 1, 2, 3
const KILL_REWARD := 30

const UNIT_STATS := [
	{"name": "Guerrero", "speed": 80.0,  "health": 120, "damage": 18, "cooldown": 0.8, "range": 120.0, "area": false},
	{"name": "Rápido", "speed": 140.0, "health": 60,  "damage": 32, "cooldown": 0.6, "range": 60.0,  "area": true},
	{"name": "Tanque", "speed": 50.0,  "health": 500, "damage": 30, "cooldown": 3.0, "range": 70.0,  "area": false},
	{"name": "Básico", "speed": 90.0,  "health": 80,  "damage": 12, "cooldown": 0.7, "range": 60.0,  "area": false},
]

var money: float = 200.0
var enemy_money: float = 200.0
var money_rate: float = 15.0

# --- Sistema de Inventario y Gacha ---
var tickets: int = 5
var owned_units: Array[int] = [3] 
var active_deck: Array[int] = [3]

signal money_changed(new_amount: float)
signal tickets_changed(new_amount: int)

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

# --- Lógica de Gacha ---
func draw_gacha() -> int:
	if tickets <= 0: return -1
	
	tickets -= 1
	tickets_changed.emit(tickets)
	
	var pool = [0, 1, 2]
	var result = pool[randi() % pool.size()]
	
	if not owned_units.has(result):
		owned_units.append(result)
	
	return result

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
