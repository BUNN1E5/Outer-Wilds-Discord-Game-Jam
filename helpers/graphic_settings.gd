extends Resource
class_name GraphicSettings

@export_group("Upscaling")
@export var upscaler_mode: int = 0: # 0: Bilinear, 1: FSR, 2: FSR2, 3: DLSS
	set(value):
		upscaler_mode = value
		emit_changed()

@export var resolution_scale: float = 1.0:
	set(value):
		resolution_scale = clamp(value, 0.5, 2.0)
		emit_changed()

@export var fsr_sharpness: float = 0.2:
	set(value):
		fsr_sharpness = clamp(value, 0.0, 2.0)
		emit_changed()

@export_group("NVIDIA Specific")
@export var dlss_frame_generation: bool = false:
	set(value):
		dlss_frame_generation = value
		emit_changed()

@export_group("Display")
@export var window_mode: int = 0: # 0: Windowed, 1: Fullscreen, 2: Exclusive
	set(value):
		window_mode = value
		emit_changed()

@export var vsync_mode: int = 1: # 0: Disabled, 1: Enabled, 2: Adaptive
	set(value):
		vsync_mode = value
		emit_changed()

@export var fps_limit: int = 0:
	set(value):
		fps_limit = value
		emit_changed()

@export_group("Post Processing")
@export var anti_aliasing_index: int = 0:
	set(value):
		anti_aliasing_index = value
		emit_changed()

@export var brightness: float = 1.0
@export var contrast: float = 1.0
@export var saturation: float = 1.0

static var instance : GraphicSettings:
	get:
		if(instance == null):
			instance = load_settings()
		return instance

## Helper to save the resource to disk
func save_settings() -> void:
	ResourceSaver.save(self, "user://graphic_settings.tres")
	print_debug("Saving Graphic Settings")

## Helper to load the resource from disk
static func load_settings() -> GraphicSettings:
	print_debug("Loading Graphic Settings")
	if ResourceLoader.exists("user://graphic_settings.tres"):
		return ResourceLoader.load("user://graphic_settings.tres")
	return GraphicSettings.new()
