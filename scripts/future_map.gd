extends Node2D

var dragging := false
var last_mouse_pos := Vector2()
var _rng := RandomNumberGenerator.new()
var _stars: Array = []
var _asteroids: Array = []

const MAP_W := 2816.0
const MAP_H := 1536.0

@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	_rng.seed = 9001
	_generate_stars()
	_generate_asteroids()
	camera.zoom = Vector2(2.0, 2.0)
	camera.position = Vector2(500, 1000)
	_clamp_camera()
	queue_redraw()
	# Ninguna fase tiene nivel asignado todavía — bloquear todas
	for btn_name in ["Stage1", "Stage2", "Stage3", "Stage4", "Stage5"]:
		var btn := get_node(btn_name) as Button
		btn.disabled = true
		btn.modulate = Color(0.40, 0.42, 0.50, 0.65)

func _generate_stars() -> void:
	# Normal stars with color temperature variation
	for _i in 450:
		var b := _rng.randf_range(0.45, 1.0)
		var t := _rng.randf()
		var col: Color
		if t < 0.08:
			col = Color(0.65, 0.80, 1.00, b)   # blue-white (hot)
		elif t < 0.16:
			col = Color(1.00, 0.95, 0.75, b)   # yellow (sun-like)
		elif t < 0.20:
			col = Color(1.00, 0.70, 0.45, b)   # orange (cool giant)
		else:
			col = Color(b, b, minf(b + 0.06, 1.0), 1.0)
		_stars.append({
			"pos": Vector2(_rng.randf_range(0, MAP_W), _rng.randf_range(0, MAP_H)),
			"r":   _rng.randf_range(0.4, 2.0),
			"col": col,
			"sparkle": _rng.randf() < 0.035,
		})
	# Milky Way band — denser diagonal strip
	for _i in 700:
		var frac := _rng.randf()
		var bx := frac * MAP_W
		var by := 920.0 - frac * 740.0 + _rng.randf_range(-220.0, 220.0)
		if by < 0.0 or by > MAP_H:
			continue
		var lb := _rng.randf_range(0.15, 0.55)
		_stars.append({
			"pos": Vector2(bx, by),
			"r":   _rng.randf_range(0.3, 0.9),
			"col": Color(lb, lb * 0.95, lb + 0.05, _rng.randf_range(0.2, 0.55)),
			"sparkle": false,
		})

func _generate_asteroids() -> void:
	for _i in 10:
		_asteroids.append({
			"pos":  Vector2(_rng.randf_range(1750, 1990), _rng.randf_range(445, 585)),
			"r":    _rng.randf_range(7, 25),
			"col":  Color(_rng.randf_range(0.38, 0.52), _rng.randf_range(0.34, 0.48), _rng.randf_range(0.28, 0.42)),
		})

# ─── Master draw ─────────────────────────────────────────────────────────────
func _draw() -> void:
	draw_rect(Rect2(0, 0, MAP_W, MAP_H), Color(0.01, 0.01, 0.06))
	_draw_nebulae()
	_draw_stars()
	_draw_comet()
	_draw_earth()
	_draw_moon()
	_draw_space_station()
	_draw_asteroids()
	_draw_mars()
	_draw_distant_jupiter()
	_draw_path()

# ─── Nebulae ──────────────────────────────────────────────────────────────────
func _draw_nebulae() -> void:
	draw_circle(Vector2(520,  310), 380, Color(0.12, 0.04, 0.30, 0.08))
	draw_circle(Vector2(680,  460), 270, Color(0.05, 0.10, 0.32, 0.07))
	draw_circle(Vector2(560,  330), 130, Color(0.20, 0.05, 0.42, 0.06))
	draw_circle(Vector2(1420, 580), 310, Color(0.07, 0.03, 0.22, 0.07))
	draw_circle(Vector2(1460, 570), 130, Color(0.08, 0.04, 0.36, 0.06))
	draw_circle(Vector2(2050, 340), 270, Color(0.04, 0.08, 0.26, 0.07))
	draw_circle(Vector2(2520, 720), 210, Color(0.12, 0.02, 0.18, 0.07))

# ─── Stars & sparkles ─────────────────────────────────────────────────────────
func _draw_stars() -> void:
	for s in _stars:
		draw_circle(s["pos"], s["r"], s["col"])
		if s["sparkle"]:
			var p: Vector2 = s["pos"]
			var l: float = s["r"] * 4.0
			var sc: Color = s["col"]
			sc.a = 0.55
			draw_line(p + Vector2(-l, 0.0), p + Vector2(l, 0.0), sc, 0.8)
			draw_line(p + Vector2(0.0, -l), p + Vector2(0.0, l), sc, 0.8)

