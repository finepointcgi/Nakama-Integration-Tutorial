extends PanelContainer

signal login(email: String, password: String)

@onready var email_input : LineEdit = %EmailInput
@onready var password_input : LineEdit = %PasswordInput
@onready var show_hide : Button = %ShowHide

func _on_login_button_pressed() -> void:

	var email : String = email_input.placeholder_text.strip_edges() \
	 if email_input.text.is_empty() \
	 else email_input.text.strip_edges()
	
	var password : String = password_input.placeholder_text.strip_edges() \
	 if password_input.text.is_empty() \
	 else password_input.text.strip_edges()
	
	login.emit(email, password)

func _on_show_hide_toggled(toggled_on: bool) -> void:
	password_input.secret = toggled_on
	show_hide.text = "Show" if toggled_on else "Hide"
