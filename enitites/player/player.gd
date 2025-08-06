extends CharacterBody3D

const SPEED = 4
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.003

@export var animation_tree: AnimationTree
@export var camera: Camera3D

var rotation_y = 0.0
var rotation_x = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		rotation_y -= event.relative.x * MOUSE_SENSITIVITY
		rotation_x -= event.relative.y * MOUSE_SENSITIVITY
		rotation_x = clamp(rotation_x, deg_to_rad(-60), deg_to_rad(60))
		rotation.y = rotation_y
		camera.rotation.x = rotation_x
		
func get_blended_float(input_vector: Vector2) -> float:
	var forward_value = 1.7
	var backward_value = 1.3
	var side_value = 1.3
	var idle_value = 1.0

	# Handle the idle case first
	if input_vector.length_squared() < 0.01: # Check if vector is near zero
		return idle_value

	# Normalize the input vector to remove speed influence
	var normalized_input = input_vector.normalized()

	# Determine the magnitude of forward/backward and side movement
	var forward_backward_magnitude = abs(normalized_input.y)
	var side_magnitude = abs(normalized_input.x)

	# Lerp between side_value and forward_value/backward_value based on vertical magnitude
	var y_blended_value: float
	if normalized_input.y > 0:
		# Interpolate between side_value and forward_value (1.0 to 1.7)
		y_blended_value = lerp(side_value, forward_value, forward_backward_magnitude)
	else:
		# Interpolate between side_value and backward_value (1.0 to 1.36)
		y_blended_value = lerp(side_value, backward_value, forward_backward_magnitude)

	# Interpolate between the y_blended_value and side_value based on horizontal magnitude
	# This ensures that when moving perfectly sideways, the value is exactly side_value (1.0)
	return lerp(side_value, y_blended_value, forward_backward_magnitude)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	animation_tree.set("parameters/blend_position", input_dir)
	animation_tree.advance(delta * get_blended_float(input_dir))
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
