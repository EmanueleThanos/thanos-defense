extends Node2D

var dragging := false
var last_mouse_pos := Vector2()
var _rng := RandomNumberGenerator.new()
var _trees: Array = []
var _flowers: Array = []
var _wfall_offsets: Array = []

const MAP_W := 2816.0
const MAP_H := 1536.0

# Centro-base de cada pirámide
const T1 := Vector2(450,  1100)
const T2 := Vector2(1380, 755)
const T3 := Vector2(2280, 415)

@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	_rng.seed = 1337
	_generate_details()
	camera.zoom = Vector2(2.0, 2.0)
	camera.position = Vector2(450, 1050)
	_clamp_camera()
	_update_stage_buttons()
	queue_redraw()

func _generate_details() -> void:
	for _i in 90:
		var p := Vector2(_rng.randf_range(200, 2650), _rng.randf_range(200, 1450))
		if _on_island(p):
			_trees.append({
				"pos": p,
				"h":    _rng.randf_range(28.0, 68.0),
				"lean": _rng.randf_range(-0.22, 0.22),
				"w":    _rng.randf_range(3.0, 6.5),
			})
	for _i in 140:
		var p := Vector2(_rng.randf_range(200, 2650), _rng.randf_range(200, 1450))
		if _on_island(p):
			_flowers.append({
				"pos": p,
				"r":   _rng.randf_range(2.5, 6.0),
				"col": [Color(1.0,0.9,0.1), Color(1.0,0.4,0.1), Color(1.0,0.3,0.6), Color(1.0,1.0,1.0)][_rng.randi() % 4],
			})
	for _i in 8:
		_wfall_offsets.append(_rng.randf_range(-3.0, 3.0))

func _on_island(p: Vector2) -> bool:
	var dx := (p.x - 1380.0) / 1180.0
	var dy := (p.y - 830.0) / 690.0
	return dx * dx + dy * dy < 0.82

func _update_stage_buttons() -> void:
	for i in 3:
		var stage := i + 1
		var btn := get_node("Stage%d" % stage) as Button
		var unlocked := GameManager.is_stage_unlocked("legend", stage)
		btn.disabled = !unlocked
		btn.modulate = Color(1, 1, 1, 1) if unlocked else Color(0.35, 0.30, 0.25, 0.60)

# ─── Draw maestro ──────────────────────────────────────────────────────────────
func _draw() -> void:
	_draw_ocean()
	_draw_island_layers()
	_draw_vegetation()
	_draw_stone_path()
	_draw_waterfall()
	_draw_temple(T1, 1)
	_draw_temple(T2, 2)
	_draw_temple(T3, 3)
	_draw_mist()

# ─── Océano ────────────────────────────────────────────────────────────────────
func _draw_ocean() -> void:
	draw_rect(Rect2(0, 0, MAP_W, MAP_H), Color(0.04, 0.14, 0.34))
	# Capas de agua para dar profundidad
	for i in 8:
		var y := float(i) * (MAP_H / 8.0)
		draw_rect(Rect2(0, y, MAP_W, MAP_H / 8.0),
				  Color(0.06, 0.20 + i * 0.008, 0.50 + i * 0.005, 0.12))
	# Espuma/olas lejanas
	for yi in range(0, int(MAP_H), 55):
		draw_line(Vector2(0, yi), Vector2(MAP_W, yi), Color(0.35, 0.65, 0.90, 0.04), 18)

