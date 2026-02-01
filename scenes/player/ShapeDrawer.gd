extends Node2D

@export var size: float = 60.0
@export var color: Color = Color.CYAN
@export var sides: int = 4

func _draw() -> void:
	var points := PackedVector2Array()
	for i in sides:
		var angle := (TAU / sides) * i - PI / 2
		points.append(Vector2(cos(angle), sin(angle)) * size / 2)
	draw_colored_polygon(points, color)
	draw_polyline(points + PackedVector2Array([points[0]]), Color.WHITE, 2.0)
