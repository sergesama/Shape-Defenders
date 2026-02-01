extends Node

## Глобальное состояние игры

signal game_state_changed(new_state: String)

enum State { MENU, PLAYING, PAUSED, GAME_OVER }

var current_state: State = State.MENU
var current_wave: int = 0
var elapsed_time: float = 0.0

func change_state(new_state: State) -> void:
	current_state = new_state
	game_state_changed.emit(State.keys()[new_state])

func start_game() -> void:
	current_wave = 0
	elapsed_time = 0.0
	EconomyManager.reset()
	change_state(State.PLAYING)
	get_tree().change_scene_to_file("res://scenes/game/Game.tscn")

func game_over() -> void:
	change_state(State.GAME_OVER)
	var score := current_wave * 10 + int(elapsed_time)
	ProgressManager.add_points(score)
	ProgressManager.update_records(current_wave, score)

func go_to_menu() -> void:
	change_state(State.MENU)
	get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")

func go_to_upgrade_tree() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/UpgradeTree.tscn")