# ─── Capas de la isla ──────────────────────────────────────────────────────────
func _draw_island_layers() -> void:
	# Arrecife / aguas poco profundas
	draw_colored_polygon(PackedVector2Array([
		Vector2(140,1365), Vector2(360,1455), Vector2(660,1510), Vector2(990,1510),
		Vector2(1310,1490), Vector2(1610,1455), Vector2(1910,1412), Vector2(2170,1332),
		Vector2(2410,1210), Vector2(2570,1050), Vector2(2645,848),  Vector2(2605,638),
		Vector2(2490,448),  Vector2(2305,296),  Vector2(2062,186),  Vector2(1790,138),
		Vector2(1495,120),  Vector2(1198,140),  Vector2(924,202),   Vector2(660,320),
		Vector2(440,482),   Vector2(275,684),   Vector2(175,938),   Vector2(158,1180),
		Vector2(140,1365),
	]), Color(0.14, 0.46, 0.64, 0.48))

	# Arena/playa
	draw_colored_polygon(PackedVector2Array([
		Vector2(210,1348), Vector2(415,1435), Vector2(695,1488), Vector2(995,1488),
		Vector2(1308,1468), Vector2(1608,1428), Vector2(1908,1382), Vector2(2155,1298),
		Vector2(2392,1178), Vector2(2542,1018), Vector2(2605,822),  Vector2(2562,616),
		Vector2(2448,428),  Vector2(2268,282),  Vector2(2040,175),  Vector2(1768,128),
		Vector2(1485,112),  Vector2(1195,132),  Vector2(928,192),   Vector2(670,302),
		Vector2(450,460),   Vector2(290,656),   Vector2(195,905),   Vector2(178,1158),
		Vector2(210,1348),
	]), Color(0.87, 0.77, 0.54))

	# Jungla exterior (verde claro)
	draw_colored_polygon(PackedVector2Array([
		Vector2(295,1312), Vector2(476,1396), Vector2(736,1438), Vector2(1018,1438),
		Vector2(1328,1412), Vector2(1628,1368), Vector2(1928,1308), Vector2(2178,1212),
		Vector2(2375,1085), Vector2(2492,922),  Vector2(2522,732),  Vector2(2462,542),
		Vector2(2330,382),  Vector2(2132,252),  Vector2(1895,180),  Vector2(1635,148),
		Vector2(1375,148),  Vector2(1105,175),  Vector2(850,246),   Vector2(612,368),
		Vector2(408,528),   Vector2(262,728),   Vector2(195,972),   Vector2(210,1182),
		Vector2(295,1312),
	]), Color(0.18, 0.48, 0.18))

	# Jungla media (verde medio)
	draw_colored_polygon(PackedVector2Array([
		Vector2(396,1238), Vector2(578,1318), Vector2(838,1368), Vector2(1098,1362),
		Vector2(1398,1328), Vector2(1698,1262), Vector2(1978,1168), Vector2(2218,1038),
		Vector2(2375,878),  Vector2(2395,698),  Vector2(2315,518),  Vector2(2175,368),
		Vector2(1995,268),  Vector2(1775,218),  Vector2(1535,198),  Vector2(1288,212),
		Vector2(1038,268),  Vector2(798,372),   Vector2(578,510),   Vector2(398,700),
		Vector2(314,920),   Vector2(318,1108),  Vector2(396,1238),
	]), Color(0.13, 0.39, 0.13))

	# Jungla profunda (verde oscuro, zona interior)
	draw_colored_polygon(PackedVector2Array([
		Vector2(595,1138), Vector2(818,1228), Vector2(1098,1268), Vector2(1398,1238),
		Vector2(1698,1158), Vector2(1958,1038), Vector2(2158,888),  Vector2(2238,708),
		Vector2(2175,538),  Vector2(2035,410),  Vector2(1855,334),  Vector2(1648,298),
		Vector2(1418,298),  Vector2(1188,338),  Vector2(968,428),   Vector2(772,562),
		Vector2(622,742),   Vector2(558,948),   Vector2(578,1068),  Vector2(595,1138),
	]), Color(0.09, 0.29, 0.09))

