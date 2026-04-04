@tool
extends Resource

class_name CelestialBody

#Physical Constant used in Gravity Equation
# G = 4* PI^2 * AU^3 / (SOLAR_MASS * 
# G = (4 * PI^2) / (SOLAR_MASS * DAYS_IN_YEAR^2)
static var G = 4 * PI ** 2 / (1. * 365.256 ** 2)
const c : float = 173.145

@export var position : Vector3
@export var last_position : Vector3
@export var radius : float
@export var mass : float
@export var drag : float = 0
@export var circular_correction_mult : float = 0.
@export var velocity : Vector3
@export var velocity_mag : float : 
	get: return velocity.length()

static func Create(mass, position, velocity, radius, drag) -> CelestialBody:
	var new_body : CelestialBody = CelestialBody.new()
	new_body.position = position
	new_body.last_position = new_body.position - velocity * new_body.last_delta
	new_body.radius = radius
	new_body.mass = mass
	new_body.drag = drag
	return new_body
	
static func Create_BH(mass, position, velocity) -> CelestialBody:
	var new_body : CelestialBody = CelestialBody.new()
	new_body.position = position
	new_body.last_position = new_body.position - velocity * new_body.last_delta
	new_body.radius = 2 * G * mass / c**2
	new_body.mass = mass
	return new_body

@export var circle_str = 0.
func accleration(_position, _velocity, _other_position, _other_mass, _other_radius):
	var dist = _other_position - _position
	var r = dist.length()
	if(r < _other_radius):
		return Vector3.ZERO
	var mag = min((G * _other_mass / (dist.length_squared() * (1.0 - (_other_radius/r)))), Limits.MAX_ACCEL)
	var accel : Vector3 = dist.normalized() * mag
	
	var start_radius = _other_radius * 10000000.0
	var t = pow(clamp(1 - r / start_radius, 0, 1), 5)
	circle_str = t * circular_correction_mult
	var vel_err = _calculate_circular_correction(dist, _velocity, _other_mass)
	accel = accel.lerp(accel + vel_err, circle_str)
	
	accel -= _velocity * drag
	return accel 

func predict(_position, _velocity, step_size, _other_position, other : CelestialBody) -> Array[Vector3]:
	return 	_get_next_rk4_state(_position, _velocity, _other_position, other, step_size)

@export var sub_steps : int
func integrate_adaptive(delta: float, other : CelestialBody):
	var step_sensitivity = .25
	var r = (position - other.position).length_squared();
	if(r < other.radius / 2.):
		#we are inside something else
		velocity = Vector3.ZERO
		return
	sub_steps = clamp(1./r * step_sensitivity, 1, 400)
	var sub_delta = delta / sub_steps
	for i in range(sub_steps):
		_rk4_step(other, sub_delta)

func _rk4_step(other : CelestialBody, dt : float):
	var rk4_state = _get_next_rk4_state(position, velocity, other.position, other, dt)
	position = rk4_state[0]
	velocity = rk4_state[1]

func _get_next_rk4_state(pos : Vector3, vel : Vector3, _other_position : Vector3, other : CelestialBody, dt : float) -> Array[Vector3]:
	# k1
	var v1 = vel
	var a1 = accleration(pos, v1, _other_position, other.mass, other.radius)
	# k2
	var v2 = vel + a1 * (dt * 0.5)
	var a2 = accleration(pos + v1 * (dt * 0.5), v2, _other_position, other.mass, other.radius)
	# k3
	var v3 = vel + a2 * (dt * 0.5)
	var a3 = accleration(pos + v2 * (dt * 0.5), v3, _other_position, other.mass, other.radius)
	# k4
	var v4 = vel + a3 * dt
	var a4 = accleration(pos + v3 * dt, v4, _other_position, other.mass, other.radius)
	vel += (a1 + 2*a2 + 2*a3 + a4) / 6.0 * dt
	pos += (v1 + 2*v2 + 2*v3 + v4) / 6.0 * dt
	vel = vel.normalized() * min(vel.length(), Limits.MAX_VEL)
	return [pos, vel]
	
func _calculate_circular_correction(dist_vec: Vector3, _velocity, _other_mass) -> Vector3:
	#Vis-Visa equation to get our "perfect" orbit
	var r = dist_vec.length()
	var target_speed = sqrt(G * _other_mass / r)
	var radial_vel = _velocity.project(dist_vec.normalized())
	var tan = (_velocity - radial_vel).normalized()
	var target_velocity = tan * target_speed
	#We are gonna do a little cheat where we average the 2 velocities
	var vel_err = target_velocity - _velocity
	return vel_err
