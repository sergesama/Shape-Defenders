extends Area2D
class_name BaseModule

signal activated

@export var module_name: String = "Base"
@export var cost: int = 0
@export var shape_color: Color = Color.GRAY

var owner_player: Node2D

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	_draw_module_shape()

func _draw_module_shape() -> void:
	pass  # Переопределяется в наследниках

func activate() -> void:
	activated.emit()
