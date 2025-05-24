extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Called when the node enters the scene tree
func _ready():
	print("Player instance created: ", name)
	if name == str(multiplayer.get_unique_id()):
		# Set a slightly different color for local player
		modulate = Color(0.8, 1, 0.8)

func _physics_process(delta):
	if name == str(multiplayer.get_unique_id()):
		# Add the gravity.
		if not is_on_floor():
			velocity.y += gravity * delta

		# Handle jump.
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var direction = Input.get_axis("ui_left", "ui_right")
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		move_and_slide()
		
		# Only sync position if it has changed significantly
		if velocity.length() > 0.5:
			syncPos.rpc(global_position)

@rpc("any_peer", "call_local")
func syncPos(p):
	if name != str(multiplayer.get_unique_id()):  # Only update remote players
		global_position = p