# ─── Vegetación ────────────────────────────────────────────────────────────────
func _draw_vegetation() -> void:
	for t in _trees:
		var p: Vector2 = t["pos"]
		var h: float   = t["h"]
		var lean: float = t["lean"]
		var w: float   = t["w"]
		var top := p + Vector2(lean * h, -h)
		draw_line(p, top, Color(0.32, 0.22, 0.10), w)
		for a_deg in [-90, -55, -25, 0, 25, 55, 90]:
			var a := deg_to_rad(float(a_deg) - 90.0)
			draw_line(top, top + Vector2(cos(a), sin(a)) * h * 0.55,
					  Color(0.16, 0.50, 0.12, 0.85), 2)
	for f in _flowers:
		draw_circle(f["pos"], f["r"], f["col"])
		draw_circle(f["pos"], f["r"] * 0.42, Color(1, 1, 0.7, 0.85))

# ─── Camino de piedra ──────────────────────────────────────────────────────────
func _draw_stone_path() -> void:
	var pts := [
		T1,
		Vector2(625, 1008), Vector2(840, 928), Vector2(1065, 858), Vector2(1215, 808),
		T2,
		Vector2(1558, 678), Vector2(1762, 608), Vector2(1992, 540), Vector2(2135, 480),
		T3,
	]
	# Tierra/barro bajo el camino
	for i in pts.size() - 1:
		draw_line(pts[i], pts[i + 1], Color(0.38, 0.28, 0.15, 0.75), 24)
	# Adoquines de piedra
	for i in pts.size() - 1:
		draw_dashed_line(pts[i], pts[i + 1], Color(0.58, 0.53, 0.43, 0.90), 14, 22)
	# Musgo en las grietas
	for i in pts.size() - 1:
		draw_line(pts[i], pts[i + 1], Color(0.22, 0.48, 0.18, 0.22), 4)

# ─── Cascada ───────────────────────────────────────────────────────────────────
func _draw_waterfall() -> void:
	var wp := Vector2(2148, 478)
	# Roca
	draw_rect(Rect2(wp + Vector2(-14, -35), Vector2(28, 88)), Color(0.44, 0.38, 0.30))
	draw_rect(Rect2(wp + Vector2(-14, -35), Vector2(28, 5)), Color(0.56, 0.52, 0.42))
	# Chorros de agua
	for i in _wfall_offsets.size():
		var xo: float = _wfall_offsets[i]
		draw_line(wp + Vector2(xo - 2, -28), wp + Vector2(xo + 1, 58),
				  Color(0.55, 0.82, 1.00, 0.38), 2)
	# Niebla de la base
	draw_circle(wp + Vector2(0, 62), 30, Color(0.78, 0.92, 1.00, 0.15))
	draw_circle(wp + Vector2(0, 72), 20, Color(0.92, 0.97, 1.00, 0.20))

