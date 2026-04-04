@tool
extends Node3D
class_name OrbitManager

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
const day = 60 * 24 * 2#minutes in day (*2 cause for some reason that is half time otherwise)
@export var game_minutes_to_days : float:
	set(minutes):
		game_minutes_to_days = minutes
		day_ratio = day / game_minutes_to_days
@export var day_ratio : float
@export var time_dialation_mult : float = 1.#For extra control

@export_range(1, 100, .25) var sim_speed_inv : float =1
@export var sim_speed : float:
	get: return sim_speed_mul * 1/sim_speed_inv
@export var AU_SCALE : float = 1;
@export var object_scale : float = 1;
@export var star_scale_mult : float = 1.
@export var bh_scale_mult : float = 1.
@export var sky_material : ShaderMaterial

@export var star_node : Node3D
@export var bh_node : Node3D
@export var ship_node : Node3D


const SOLAR_RADIUS : float = 0.00465047;#AU
const AUS_TO_LIGHT : float = 499.005 #AU/S
const LIGHT_IN_AUS : float = 0.00200399
const LIGHT_IN_AUD : float = 173.145
const SOLAR_MASS : float = 1.
const UNIT_TO_AU : float = 6.68459e-12
const KG_TO_SM : float = 5.02785e-31

#Blackhole stuff
@export var bh : CelestialBody
@onready var bh_radius_world = 0;

#Star Stuff
@export var star : CelestialBody
@export var star_radius_world = 0

@export_range(0, .01, .000001) var ship_drag : float :
	set(v):
		ship_drag = v
		ship.drag = ship_drag
		
@export var ship_distance_to_bh : float
@export_range(0, 1, 0.001) var ship_orbit_eliptical : float:
	set(value):
		bh_size_from_ship = bh_size_from_ship
		ship_orbit_eliptical=value
		pass

@export var ship : CelestialBody

@export_range(0.0001, 0.001, .000001) var bh_size_from_ship : float:
	set(value):
		bh_size_from_ship = value
		var dist = 2.6/(tan(deg_to_rad(value)/2))
		var r = bh.radius * dist
		ship.position = bh.position + Vector3(0,0, r)
		
		#Visa Vis Equation
		#stable orbit is v = sqrt(GM(2/r-1/a)
		#var ship_vel_mag = sqrt(G * bh_mass * ((schwarzschild_radius * dist)))
		var a = r / (1.0 - ship_orbit_eliptical)
		var ship_vmag = sqrt(CelestialBody.G * bh.mass * (2/(r) - 1/(a)))
		ship.velocity = bh.velocity + Vector3(ship_vmag,0,0)
		

#Ship Stuff
@export var ship_time : Date = Date.Create(2524608000)
@export var earth_time : Date = Date.Create(2524608000)

func simulate_orbits(delta):
	if !simulate:
		return
	var sim_delta = delta * sim_speed
	#Gravity Equation
	# F = ma = G * (m1 * m2) / r^2
	# v += ma * dt ==> v += G * m2 / r^2
	bh.integrate_adaptive(sim_delta, star)
	star.integrate_adaptive(sim_delta, bh)
	#var ship_accel = dist.normalized() * (G * bh.mass / (r ** 2.0 * (1.0- (bh.radius/r))));
	ship.integrate_adaptive(sim_delta, bh)
	
	#calculate time dialation
	#delta is in sec ship_vel and LIGHT_IN_AUD are in AU/day
	#AU/day ends up getting cancelled out so it dont matter
	#edt = dt / sqrt(1 - v^2/c^2)
	ship_distance_to_bh = (bh.position - ship.position).length()
	var r = ship_distance_to_bh
	ship.drag = ship_drag * (1-ship_distance_to_bh)
	
	var grav_dilation = sqrt(1.0 - (bh.radius / r))
	var vc =  (ship.velocity.length_squared()) / (LIGHT_IN_AUD**2);
	var lorentz = 1 / sqrt(1 - vc)
	#We are NOT multiplying by sim speed to Gameplay reasons
	earth_time.seconds += delta * (lorentz/grav_dilation) * bh_scale_mult * day_ratio * time_dialation_mult
	ship_time.seconds += delta * day_ratio

func _init() -> void:
	pass

func _ready() -> void:
	star.position = Vector3(0.72232, 0, 0)
	star.velocity = Vector3(0, 0, 0.06703)
	bh.position = Vector3(-0.07246, 0, 0)
	bh.velocity = Vector3(0, 0, -0.00672)
	bh.radius = (2 * CelestialBody.G * bh.mass) / (CelestialBody.c**2)
	bh_size_from_ship = bh_size_from_ship
	ship.drag = 0.
	ship.circular_correction_mult = 1.
	ship_time.seconds = 2524608000;
	earth_time.seconds = ship_time.seconds;



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
			reference_pos = star.position
		StellarObject.BlackHole:
			reference_pos = bh.position
		StellarObject.Ship:
			reference_pos = ship.position
			
	var bh_world_pos = (bh.position - reference_pos * float(stationary_reference)) * AU_SCALE
	var star_world_pos = (star.position - reference_pos * float(stationary_reference)) * AU_SCALE
	
	var ship_world_pos = (ship.position - reference_pos * float(stationary_reference)) * AU_SCALE
	
	_prev_basis = _basis
	_basis = Basis.IDENTITY
	if(reference_object == StellarObject.Ship):
		_basis = Basis.looking_at(ship_world_pos - bh_world_pos)
	
	sky_material.set_shader_parameter("rotation_offset_matrix", _basis)
	sky_material.set_shader_parameter("sim_speed", sim_speed)
	sky_material.set_shader_parameter("black_hole_center", bh_world_pos)
	sky_material.set_shader_parameter("star_center", star_world_pos)
	
	
	sky_material.set_shader_parameter("ship_angular_vel", 	(_basis * _prev_basis.inverse()).get_euler() / delta)

	star_world_pos = star_world_pos * _basis
	if(star_node != null):
		star_node.position = star_world_pos
	
	bh_world_pos = bh_world_pos * _basis
	if(bh_node != null):
		bh_node.position = bh_world_pos

	star_radius_world = star_scale_mult * object_scale * star.radius * AU_SCALE
	
	var theta = 2 * atan(bh.radius / (ship_distance_to_bh/UNIT_TO_AU))
	
	bh_radius_world = bh_scale_mult * object_scale * bh.radius * AU_SCALE

	if(ship_node != null):
		ship_node.position = ship_world_pos
		ship_node.look_at(-bh_world_pos)
		
	sky_material.set_shader_parameter("star_radius", star_radius_world)
	sky_material.set_shader_parameter("Schwarzschild_radius", bh_radius_world)
	
	sky_material.set_shader_parameter("cam_vel_dir", ship.velocity.normalized())
	sky_material.set_shader_parameter("cam_frac_of_lightspeed", (ship.velocity.length()**2) / (LIGHT_IN_AUD**2))
