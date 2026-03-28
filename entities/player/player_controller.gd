extends CharacterBody3D

@export var mouse_sensitivity : float = 1
@export var speed : float = 1.

var camera_rotation_x : float = 0.0
var mouse_lock : bool = true
@export var cam : Camera3D


func _ready() -> void:
	mouse_lock = false
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		mouse_lock = !mouse_lock
		Input.mouse_mode = int(mouse_lock) * 2
	if event is InputEventMouseMotion:
		if(!mouse_lock): return
		var x_delta = -event.relative.y * mouse_sensitivity
		camera_rotation_x = clamp(camera_rotation_x + x_delta, -deg_to_rad(85), deg_to_rad(85))
		cam.rotation.y -= event.relative.x * mouse_sensitivity
		cam.rotation.x = camera_rotation_x
	

func _physics_process(delta: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (cam.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	velocity.x = direction.x * speed;
	velocity.z = direction.z * speed;
	
	move_and_slide()


func _process(delta: float) -> void:
	cam.position = position
	pass
