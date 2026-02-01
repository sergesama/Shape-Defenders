extends Node2D

## Основная игровая сцена

@onready var player := $Player
@onready var wave_manager := $WaveManager
@onready var hud := $HUD

var generator_scene := preload("res://scenes/modules/GeneratorModule.tscn")

func _ready() -> void:
	if player:
		player.died.connect(_on_player_died)
		player.health_changed.connect(_on_player_health_changed)
		_give_starting_module()
		hud.update_health(player.current_health, player.max_health)
		_update_slot_display()

	hud.module_purchased.connect(_on_module_purchased)
	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.wave_completed.connect(_on_wave_completed)
	wave_manager.start_waves()

func _process(delta: float) -> void:
	GameManager.elapsed_time += delta

func _give_starting_module() -> void:
	# Игрок начинает с генератором фолларов
	var gen := generator_scene.instantiate()
	player.attach_module(gen)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		GameManager.go_to_menu()

func _on_wave_started(wave_number: int) -> void:
	GameManager.current_wave = wave_number
	hud.update_wave(wave_number)

func _on_wave_completed(_wave_number: int) -> void:
	pass

func _on_player_health_changed(current: int, max_health: int) -> void:
	hud.update_health(current, max_health)

func _on_module_purchased(module_instance: Node2D) -> void:
	if player and player.attach_module(module_instance):
		_update_slot_display()
	else:
		# Нет свободных слотов — вернуть фоллары
		module_instance.queue_free()

func _update_slot_display() -> void:
	var used: int = player.modules.size()
	var total: int = player.module_slots.size()
	hud.update_slots(used, total)

func _on_player_died() -> void:
	GameManager.game_over()
	GameManager.go_to_menu()
