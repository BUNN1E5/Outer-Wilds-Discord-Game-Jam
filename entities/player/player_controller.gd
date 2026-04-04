extends CharacterBody3D
class_name PlayerController

@export_category("Movement And Camera")
@export var max_speed : float = 5.0
@export var run_accel : float = 40.0
@export var friction : float = 25.0
@export var jump_velocity : float = 4.5
@export var run_mult : float = 0.5
var lock_player_pos = false

var is_running : bool = false
var camera_rotation_x : float = 0.0
var mouse_lock : bool :
	get:
		return Input.mouse_mode == Input.MouseMode.MOUSE_MODE_CAPTURED
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")

@export_category("Survival")
@export var player_survival_data : PlayerSurvivalData

@export_category("Misc")
@export var interaction_controller : InteractionController
@export var cam : Camera3D
@export var left_hand : Node3D
@export var right_hand : Node3D


func _process(delta: float) -> void:
	if Input.is_action_pressed("interact"):
		interaction_controller.interact()

func _input(event: InputEvent) -> void:
	#Drop before we pickup cause we dont wanna actually drop it if same 
	var drop_state = false
	if event.is_action_pressed("drop"):
		drop_state = interaction_controller.drop()
	if not drop_state and event.is_action_pressed("pickup"):
		interaction_controller.pickup()
	
	if event.is_action_pressed("throw"):
		interaction_controller.throw()
	
	if lock_player_pos:
		return
	if event is InputEventMouseMotion and mouse_lock:
		var player_settings = PlayerSettings.instance
		var x_delta = -event.relative.y * PlayerSettings.instance.mouse_sensitivity
		camera_rotation_x = clamp(camera_rotation_x + x_delta, -deg_to_rad(85), deg_to_rad(85))
		cam.rotation.x = camera_rotation_x
		rotate_y(-event.relative.x * PlayerSettings.instance.mouse_sensitivity)

func _physics_process(delta: float) -> void:
	if(lock_player_pos):
		return
	
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	is_running = Input.is_action_pressed("sprint")

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
