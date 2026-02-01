extends BaseModule
class_name GeneratorModule

@export var generate_interval: float = 2.0
@export var generate_amount: int = 5

var timer: float = 0.0

func _ready() -> void:
	super._ready()
	module_name = "Генератор"
	shape_color = Color.GOLD

func _process(delta: float) -> void:
	timer += delta
	if timer >= generate_interval:
		timer = 0.0
		EconomyManager.add_follars(generate_amount)
		activate()

func _draw_module_shape() -> void:
	# Ромб
	var points := PackedVector2Array([
		Vector2(0, -15),
		Vector2(12, 0),
		Vector2(0, 15),
		Vector2(-12, 0)
	])
	draw_colored_polygon(points, shape_color)
	draw_polyline(points + PackedVector2Array([points[0]]), Color.WHITE, 1.5)
