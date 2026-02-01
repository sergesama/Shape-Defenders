extends HBoxContainer

signal module_purchased(module_scene: PackedScene)

var module_catalog := [
	{
		"name": "Генератор",
		"cost": 30,
		"scene": preload("res://scenes/modules/GeneratorModule.tscn"),
		"color": Color.GOLD
	},
	{
		"name": "Турель",
		"cost": 50,
		"scene": preload("res://scenes/modules/TurretModule.tscn"),
		"color": Color.ORANGE_RED
	},
	{
		"name": "Спавнер",
		"cost": 80,
		"scene": preload("res://scenes/modules/SpawnerModule.tscn"),
		"color": Color.LIME_GREEN
	}
]

var buttons: Array[Button] = []

func _ready() -> void:
	for entry in module_catalog:
		var btn := Button.new()
		btn.text = "%s (%dФ)" % [entry.name, entry.cost]
		btn.custom_minimum_size = Vector2(160, 40)
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(_on_buy_pressed.bind(entry))
		add_child(btn)
		buttons.append(btn)
	EconomyManager.follars_changed.connect(_update_buttons)
	_update_buttons(EconomyManager.current_follars)

func _update_buttons(_follars: int) -> void:
	for i in module_catalog.size():
		buttons[i].disabled = EconomyManager.current_follars < module_catalog[i].cost

func _on_buy_pressed(entry: Dictionary) -> void:
	if EconomyManager.spend_follars(entry.cost):
		var module: Node2D = entry.scene.instantiate()
		module_purchased.emit(module)
