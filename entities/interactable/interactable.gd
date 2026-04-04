extends Node
class_name Interactable

@export var nodes_to_affect: Array[Node]
@export var flavor_text : String
@export var color : Color = Color.DIM_GRAY

enum InteractionType{
	DEFAULT,
}

@export var object_ref : Node3D = self.get_parent()
@onready var mesh : MeshInstance3D = object_ref.find_children("*", "MeshInstance3D")[0]
@export var interaction_type : InteractionType = InteractionType.DEFAULT

@export var can_interact: bool = true
var is_interacting: bool = false

@export var can_pickup: bool = true
var is_picked_up : bool = false
var player_hand : Marker3D

func _ready() -> void:
	var rigidbody : RigidBody3D = object_ref as RigidBody3D
	if rigidbody:
		rigidbody.set_collision_layer_value(1, true)
		rigidbody.set_collision_layer_value(2, true)
	pass
	
func pre_interact(hand : Marker3D):
	player_hand = hand
	is_interacting = true
	return
	
func post_interact():
	is_interacting = false
	pass

func interact():
	if not can_interact:
		return
	print("Interacting")

#Runs every frame the player is looking at it
func highlight():
	Signals.emit_signal("show_object_screen_bounds", self)
	pass

func pre_pickup(hand : Marker3D):
	if !can_pickup:
		return
	player_hand = hand
	var rigidbody : RigidBody3D = object_ref as RigidBody3D
	if rigidbody:
		rigidbody.set_collision_layer_value(1, false)
		rigidbody.set_collision_layer_value(2, true)
		rigidbody.continuous_cd = true
		is_picked_up = true
	
func post_pickup():
	is_picked_up = false
	var rigidbody : RigidBody3D = object_ref as RigidBody3D
	if rigidbody:
		rigidbody.set_collision_layer_value(1, true)
		rigidbody.set_collision_layer_value(2, true)
		rigidbody.continuous_cd = false

func throw():
	post_pickup()
	var object_current_position : Vector3 = object_ref.global_position
	var player_hand_position : Vector3 = player_hand.global_position
	var object_distance: Vector3 = player_hand_position - object_current_position
	var rigidbody : RigidBody3D = object_ref as RigidBody3D
	if rigidbody:
		var throw_direction = -player_hand.global_transform.basis.z.normalized()
		var throw_strength: float = (10/rigidbody.mass)
		rigidbody.linear_velocity = throw_direction * throw_strength
	

func pickup():
	var object_current_position : Vector3 = object_ref.global_position
	var player_hand_position : Vector3 = player_hand.global_position
	var object_distance: Vector3 = player_hand_position - object_current_position
	var rigidbody : RigidBody3D = object_ref as RigidBody3D
	if rigidbody: 
		rigidbody.linear_velocity = (object_distance)*(10/rigidbody.mass)

func _process(delta: float) -> void:
	if !is_picked_up:
		return
	highlight()
	pass

func _physics_process(delta: float) -> void:
	if !is_picked_up:
		return
	pickup()
