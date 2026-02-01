extends BaseModule
class_name SpawnerModule

@export var spawn_cost: int = 20
@export var auto_spawn_interval: float = 5.0

var warrior_scene := preload("res://scenes/warriors/MiniWarrior.tscn")
var timer: float = 0.0

func _ready() -> void:
	super._ready()
	module_name = "Спавнер"
	shape_color = Color.LIME_GREEN

func _process(delta: float) -> void:
	timer += delta
	if timer >= auto_spawn_interval:
		timer = 0.0
		try_spawn_warrior()

func try_spawn_warrior() -> void:
	if EconomyManager.spend_follars(spawn_cost):
		var warrior := warrior_scene.instantiate()
		warrior.global_position = global_position
		get_tree().current_scene.add_child(warrior)
		activate()

func _draw_module_shape() -> void:
	# Параллелограмм
	var points := PackedVector2Array([
		Vector2(-10, -10),
		Vector2(15, -10),
		Vector2(10, 10),
		Vector2(-15, 10)
	])
	draw_colored_polygon(points, shape_color)
	draw_polyline(points + PackedVector2Array([points[0]]), Color.WHITE, 1.5)
