extends Node

## Корневая сцена — контейнер для переключения между меню и игрой

func _ready() -> void:
	# Запускаем с главного меню
	get_tree().change_scene_to_file.call_deferred("res://scenes/menu/MainMenu.tscn")
