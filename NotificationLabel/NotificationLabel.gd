extends Label
class_name NotificationLabel

@export var green_dialog : StyleBoxFlat
@export var red_dialog : StyleBoxFlat

@onready var timer : Timer = $Timer

func set_wait_time(time: float) -> void:
	timer.wait_time = time

func show_accept_label(new_text: String) -> void:
	add_theme_stylebox_override("normal", green_dialog)
	text = new_text
	timer.start()

func show_error_label(new_text: String) -> void:
	add_theme_stylebox_override("normal", red_dialog)
	text = new_text
	timer.start()

func _on_timer_timeout() -> void:
	queue_free()
