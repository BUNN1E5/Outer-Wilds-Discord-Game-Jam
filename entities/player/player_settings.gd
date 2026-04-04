extends Resource
class_name PlayerSettings

@export_range(0.01, 0.1, .01) var mouse_sensitivity : float = .01

static var instance : PlayerSettings:
	get:
		if(instance == null):
			instance = load_settings()
		return instance


## Helper to save the resource to disk
func save_settings() -> void:
	ResourceSaver.save(self, "user://player_settings.tres")
	print_debug("Saving Player Settings")


## Helper to load the resource from disk
static func load_settings() -> PlayerSettings:
	print_debug("Loading Player Settings")
	if ResourceLoader.exists("user://player_settings.tres"):
		return ResourceLoader.load("user://player_settings.tres")
	return PlayerSettings.new()
