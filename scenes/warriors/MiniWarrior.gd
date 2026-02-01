extends CharacterBody2D

@export var speed: float = 150.0
@export var damage: int = 10
@export var max_health: int = 30
@export var lifetime: float = 15.0

var current_health: int
var target: Node2D
var timer: float = 0.0

func _ready() -> void:
	add_to_group("warriors")
	collision_layer = 8   # warriors
	collision_mask = 2    # enemies
	current_health = max_health
	queue_redraw()

func _physics_process(delta: float) -> void:
	timer += delta
	if timer >= lifetime:
		queue_free()
		return

	target = _find_nearest_enemy()
	if target and is_instance_valid(target):
		var direction := (target.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()

func _draw() -> void:
	# Маленький треугольник
	var points := PackedVector2Array([
		Vector2(0, -8),
		Vector2(7, 6),
		Vector2(-7, 6)
	])
	draw_colored_polygon(points, Color.LIME_GREEN)
	draw_polyline(points + PackedVector2Array([points[0]]), Color.WHITE, 1.0)

func _find_nearest_enemy() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist := 999999.0
	for enemy in enemies:
		var dist := global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	return nearest

func take_damage(amount: int) -> void:
	current_health -= amount
	if current_health <= 0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
