extends Node
class_name WaveManager

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)

var current_wave: int = 0
var enemies_remaining: int = 0
var wave_active: bool = false

var enemy_scenes := {
	"small": preload("res://scenes/enemies/SmallCircle.tscn"),
	"medium": preload("res://scenes/enemies/MediumCircle.tscn"),
	"large": preload("res://scenes/enemies/LargeCircle.tscn"),
	"fast": preload("res://scenes/enemies/FastEllipse.tscn"),
	"tank": preload("res://scenes/enemies/TankCircle.tscn"),
	"boss": preload("res://scenes/enemies/BossOval.tscn")
}

func start_waves() -> void:
	_start_next_wave()

func _start_next_wave() -> void:
	current_wave += 1
	wave_started.emit(current_wave)
	wave_active = true

	var wave_composition := _get_wave_composition(current_wave)
	enemies_remaining = wave_composition.size()

	for i in wave_composition.size():
		await get_tree().create_timer(0.8).timeout
		if not is_inside_tree():
			return
		_spawn_enemy(wave_composition[i])

func _get_wave_composition(wave: int) -> Array[String]:
	var composition: Array[String] = []
	var enemy_count := wave * 3

	for i in enemy_count:
		if wave <= 5:
			composition.append("small")
		elif wave <= 10:
			composition.append("small" if randf() > 0.3 else "medium")
		elif wave <= 15:
			var roll := randf()
			if roll < 0.5:
				composition.append("small")
			elif roll < 0.8:
				composition.append("medium")
			else:
				composition.append("large" if randf() > 0.5 else "fast")
		elif wave <= 20:
			var roll := randf()
			if roll < 0.3:
				composition.append("small")
			elif roll < 0.5:
				composition.append("medium")
			elif roll < 0.7:
				composition.append("large")
			elif roll < 0.85:
				composition.append("fast")
			else:
				composition.append("tank")
		else:
			# Wave 20+
			var roll := randf()
			if roll < 0.2:
				composition.append("medium")
			elif roll < 0.4:
				composition.append("large")
			elif roll < 0.6:
				composition.append("fast")
			else:
				composition.append("tank")

	# Босс каждые 5 волн начиная с 20
	if wave >= 20 and wave % 5 == 0:
		composition.append("boss")

	return composition

func _spawn_enemy(type: String) -> void:
	if not is_inside_tree():
		return
	var scene: PackedScene = enemy_scenes[type]
	var enemy: Node2D = scene.instantiate()
	var spawn_pos := _get_random_spawn_position()
	enemy.global_position = spawn_pos
	enemy.died.connect(_on_enemy_died)
	get_tree().current_scene.add_child(enemy)

func _get_random_spawn_position() -> Vector2:
	var viewport := get_viewport().get_visible_rect()
	var side := randi() % 4
	var margin := 50.0

	match side:
		0: return Vector2(randf_range(0, viewport.size.x), -margin)          # Top
		1: return Vector2(viewport.size.x + margin, randf_range(0, viewport.size.y))  # Right
		2: return Vector2(randf_range(0, viewport.size.x), viewport.size.y + margin)  # Bottom
		3: return Vector2(-margin, randf_range(0, viewport.size.y))          # Left
	return Vector2.ZERO

func _on_enemy_died(reward: int) -> void:
	EconomyManager.add_follars(reward)
	enemies_remaining -= 1

	if enemies_remaining <= 0 and wave_active:
		wave_active = false
		wave_completed.emit(current_wave)
		var interval := maxf(5.0, 15.0 - current_wave * 0.5)
		await get_tree().create_timer(interval).timeout
		if is_inside_tree():
			_start_next_wave()
