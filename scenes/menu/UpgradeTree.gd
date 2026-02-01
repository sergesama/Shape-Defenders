extends Control

## Дерево прокачки — заглушка для этапа 1

func _ready() -> void:
	%BackButton.pressed.connect(_on_back_pressed)
	%PointsLabel.text = "Очки: %d" % ProgressManager.data.total_points

func _on_back_pressed() -> void:
	GameManager.go_to_menu()
