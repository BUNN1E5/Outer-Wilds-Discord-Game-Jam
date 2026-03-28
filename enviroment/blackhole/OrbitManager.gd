@tool
extends Node3D

@export_category("Reset")
@export var reset : bool:
	set(value):
		_ready()
@export var simulate : bool = true
@export var stationary_blackhole = false;

#These are our scaler variables
#They are our only proper way to modify it
@export var sim_speed : float = 1. 
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
const SOLAR_MASS : float = 1.
const UNIT_TO_AU : float = 6.68459e-12
const KG_TO_SM : float = 5.02785e-31


#Physical Constant used in Gravity Equation
# G = 4* PI^2 * AU^3 / (SOLAR_MASS * 
# G = (4 * PI^2) / (SOLAR_MASS * DAYS_IN_YEAR^2)
const G = 4 * PI ** 2 / (SOLAR_MASS * 365.256 ** 2)


const blackhole_mass : float = 9.27 * SOLAR_MASS
@export var blackhole_pos : Vector3 = Vector3(-0.07246, 0, 0) # AU
@export var blackhole_vel : Vector3 = Vector3(0, 0, -0.00672) # AU/day

#r = 2 * G * M / c^2
const schwarzschild_radius : float = 2 * G * blackhole_mass / c**2

const star_mass : float = .93 * SOLAR_MASS
@export var star_pos : Vector3 = Vector3(0.72232, 0, 0) # AU
@export var star_vel : Vector3 = Vector3(0, 0, 0.06703) # AU/day
var star_radius : float = 1. * SOLAR_RADIUS#AU

var ship_mass : float = 2000000 * KG_TO_SM  
var ship_position : Vector3 = blackhole_pos - Vector3(0, 0, 20) * UNIT_TO_AU;
var ship_velocity : Vector3 = Vector3(0,0,0)

func _init() -> void:
	pass

func _ready() -> void:
	star_pos = Vector3(0.72232, 0, 0)
	star_vel = Vector3(0, 0, 0.06703)
	blackhole_pos = Vector3(-0.07246, 0, 0)
	blackhole_vel = Vector3(0, 0, -0.00672)

@export var blackhole_radius = object_scale * schwarzschild_radius * AU_SCALE;
@export var star_radius_a = object_scale * star_radius * AU_SCALE
func _process(delta: float) -> void:
	if(Engine.is_editor_hint()):
		if(!simulate):
			return
	#Gravity Equation
	# F = ma = G * (m1 * m2) / r^2
	# v += ma * dt ==> v += G * m2 / r^2
	var dist = star_pos - blackhole_pos
	blackhole_vel += dist.normalized() * (G * star_mass / (dist.length() ** 2)) * delta * sim_speed
	star_vel += -dist.normalized() * (G * blackhole_mass / (dist.length() ** 2)) * delta * sim_speed
	
	blackhole_pos += blackhole_vel * delta * sim_speed
	star_pos += star_vel * delta * sim_speed
	
	if(star != null):
		star.position = (star_pos - blackhole_pos * float(stationary_blackhole)) * AU_SCALE
	
	if(bh != null):
		bh.position = (blackhole_pos - blackhole_pos * float(stationary_blackhole)) * AU_SCALE
	
	sky_material.set_shader_parameter("star_radius", star_scale_mult * object_scale * star_radius * AU_SCALE)
	sky_material.set_shader_parameter("Schwarzschild_radius", bh_scale_mult * object_scale * schwarzschild_radius * AU_SCALE)
	star_radius_a = object_scale * star_radius * AU_SCALE
	blackhole_radius = object_scale * schwarzschild_radius * AU_SCALE
	
	sky_material.set_shader_parameter("black_hole_center", (blackhole_pos - blackhole_pos * float(stationary_blackhole)) * AU_SCALE)
	sky_material.set_shader_parameter("star_center", (star_pos - blackhole_pos * float(stationary_blackhole)) * AU_SCALE)
	
	pass
