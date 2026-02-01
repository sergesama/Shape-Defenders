# Shape Defenders — Инструкция по реализации (Godot 4.5)

Roguelite tower defense игра с геометрическими фигурами.

## Концепция

Игрок управляет главной фигурой (начиная с квадрата), защищаясь от волн круглых врагов. К главной фигуре присоединяются модули той же угловатости — каждый со своей способностью. Цель: выжить максимально долго, зарабатывая очки для мета-прогрессии.

## Технологический стек

- **Движок**: Godot 4.5
- **Язык**: GDScript
- **Рендер**: 2D с программной отрисовкой фигур (Polygon2D, draw_* методы)
- **Хранение прогресса**: ConfigFile / JSON в user://

## Структура проекта

```
shape_defenders/
├── project.godot
├── icon.svg
├── autoload/
│   ├── GameManager.gd         # Глобальное состояние игры
│   ├── EconomyManager.gd      # Система фолларов
│   └── ProgressManager.gd     # Сохранение/загрузка прогресса
├── resources/
│   ├── enemy_data/
│   │   ├── small_circle.tres
│   │   ├── medium_circle.tres
│   │   └── boss_oval.tres
│   ├── module_data/
│   │   ├── generator.tres
│   │   ├── spawner.tres
│   │   └── turret.tres
│   └── upgrade_tree.tres
├── scenes/
│   ├── main/
│   │   ├── Main.tscn           # Корневая сцена
│   │   └── Main.gd
│   ├── menu/
│   │   ├── MainMenu.tscn
│   │   ├── MainMenu.gd
│   │   ├── UpgradeTree.tscn
│   │   └── UpgradeTree.gd
│   ├── game/
│   │   ├── Game.tscn           # Основной геймплей
│   │   ├── Game.gd
│   │   └── GameOver.tscn
│   ├── player/
│   │   ├── Player.tscn
│   │   └── Player.gd
│   ├── modules/
│   │   ├── BaseModule.tscn
│   │   ├── BaseModule.gd
│   │   ├── GeneratorModule.gd
│   │   ├── SpawnerModule.gd
│   │   └── TurretModule.gd
│   ├── enemies/
│   │   ├── BaseEnemy.tscn
│   │   ├── BaseEnemy.gd
│   │   └── enemy_variants/
│   │       ├── SmallCircle.gd
│   │       ├── MediumCircle.gd
│   │       └── BossOval.gd
│   ├── projectiles/
│   │   ├── Projectile.tscn
│   │   └── Projectile.gd
│   ├── warriors/
│   │   ├── MiniWarrior.tscn
│   │   └── MiniWarrior.gd
│   └── ui/
│       ├── HUD.tscn
│       ├── HUD.gd
│       ├── ModulePanel.tscn
│       └── ModulePanel.gd
├── scripts/
│   ├── wave_manager.gd
│   └── collision_layers.gd
└── shaders/
    └── glow.gdshader           # Опционально для эффектов
```

## Настройка проекта Godot

### project.godot ключевые настройки
```ini
[application]
config/name="Shape Defenders"
run/main_scene="res://scenes/main/Main.tscn"
config/features=PackedStringArray("4.5", "Forward Plus")

[autoload]
GameManager="*res://autoload/GameManager.gd"
EconomyManager="*res://autoload/EconomyManager.gd"
ProgressManager="*res://autoload/ProgressManager.gd"

[display]
window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="viewport"
window/stretch/aspect="keep"

[input]
move_up={deadzone: 0.5, events: [InputEventKey(keycode=W), InputEventKey(keycode=KEY_UP)]}
move_down={deadzone: 0.5, events: [InputEventKey(keycode=S), InputEventKey(keycode=KEY_DOWN)]}
move_left={deadzone: 0.5, events: [InputEventKey(keycode=A), InputEventKey(keycode=KEY_LEFT)]}
move_right={deadzone: 0.5, events: [InputEventKey(keycode=D), InputEventKey(keycode=KEY_RIGHT)]}
pause={deadzone: 0.5, events: [InputEventKey(keycode=KEY_ESCAPE)]}

[layer_names]
2d_physics/layer_1="player"
2d_physics/layer_2="enemies"
2d_physics/layer_3="projectiles"
2d_physics/layer_4="warriors"
2d_physics/layer_5="modules"
```

## Этапы реализации

### Этап 1: Базовый каркас

1. Создать проект Godot 4.5, настроить project.godot
2. Создать Main.tscn как контейнер сцен (Node)
3. Создать автозагрузки (GameManager, EconomyManager, ProgressManager)
4. Реализовать MainMenu.tscn с кнопками "Играть" и "Прокачка"
5. Настроить переходы между сценами через `get_tree().change_scene_to_file()`

