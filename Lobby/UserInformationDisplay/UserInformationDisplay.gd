extends PanelContainer

@onready var username = %UserAccountText
@onready var display_name = %DisplayNameText
@onready var email = %EmailText

@onready var grid = $VBox/Grid
@onready var button = $VBox/HBox/Button

func update_user_info(user: NakamaAPI.ApiUser) -> void:
	username.text = user.username
	display_name.text = user.display_name
	email.text = ""

func _on_button_pressed() -> void:
	grid.visible = not grid.visible
	button.text = "Hide" if grid.visible else "Show"


func _on_copy_user_pressed() -> void:
	DisplayServer.clipboard_set(username.text)

func _on_copy_email_pressed() -> void:
	DisplayServer.clipboard_set(email.text)
