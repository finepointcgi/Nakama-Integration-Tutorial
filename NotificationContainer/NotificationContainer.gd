extends VBoxContainer
class_name NotificationContainer

enum NakamaExceptionError {
	SERVER_ERROR = 13
}


enum NotificationType {
	WARNING,
	OK,
	ERROR
}

@export var notification_label_scene : PackedScene
@export_range(2,15,0.1) var notification_time : float

func create_notification(text: String, 
						notification_type: NotificationType = NotificationType.OK) -> void:
	
	var notification_label : NotificationLabel = notification_label_scene.instantiate()
	
	add_child(notification_label)

	notification_label.set_wait_time(notification_time)
	
	match notification_type:
		NotificationType.OK:
			notification_label.show_accept_label(text)
		NotificationType.ERROR:
			notification_label.show_error_label(text)

func handle_exception(status_code: int) -> void:
		match status_code:
			NakamaExceptionError.SERVER_ERROR:
				create_notification("Falhou a conexão ao servidor!",
									NotificationContainer.NotificationType.ERROR)
			_:
				create_notification("Erro credenciais incorretas!",
									NotificationContainer.NotificationType.ERROR)
