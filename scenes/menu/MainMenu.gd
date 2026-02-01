extends Control

func _ready() -> void:
	# Подключаем кнопки
	%PlayButton.pressed.connect(_on_play_pressed)
	%UpgradeButton.pressed.connect(_on_upgrade_pressed)

func _on_play_pressed() -> void:
	GameManager.start_game()

func _on_upgrade_pressed() -> void:
	GameManager.go_to_upgrade_tree()