# ─── Comet ────────────────────────────────────────────────────────────────────
func _draw_comet() -> void:
	var cp := Vector2(1820, 155)
	var td := Vector2(0.96, 0.28).normalized()
	var tl := 300.0
	# Dust tail (wide, warm)
	for i in 14:
		var frac := float(i) / 14.0
		draw_circle(cp + td * tl * frac, 22.0 * (1.0 - frac * 0.55),
					Color(0.92, 0.86, 0.60, 0.045 * (1.0 - frac)))
	# Ion tail (thin, blue-white)
	draw_line(cp, cp + td * tl, Color(0.55, 0.82, 1.0, 0.38), 1.5)
	# Coma glow
	draw_circle(cp, 20, Color(0.82, 0.92, 1.0, 0.28))
	draw_circle(cp, 11, Color(0.94, 0.97, 1.0, 0.55))
	# Nucleus
	draw_circle(cp, 4, Color(1.0, 1.0, 1.0, 0.96))

# ─── Earth ────────────────────────────────────────────────────────────────────
func _draw_earth() -> void:
	var c := Vector2(270, 1310)
	# Night-side shadow (offset dark circle)
	draw_circle(c + Vector2(-28, 22), 218, Color(0.0, 0.0, 0.04, 0.52))
	# Ocean
	draw_circle(c, 210, Color(0.08, 0.22, 0.64))
	# Deep ocean patches
	draw_circle(c + Vector2(22, 32), 118, Color(0.06, 0.17, 0.56))
	# Sunlit shimmer
	draw_circle(c + Vector2(52, -62), 88, Color(0.15, 0.33, 0.80, 0.48))

	# North America
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-100, -140), c + Vector2(-48, -162), c + Vector2(-8, -132),
		c + Vector2(-28, -88),   c + Vector2(-78, -78),  c + Vector2(-122, -98),
	]), Color(0.16, 0.50, 0.19))
	# South America
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-38, -48), c + Vector2(22, -58), c + Vector2(42, 2),
		c + Vector2(32, 72),   c + Vector2(-18, 82), c + Vector2(-48, 22),
	]), Color(0.16, 0.50, 0.19))
	# Europe + Africa
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(58, -148), c + Vector2(102, -138), c + Vector2(122, -98),
		c + Vector2(132, -28), c + Vector2(112, 72),   c + Vector2(82, 122),
		c + Vector2(62, 62),   c + Vector2(72, -18),   c + Vector2(52, -78),
	]), Color(0.16, 0.50, 0.19))
	# Asia
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(80, -168), c + Vector2(138, -138), c + Vector2(172, -78),
		c + Vector2(158, -42), c + Vector2(118, -52),  c + Vector2(98, -108),
	]), Color(0.16, 0.50, 0.19))
	# Antarctica
	draw_circle(c + Vector2(0, 172), 46, Color(0.88, 0.92, 1.0, 0.86))

	# Cloud wisps
	for cl in [
		[c + Vector2(-58, -118), 46], [c + Vector2(42, -102), 36],
		[c + Vector2(-112, -28), 40], [c + Vector2(92, 42), 32],
		[c + Vector2(-18, 102), 42],  [c + Vector2(62, -158), 28],
	]:
		draw_circle(cl[0], cl[1], Color(1.0, 1.0, 1.0, 0.18))

	# Atmosphere layers
	draw_arc(c, 220, 0, TAU, 64, Color(0.40, 0.65, 1.00, 0.30), 12)
	draw_arc(c, 230, 0, TAU, 64, Color(0.30, 0.55, 0.90, 0.14), 10)
	draw_arc(c, 242, 0, TAU, 64, Color(0.20, 0.45, 0.80, 0.07), 10)

