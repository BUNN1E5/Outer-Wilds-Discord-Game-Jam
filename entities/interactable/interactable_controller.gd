extends Node

#Based on code from here:
#https://github.com/CrookedSmileStudios/ultimate_immersive_fps_horror
class_name InteractionController

@export var raycast : RayCast3D
@export var hand : Marker3D
@export var player_camera : Camera3D

var current_object : Interactable
var last_potential_objet : Object
var interaction_component : Node

func get_interactable() -> Interactable:
	if(raycast.is_colliding()):
		var obj = raycast.get_collider() as Node
		var interactable = obj.get_node_or_null("InteractableComponent") as Interactable
		if interactable and interactable.can_interact:
			interactable.highlight()
			return interactable
	return null
	
func _process(delta: float) -> void:
	#We do this so it highlights
	var potential_object = get_interactable()

#Interactions have to be held
func interact():
	if current_object: 
		current_object.interact()
	var interactable = get_interactable()
	if interactable:
		current_object = interactable
		interactable.pre_interact(self.hand)
	pass

func throw():
	if(!current_object): return false
	current_object.throw()
	current_object = null
	return true

#Holdeable items are toggle
func drop() -> bool:
	if(!current_object): return false
	current_object.post_pickup()
	current_object = null
	return true

func pickup() -> bool:
	if(current_object): return false
	var obj = get_interactable()
	if(obj):
		current_object = obj
		current_object.pre_pickup(hand)
		return true
	return false
