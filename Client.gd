extends Control
class_name NakamaMultiplayer

var session : NakamaSession # this is the session
var client : NakamaClient # this is the client {session}
var socket : NakamaSocket # connection to nakama
var createdMatch
var multiplayerBridge : NakamaMultiplayerBridge

var selectedGroup
var currentChannel
var chatChannels := {}

static var Players = {}

var party

signal OnStartGame()

# Called when the node enters the scene tree for the first time.
func _ready():
	client = Nakama.create_client("defaultkey", "127.0.0.1", 7350, "http")
	#client = Nakama.create_client("defaultkey", "198.199.80.118", 7350, "http")
	
	pass # Replace with function body.

func updateUserInfo(username, displayname, avaterurl = "", language = "en", location = "us", timezone = "est"):
	await client.update_account_async(session, username, displayname, avaterurl, language, location, timezone)

func onMatchPresence(presence : NakamaRTAPI.MatchPresenceEvent):
	print(presence)

func onMatchState(state : NakamaRTAPI.MatchData):
	print("data is : " + str(state.data))

func onSocketConnected():
	print("Socket Connected")

func onSocketClosed():
	print("Socket Closed")

func onSocketReceivedError(err):
	print("Socket Error:" + str(err))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_login_button_button_down():
	session = await client.authenticate_email_async($Panel2/EmailInput.text , $Panel2/PasswordInput.text)
	
	#var deviceid = OS.get_unique_id()
	#session = await client.authenticate_device_async(deviceid)
	socket = Nakama.create_socket_from(client)
	
	await socket.connect_async(session)
	
	socket.connected.connect(onSocketConnected)
	socket.closed.connect(onSocketClosed)
	socket.received_error.connect(onSocketReceivedError)
	
	socket.received_match_presence.connect(onMatchPresence)
	socket.received_match_state.connect(onMatchState)
	
	socket.received_channel_message.connect(onChannelMessage)
	
	socket.received_party_presence.connect(onPartyPresence)
	
	#updateUserInfo("test", "testDisplay")
	
	#var account = await client.get_account_async(session)
	#
	#$Panel/UserAccountText.text = account.user.username
	#$Panel/DisplayNameText.text = account.user.display_name
	
	setupMultiplayerBridge()
	subToFriendChannels()
	pass # Replace with function body.



func setupMultiplayerBridge():
	multiplayerBridge = NakamaMultiplayerBridge.new(socket)
	multiplayerBridge.match_join_error.connect(onMatchJoinError)
	var multiplayer = get_tree().get_multiplayer()
	multiplayer.set_multiplayer_peer(multiplayerBridge.multiplayer_peer)
	multiplayer.peer_connected.connect(onPeerConnected)
	multiplayer.peer_disconnected.connect(onPeerDisconnected)
	
func onPeerConnected(id):
	print("Peer connected id is : " + str(id))
	
	if !Players.has(id):
		Players[id] = {
			"name" : id,
			"ready" : 0
		}
	if !Players.has(multiplayer.get_unique_id()):
		Players[multiplayer.get_unique_id()]= {
			"name" : multiplayer.get_unique_id(),
			"ready" : 0
		}
	print(Players)
	
func onPeerDisconnected(id):
	print("Peer disconnected id is : " + str(id))
	
func onMatchJoinError(error):
	print("Unable to join match: " + error.message)

func onMatchJoin():
	print("joined Match with id: " + multiplayerBridge.match_id)
func _on_store_data_button_down():
	var saveGame = {
		"name" : "username",
		"items" : [{
			"id" : 1,
			"name" : "gun",
			"ammo" : 10
		},
		{
			"id" : 2,
			"name" : "sword",
			"ammo" : 0
		}],
		"level" : 10
	}
	var data = JSON.stringify(saveGame)
	var result = await client.write_storage_objects_async(session, [
		NakamaWriteStorageObject.new("saves", "savegame2", 1, 1, data , "")
	])
	
	if result.is_exception():
		print("error" + str(result))
		return
	print("Stored data successfully!")
	pass # Replace with function body.


func _on_get_data_button_down():
	var result = await client.read_storage_objects_async(session, [
		NakamaStorageObjectId.new("saves", "savegame", session.user_id)
	])
	
	if result.is_exception():
		print("error" + str(result))
		return
	for i in result.objects:
		print(i.value)
	pass # Replace with function body.


