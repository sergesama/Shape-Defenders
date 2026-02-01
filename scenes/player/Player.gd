extends CharacterBody2D
class_name Player

signal health_changed(current: int, max_health: int)
signal died

@export var max_health: int = 100
@export var speed: float = 200.0
@export var shape_sides: int = 4  # Количество углов фигуры
@export var contact_damage: int = 5
@export var knockback_force: float = 150.0

var current_health: int
var modules: Array = []
var module_slots: Array[Marker2D] = []

func _ready() -> void:
	add_to_group("player")
	current_health = max_health
	_setup_slots()
	_draw_shape()
	health_changed.emit(current_health, max_health)
	$HurtBox.body_entered.connect(_on_hurtbox_body_entered)

func _physics_process(_delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * speed
	move_and_slide()
	_clamp_to_screen()

func _setup_slots() -> void:
	module_slots = []
	for child in $ModuleSlots.get_children():
		if child is Marker2D:
			module_slots.append(child)

func _draw_shape() -> void:
	$ShapeDrawer.sides = shape_sides
	$ShapeDrawer.queue_redraw()

func attach_module(module: Node2D) -> bool:
	var free_slot := _get_free_slot()
	if free_slot == null:
		return false
	module.position = free_slot.position
	if module.get_parent():
		module.reparent(free_slot)
	else:
		free_slot.add_child(module)
	modules.append(module)
	return true

func _get_free_slot() -> Marker2D:
	for slot in module_slots:
		if slot.get_child_count() == 0:
			return slot
	return null

func take_damage(amount: int) -> void:
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		died.emit()

func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(contact_damage)
		var knockback := (body.global_position - global_position).normalized() * knockback_force
		body.global_position += knockback

func _clamp_to_screen() -> void:
	var viewport_rect := get_viewport_rect()
	position.x = clamp(position.x, 30, viewport_rect.size.x - 30)
	position.y = clamp(position.y, 30, viewport_rect.size.y - 30)