# ─── Templo ────────────────────────────────────────────────────────────────────
func _draw_temple(center: Vector2, tier: int) -> void:
	var base_w  := 120.0 + tier * 32.0   # T1=152, T2=184, T3=216
	var step_h  := 32.0
	var n_steps := tier + 2               # T1=3, T2=4, T3=5
	var inset   := 22.0

	var s_dark := Color(0.38 + tier * 0.05, 0.34 + tier * 0.04, 0.25 + tier * 0.04)
	var s_mid  := Color(0.52 + tier * 0.04, 0.47 + tier * 0.04, 0.36 + tier * 0.04)
	var s_lite := Color(0.70 + tier * 0.02, 0.64 + tier * 0.02, 0.50 + tier * 0.02)

	# Sombra debajo
	draw_circle(center + Vector2(8, 8), base_w * 0.55, Color(0, 0, 0, 0.25))

	# Escalones de la pirámide
	for s in n_steps:
		var w  := base_w - s * inset * 2.0
		var y0 := center.y - (s + 1) * step_h
		var x0 := center.x - w / 2.0
		# Cara frontal
		draw_rect(Rect2(x0, y0, w, step_h), s_mid)
		# Borde superior iluminado
		draw_rect(Rect2(x0, y0, w, 5), s_lite)
		# Borde derecho en sombra
		draw_rect(Rect2(x0 + w - 5, y0, 5, step_h), s_dark)
		# Saliente horizontal entre escalones
		if s < n_steps - 1:
			draw_rect(Rect2(x0, y0 + step_h - 5, w, 5), s_lite)

	# Plataforma superior
	var top_w := base_w - n_steps * inset * 2.0
	var top_y := center.y - n_steps * step_h
	draw_rect(Rect2(center.x - top_w / 2.0 - 5, top_y - 22, top_w + 10, 22), s_mid)
	draw_rect(Rect2(center.x - top_w / 2.0 - 5, top_y - 26, top_w + 10, 5), s_lite)

	# Puerta
	var dw := 16.0 + tier * 5.0
	draw_rect(Rect2(center.x - dw / 2.0, center.y - dw * 1.6, dw, dw * 1.6), Color(0.10, 0.08, 0.06))

	# Antorchas
	for t in tier:
		var tx := center.x + (float(t) - float(tier - 1) / 2.0) * (top_w * 0.55 + 8)
		var ty := top_y - 22.0
		draw_rect(Rect2(tx - 2, ty - 16, 4, 16), s_dark)
		draw_circle(Vector2(tx, ty - 20), 7, Color(1.0, 0.45, 0.10, 0.55))
		draw_circle(Vector2(tx, ty - 22), 5, Color(1.0, 0.85, 0.20, 0.90))
		draw_circle(Vector2(tx, ty - 25), 3, Color(1.0, 1.0, 0.85, 0.75))

	# Enredaderas (T1 más ruinoso)
	if tier == 1:
		draw_line(center + Vector2(-base_w / 2 + 12, -step_h),
				  center + Vector2(-base_w / 2 + 6, -3 * step_h), Color(0.15, 0.55, 0.15, 0.72), 3)
		draw_circle(center + Vector2(-base_w / 2 + 8, -2 * step_h), 4, Color(0.22, 0.62, 0.22, 0.65))
		draw_line(center + Vector2(base_w / 2 - 12, -2 * step_h),
				  center + Vector2(base_w / 2 - 8, -3 * step_h + 8), Color(0.15, 0.55, 0.15, 0.72), 3)

	# Cristal brillante en T3
	if tier == 3:
		var cp := Vector2(center.x, top_y - 36)
		draw_circle(cp, 12, Color(0.58, 0.88, 1.00, 0.30))
		draw_circle(cp, 7,  Color(0.78, 0.95, 1.00, 0.65))
		draw_circle(cp, 3,  Color(1.00, 1.00, 1.00, 0.95))
		draw_arc(cp, 20, 0, TAU, 32, Color(0.58, 0.88, 1.00, 0.14), 9)

# ─── Niebla ────────────────────────────────────────────────────────────────────
func _draw_mist() -> void:
	for m in [
		[Vector2(1100, 695), 225], [Vector2(1700, 548), 185],
		[Vector2(810,  905), 165], [Vector2(2010, 628), 145],
		[Vector2(1395, 445), 125],
	]:
		draw_circle(m[0], m[1], Color(0.85, 0.92, 0.95, 0.07))

# ─── Input / cámara ────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		last_mouse_pos = event.position
	if event is InputEventMouseMotion and dragging:
		camera.position += (last_mouse_pos - event.position) / camera.zoom
		last_mouse_pos = event.position
		_clamp_camera()

func _clamp_camera() -> void:
	var h := get_viewport_rect().size / camera.zoom / 2.0
	camera.position.x = clampf(camera.position.x, h.x, MAP_W - h.x)
	camera.position.y = clampf(camera.position.y, h.y, MAP_H - h.y)

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/StageSelection.tscn")

func _on_stage_1_pressed() -> void:
	GameManager.start_stage("legend", 1)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_stage_2_pressed() -> void:
	GameManager.start_stage("legend", 2)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_stage_3_pressed() -> void:
	GameManager.start_stage("legend", 3)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
