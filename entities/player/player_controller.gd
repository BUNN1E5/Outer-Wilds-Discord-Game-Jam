extends CharacterBody3D

@export_category("Movement And Camera")
@export_range(0.01, 0.1, .01) var mouse_sensitivity : float = .01
@export var max_speed : float = 5.0
@export var run_accel : float = 40.0
@export var friction : float = 25.0
@export var jump_velocity : float = 4.5
@export var run_mult : float = 0.5
var is_running : bool = false
var camera_rotation_x : float = 0.0
var mouse_lock : bool = true
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")

@export_category("Survival")
@export var sleep : float = 1.
@export var hunger : float = 1.
@export var sleep_rate : float = .1
@export var hunger_rate : float = .1

@export_category("Misc")
@export var raycast : RayCast3D
@export var cam : Camera3D
@export var left_hand : Node3D
@export var right_hand : Node3D
@export var held_interactable : Interactable

func get_interactable() -> Interactable:
	if(raycast.is_colliding()):
		var obj = raycast.get_collider()
		if(obj is Interactable):
			obj.highlight()
			return obj
	return null

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mouse_lock = true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		mouse_lock = !mouse_lock
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if mouse_lock else Input.MOUSE_MODE_VISIBLE
		Signals.toggle_pause_state.emit()
	
	if event.is_action("pickup"):
		var obj = get_interactable()
		if(obj != null):
			obj.pickup()
	
	if event.is_action_pressed("interact"):
		var obj = get_interactable()
		if(obj != null):
			obj.interact()
			
	is_running = Input.is_action_pressed("sprint")
	
	if event is InputEventMouseMotion and mouse_lock:
		var x_delta = -event.relative.y * mouse_sensitivity
		camera_rotation_x = clamp(camera_rotation_x + x_delta, -deg_to_rad(85), deg_to_rad(85))
		cam.rotation.x = camera_rotation_x
		rotate_y(-event.relative.x * mouse_sensitivity)

func _physics_process(delta: float) -> void:
	get_interactable()
	
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var speed = max_speed * (1.0 + float(is_running) * run_mult)
	
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * speed, run_accel * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, run_accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)

	move_and_slide()
