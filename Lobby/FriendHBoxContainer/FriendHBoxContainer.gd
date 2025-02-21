extends HBoxContainer
class_name FriendHBoxContainer

@onready var display_name : Label = $DisplayName
@onready var trade : Button = $Trade
@onready var delete : Button = $Delete
@onready var block : Button = $Block

func set_friend(text: String, 
				 trade_callable: Callable, 
				 delete_callable: Callable,
				 block_callable: Callable) -> void:
	
	display_name.text = text
	trade.pressed.connect(trade_callable)
	delete.pressed.connect(delete_callable)
	block.pressed.connect(block_callable)
