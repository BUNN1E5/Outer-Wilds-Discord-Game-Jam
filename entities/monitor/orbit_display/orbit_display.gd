@tool
extends Node2D


@export var modifiers : Array[float]
@export var star_trail_count : int = 1
@export var star_trail_step_size = .1
@export var ship_trail_count : int = 1
@export_range(0.0001, .0025, .00001) var ship_trail_step_size = .1
@export var orbit_manager : OrbitManager
@export var bh_icon : Node2D
@export var star_icon : Node2D
@export var ship_icon : Node2D

@export var trails : Array[Line2D]
@export var size : Vector2

func _ready() -> void:
	size = get_window().size;

func _process(delta: float) -> void:
	if(orbit_manager == null):
		return
	var bh_pos = Vector2(orbit_manager.bh.position.x, orbit_manager.bh.position.z)
	bh_icon.position = (bh_pos-bh_pos) * size.y
	star_icon.position = (Vector2(orbit_manager.star.position.x, orbit_manager.star.position.z) - bh_pos) * size.y * modifiers[1]
	ship_icon.position = (Vector2(orbit_manager.ship.position.x, orbit_manager.ship.position.z) - bh_pos) * size.y * modifiers[2]
	
	for trail in trails:
		if(trail == null):
			continue
		trail.clear_points()
	
	var star_pred = orbit_manager.star.predict(star_trail_step_size, star_trail_count, orbit_manager.bh, orbit_manager.G)
	#star_pred.reverse()
	#star_pred.append_array(orbit_manager.star.predict(star_trail_step_size, star_trail_count, orbit_manager.bh, orbit_manager.G))	
	
	var ship_pred = orbit_manager.ship.predict(ship_trail_step_size, ship_trail_count, orbit_manager.bh, orbit_manager.G)
	#ship_pred.reverse()
	#ship_pred.append_array(orbit_manager.star.predict(ship_trail_step_size, ship_trail_count, orbit_manager.bh, orbit_manager.G))	
	
	var orbits_pred = [[], star_pred, ship_pred]
	trails[1].add_point(star_icon.position)
	trails[2].add_point(ship_icon.position)
	
	for i in range(1, 3):
		for orbit_pos in orbits_pred[i]:
			trails[i].add_point((Vector2(orbit_pos.x, orbit_pos.z) - bh_pos) * size.y * modifiers[i])
