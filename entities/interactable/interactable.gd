extends Node
class_name Interactable

@export var flavor_text : String
@onready var mesh : MeshInstance3D = find_children("*", "MeshInstance3D")[0]
@export var active : bool

#Runs every frame the player is looking at it
func highlight():
	Signals.emit_signal("show_object_screen_bounds", self)
	pass

func interact():
	print("We Interacted!")
	pass

func pickup():
	print("We Picked up!")
	pass