### Этап 2: Игрок и движение

**Player.tscn структура:**
```
Player (CharacterBody2D)
├── CollisionShape2D (RectangleShape2D 60x60)
├── ShapeDrawer (Node2D) — кастомная отрисовка
├── ModuleSlots (Node2D)
│   ├── SlotTop (Marker2D)
│   ├── SlotRight (Marker2D)
│   ├── SlotBottom (Marker2D)
│   └── SlotLeft (Marker2D)
└── HurtBox (Area2D)
    └── CollisionShape2D
```

**Player.gd:**
```gdscript
extends CharacterBody2D
class_name Player

signal health_changed(current: int, max_health: int)
signal died

@export var max_health: int = 100
@export var speed: float = 200.0
@export var shape_sides: int = 4  # Количество углов фигуры

var current_health: int
var modules: Array[BaseModule] = []
var module_slots: Array[Marker2D] = []

func _ready() -> void:
	current_health = max_health
	_setup_slots()
	_draw_shape()

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * speed
	move_and_slide()
	_clamp_to_screen()

func _setup_slots() -> void:
	module_slots = $ModuleSlots.get_children()

func _draw_shape() -> void:
	$ShapeDrawer.queue_redraw()

func attach_module(module: BaseModule) -> bool:
	var free_slot := _get_free_slot()
	if free_slot == null:
		return false
	module.position = free_slot.position
	module.reparent($ModuleSlots)
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

func _clamp_to_screen() -> void:
	var viewport_rect := get_viewport_rect()
	position.x = clamp(position.x, 30, viewport_rect.size.x - 30)
	position.y = clamp(position.y, 30, viewport_rect.size.y - 30)
```

**ShapeDrawer.gd (дочерний Node2D):**
```gdscript
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
```

### Этап 3: Модули (базовые 3)

**BaseModule.gd:**
```gdscript
extends Area2D
class_name BaseModule

signal activated

@export var module_name: String = "Base"
@export var cost: int = 0
@export var shape_color: Color = Color.GRAY

var owner_player: Player

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	_draw_module_shape()

func _draw_module_shape() -> void:
	pass  # Переопределяется в наследниках

func activate() -> void:
	activated.emit()
```

**GeneratorModule.gd:**
```gdscript
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
```

**SpawnerModule.gd:**
```gdscript
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
```

**TurretModule.gd:**
```gdscript
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
```

### Этап 4: Враги

**EnemyData Resource:**
```gdscript
# resources/EnemyData.gd
extends Resource
class_name EnemyData

@export var enemy_name: String
@export var max_health: int
@export var damage: int
@export var speed: float
@export var reward: int
@export var color: Color
@export var shape_type: String  # "circle", "ellipse"
@export var size: Vector2
```

**BaseEnemy.gd:**
```gdscript
extends CharacterBody2D
class_name BaseEnemy

signal died(reward: int)

@export var data: EnemyData

var current_health: int
var target: Node2D

func _ready() -> void:
	add_to_group("enemies")
	current_health = data.max_health
	target = _find_player()
	queue_redraw()

func _physics_process(delta: float) -> void:
	if target and is_instance_valid(target):
		var direction := (target.global_position - global_position).normalized()
		velocity = direction * data.speed
		move_and_slide()

func _draw() -> void:
	match data.shape_type:
		"circle":
			draw_circle(Vector2.ZERO, data.size.x, data.color)
			draw_arc(Vector2.ZERO, data.size.x, 0, TAU, 32, Color.WHITE, 2.0)
		"ellipse":
			_draw_ellipse(data.size, data.color)

func _draw_ellipse(size: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 32:
		var angle := (TAU / 32) * i
		points.append(Vector2(cos(angle) * size.x, sin(angle) * size.y))
	draw_colored_polygon(points, color)
	draw_polyline(points + PackedVector2Array([points[0]]), Color.WHITE, 2.0)

func take_damage(amount: int) -> void:
	current_health -= amount
	_flash_white()
	if current_health <= 0:
		died.emit(data.reward)
		queue_free()

func _flash_white() -> void:
	modulate = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1, 1)

func _find_player() -> Node2D:
	return get_tree().get_first_node_in_group("player")

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.take_damage(data.damage)
		# Отскок от игрока
		var knockback := (global_position - body.global_position).normalized() * 100
		global_position += knockback
```

**Параметры врагов (создать .tres файлы):**

