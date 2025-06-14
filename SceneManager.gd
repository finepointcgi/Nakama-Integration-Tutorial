extends Node2D

var spawnpoints
@export var playerScene : PackedScene
# Called when the node enters the scene tree for the first time.
func _ready():
	
	add_to_group("InGame")
	
	spawnpoints = get_tree().get_nodes_in_group("SpawnPoint")
	
	var index = 0
	var keys = NakamaMultiplayer.Players.keys()
	var players = NakamaMultiplayer.Players
	print("current nakama players: ", players)
	if keys.size() == 0:
		print("Warning: no players when starting game. Adding local player")
		var localid = get_tree().get_multiplayer().get_unique_id()
		if localid > 0 and !NakamaMultiplayer.Players.has(localid):
			NakamaMultiplayer.Players[localid] = {
				"name" = localid, 
				"ready" = 1
			}
			print("Added fallback local player: " + str(localid))
		
		keys = [localid] if localid > 0 else []
	
	keys.sort()
	for i in keys:
		spawnPlayer(i, index)
		index += 1
		
	var multipler = get_tree().get_multiplayer()
	multipler.peer_connected.connect(onPlayerJoinedMidGame)
	multipler.peer_disconnected.connect(onPlayerLeftMidGame)
	
	if multipler.is_server():
		await  get_tree().create_timer(.5).timeout
		broadcastAllPositions()
	pass # Replace with function body.

func onPlayerJoinedMidGame(id):
	print("player joined game: ", id)
	if get_tree().get_multiplayer().is_server():
		
		#sync all players with joining player
		for playerid in NakamaMultiplayer.Players:
			if playerid != id && has_node(str(playerid)):
				var existingPlayer = get_node(str(playerid))
				syncPlayerPosition.rpc_id(id, playerid, existingPlayer.global_position)
		
		#sync joining player with all players
		if not has_node(str(id)):
			var index = NakamaMultiplayer.Players.keys().find(id)
			if index == -1:
				index = randi() % spawnpoints.size()
			var player = spawnPlayer(id, index)
			syncPlayerPosition.rpc(id, player.global_position)

func onPlayerLeftMidGame(id):
	print("player has left mid game: ", id)
	
	if has_node(str(id)):
		get_node(str(id)).queue_free()

func broadcastAllPositions():
	for id in NakamaMultiplayer.Players:
		if has_node(str(id)):
			var player = get_node(str(id))
			syncPlayerPosition.rpc(id, player.global_position)

@rpc("any_peer", "call_local")
func syncPlayerPosition(id, position):
	if has_node(str(id)):
		get_node(str(id)).global_position = position
	else:
		if NakamaMultiplayer.Players.has(id):
			var spawnIndex = NakamaMultiplayer.Players.keys().find(id)
			if spawnIndex == -1:
				spawnIndex = 0
			var player = spawnPlayer(id, spawnIndex)
			player.global_position = position
			
func spawnPlayer(id, spawnIndex = -1):
	
	var instancedPlayer = playerScene.instantiate()
	instancedPlayer.name = str(id)
	
	add_child(instancedPlayer)
	if spawnIndex == -1:
		spawnIndex = randi() % spawnpoints.size()
		
	spawnIndex = spawnIndex % spawnpoints.size()
	
	instancedPlayer.global_position = spawnpoints[spawnIndex].global_position
	
	return instancedPlayer

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
