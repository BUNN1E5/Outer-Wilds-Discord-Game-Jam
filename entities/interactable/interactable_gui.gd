extends Control

class InteractableRender:
	var bounds : Rect2
	var flavor_text : String
	var color : Color
	static func Create(bounds, flavor_text, color) -> InteractableRender:
		var ir = InteractableRender.new()
		ir.bounds = bounds
		ir.flavor_text = flavor_text
		ir.color = color
		return ir

var camera : Camera3D : 
	get:
		if(camera == null):
			camera = get_viewport().get_camera_3d()
		return camera
var obj_buff : Dictionary[int, InteractableRender]
@export var length = 1.
@export var width = 1.
@export var color : Color = Color.GRAY

@export var font : Font
@export var font_size : int
@export var font_width : float
@export var font_color : Color

@export var padding : Vector2 = Vector2(10,10)
@export var shift : Vector2 = Vector2(-3,-25)

func _init() -> void:
	Signals.show_object_screen_bounds.connect(_show_object_screen_bounds)

func _draw() -> void:
	for obj : InteractableRender in obj_buff.values():
		_draw_corners(obj, length, width, color)
	is_called = false

func clear_buff():
	obj_buff.clear()

func _process(delta: float) -> void:
	queue_redraw()
	call_deferred("clear_buff")

func _draw_corners(ir: InteractableRender, length: float, width: float, color: Color):
	var center = ir.bounds.get_center() # Top Left	
	for i in range(-1, 2, 2):
		for j in range(-1, 2, 2):
			var points = PackedVector2Array();
			var p = center + ir.bounds.size/2 * Vector2(i, j)
			points.append(p + Vector2(length * -i, 0))
			points.append(p)
			points.append(p + Vector2(0, length * -j))
			draw_polyline(points, ir.color, width)
	var string_bounds = font.get_string_size(ir.flavor_text, 0, font_width, font_size)
	var rect : Rect2 = Rect2(ir.bounds.position + shift - padding/2, string_bounds + padding)
	var text_pos = ir.bounds.position + shift + Vector2(0, font.get_ascent(font_size))
	draw_rect(rect, ir.color, true)
	draw_string_outline(font, text_pos, ir.flavor_text, 0, font_width, font_size, 4, font_color.inverted())
	draw_string(font, text_pos, ir.flavor_text, 0, font_width, font_size, font_color)
	
	
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
	var ir = InteractableRender.Create(Rect2(min_pos, max_pos - min_pos), interactable.flavor_text, interactable.color)
	obj_buff[interactable.get_instance_id()] = ir