| Файл | shape_type | size | color | HP | damage | speed | reward |
|------|------------|------|-------|-----|--------|-------|--------|
| small_circle.tres | circle | (15, 15) | #FF0000 | 30 | 10 | 120 | 5 |
| medium_circle.tres | circle | (25, 25) | #FF8800 | 60 | 20 | 90 | 12 |
| large_circle.tres | circle | (40, 40) | #FFFF00 | 120 | 35 | 60 | 25 |
| fast_ellipse.tres | ellipse | (20, 30) | #00FF00 | 40 | 15 | 180 | 15 |
| tank_circle.tres | circle | (50, 50) | #0088FF | 200 | 50 | 40 | 40 |
| boss_oval.tres | ellipse | (80, 50) | #8800FF | 500 | 100 | 30 | 150 |

### Этап 5: Система волн

**wave_manager.gd:**
```gdscript
extends Node
class_name WaveManager

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)

@export var spawn_points: Array[Marker2D] = []

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
	var enemy := enemy_scenes[type].instantiate()
	var spawn_pos := _get_random_spawn_position()
	enemy.global_position = spawn_pos
	enemy.died.connect(_on_enemy_died)
	get_tree().current_scene.add_child(enemy)

func _get_random_spawn_position() -> Vector2:
	var viewport := get_viewport().get_visible_rect()
	var side := randi() % 4
	var margin := 50.0
	
	match side:
		0: return Vector2(randf_range(0, viewport.size.x), -margin)  # Top
		1: return Vector2(viewport.size.x + margin, randf_range(0, viewport.size.y))  # Right
		2: return Vector2(randf_range(0, viewport.size.x), viewport.size.y + margin)  # Bottom
		3: return Vector2(-margin, randf_range(0, viewport.size.y))  # Left
	return Vector2.ZERO

func _on_enemy_died(reward: int) -> void:
	EconomyManager.add_follars(reward)
	enemies_remaining -= 1
	
	if enemies_remaining <= 0 and wave_active:
		wave_active = false
		wave_completed.emit(current_wave)
		var interval := maxf(5.0, 15.0 - current_wave * 0.5)
		await get_tree().create_timer(interval).timeout
		_start_next_wave()
```

### Этап 6: Экономика и HUD

**EconomyManager.gd (автозагрузка):**
```gdscript
extends Node

signal follars_changed(amount: int)

var current_follars: int = 0

func add_follars(amount: int) -> void:
	current_follars += amount
	follars_changed.emit(current_follars)

func spend_follars(amount: int) -> bool:
	if current_follars >= amount:
		current_follars -= amount
		follars_changed.emit(current_follars)
		return true
	return false

func reset() -> void:
	current_follars = 0
	follars_changed.emit(current_follars)
```

**HUD.tscn структура:**
```
HUD (CanvasLayer)
└── MarginContainer
    └── VBoxContainer
        ├── HBoxContainer (верхняя панель)
        │   ├── FollarsLabel
        │   ├── WaveLabel
        │   └── TimeLabel
        ├── HealthBar (ProgressBar)
        └── ModulePanel (внизу)
```

**HUD.gd:**
```gdscript
extends CanvasLayer

@onready var follars_label: Label = $MarginContainer/VBoxContainer/TopBar/FollarsLabel
@onready var wave_label: Label = $MarginContainer/VBoxContainer/TopBar/WaveLabel
@onready var time_label: Label = $MarginContainer/VBoxContainer/TopBar/TimeLabel
@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBar

var elapsed_time: float = 0.0

func _ready() -> void:
	EconomyManager.follars_changed.connect(_on_follars_changed)
	_on_follars_changed(EconomyManager.current_follars)

func _process(delta: float) -> void:
	elapsed_time += delta
	_update_time_display()

func _on_follars_changed(amount: int) -> void:
	follars_label.text = "Ф: %d" % amount

func update_wave(wave: int) -> void:
	wave_label.text = "Волна: %d" % wave

func update_health(current: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = current

func _update_time_display() -> void:
	var minutes := int(elapsed_time) / 60
	var seconds := int(elapsed_time) % 60
	time_label.text = "%02d:%02d" % [minutes, seconds]
```

### Этап 7: Дерево прокачки (мета-прогрессия)

