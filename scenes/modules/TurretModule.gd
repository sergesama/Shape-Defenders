extends BaseModule
class_name TurretModule

@export var fire_interval: float = 1.5
@export var damage: int = 15
@export var range_radius: float = 300.0

var projectile_scene := preload("res://scenes/projectiles/Projectile.tscn")
var timer: float = 0.0

func _ready() -> void:
	super._ready()
	module_name = "Турель"
	shape_color = Color.ORANGE_RED

func _process(delta: float) -> void:
	timer += delta
	if timer >= fire_interval:
		timer = 0.0
		_fire_at_nearest_enemy()

func _fire_at_nearest_enemy() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist := range_radius

	for enemy in enemies:
		var dist := global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy

	if nearest:
		var projectile := projectile_scene.instantiate()
		projectile.global_position = global_position
		projectile.direction = (nearest.global_position - global_position).normalized()
		projectile.damage = damage
		get_tree().current_scene.add_child(projectile)
		activate()

func _draw_module_shape() -> void:
	# Трапеция
	var points := PackedVector2Array([
		Vector2(-8, -12),
		Vector2(8, -12),
		Vector2(14, 12),
		Vector2(-14, 12)
	])
	draw_colored_polygon(points, shape_color)
	draw_polyline(points + PackedVector2Array([points[0]]), Color.WHITE, 1.5)
