extends Node

## Система фолларов

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