func _on_list_data_button_down():
	var dataList = await client.list_storage_objects_async(session, "saves",session.user_id, 5)
	for i in dataList.objects:
		print(i)
	pass # Replace with function body.


func _on_join_create_match_button_down():
	multiplayerBridge.join_named_match($Panel3/MatchName.text)
	
	#createdMatch = await socket.create_match_async($Panel3/MatchName.text)
	#if createdMatch.is_exception():
		#print("Failed to create match " + str(createdMatch))
		#return
	#
	#print("Created match :" + str(createdMatch.match_id))
	pass # Replace with function body.


func _on_ping_button_down():
	#sendData.rpc("hello world")
	var data = {"hello" : "world"}
	socket.send_match_state_async(createdMatch.match_id, 1, JSON.stringify(data))
	pass # Replace with function body.

@rpc("any_peer")
func sendData(message):
	print(message)


func _on_matchmaking_button_down():
	var query = "+properties.region:US +properties.rank:>=4 +properties.rank:<=10"
	var stringP = {"region" : "US"}
	var numberP = { "rank": 6}
	
	var ticket = await socket.add_matchmaker_async(query,2, 4, stringP, numberP)
	
	if ticket.is_exception():
		print("failed to matchmake : " + str(ticket))
		return
	
	print("match ticket number : " + str(ticket))
	
	socket.received_matchmaker_matched.connect(onMatchMakerMatched)
	pass # Replace with function body.

func onMatchMakerMatched(matched : NakamaRTAPI.MatchmakerMatched):
	var joinedMatch = await socket.join_matched_async(matched)
	createdMatch = joinedMatch

######### Friends 
func _on_add_friend_button_down():
	var id = [$Panel4/AddFriendText.text]
	
	var result = await client.add_friends_async(session, null, id)
	pass # Replace with function body.


func _on_get_friends_button_down():
	var result = await client.list_friends_async(session)
	
	for i in result.friends:
		var container = HBoxContainer.new()
		var currentlabel = Label.new()
		currentlabel.text = i.user.display_name
		container.add_child(currentlabel)
		print(i)
		var currentButton = Button.new()
		container.add_child(currentButton)
		currentButton.text = "Trade"
		currentButton.button_down.connect(trade.bind(i.user.id))
		$Panel4/Panel4/VBoxContainer.add_child(container)
		
	pass # Replace with function body.

func _on_remove_friend_button_down():
	var result = await client.delete_friends_async(session,[], [$Panel4/AddFriendText.text])
	pass # Replace with function body.


func _on_block_friends_button_down():
	var result = await client.block_friends_async(session,[], [$Panel4/AddFriendText.text])
	pass # Replace with function body.


func _on_create_group_button_down():
	var group = await client.create_group_async(session, $Panel6/GroupName.text, $Panel6/GroupDesc.text, "" , "en", true, 32)
	print(group)
	pass # Replace with function body.


func _on_get_group_memebers_button_down():
	var result = await client.list_group_users_async(session, $Panel5/GroupName.text)
	
	for i in result.group_users:
		var currentlabel = Label.new()
		currentlabel.text = i.user.display_name
		$Panel5/Panel4/GroupVBox.add_child(i.user.username)
		print("users in group " + $Panel5/GroupName.text  + i.user.username)
	pass # Replace with function body.


func _on_button_button_down():
	Ready.rpc(multiplayer.get_unique_id())
	pass # Replace with function body.
	
@rpc("any_peer", "call_local")
func Ready(id):
	Players[id].ready = 1
	if multiplayer.is_server():
		var readyPlayers = 0
		for i in Players:
			if Players[i].ready == 1:
				readyPlayers += 1
		if readyPlayers == Players.size():
			StartGame.rpc()

@rpc("any_peer", "call_local")
func StartGame():
	OnStartGame.emit()
	hide()
	pass

####### Group 
func _on_add_user_to_group_button_down():
	await  client.join_group_async(session, selectedGroup.id)
	pass # Replace with function body.


func _on_add_user_to_group_2_button_down():
	var users = await client.list_group_users_async(session,selectedGroup.id, 3)
	
	for user in users.group_users:
		var u = user.user as NakamaAPI.ApiUser
		await client.add_group_users_async(session, selectedGroup.id, [u.id])
	pass # Replace with function body.


