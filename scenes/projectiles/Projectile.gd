extends Area2D

@export var speed: float = 500.0
@export var lifetime: float = 3.0

var direction := Vector2.ZERO
var damage: int = 10
var timer: float = 0.0

func _ready() -> void:
	collision_layer = 4  # projectiles
	collision_mask = 2   # enemies
	queue_redraw()

func _process(delta: float) -> void:
	position += direction * speed * delta
	timer += delta
	if timer >= lifetime:
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 4.0, Color.YELLOW)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
