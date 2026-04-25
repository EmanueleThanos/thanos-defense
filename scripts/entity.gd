extends Area2D

@export var speed: float = 80.0
@export var max_health: int = 100
@export var damage: int = 20
@export var attack_cooldown: float = 1.5
@export var attack_range: float = 60.0
@export var is_area_attack: bool = false
@export var is_player_unit: bool = true
@export var unit_type: int = 0

const PLAYER_COLORS := [
	Color.CORNFLOWER_BLUE, # Guerrero (0)
	Color(0.88, 0.28, 0.18), # Rápido (1)
	Color(0.22, 0.65, 0.30), # Tanque (2)
	Color(0.8, 0.8, 0.8),     # Básico (3)
]
const ENEMY_COLORS := [
	Color(0.10, 0.14, 0.48),
	Color(0.46, 0.05, 0.04),
	Color(0.04, 0.28, 0.08),
	Color(0.4, 0.4, 0.4),
]

var wall_scene = preload("res://scenes/Wall.tscn")

var current_health: int
var targets: Array = []
var wall_placed := false

enum State { MOVING, ATTACKING, KNOCKBACK }
var state: State = State.MOVING

func _ready() -> void:
	current_health = max_health
	$AttackCooldownTimer.wait_time = attack_cooldown

	var circle := CircleShape2D.new()
	circle.radius = attack_range
	$AttackRange/CollisionShape2D.shape = circle

	if is_player_unit:
		collision_layer = 1
		collision_mask = 0
		$AttackRange.collision_mask = 2
		$Visual.color = PLAYER_COLORS[unit_type]
	else:
		collision_layer = 2
		collision_mask = 0
		$AttackRange.collision_mask = 1
		$Visual.color = ENEMY_COLORS[unit_type]

func _physics_process(delta: float) -> void:
	if state == State.MOVING:
		position.x += speed * delta * (1 if is_player_unit else -1)

func _on_attack_range_area_entered(area: Area2D) -> void:
	if state == State.KNOCKBACK: return
	
	targets.append(area)
	if state == State.MOVING:
		state = State.ATTACKING
		$AttackCooldownTimer.start()

func _on_attack_range_area_exited(area: Area2D) -> void:
	targets.erase(area)
	if targets.is_empty() and state != State.KNOCKBACK:
		state = State.MOVING
		wall_placed = false

func _on_attack_cooldown_timer_timeout() -> void:
	if state == State.KNOCKBACK: return
	
	targets = targets.filter(func(t): return is_instance_valid(t))
	if targets.is_empty():
		state = State.MOVING
		wall_placed = false
		return

	# Efectos de ataque (Battle Cats style)
	if has_node("HitParticles"):
		$HitParticles.emitting = true
	if has_node("AttackSound") and $AttackSound.stream:
		$AttackSound.play()

	if is_area_attack:
		for target in targets:
			if target.has_method("take_damage"):
				target.take_damage(damage)
	else:
		if targets[0].has_method("take_damage"):
			targets[0].take_damage(damage)

	if unit_type == 2 and is_player_unit and not wall_placed:
		_place_wall()
		wall_placed = true

	$AttackCooldownTimer.start()

func _place_wall() -> void:
	var wall = wall_scene.instantiate()
	wall.position = Vector2(position.x - 60, position.y)
	get_parent().add_child(wall)

func take_damage(amount: int) -> void:
	current_health -= amount
	
	if amount >= max_health * 0.25 and state != State.KNOCKBACK and unit_type != 2:
		apply_knockback()
	
	if current_health <= 0:
		if is_player_unit:
			GameManager.reward_enemy_kill()
		else:
			GameManager.reward_player_kill()
		queue_free()

func apply_knockback() -> void:
	state = State.KNOCKBACK
	$AttackCooldownTimer.stop()
	
	var knockback_distance = 60.0
	var knockback_duration = 0.4
	var direction = -1 if is_player_unit else 1
	var target_x = position.x + (knockback_distance * direction)
	
	# Ángulo de inclinación (Tilt)
	var tilt_angle = -0.4 if is_player_unit else 0.4
	
	var tween = create_tween().set_parallel(true)
	# Mover hacia atrás
	tween.tween_property(self, "position:x", target_x, knockback_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Inclinar visualmente
	tween.tween_property($Visual, "rotation", tilt_angle, knockback_duration * 0.4).set_trans(Tween.TRANS_SINE)
	
	var visual_tween = create_tween()
	visual_tween.tween_property($Visual, "modulate:a", 0.5, 0.1)
	visual_tween.tween_property($Visual, "modulate:a", 1.0, 0.1)
	
	await tween.finished
	
	# Recuperar postura suavemente
	var recovery_tween = create_tween()
	recovery_tween.tween_property($Visual, "rotation", 0.0, 0.2)
	await recovery_tween.finished
	
	if is_instance_valid(self) and current_health > 0:
		state = State.MOVING
		targets = targets.filter(func(t): return is_instance_valid(t))
		if not targets.is_empty():
			state = State.ATTACKING
			$AttackCooldownTimer.start()