func _on_check_button_toggled(toggled_on):
	await client.update_group_async(session, selectedGroup.id, "Strong Gamers", "we are the strong gamers!", null, "en", toggled_on)
	pass # Replace with function body.


func _on_list_groups_button_down():
	var limit = 10
	var result = await client.list_groups_async(session, $Panel6/GroupQuery.text, limit, null, null, null)
	
	for group in result.groups:
		var vbox = VBoxContainer.new()
		var hbox = HBoxContainer.new()
		
		var namelabel = Label.new()
		namelabel.text = group.name
		hbox.add_child(namelabel)
		var button = Button.new()
		button.button_down.connect(onGroupSelectButton.bind(group))
		button.text = "Select Group"
		hbox.add_child(button)
		vbox.add_child(hbox)
		$Panel6/Panel/VBoxContainer.add_child(vbox)
	pass # Replace with function body.

func onGroupSelectButton(group):
	selectedGroup = group
	




func _on_promote_user_button_down():
	var result : NakamaAPI.ApiUsers = await  client.get_users_async(session, [],[$Panel6/UserToManage.text], null)
	for u in result.users:
		await client.promote_group_users_async(session, selectedGroup.id, [u.id])
	pass # Replace with function body.


func _on_demote_user_button_down():
	var result : NakamaAPI.ApiUsers = await  client.get_users_async(session, [],[$Panel6/UserToManage.text], null)
	for u in result.users:
		await client.demote_group_users_async(session, selectedGroup.id, [u.id])
	pass # Replace with function body.


func _on_kick_user_button_down():
	var result : NakamaAPI.ApiUsers = await  client.get_users_async(session, [],[$Panel6/UserToManage.text], null)
	for u in result.users:
		await client.kick_group_users_async(session, selectedGroup.id, [u.id])
	pass # Replace with function body.



func _on_leave_group_button_down():
	await client.leave_group_async(session, selectedGroup.id)
	pass # Replace with function body.


func _on_delete_group_button_down():
	await  client.delete_group_async(session, selectedGroup.id)
	pass # Replace with function body.

########## Chat Room Code
func _on_join_chat_room_button_down():
	var type = NakamaSocket.ChannelType.Room
	currentChannel = await socket.join_chat_async($Panel7/ChatName.text, type, false, false)
	
	print("channel id: " + currentChannel.id)
	pass # Replace with function body.

func onChannelMessage(message : NakamaAPI.ApiChannelMessage):
	var content = JSON.parse_string(message.content)
	if content.type == 0:
		$Panel7/Chat/TabContainer.get_node(content.id).text += message.username + ": " + str(content.message) + "\n"
	elif content.type == 1 && party == null:
		$Panel8/Panel2.show()
		party = {"id" : content.partyID}
		$Panel8/Panel2/Label.text = str(content.message)
		pass

func _on_submit_chat_button_down():
	await socket.write_chat_message_async(currentChannel.id, {
		 "message" : $Panel7/Chat/ChatText.text,
		"id" : chatChannels[currentChannel.id].label,
		"type" : 0
		})
	pass # Replace with function body.


func _on_join_group_chat_room_button_down():
	var type = NakamaSocket.ChannelType.Group
	currentChannel = await socket.join_chat_async(selectedGroup.id, type, true, false)
	
	print("channel id: " + currentChannel.id)
	chatChannels[selectedGroup.id] = {
		"channel" : currentChannel,
		"label" : "Group Chat"
		}
	var currentEdit = TextEdit.new()
	currentEdit.name = "currentGroup"
	$Panel7/Chat/TabContainer.add_child(currentEdit)
	currentEdit.text = await listMessages(currentChannel)
	$Panel7/Chat/TabContainer.tab_changed.connect(onChatTabChanged.bind(selectedGroup.id))
	
	pass # Replace with function body.

func onChatTabChanged(index, channelID):
	currentChannel = chatChannels[channelID].channel
	pass
	
func listMessages(currentChannel):
	
	var result = await  client.list_channel_messages_async(session, currentChannel.id, 100, true)
	var text = ""
	for message in result.messages:
		if(message.content != "{}"):
			var content = JSON.parse_string(message.content)
		
			#text += message.username + ": " + str(content.message) + "\n"
	return text
	
