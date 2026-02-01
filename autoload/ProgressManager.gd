extends Node

## Сохранение/загрузка прогресса

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
