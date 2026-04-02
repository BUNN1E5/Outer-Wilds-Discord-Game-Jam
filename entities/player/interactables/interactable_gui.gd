extends Control

var camera : Camera3D : 
	get:
		if(camera == null):
			camera = get_viewport().get_camera_3d()
		return camera
var obj_buff : Dictionary[int, Rect2]
@export var length = 1.
@export var width = 1.
@export var color : Color = Color.GRAY

func _init() -> void:
	Signals.show_object_screen_bounds.connect(_show_object_screen_bounds)

func _draw() -> void:
	for obj in obj_buff.values():
		_draw_corners(obj, length, width, color)
	obj_buff.clear()
	is_called = false

func _process(delta: float) -> void:
	call_deferred("queue_redraw")

func _draw_corners(rect: Rect2, length: float, width: float, color: Color):
	var p1 = rect.position # Top Left
	var p2 = rect.end      # Bottom Right

	draw_line(p1, p1 + Vector2(length, 0), color, width)
	draw_line(p1, p1 + Vector2(0, length), color, width)

	var tr = Vector2(p2.x, p1.y)
	draw_line(tr, tr + Vector2(-length, 0), color, width)
	draw_line(tr, tr + Vector2(0, length), color, width)

	var bl = Vector2(p1.x, p2.y)
	draw_line(bl, bl + Vector2(length, 0), color, width)
	draw_line(bl, bl + Vector2(0, -length), color, width)

	draw_line(p2, p2 + Vector2(-length, 0), color, width)
	draw_line(p2, p2 + Vector2(0, -length), color, width)

var is_called : bool = false
func _show_object_screen_bounds(interactable : Interactable):
	var aabb = interactable.mesh.get_aabb()
	var transform = interactable.mesh.global_transform

	var corners = []
	for i in range(8):
		corners.append(transform * aabb.get_endpoint(i))
		
	var min_pos = Vector2(INF, INF)
	var max_pos = Vector2(-INF, -INF)

	for corner in corners:
		if not camera.is_position_behind(corner):
			var screen_pos = camera.unproject_position(corner)
			min_pos.x = min(min_pos.x, screen_pos.x)
			min_pos.y = min(min_pos.y, screen_pos.y)
			max_pos.x = max(max_pos.x, screen_pos.x)
			max_pos.y = max(max_pos.y, screen_pos.y)
	obj_buff[interactable.get_instance_id()] = Rect2(min_pos, max_pos - min_pos)
