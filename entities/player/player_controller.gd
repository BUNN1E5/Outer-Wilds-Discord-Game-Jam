extends CharacterBody3D

@export var mouse_sensitivity : float = 1
@export var speed : float = 1.

var camera_rotation_x : float = 0.0
var mouse_lock : bool = true
@export var cameras : Array[Camera3D]


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mouse_lock = true
	cameras.append($CanvasLayer/PlayerScreen/PixelatedViewport/SubViewport/PixelatedCamera)
	cameras.append($CanvasLayer/PlayerScreen/NonPixelatedViewport/SubViewport/NonPixelatedCamera)
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		mouse_lock = !mouse_lock
		Input.mouse_mode = int(mouse_lock) * 2
	if event is InputEventMouseMotion:
		if(!mouse_lock): return
		var x_delta = -event.relative.y * mouse_sensitivity
		camera_rotation_x = clamp(camera_rotation_x + x_delta, -deg_to_rad(85), deg_to_rad(85))
		for cam in cameras:
			cam.rotation.y -= event.relative.x * mouse_sensitivity
			cam.rotation.x = camera_rotation_x
	

func _physics_process(delta: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (cameras[0].basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	velocity.x = direction.x * speed;
	velocity.z = direction.z * speed;
	
	print(velocity)
	#if(!is_on_floor()):
	#	velocity.y += -9.8;
	
	move_and_slide()


func _process(delta: float) -> void:
	for cam in cameras:
			cam.position = position
	pass
