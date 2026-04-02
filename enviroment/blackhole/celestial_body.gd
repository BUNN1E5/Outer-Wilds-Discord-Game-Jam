@tool
extends Resource

class_name CelestialBody

var last_delta : float = 1.0/60.0

@export var position : Vector3
@export var last_position : Vector3
@export var radius : float
@export var mass : float
@export var drag : float = 0
@export var velocity : Vector3 :
	get():
		return (position - last_position) / max(Limits.MIN_DEC_FLOAT, last_delta) 
	set(value):		
		var mag = clamp(value.length(), -Limits.MAX_FLOAT, Limits.MAX_FLOAT)
		value = value.normalized() * mag
		_velocity = value
		last_position = position - value * max(Limits.MIN_DEC_FLOAT, last_delta)
var _velocity : Vector3
		

static func Create(mass, position, velocity, radius, drag) -> CelestialBody:
	var new_body : CelestialBody = CelestialBody.new()
	new_body.position = position
	new_body.last_position = new_body.position - velocity * new_body.last_delta
	new_body.radius = radius
	new_body.mass = mass
	new_body.drag = drag
	return new_body
	
static func Create_BH(mass, position, velocity, G, c) -> CelestialBody:
	var new_body : CelestialBody = CelestialBody.new()
	new_body.position = position
	new_body.last_position = new_body.position - velocity * new_body.last_delta
	new_body.radius = 2 * G * mass / c**2
	new_body.mass = mass
	return new_body
	
func acceleration(_position, other : CelestialBody, G) -> Vector3:
	var dist = other.position - _position
	var r = dist.length()
	if(r < other.radius):
		return Vector3.ZERO
	var mag = min((G * other.mass / (dist.length_squared() * (1.0 - (other.radius/r)))), Limits.MAX_ACCEL)
	var accel = dist.normalized() * mag
	accel -= velocity * drag
	return accel 
	
func integrate(delta, other, G):
	var time_ratio = delta / last_delta
	var v = (position - last_position) * time_ratio
	var a = acceleration(position, other, G) * (delta**2)
	last_position = position
	#position += v * (1.0 - drag) + a
	position += v + a
	last_delta = delta

func predict(step_size, steps, other, G) -> Array[Vector3]:
	var positions : Array[Vector3]
	var temp_pos = position
	var temp_last = last_position
	var temp_last_delta = last_delta
	for i in range(steps):
		var v = (temp_pos - temp_last) * (1/temp_last_delta)
		var speed = v.length()
		if speed < Limits.MIN_DEC_FLOAT: 
			break
		var step_delta = step_size / speed
		v *= step_delta
		var a = acceleration(temp_pos, other, G) * (step_delta**2)
		temp_last = temp_pos
		temp_pos += v + a
		temp_last_delta = step_delta
		positions.push_back(temp_pos)
	return positions

@export var sub_steps : int
func integrate_adaptive(delta: float, other : CelestialBody, G):
	var step_sensitivity = .25
	var r = (position - other.position).length_squared();
	if(r < other.radius):
		#we are inside something else
		velocity = Vector3.ZERO
		return
	sub_steps = clamp(1./r * step_sensitivity, 1, 400)
	#sub_steps = clamp( int(pow(acceleration(position, other, G).length(), step_sensitivity)), 1, 500)
	var sub_delta = delta / sub_steps
	for i in range(sub_steps):
		_rk4_step(sub_delta, other, G)
	velocity = _velocity

func _rk4_step(dt: float, other, G):
	# k1
	var v1 = _velocity
	var a1 = acceleration(position, other, G)
	# k2
	var v2 = _velocity + a1 * (dt * 0.5)
	var a2 = acceleration(position + v1 * (dt * 0.5), other, G)
	# k3
	var v3 = _velocity + a2 * (dt * 0.5)
	var a3 = acceleration(position + v2 * (dt * 0.5), other, G)
	# k4
	var v4 = _velocity + a3 * dt
	var a4 = acceleration(position + v3 * dt, other, G)
	velocity = _velocity + (a1 + 2*a2 + 2*a3 + a4) / 6.0 * dt
	position += (v1 + 2*v2 + 2*v3 + v4) / 6.0 * dt
	
