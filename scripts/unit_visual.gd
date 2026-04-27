extends Node2D

var color: Color = Color.CORNFLOWER_BLUE
var unit_type: int = 0
var is_walking: bool = true

var _walk_phase: float = 0.0
var _rifle_offset: float = 0.0  # >0 = rifle floats away (knockback); <0 = recoil
var _attack_timer: float = 0.0  # 1..0 decays after shooting

const _WALK_SPEED  := 6.5
const _RIFLE_DECAY := 28.0
const _ATCK_DECAY  := 4.5

func _process(delta: float) -> void:
	if unit_type != 0:
		return
	if is_walking:
		_walk_phase += delta * _WALK_SPEED
	_rifle_offset = move_toward(_rifle_offset, 0.0, delta * _RIFLE_DECAY)
	_attack_timer = move_toward(_attack_timer, 0.0, delta * _ATCK_DECAY)
	queue_redraw()

func play_attack() -> void:
	_attack_timer = 1.0
	_rifle_offset = -3.0  # slight recoil toward body

func play_knockback_visual() -> void:
	_rifle_offset = 10.0  # rifle floats away from hand

func _draw() -> void:
	if unit_type == 0:
		_draw_soldier()
	else:
		draw_rect(Rect2(-15, -75, 30, 75), color)

func _draw_soldier() -> void:
	var c  := color
	var cd := c.darkened(0.32)
	var cl := c.lightened(0.18)

	var w:   float = sin(_walk_phase)
	var bob: float = abs(w) * 1.5  # body sinks slightly at max leg spread

	# Per-limb swing offsets at the far end (hip/shoulder stays fixed)
	var ll_x: float = -w * 8.0   # left  leg foot X
	var rl_x: float =  w * 8.0   # right leg foot X
	var la_x: float =  w * 4.0   # left  arm hand X (opposite phase)
	var ra_x: float = -w * 4.0   # right arm hand X

	# ── Feet ──────────────────────────────────────────────────────────────────
	draw_rect(Rect2(-12.0 + ll_x * 0.7, bob - 5.0, 11.0, 5.0), cd)
	draw_rect(Rect2(  1.0 + rl_x * 0.7, bob - 5.0, 11.0, 5.0), cd)

	# ── Legs (hip fixed, foot swings) ─────────────────────────────────────────
	draw_line(Vector2(-5, -28 + bob), Vector2(-5 + ll_x, -5 + bob), c, 8, true)
	draw_line(Vector2( 5, -28 + bob), Vector2( 5 + rl_x, -5 + bob), c, 8, true)

	# ── Left arm (behind body) ────────────────────────────────────────────────
	var la_bot := Vector2(-14 + la_x, -39 + bob)
	draw_line(Vector2(-11, -52 + bob), la_bot, c, 7, true)

	# ── Torso ─────────────────────────────────────────────────────────────────
	draw_rect(Rect2(-10, -57 + bob, 20, 28), c)
	# Belt
	draw_rect(Rect2(-11, -30 + bob, 22, 4), cd)
	# Chest pocket
	draw_rect(Rect2(-8, -52 + bob, 6, 8), cd)

	# ── Neck ──────────────────────────────────────────────────────────────────
	draw_rect(Rect2(-4, -63 + bob, 8, 7), c)

	# ── Right arm + rifle ─────────────────────────────────────────────────────
	var ra_bot := Vector2(14 + ra_x, -39 + bob)
	draw_line(Vector2(11, -52 + bob), ra_bot, c, 7, true)

	# Rifle attached to right hand, extends forward (positive X = forward for player)
	var rx:     float = ra_bot.x + _rifle_offset
	var ry:     float = ra_bot.y - 2.0
	var recoil: float = _attack_timer * -2.5

	# Main rifle body
	draw_rect(Rect2(rx + recoil, ry - 3.0, 20.0, 6.0), cd)
	# Barrel (thinner, further forward)
	draw_rect(Rect2(rx + recoil + 17.0, ry - 1.5, 9.0, 3.0), cd.darkened(0.15))
	# Grip / stock (below body)
	draw_rect(Rect2(rx + recoil + 1.0, ry + 2.5, 6.0, 6.0), cd)

	# Muzzle flash
	if _attack_timer > 0.25:
		draw_circle(Vector2(rx + recoil + 27.0, ry - 1.0),
				3.5 * _attack_timer,
				Color(1.0, 0.88, 0.20, _attack_timer))

	# ── Head ──────────────────────────────────────────────────────────────────
	draw_circle(Vector2(0, -68 + bob), 9.0, c)
	# Eye dot
	draw_circle(Vector2(4, -67 + bob), 1.5, cd)

	# ── Helmet ────────────────────────────────────────────────────────────────
	# Brim (wider than head)
	draw_rect(Rect2(-12, -65 + bob, 24.0, 4.0), cd)
	# Dome
	draw_circle(Vector2(0, -72 + bob), 7.5, cd)
	# Badge (small bright rectangle)
	draw_rect(Rect2(-1.5, -76 + bob, 3.0, 3.0), cl)
