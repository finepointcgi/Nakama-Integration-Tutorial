extends PanelContainer

signal register_account(username: String,
						email: String,
						password: String)
						
@onready var username_input : LineEdit = %UsernameInput
@onready var email_input : LineEdit = %EmailInput
@onready var password_input : LineEdit = %PasswordInput
@onready var confirm_password_input : LineEdit = %ConfirmPasswordField
@onready var show_hide : Button = %ShowHide


func _on_show_hide_toggled(toggled_on: bool) -> void:
	password_input.secret = toggled_on
	show_hide.text = "Show" if toggled_on else "Hide"

func _on_register_button_pressed() -> void:

	var username : String = username_input.placeholder_text.strip_edges() \
	 if username_input.text.is_empty() \
	 else username_input.text.strip_edges()
	
	var email : String = email_input.placeholder_text.strip_edges() \
	 if email_input.text.is_empty() \
	 else email_input.text.strip_edges()
	
	var password : String = password_input.placeholder_text.strip_edges() \
	 if password_input.text.is_empty() \
	 else password_input.text.strip_edges()
	
	var confirm_password : String = confirm_password_input.placeholder_text.strip_edges() \
	 if confirm_password_input.text.is_empty() \
	 else confirm_password_input.text.strip_edges()
	
	if password != confirm_password:
		return
		
	register_account.emit(username, email, password)