# ─── Moon ─────────────────────────────────────────────────────────────────────
func _draw_moon() -> void:
	var c := Vector2(930, 750)
	# Shadow side
	draw_circle(c + Vector2(-22, 18), 98, Color(0.0, 0.0, 0.02, 0.62))
	# Surface
	draw_circle(c, 95, Color(0.75, 0.75, 0.75))
	# Highlands (brighter)
	draw_circle(c + Vector2(28, -32), 42, Color(0.82, 0.82, 0.82, 0.58))
	draw_circle(c + Vector2(-32, 32), 32, Color(0.80, 0.80, 0.80, 0.48))
	# Mare regions (dark flat plains)
	draw_circle(c + Vector2(-22, -14), 29, Color(0.54, 0.55, 0.58))  # Mare Imbrium
	draw_circle(c + Vector2(26, 22),   21, Color(0.57, 0.58, 0.60))  # Mare Tranquillitatis
	draw_circle(c + Vector2(-10, 37),  17, Color(0.55, 0.56, 0.58))  # Mare Nubium
	draw_circle(c + Vector2(48, -28),  14, Color(0.56, 0.57, 0.59))  # Mare Crisium
	# Craters (with rim highlight)
	for cr in [
		[c + Vector2(52, -52), 14], [c + Vector2(-56, -38), 11],
		[c + Vector2(62, 32), 9],   [c + Vector2(-42, 57), 13],
		[c + Vector2(12, -72), 8],  [c + Vector2(-72, 12), 8],
		[c + Vector2(42, 62), 7],   [c + Vector2(-18, -58), 7],
		[c + Vector2(72, -10), 5],  [c + Vector2(32, -42), 5],
		[c + Vector2(-62, -58), 6], [c + Vector2(18, 78), 4],
	]:
		draw_circle(cr[0], cr[1], Color(0.60, 0.60, 0.60))
		draw_arc(cr[0], cr[1], 0, TAU, 16, Color(0.86, 0.86, 0.86, 0.42), 1.5)
	# Subtle outer glow
	draw_arc(c, 103, 0, TAU, 48, Color(0.88, 0.88, 0.96, 0.10), 6)

# ─── Space Station (ISS-style) ────────────────────────────────────────────────
func _draw_space_station() -> void:
	var c := Vector2(1560, 520)
	# Main integrated truss
	draw_rect(Rect2(c + Vector2(-82, -4), Vector2(164, 8)), Color(0.72, 0.75, 0.83))
	# Pressurised modules cluster
	draw_rect(Rect2(c + Vector2(-20, -13), Vector2(40, 26)), Color(0.80, 0.82, 0.90))
	draw_rect(Rect2(c + Vector2(-42, -10), Vector2(24, 20)), Color(0.78, 0.80, 0.88))
	draw_rect(Rect2(c + Vector2(18, -10),  Vector2(24, 20)), Color(0.78, 0.80, 0.88))
	# Node modules (connectors)
	draw_rect(Rect2(c + Vector2(-10, -22), Vector2(20, 10)), Color(0.75, 0.77, 0.85))
	draw_rect(Rect2(c + Vector2(-10, 12),  Vector2(20, 10)), Color(0.75, 0.77, 0.85))
	# Solar array wings — 4 port / 4 starboard
	for px in [-70.0, -50.0, 28.0, 48.0]:
		draw_rect(Rect2(c + Vector2(px - 2.0, -26.0), Vector2(4.0, 48.0)), Color(0.32, 0.52, 0.92, 0.88))
	# Thermal radiators
	draw_rect(Rect2(c + Vector2(-14, 22), Vector2(9, 20)), Color(0.88, 0.52, 0.30, 0.75))
	draw_rect(Rect2(c + Vector2(5, 22),   Vector2(9, 20)), Color(0.88, 0.52, 0.30, 0.75))
	# Solar panels highlight line
	draw_line(c + Vector2(-80, 0), c + Vector2(80, 0), Color(1.0, 1.0, 1.0, 0.12), 1)
	# Glow
	draw_circle(c, 32, Color(0.50, 0.80, 1.00, 0.06))

# ─── Asteroid belt ────────────────────────────────────────────────────────────
func _draw_asteroids() -> void:
	for a in _asteroids:
		var p: Vector2 = a["pos"]
		var r: float  = a["r"]
		var col: Color = a["col"]
		draw_circle(p, r, col)
		# Shadow
		draw_circle(p + Vector2(-r * 0.30, r * 0.30), r * 0.72, Color(0.0, 0.0, 0.0, 0.28))
		# Highlight
		draw_circle(p + Vector2(r * 0.28, -r * 0.28), r * 0.38, Color(0.72, 0.70, 0.64, 0.42))

