extends Control
class_name NakamaMultiplayer

var session : NakamaSession # this is the session
var client : NakamaClient # this is the client {session}
var socket : NakamaSocket # connection to nakama
var createdMatch
var multiplayerBridge : NakamaMultiplayerBridge

var selectedGroup
var currentChannel

static var Players = {}

var party

signal OnStartGame()

# Called when the node enters the scene tree for the first time.
func _ready():
	client = Nakama.create_client("defaultkey", "127.0.0.1", 7350, "http")
	
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
	subToFriendsChannels()
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
		currentButton.text = "Invite"
		currentButton.button_down.connect(onInviteToParty.bind(i))
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
		$Panel7/Chat/ChatTextBox.text += message.username + ": " + str(content.message) + "\n"
	elif content.type == 1 && party == null:
		$Panel8/Panel2.show()
		party = {"id" : content.partyID}
		$Panel8/Panel2/Label.text = str(content.message)
		pass

func _on_submit_chat_button_down():
	await socket.write_chat_message_async(currentChannel.id, {
		 "message" : $Panel7/Chat/ChatText.text,
		"type" : 0
		})
	pass # Replace with function body.


func _on_join_group_chat_room_button_down():
	var type = NakamaSocket.ChannelType.Group
	currentChannel = await socket.join_chat_async(selectedGroup.id, type, true, false)
	
	print("channel id: " + currentChannel.id)
	
	var result = await  client.list_channel_messages_async(session, currentChannel.id, 100, true)
	
	for message in result.messages:
		if(message.content != "{}"):
			var content = JSON.parse_string(message.content)
		
			$Panel7/Chat/ChatTextBox.text += message.username + ": " + str(content.message) + "\n"
	
	pass # Replace with function body.
	

func subToFriendsChannels():
	var result = await client.list_friends_async(session)
	for i in result.friends:
		var type = NakamaSocket.ChannelType.DirectMessage
		await socket.join_chat_async(i.user.id, type, true, false)

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
