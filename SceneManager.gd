extends Node2D

var spawnpoints
@export var playerScene : PackedScene
# Called when the node enters the scene tree for the first time.
func _ready():
	spawnpoints = get_tree().get_nodes_in_group("SpawnPoint")
	var index = 0
	var keys = NakamaMultiplayer.Players.keys()
	keys.sort()
	for i in keys:
		var instancedPlayer = playerScene.instantiate()
		instancedPlayer.name = str(NakamaMultiplayer.Players[i].name)
		
		add_child(instancedPlayer)
		
		instancedPlayer.global_position = spawnpoints[index].global_position
		
		index += 1
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
