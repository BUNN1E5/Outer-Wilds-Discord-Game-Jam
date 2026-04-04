@tool
extends Control


@export var modifiers : Array[float]
@export var star_trail := CircularBuffer.new(trail_size)
@export var ship_trail := CircularBuffer.new(trail_size)

@export var trail_size : int = 1:
	set(v):
		trail_size = v
		star_trail.change_size(v)
		ship_trail.change_size(v)
		
@export var predict : bool = false
@export var trail : bool = false

@export var pred_size : int = 1
@export var pred_step_size : float = .1

@export var bh : CelestialBody
@export var star : CelestialBody
@export var ship : CelestialBody
@export var bh_icon : Node2D
@export var star_icon : Node2D
@export var ship_icon : Node2D
@export var trails : Array[Line2D]

var center_reference_pos : Vector2:
	get:
		return size/2

func _ready() -> void:
	star_trail = CircularBuffer.new(trail_size)
	ship_trail = CircularBuffer.new(trail_size)
	for trail in trails:
		if(trail): trail.clear_points()
	size = get_window().size;

func _process(delta: float) -> void:
	var center = bh.position
	var bh_rel = bh.position - center
	var bh_pos = Vector2(bh_rel.x, bh_rel.z)
	bh_icon.position = bh_pos * size.y * modifiers[0] + center_reference_pos
	var star_rel = star.position - center
	var ship_rel = ship.position - center
	star_icon.position = (Vector2(star_rel.x, star_rel.z)) * size.y * modifiers[1]  + center_reference_pos
	ship_icon.position = (Vector2(ship_rel.x, ship_rel.z)) * size.y * modifiers[2] + center_reference_pos
	
	for trail in trails:
		if(trail): trail.clear_points()
	
	if trail:	
		ship_trail.append(ship.position - center)
		star_trail.append(star.position - center)
	
		var star_points = star_trail.get_all()
		var ship_points = ship_trail.get_all()
	
		for point in star_points:
			trails[1].add_point(Vector2(point.x, point.z) * size.y * modifiers[1] + center_reference_pos) 
	
		for point in ship_points:
			trails[2].add_point(Vector2(point.x, point.z) * size.y * modifiers[2] + center_reference_pos)
	
	if predict:
		var g_bh : Array[Vector3] = [bh.position, bh.velocity]
		var g_star : Array[Vector3] = [star.position, star.velocity]
		var g_ship : Array[Vector3] = [ship.position, ship.velocity]
		
		for i in range(pred_size):
			g_bh = bh.predict(g_bh[0], g_bh[1], pred_step_size, g_star[0], star)
			g_star = bh.predict(g_star[0], g_star[1], pred_step_size, g_bh[0], bh)
			g_ship = bh.predict(g_ship[0], g_ship[1], pred_step_size, g_bh[0], bh)
			
			var pred_star_rel = (g_star[0] - center)
			var pred_ship_rel = (g_ship[0] - center)
			
			trails[1].add_point(Vector2(pred_star_rel.x, pred_star_rel.z) * size.y * modifiers[1] + center_reference_pos)
			trails[2].add_point(Vector2(pred_ship_rel.x, pred_ship_rel.z) * size.y * modifiers[2] + center_reference_pos)
