extends Node2D

var spawnpoints
@export var playerScene : PackedScene
# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("InGame")
	spawnpoints = get_tree().get_nodes_in_group("SpawnPoint")
	
	print("SceneManager ready. Players: ", NakamaMultiplayer.Players)
	
	var index = 0
	var keys = NakamaMultiplayer.Players.keys()
	if keys.size() == 0:
		print("WARNING: No players in dictionary when starting game!")
		# Ensure at least the local player is added
		var local_id = get_tree().get_multiplayer().get_unique_id()
		NakamaMultiplayer.Players[local_id] = {
			"name": local_id,
			"ready": 1
		}
		keys = [local_id]
	
	# Before we spawn players, let's verify our players dictionary
	print("About to spawn players. Dictionary contains", keys.size(), "players:")
	for player_id in keys:
		print("- Player ID:", player_id, "data:", NakamaMultiplayer.Players[player_id])
	
	keys.sort()
	for i in keys:
		spawnPlayer(i, index)
		index += 1
	
	# Connect to multiplayer signals to handle players joining/leaving during gameplay
	var multiplayer = get_tree().get_multiplayer()
	multiplayer.peer_connected.connect(onPlayerJoinedMidGame)
	multiplayer.peer_disconnected.connect(onPlayerLeftMidGame)
	
	# Broadcast positions to ensure everyone is synced
	if multiplayer.is_server():
		# Allow some time for nodes to be properly set up
		await get_tree().create_timer(0.5).timeout
		broadcastAllPositions()
	
	print("SceneManager initialized with players: ", NakamaMultiplayer.Players)

# Broadcast all player positions to everyone
func broadcastAllPositions():
	for id in NakamaMultiplayer.Players:
		if has_node(str(id)):
			var player = get_node(str(id))
			syncPlayerPosition.rpc(id, player.global_position)

func spawnPlayer(player_id, spawn_index = -1):
	var instancedPlayer = playerScene.instantiate()
	# Use the player ID directly as the node name to avoid double conversion
	instancedPlayer.name = str(player_id)
	
	print("Spawning player with ID:", player_id)
	add_child(instancedPlayer)
	
	# Use random spawn if no specific index provided
	if spawn_index == -1:
		spawn_index = randi() % spawnpoints.size()
	
	# Wrap around if we run out of spawn points
	spawn_index = spawn_index % spawnpoints.size()
	instancedPlayer.global_position = spawnpoints[spawn_index].global_position
	return instancedPlayer

func onPlayerJoinedMidGame(id):
	print("Player joined mid-game: ", id)
	print("Current Players in dictionary: ", NakamaMultiplayer.Players)
	print("Current nodes: ", get_children())
	
	# Ensure all existing players are broadcast to the new player
	if get_tree().get_multiplayer().is_server():
		# Send all current player positions to the new player
		for player_id in NakamaMultiplayer.Players:
			if player_id != id && has_node(str(player_id)):
				var existing_player = get_node(str(player_id))
				syncPlayerPosition.rpc_id(id, player_id, existing_player.global_position)
		
		# Spawn the new player for everyone
		if not has_node(str(id)):
			var index = NakamaMultiplayer.Players.keys().find(id)
			if index == -1:
				index = randi() % spawnpoints.size()
			var player = spawnPlayer(id, index)
			# Broadcast new player position to all clients
			syncPlayerPosition.rpc(id, player.global_position)

func onPlayerLeftMidGame(id):
	print("Player left mid-game: ", id)
	# Player cleanup is handled by the playerDisconnected RPC in Client.gd
	if has_node(str(id)):
		get_node(str(id)).queue_free()
	
@rpc("any_peer", "call_local")
func syncPlayerPosition(player_id, position):
	print("Syncing position for player: ", player_id, " to ", position)
	if has_node(str(player_id)):
		get_node(str(player_id)).global_position = position
	else:
		# Player node doesn't exist yet, create it
		if NakamaMultiplayer.Players.has(player_id):
			var spawn_index = NakamaMultiplayer.Players.keys().find(player_id)
			if spawn_index == -1:
				spawn_index = 0
			var player = spawnPlayer(player_id, spawn_index)
			player.global_position = position
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
