@tool
extends Node3D

@export_category("Reset")
@export var reset : bool:
	set(value):
		_ready()
@export var simulate : bool = true
enum StellarObject { Star, BlackHole, Ship }

@export var stationary_reference = false;
@export var reference_object : StellarObject = StellarObject.BlackHole

#These are our scaler variables
#They are our only proper way to modify it
@export var sim_speed_mul : float =1
@export var sim_speed_inv : float = .1
@export var sim_speed : float:
	get: return sim_speed_mul * 1/sim_speed_inv
@export var AU_SCALE : float = .1;
@export var object_scale : float = .1;
@export var star_scale_mult : float = 1.
@export var bh_scale_mult : float = 1.
@export var sky_material : ShaderMaterial

@export var star : Node3D
@export var bh : Node3D
@export var ship : Node3D


const SOLAR_RADIUS : float = 0.00465047;#AU
const c : float = 173.145 #speed of light per day
const AUS_TO_LIGHT : float = 499.005
const SOLAR_MASS : float = 1.
const UNIT_TO_AU : float = 6.68459e-12
const KG_TO_SM : float = 5.02785e-31


#Physical Constant used in Gravity Equation
# G = 4* PI^2 * AU^3 / (SOLAR_MASS * 
# G = (4 * PI^2) / (SOLAR_MASS * DAYS_IN_YEAR^2)
const G = 4 * PI ** 2 / (SOLAR_MASS * 365.256 ** 2)

#Blackhole stuff
const bh_mass : float = 9.27 * SOLAR_MASS
@export var bh_pos : Vector3 = Vector3(-0.07246, 0, 0) # AU
@export var bh_vel : Vector3 = Vector3(0, 0, -0.00672) # AU/day
#r = 2 * G * M / c^2
const schwarzschild_radius : float = 2 * G * bh_mass / c**2
@export var bh_radius = object_scale * schwarzschild_radius * AU_SCALE;

#Star Stuff
const star_mass : float = .93 * SOLAR_MASS
@export var star_pos : Vector3 = Vector3(0.72232, 0, 0) # AU
@export var star_vel : Vector3 = Vector3(0, 0, 0.06703) # AU/day
var star_radius : float = 1. * SOLAR_RADIUS#AU
@export var star_radius_a = object_scale * star_radius * AU_SCALE


#Ship Stuff
@export var ship_distance_to_bh : float
@export_range(0, 1, 0.001) var ship_orbit_eliptical : float:
	set(value):
		bh_size_from_ship = bh_size_from_ship
		ship_orbit_eliptical=value
		pass
@export var bh_size_from_ship : float:
	set(value):
		var dist = 2.6/(tan(deg_to_rad(1/value)/2))
		ship_pos = bh_pos + Vector3(0,0, schwarzschild_radius * dist)
		print(dist)
		#stable orbit is v = sqrt(GM(2/r-1/a)
		#var ship_vel_mag = sqrt(G * bh_mass * ((schwarzschild_radius * dist)))
		var dist_to_bh = schwarzschild_radius * dist;
		var a = dist_to_bh / (1.0 - ship_orbit_eliptical)
		var ship_vel_mag = sqrt(G * bh_mass * (2/(dist_to_bh) - 1/(a)))
		ship_vel = bh_vel + Vector3(ship_vel_mag,0,0)
		bh_size_from_ship = value
@export var ship_pos : Vector3 = (bh_pos + Vector3(0,0,schwarzschild_radius * 3))
@export var ship_vel : Vector3 = Vector3(0,0,0)

func simulate_orbits(delta):
	#Gravity Equation
	# F = ma = G * (m1 * m2) / r^2
	# v += ma * dt ==> v += G * m2 / r^2
	var dist = star_pos - bh_pos
	bh_vel += dist.normalized() * (G * star_mass / (dist.length() ** 2)) * delta * sim_speed
	star_vel += -dist.normalized() * (G * bh_mass / (dist.length() ** 2)) * delta * sim_speed
	
	dist = bh_pos - ship_pos;
	ship_vel += dist.normalized() * (G * bh_mass / (dist.length() ** 2)) * delta * sim_speed
	
	bh_pos += bh_vel * delta * sim_speed
	star_pos += star_vel * delta * sim_speed
	ship_pos += ship_vel * delta * sim_speed
	pass

func _init() -> void:
	pass

func _ready() -> void:
	star_pos = Vector3(0.72232, 0, 0)
	star_vel = Vector3(0, 0, 0.06703)
	bh_pos = Vector3(-0.07246, 0, 0)
	bh_vel = Vector3(0, 0, -0.00672)
	# 2.6 / sin(theta/2)
	bh_size_from_ship = bh_size_from_ship
func _physics_process(delta: float) -> void:
	simulate_orbits(delta)

	pass
var _basis = Basis.IDENTITY
var _prev_basis = Basis.IDENTITY
func _process(delta: float) -> void:
	if(Engine.is_editor_hint()):
		if(!simulate):
			return
		simulate_orbits(delta)
	
	var reference_pos;
	match(reference_object):
		StellarObject.Star:
			reference_pos = star_pos
		StellarObject.BlackHole:
			reference_pos = bh_pos
		StellarObject.Ship:
			reference_pos = ship_pos
			
	var bh_world_pos = (bh_pos - reference_pos * float(stationary_reference)) * AU_SCALE
	var star_world_pos = (star_pos - reference_pos * float(stationary_reference)) * AU_SCALE
	var ship_world_pos = (ship_pos - reference_pos * float(stationary_reference)) * AU_SCALE
	
	_prev_basis = _basis
	_basis = Basis.IDENTITY
	if(reference_object == StellarObject.Ship):
		_basis = Basis.looking_at(bh_world_pos - ship_world_pos)
	
	sky_material.set_shader_parameter("rotation_offset_matrix", _basis)
	sky_material.set_shader_parameter("sim_speed", sim_speed)
	
	
	
	sky_material.set_shader_parameter("ship_angular_vel", 	(_basis * _prev_basis.inverse()).get_rotation_quaternion() / delta)

	star_world_pos = -star_world_pos * _basis
	if(star != null):
		star.position = star_world_pos
	
	bh_world_pos = -bh_world_pos * _basis 
	if(bh != null):
		bh.position = bh_world_pos

	if(ship != null):
		ship.position = ship_world_pos
		ship.look_at(bh_world_pos)
	
	ship_distance_to_bh = (ship_pos - bh_pos).length()

	
	sky_material.set_shader_parameter("star_radius", star_scale_mult * object_scale * star_radius * AU_SCALE)
	sky_material.set_shader_parameter("Schwarzschild_radius", bh_scale_mult * object_scale * schwarzschild_radius * AU_SCALE)
	star_radius_a = object_scale * star_radius * AU_SCALE
	bh_radius = object_scale * schwarzschild_radius * AU_SCALE
	
	sky_material.set_shader_parameter("black_hole_center", (bh_pos - reference_pos * float(stationary_reference)) * AU_SCALE)
	sky_material.set_shader_parameter("star_center", (star_pos - reference_pos * float(stationary_reference)) * AU_SCALE)
	
	sky_material.set_shader_parameter("cam_vel_dir", ship_vel.normalized())
	sky_material.set_shader_parameter("cam_frac_of_lightspeed", ship_vel.length() * AUS_TO_LIGHT * delta)
#	sky_material.set_shader_parameter("cam_frac_of_lightspeed", 0.)
	
	pass
