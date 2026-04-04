extends Object
class_name SaveManager

#reference for this:
#https://forum.godotengine.org/t/how-to-save-a-scene-at-run-time/33234/4
#tbh there is a good chance this will not work

static var save_id : int
const save_path = "user://save_%d.tscn"

static func save_game(scene : Node):
	var packed_scene = PackedScene.new()
	packed_scene.pack(scene)
	ResourceSaver.save(packed_scene, save_path % save_id)
	pass

static func load_game(id : int) -> PackedScene:
	return ResourceLoader.load(save_path % id)
