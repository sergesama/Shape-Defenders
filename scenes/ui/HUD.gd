extends CanvasLayer

signal module_purchased(module_instance: Node2D)

@onready var follars_label: Label = %FollarsLabel
@onready var wave_label: Label = %WaveLabel
@onready var time_label: Label = %TimeLabel
@onready var health_bar: ProgressBar = %HealthBar
@onready var module_panel := %ModulePanel
@onready var slots_label: Label = %SlotsLabel

var elapsed_time: float = 0.0

func _ready() -> void:
	EconomyManager.follars_changed.connect(_on_follars_changed)
	_on_follars_changed(EconomyManager.current_follars)
	module_panel.module_purchased.connect(func(m: Node2D): module_purchased.emit(m))

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

func update_slots(used: int, total: int) -> void:
	slots_label.text = "Слоты: %d/%d" % [total - used, total]
	module_panel.visible = used < total

func _update_time_display() -> void:
	@warning_ignore("integer_division")
	var minutes := int(elapsed_time) / 60
	@warning_ignore("integer_division")
	var seconds := int(elapsed_time) % 60
	time_label.text = "%02d:%02d" % [minutes, seconds]