func subToFriendChannels():
	var result = await client.list_friends_async(session)
	for i in result.friends:
		var type = NakamaSocket.ChannelType.DirectMessage
		var channel = await socket.join_chat_async(i.user.id, type, true, false)
		chatChannels[channel.id] = {
		"channel" : channel,
		"label" : i.user.username
		} 
		var currentEdit = TextEdit.new()
		currentEdit.name = i.user.username
		$Panel7/Chat/TabContainer.add_child(currentEdit)
		currentEdit.text = await listMessages(channel)
		$Panel7/Chat/TabContainer.tab_changed.connect(onChatTabChanged.bind(channel.id))

func _on_join_direct_chat_button_down():
	var type = NakamaSocket.ChannelType.DirectMessage
	var usersResult = await  client.get_users_async(session, [], [$Panel7/ChatName.text])
	if usersResult.users.size() > 0:
		currentChannel = await socket.join_chat_async(usersResult.users[0].id, type, true, false)
		
		print("channel id: " + currentChannel.id)
		
		var result = await  client.list_channel_messages_async(session, currentChannel.id, 100, true)
		
		for message in result.messages:
			if(message.content != "{}"):
				var content = JSON.parse_string(message.content)
			
				$Panel7/Chat/ChatTextBox.text += message.username + ": " + str(content.message) + "\n"
		
	
	pass # Replace with function body.

###### Party System

func _on_create_party_button_down():
	party = await  socket.create_party_async(false, 2)
	
	pass # Replace with function body.

func onInviteToParty(friend):
	var channel = await socket.join_chat_async(friend.user.id, NakamaSocket.ChannelType.DirectMessage)
	var ack = await socket.write_chat_message_async(channel.id, {
			"message" : "Join Party with "  + session.username,
			"partyID" : party.party_id,
			"type" : 1
			}
		)
	pass


func _on_join_party_yes_button_down():
	var result = await  socket.join_party_async(party.id)
	if result.is_exception():
		print("failed to join party")
	$Panel8/Panel2.hide()
	pass # Replace with function body.
	

func _on_join_party_no_button_down():
	$Panel8/Panel2.hide()
	pass # Replace with function body.

func onPartyPresence(presence : NakamaRTAPI.PartyPresenceEvent):
	print("JOINED PARTY " + presence.party_id)



# Function to add an item to the player's inventory
func add_item_to_inventory(item_data: Dictionary):
	var payload = JSON.stringify(item_data)
	var rpc_future = await client.rpc_async(session, "add_item_to_inventory", payload)
	

	var response = JSON.parse_string(rpc_future.payload)
	print("Item added with ID: %s" % response.item_id)

# Function to create a trade offer
func create_trade_offer(receiver_id: String, offer_items: Array, request_items: Array):
	var payload = {
	"receiver_id": receiver_id,
	"offer_items": offer_items,
	"request_items": request_items
	}
	var rpc_future = await client.rpc_async(session, "create_trade_offer", JSON.stringify(payload))
	

	
	var response = JSON.parse_string(rpc_future.payload)
	print("Trade offer created with ID: %s" % response.offer_id)

# Function to accept a trade offer
func accept_trade_offer(offer_id: String):
	var payload = {"offer_id": offer_id}
	var rpc_future = await client.rpc_async(session, "accept_trade_offer", JSON.stringify(payload))


	
	var response = JSON.parse_string(rpc_future.payload)
	print("Trade accepted: %s" % response)

# Function to cancel a trade offer
func cancel_trade_offer(offer_id: String):
	var payload = {"offer_id": offer_id}
	var rpc_future = await client.rpc_async(session, "cancel_trade_offer", JSON.stringify(payload))


	if rpc_future.is_error():
		print("Failed to cancel trade offer: %s" % rpc_future.error)
	else:
		var response = JSON.stringify(rpc_future.get_result().payload)
		print("Trade offer canceled: %s" % response.result)

# Function to get the player's inventory
func get_inventory(id):
	var rpc_future = await client.rpc_async(session, "get_inventory", JSON.stringify({"id": id}))

	var inventory  = JSON.parse_string(rpc_future.payload)
	print("Inventory: %s" % inventory)
		# You can process the inventory data as needed
		
	return inventory

