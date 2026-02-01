extends CharacterBody2D
class_name BaseEnemy

signal died(reward: int)

@export var data: Resource  # EnemyData

var current_health: int
var target: Node2D

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 2   # enemies
	collision_mask = 1    # player
	current_health = data.max_health
	target = _find_player()
	queue_redraw()

func _physics_process(_delta: float) -> void:
	if target and is_instance_valid(target):
		var direction := (target.global_position - global_position).normalized()
		velocity = direction * data.speed
		move_and_slide()

func _draw() -> void:
	var hp_fraction := float(current_health) / float(data.max_health)
	match data.shape_type:
		"circle":
			_draw_partial_circle(data.size.x, data.color, hp_fraction)
		"ellipse":
			_draw_partial_ellipse(data.size, data.color, hp_fraction)

func _draw_partial_circle(radius: float, color: Color, fraction: float) -> void:
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color.WHITE, 2.0)
	if fraction <= 0.0:
		return
	if fraction >= 1.0:
		draw_circle(Vector2.ZERO, radius, color)
		return
	# Заполнение снизу вверх пропорционально HP
	var fill_y := radius * (1.0 - 2.0 * fraction)
	var sin_val := clampf(fill_y / radius, -1.0, 1.0)
	var a1 := asin(sin_val)
	var a2 := PI - a1
	var points := PackedVector2Array()
	var segments := 32
	for i in range(segments + 1):
		var a := a1 + (a2 - a1) * float(i) / float(segments)
		points.append(Vector2(cos(a) * radius, sin(a) * radius))
	if points.size() >= 3:
		draw_colored_polygon(points, color)

func _draw_partial_ellipse(esize: Vector2, color: Color, fraction: float) -> void:
	var outline_points := PackedVector2Array()
	for i in 32:
		var angle := (TAU / 32) * i
		outline_points.append(Vector2(cos(angle) * esize.x, sin(angle) * esize.y))
	draw_polyline(outline_points + PackedVector2Array([outline_points[0]]), Color.WHITE, 2.0)
	if fraction <= 0.0:
		return
	if fraction >= 1.0:
		draw_colored_polygon(outline_points, color)
		return
	var fill_y := esize.y * (1.0 - 2.0 * fraction)
	var sin_val := clampf(fill_y / esize.y, -1.0, 1.0)
	var a1 := asin(sin_val)
	var a2 := PI - a1
	var points := PackedVector2Array()
	var segments := 32
	for i in range(segments + 1):
		var a := a1 + (a2 - a1) * float(i) / float(segments)
		points.append(Vector2(cos(a) * esize.x, sin(a) * esize.y))
	if points.size() >= 3:
		draw_colored_polygon(points, color)

func take_damage(amount: int) -> void:
	current_health -= amount
	_flash_white()
	queue_redraw()
	if current_health <= 0:
		died.emit(data.reward)
		queue_free()

func _flash_white() -> void:
	modulate = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self):
		modulate = Color(1, 1, 1, 1)

func _find_player() -> Node2D:
	return get_tree().get_first_node_in_group("player")

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		if body.is_in_group("player"):
			body.take_damage(data.damage)
			var knockback := (global_position - body.global_position).normalized() * 100
			global_position += knockback
		elif body.is_in_group("warriors"):
			body.take_damage(data.damage)