# ─── Mars ─────────────────────────────────────────────────────────────────────
func _draw_mars() -> void:
	var c := Vector2(2360, 430)
	# Night-side shadow
	draw_circle(c + Vector2(-26, 22), 84, Color(0.0, 0.0, 0.0, 0.46))
	# Planet base
	draw_circle(c, 80, Color(0.70, 0.28, 0.12))
	# Surface colour variation
	draw_circle(c + Vector2(-22, 12), 46, Color(0.60, 0.22, 0.10, 0.58))
	draw_circle(c + Vector2(30, -22), 36, Color(0.65, 0.25, 0.11, 0.48))
	# Valles Marineris (great canyon)
	draw_line(c + Vector2(-36, 10), c + Vector2(46, 5),  Color(0.44, 0.15, 0.07, 0.72), 5)
	draw_line(c + Vector2(-30, 15), c + Vector2(42, 10), Color(0.32, 0.10, 0.05, 0.40), 3)
	# Olympus Mons (volcano)
	draw_circle(c + Vector2(-42, -26), 14, Color(0.54, 0.20, 0.09))
	draw_circle(c + Vector2(-42, -26),  5, Color(0.48, 0.16, 0.07))
	# Polar ice cap (north)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-20, -64), c + Vector2(6, -72), c + Vector2(26, -64),
		c + Vector2(30, -54),  c + Vector2(9, -51), c + Vector2(-16, -54),
	]), Color(0.90, 0.90, 0.95, 0.86))
	# Dust storm (faint)
	draw_circle(c + Vector2(36, 32), 30, Color(0.82, 0.46, 0.26, 0.14))
	# Atmosphere rings
	draw_arc(c, 88, 0, TAU, 48, Color(0.80, 0.44, 0.24, 0.20), 7)
	draw_arc(c, 96, 0, TAU, 48, Color(0.68, 0.34, 0.14, 0.08), 7)
	# Phobos
	var ph := c + Vector2(112, -42)
	draw_circle(ph, 6, Color(0.55, 0.50, 0.44))
	draw_circle(ph + Vector2(-2, 1), 2, Color(0.44, 0.40, 0.37))

# ─── Distant Jupiter ──────────────────────────────────────────────────────────
func _draw_distant_jupiter() -> void:
	var c := Vector2(2688, 872)
	draw_circle(c, 40, Color(0.72, 0.60, 0.48, 0.58))
	# Band stripes
	for i in 6:
		var yo := float(i - 3) * 11.0
		draw_line(c + Vector2(-36, yo), c + Vector2(36, yo),
				  Color(0.58, 0.48, 0.38, 0.14 + float(i) * 0.025), 3)
	# Great Red Spot hint
	draw_circle(c + Vector2(12, 8), 8, Color(0.72, 0.32, 0.24, 0.22))
	draw_arc(c, 44, 0, TAU, 32, Color(0.70, 0.58, 0.44, 0.10), 5)

# ─── Trajectory path ──────────────────────────────────────────────────────────
func _draw_path() -> void:
	var pts := [
		Vector2(480, 970),    # Stage 1 — Earth orbit
		Vector2(700, 840),    # Stage 2 — Low orbit
		Vector2(960, 750),    # (near Moon, no button)
		Vector2(1220, 660),   # Stage 3 — Lunar surface
		Vector2(1560, 520),   # (near station)
		Vector2(1870, 505),   # Stage 4 — Asteroid belt
		Vector2(2360, 430),   # (near Mars)
		Vector2(2620, 360),   # Stage 5 — Mars
	]
	# Glow underneath
	for i in pts.size() - 1:
		draw_line(pts[i], pts[i + 1], Color(0.28, 0.58, 1.00, 0.10), 9)
	# Dashed line
	for i in pts.size() - 1:
		draw_dashed_line(pts[i], pts[i + 1], Color(0.52, 0.80, 1.00, 0.62), 2, 16)
	# Stage node rings (at the 5 stage positions)
	for idx in [0, 1, 3, 5, 7]:
		draw_circle(pts[idx], 13, Color(0.18, 0.48, 1.00, 0.22))
		draw_arc(pts[idx], 13, 0, TAU, 32, Color(0.62, 0.88, 1.00, 0.72), 2)
		draw_circle(pts[idx], 4, Color(0.80, 0.95, 1.00, 0.90))

# ─── Input / camera ───────────────────────────────────────────────────────────
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
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
func _on_stage_2_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
func _on_stage_3_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
func _on_stage_4_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
func _on_stage_5_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