**ProgressManager.gd (автозагрузка):**
```gdscript
extends Node

const SAVE_PATH := "user://progress.json"

signal points_changed(amount: int)

var data := {
	"total_points": 0,
	"unlocked_nodes": [],
	"high_score": 0,
	"max_wave": 0,
	"unlocked_characters": ["square"]
}

var upgrade_tree := {
	"hp1": {"name": "+10% HP", "cost": 100, "requires": []},
	"damage1": {"name": "+10% урон турели", "cost": 100, "requires": []},
	"hp2": {"name": "+20% HP", "cost": 250, "requires": ["hp1"]},
	"damage2": {"name": "+20% урон турели", "cost": 250, "requires": ["damage1"]},
	"slot1": {"name": "+1 слот модулей", "cost": 400, "requires": ["hp1", "damage1"]},
	"pentagon": {"name": "Пятиугольник", "cost": 500, "requires": ["slot1"]},
	"hexagon": {"name": "Шестиугольник", "cost": 1500, "requires": ["pentagon"]},
	"triangle": {"name": "Треугольник", "cost": 300, "requires": []},
	"shield_module": {"name": "Модуль Щит", "cost": 600, "requires": ["hp2"]},
	"slow_module": {"name": "Модуль Замедлитель", "cost": 600, "requires": ["damage2"]}
}

func _ready() -> void:
	load_progress()

func save_progress() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))

func load_progress() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		var json := JSON.new()
		if json.parse(file.get_as_text()) == OK:
			data = json.data

func add_points(amount: int) -> void:
	data.total_points += amount
	points_changed.emit(data.total_points)
	save_progress()

func unlock_node(node_id: String) -> bool:
	if node_id in data.unlocked_nodes:
		return false
	
	var node_data: Dictionary = upgrade_tree.get(node_id, {})
	if node_data.is_empty():
		return false
	
	# Проверить требования
	for req in node_data.requires:
		if req not in data.unlocked_nodes:
			return false
	
	# Проверить стоимость
	if data.total_points < node_data.cost:
		return false
	
	data.total_points -= node_data.cost
	data.unlocked_nodes.append(node_id)
	
	# Разблокировать персонажей
	if node_id in ["pentagon", "hexagon", "triangle"]:
		data.unlocked_characters.append(node_id)
	
	save_progress()
	points_changed.emit(data.total_points)
	return true

func is_unlocked(node_id: String) -> bool:
	return node_id in data.unlocked_nodes

func get_bonus(stat: String) -> float:
	var bonus := 0.0
	if "hp1" in data.unlocked_nodes:
		bonus += 0.1 if stat == "hp" else 0.0
	if "hp2" in data.unlocked_nodes:
		bonus += 0.2 if stat == "hp" else 0.0
	if "damage1" in data.unlocked_nodes:
		bonus += 0.1 if stat == "damage" else 0.0
	if "damage2" in data.unlocked_nodes:
		bonus += 0.2 if stat == "damage" else 0.0
	return bonus

func update_records(wave: int, score: int) -> void:
	if wave > data.max_wave:
		data.max_wave = wave
	if score > data.high_score:
		data.high_score = score
	save_progress()
```

### Этап 8: Персонажи

| Фигура | sides | Слотов | Особенность | Разблокировка |
|--------|-------|--------|-------------|---------------|
| Квадрат | 4 | 4 | Стартовый | — |
| Пятиугольник | 5 | 5 | +1 слот | 500 ОФ |
| Шестиугольник | 6 | 6 | +2 слота | 1500 ОФ |
| Треугольник | 3 | 3 | +50% скорость, -30% HP | 300 ОФ |

### Этап 9: Полировка

1. **Частицы** — GPUParticles2D при смерти врагов
2. **Screen shake** — через Camera2D offset с tween
3. **Звуки** — AudioStreamPlayer для эффектов
4. **Пауза** — `get_tree().paused = true` + меню паузы
5. **Мобильное управление** — виртуальный джойстик (TouchScreenButton)

**Пример screen shake:**
```gdscript
func shake_camera(intensity: float = 10.0, duration: float = 0.2) -> void:
	var camera := get_viewport().get_camera_2d()
	var tween := create_tween()
	for i in 10:
		tween.tween_property(camera, "offset", Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		), duration / 10)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)
```

## Критерии готовности

- [ ] Игрок двигается, присоединяет модули
- [ ] 3 базовых модуля работают корректно
- [ ] Волны спавнятся с нарастающей сложностью
- [ ] Экономика фолларов функционирует
- [ ] Дерево прокачки сохраняется между сессиями
- [ ] Game over с отображением статистики
- [ ] Минимум 6 типов врагов
- [ ] Стабильные 60 FPS при 50+ объектах

## Примечания для агента

1. **Графика программно** — использовать `_draw()`, Polygon2D, Line2D. Никаких внешних спрайтов
2. **Физика** — CharacterBody2D для игрока/врагов, Area2D для хитбоксов и модулей
3. **Группы** — добавлять врагов в группу "enemies", игрока в "player"
4. **Сигналы** — использовать для связи между системами (died, health_changed, и т.д.)
5. **Ресурсы** — создавать .tres файлы для данных врагов и модулей
6. **Автозагрузки** — GameManager, EconomyManager, ProgressManager как синглтоны
7. **Начисление ОФ** — при смерти игрока: `очки = волна * 10 + время_в_секундах`