# Function to get pending trade offers
func get_trade_offers():
	var rpc_future = await client.rpc_async(session, "get_trade_offers", "")

	
	var trade_offers = JSON.parse_string(rpc_future.payload)
	print("Pending trade offers: %s" % trade_offers)
		# You can process the trade offers data as needed
	return trade_offers
func get_items(playerId, id):
	var data = {"id" : playerId, "item_id" : id}
	var rpc_future = await client.rpc_async(session, "get_item", JSON.stringify(data))
	
	return JSON.parse_string(rpc_future.payload)
# Example usage
func some_function():
	# Adding an item
	

	# Creating a trade offer
	var receiver = "2e046658-5d93-4c47-a9ef-7eea3eaa520a"  # Replace with actual receiver user ID
	var offer_items = ["4a082709-ca11-4613-8b83-3169d7964469"]
	var request_items = []
	create_trade_offer(receiver, offer_items, request_items)

	# Accepting a trade offer
	var offer_id = "trade_offer_id"  # Replace with actual trade offer ID
	accept_trade_offer(offer_id)

	# Canceling a trade offer
	cancel_trade_offer(offer_id)

	# Getting inventory
	get_inventory(session.user_id)

	# Getting trade offers
	get_trade_offers()


func _on_add_inventory_button_down():
	var item = {"name": "Sword", "type": "Weapon", "rarity": "Rare"}
	add_item_to_inventory(item)
	pass # Replace with function body.


func _on_get_inventory_button_down():
	get_inventory(session.user_id)
	pass # Replace with function body.


func _on_offer_trade_button_down():
	# Creating a trade offer
	var receiver = PlayerToTradeWith  # Replace with actual receiver user ID
	var offer_items = TradeItems
	var request_items = ItemsToTradeFor
	create_trade_offer(receiver, offer_items, request_items)
	pass # Replace with function body.


func _on_get_trades_button_down():
	var trade_offers = await get_trade_offers()
	#var data = JSON.parse_string(trade_offers)
	for i in trade_offers:
		var button = Button.new()
		var id = await client.get_users_async(session, [i.sender_id], null)
		button.text = id.users[0].display_name
		button.button_down.connect(setTradeOffers.bind(i))
		$Trading/Inventory/VBoxContainer.add_child(button)
	pass # Replace with function body.

func setTradeOffers(offer):
	for i in offer.request_items:
		#var item = await get_items(offer.receiver_id, i.item_id)
		var button = Button.new()
		button.text = i.name
		$"Trading/Panel/Player 2/VBoxContainer".add_child(button)
	for i in offer.offer_items:
		#var item = await get_items(offer.sender_id, i.item_id)
		var button = Button.new()
		button.text = i.name
		$"Trading/Panel/Player 1/VBoxContainer".add_child(button)
	currentTradeOffer = offer

func _on_accept_trade_button_down():
	
	# Accepting a trade offer
	var offer_id = currentTradeOffer.offer_id  # Replace with actual trade offer ID
	accept_trade_offer(offer_id)
	pass # Replace with function body.

var TradeItems = []
var ItemsToTradeFor = []
var PlayerToTradeWith
var currentTradeOffer
func trade(id):
	PlayerToTradeWith = id
	print("player to trade with" + PlayerToTradeWith)
	var inventory = await get_inventory(id)
	for i in inventory:
		var button = Button.new()
		button.text = i.name
		button.button_down.connect(setItemForTrade.bind(i, button, false))
		$"Trading/Panel/Player 2/VBoxContainer".add_child(button)
	
	var myInventory = await get_inventory(session.user_id)
	
	for s in myInventory:
		var button = Button.new()
		button.text = s.name
		button.button_down.connect(setItemForTrade.bind(s, button, true))
		$"Trading/Panel/Player 1/VBoxContainer".add_child(button)
		
func setItemForTrade(item, button : Button, player):
	var items
	if player:
		items = TradeItems
	else:
		items = ItemsToTradeFor
	if(!items.has(item)):
		items.append(item)
		var stylebox = StyleBoxFlat.new()
		stylebox.bg_color = Color.GREEN
		button.add_theme_stylebox_override("normal", stylebox)
	else:
		items.erase(item)
		var stylebox = StyleBoxFlat.new()
		stylebox.bg_color = Color.WHITE
		button.add_theme_stylebox_override("normal", stylebox)
	if player:
		TradeItems = items
	else:
		ItemsToTradeFor = items 
		
