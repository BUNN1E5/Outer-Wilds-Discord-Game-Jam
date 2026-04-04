extends Interactable
class_name MonitorInteractable

@export var camera_position : Node3D
@export var slide_time : float = 1.
var cam_orig_transform = Transform3D.IDENTITY

#LMAO I'll need to refactor ths
func pre_pickup(hand : Marker3D):
	#super(hand) #We do not wanna try and pick it up lol
	#Bad way of doing this, but whatever
	player_hand = hand
	var pc = player_hand.get_parent() as PlayerController
	if not pc:
		return
	pc.lock_player_pos = true;
	cam_orig_transform = pc.cam.global_transform
	var tween = get_tree().create_tween()
	tween.tween_property(pc.cam, "global_transform", camera_position.global_transform, slide_time)
	tween.tween_callback(func(): Input.mouse_mode = Input.MOUSE_MODE_CONFINED)
	
func post_pickup():
	#super() #Same
	var pc = player_hand.get_parent() as PlayerController
	if not pc:
		return
	
	var tween = get_tree().create_tween()
	tween.tween_property(pc.cam, "global_transform", cam_orig_transform, slide_time)
	tween.tween_callback(func(): Input.mouse_mode = Input.MOUSE_MODE_CAPTURED)
	tween.tween_callback(func(): pc.lock_player_pos = false)
	# TODO :: FIX PROBLEM WHERE YOU CAN DESYNC CAMERA
	tween.tween_callback(func(): pc.cam.global_transform = cam_orig_transform)

func interact():
	super()
