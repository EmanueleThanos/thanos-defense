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
const ENEMY_INCOME_RATE := 15.0

# --- Sistema de mejoras permanentes ---
var mp: int = 0
var music_volume: float = 1.0
var sfx_volume: float   = 1.0
var production_level: int = 1   # max 100  (MP/s en batalla)
var base_hp_level: int = 1      # max 50   (+250 HP por nivel)
var max_units_level: int = 1    # max 8    (3–10 unidades simultáneas)

signal mp_changed(new_amount: int)

func get_money_rate() -> float:
	if production_level >= 100:
		return 1000.0
	return 15.0 + (485.0 / 98.0) * (production_level - 1)

func get_player_max_hp() -> int:
	return 1000 + 250 * (base_hp_level - 1)

func get_max_units() -> int:
	return 2 + max_units_level   # nivel 1=3, nivel 8=10

# Coste de subir del nivel N al N+1
func upgrade_cost_unit(level: int) -> int:
	if level >= 99: return 40 * 99 * 8   # 31 680 MP para el nivel 100
	return 40 * level

func upgrade_cost_production(level: int) -> int:
	if level >= 99: return 80 * 99 * 6   # 47 520 MP para el nivel 100
	return 80 * level

func upgrade_cost_base_hp(level: int) -> int:
	return 60 * level                     # sin tope especial

func upgrade_cost_max_units(level: int) -> int:
	return 300 * level

func try_upgrade_unit(unit_id: int) -> bool:
	var lvl := unit_levels[unit_id]
	if lvl >= 100: return false
	var cost := upgrade_cost_unit(lvl)
	if mp < cost: return false
	mp -= cost
	unit_levels[unit_id] += 1
	mp_changed.emit(mp)
	unit_leveled_up.emit(unit_id, unit_levels[unit_id])
	return true

func try_upgrade_production() -> bool:
	if production_level >= 100: return false
	var cost := upgrade_cost_production(production_level)
	if mp < cost: return false
	mp -= cost
	production_level += 1
	mp_changed.emit(mp)
	return true

func try_upgrade_base_hp() -> bool:
	if base_hp_level >= 50: return false
	var cost := upgrade_cost_base_hp(base_hp_level)
	if mp < cost: return false
	mp -= cost
	base_hp_level += 1
	mp_changed.emit(mp)
	return true

func try_upgrade_max_units() -> bool:
	if max_units_level >= 8: return false
	var cost := upgrade_cost_max_units(max_units_level)
	if mp < cost: return false
	mp -= cost
	max_units_level += 1
	mp_changed.emit(mp)
	return true

# --- Progresión de fases ---
var current_chapter: String = ""
var current_stage: int = 0
# Guarda el número de la última fase completada por capítulo (0 = ninguna)
var chapter_progress: Dictionary = {"legend": 0, "future": 0, "story": 0}

func start_stage(chapter: String, stage: int) -> void:
	current_chapter = chapter
	current_stage = stage
	reset_battle()

func complete_stage(chapter: String, stage: int) -> void:
	if chapter == "" or stage <= 0:
		return
	if stage > chapter_progress.get(chapter, 0):
		chapter_progress[chapter] = stage

func is_stage_unlocked(chapter: String, stage: int) -> bool:
	return stage == 1 or stage <= chapter_progress.get(chapter, 0) + 1

# Dificultad por fase: HP base enemiga y nivel de las unidades enemigas
const STAGE_DIFFICULTY := {
	"legend_1": {"enemy_hp": 1000,  "enemy_unit_level": 1,  "ticket_reward": 1},
	"legend_2": {"enemy_hp": 1500,  "enemy_unit_level": 3,  "ticket_reward": 3},
	"legend_3": {"enemy_hp": 10666, "enemy_unit_level": 30, "ticket_reward": 12},
}

func get_stage_difficulty() -> Dictionary:
	var key := current_chapter + "_" + str(current_stage)
	return STAGE_DIFFICULTY.get(key, {"enemy_hp": 1000, "enemy_unit_level": 1})

func get_enemy_level_multiplier() -> float:
	var level: int = get_stage_difficulty().get("enemy_unit_level", 1)
	return 1.0 + 0.25 * (level - 1)

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
		money += get_money_rate() * delta
		enemy_money += ENEMY_INCOME_RATE * delta
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
		return {"unit_id": -1, "is_duplicate": false, "color": Color.WHITE}

	tickets -= 1
	tickets_changed.emit(tickets)

	var entry := _weighted_gacha_draw()
	var result: int = entry["unit_id"]

	if owned_units.has(result):
		return {"unit_id": result, "is_duplicate": true, "color": entry["color"]}
	else:
		owned_units.append(result)
		return {"unit_id": result, "is_duplicate": false, "color": entry["color"]}

func level_up_unit(unit_id: int) -> void:
	if unit_levels[unit_id] < 100:
		unit_levels[unit_id] += 1
		unit_leveled_up.emit(unit_id, unit_levels[unit_id])

func sell_gacha_duplicate(unit_id: int) -> void:
	mp += get_sell_price(unit_id)
	mp_changed.emit(mp)

# Saca `count` bolas, descuenta tickets, PERO no aplica los resultados todavía
func draw_gacha_multi_preview(count: int) -> Array:
	if tickets < count: return []
	tickets -= count
	tickets_changed.emit(tickets)
	var results := []
	var seen: Array[int] = []
	for _i in count:
		var entry := _weighted_gacha_draw()
		var uid: int = entry["unit_id"]
		results.append({
			"unit_id":      uid,
			"color":        entry["color"],
			"is_duplicate": owned_units.has(uid) or seen.has(uid),
			"sell_price":   get_sell_price(uid),
		})
		if not seen.has(uid):
			seen.append(uid)
	return results

# Aplica los resultados: sell_indices son los índices que el jugador eligió vender
func apply_gacha_results(results: Array, sell_indices: Array) -> void:
	var earned := 0
	for i in results.size():
		var uid: int = results[i]["unit_id"]
		if sell_indices.has(i):
			earned += results[i]["sell_price"]
		else:
			if owned_units.has(uid):
				if unit_levels[uid] < 100:
					unit_levels[uid] += 1
					unit_leveled_up.emit(uid, unit_levels[uid])
			else:
				owned_units.append(uid)
	if earned > 0:
		mp += earned
		mp_changed.emit(mp)

func draw_gacha_multi(count: int) -> Array:
	var results := []
	for i in range(count):
		var draw = draw_gacha()
		if draw["unit_id"] >= 0 and draw["is_duplicate"]:
			var can_level := unit_levels[draw["unit_id"]] < 100
			if can_level:
				level_up_unit(draw["unit_id"])
			draw["leveled_up"] = can_level
			draw["new_level"] = unit_levels[draw["unit_id"]]
		else:
			draw["leveled_up"] = false
			draw["new_level"] = 1
		results.append(draw)
	return results

func reward_win() -> void:
	var reward: int = get_stage_difficulty().get("ticket_reward", 1)
	tickets += reward
	tickets_changed.emit(tickets)

func get_sell_price(unit_id: int) -> int:
	return int(UNIT_COSTS[unit_id] * 0.4)

func add_to_deck(unit_id: int):
	if owned_units.has(unit_id) and not active_deck.has(unit_id) and active_deck.size() < get_max_units():
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
