extends Control
class_name SettingsMenu

# Core Nodes
@onready var tab_container: TabContainer = $VBoxContainer/TabContainer

# Tab Sections
@onready var back_button: Button = $VBoxContainer/TabContainer/Back
@onready var gameplay_tab: Control = $VBoxContainer/TabContainer/Gameplay
@onready var controls_tab: Control = $VBoxContainer/TabContainer/Controls
@onready var graphics_tab: PanelContainer = $VBoxContainer/TabContainer/Graphics

# Graphics -> Video Settings
@onready var resolution_label: Label = $VBoxContainer/TabContainer/Graphics/ScrollContainer/VBoxContainer/VideoSettings/Resolution/Option
@onready var upscaler_option: OptionButton = $"VBoxContainer/TabContainer/Graphics/ScrollContainer/VBoxContainer/VideoSettings/Display-Filter/OptionButton"
@onready var fsr_sharpness_label : Label = $"VBoxContainer/TabContainer/Graphics/ScrollContainer/VBoxContainer/VideoSettings/FSR-Sharpness/Control/Label2"
@onready var fsr_sharpness_slider : HSlider = $"VBoxContainer/TabContainer/Graphics/ScrollContainer/VBoxContainer/VideoSettings/FSR-Sharpness/Control/HSlider"
@onready var fsr_sharpness_group : Control = $"VBoxContainer/TabContainer/Graphics/ScrollContainer/VBoxContainer/VideoSettings/FSR-Sharpness"

@onready var dlss_scale_label : Label = $"VBoxContainer/TabContainer/Graphics/ScrollContainer/VBoxContainer/VideoSettings/FSR-Sharpness/Control/Label2"
@onready var dlss_scale_slider : HSlider = $"VBoxContainer/TabContainer/Graphics/ScrollContainer/VBoxContainer/VideoSettings/FSR-Sharpness/Control/HSlider"
@onready var dlss_scale_group : Control = $"VBoxContainer/TabContainer/Graphics/ScrollContainer/VBoxContainer/VideoSettings/FSR-Sharpness"

@onready var dlss_frame_gen_toggle : Button = $"VBoxContainer/TabContainer/Graphics/ScrollContainer/VBoxContainer/VideoSettings/DLSS-Frame-Generation/Button"
@onready var dlss_frame_gen_group : Control = $"VBoxContainer/TabContainer/Graphics/ScrollContainer/VBoxContainer/VideoSettings/DLSS-Frame-Generation"


@onready var res_scale_slider: HSlider = $"VBoxContainer/TabContainer/Graphics/ScrollContainer/VBoxContainer/VideoSettings/Resolution-Scale/Control/HSlider"
@onready var res_scale_label: Label = $"VBoxContainer/TabContainer/Graphics/ScrollContainer/VBoxContainer/VideoSettings/Resolution-Scale/Control/Label2"
@onready var fullscreen_option: OptionButton = $VBoxContainer/TabContainer/Graphics/ScrollContainer/VBoxContainer/VideoSettings/Fullscreen/OptionButton
@onready var vsync_option: OptionButton = $VBoxContainer/TabContainer/Graphics/ScrollContainer/VBoxContainer/VideoSettings/Vsync/OptionButton
@onready var fps_limit_slider: HSlider = $"VBoxContainer/TabContainer/Graphics/ScrollContainer/VBoxContainer/VideoSettings/FPS-Limit/Control/HSlider"
@onready var fps_limit_label: Label = $"VBoxContainer/TabContainer/Graphics/ScrollContainer/VBoxContainer/VideoSettings/FPS-Limit/Control/Label2"
@onready var aa_option: OptionButton = $"VBoxContainer/TabContainer/Graphics/ScrollContainer/VBoxContainer/VideoSettings/Anti-Aliasing/OptionButton"

# Graphics -> Adjustments
@onready var brightness_slider: HSlider = $VBoxContainer/TabContainer/Graphics/ScrollContainer/VBoxContainer/AdjustmentSettings2/Brightness/HSlider
@onready var contrast_slider: HSlider = $VBoxContainer/TabContainer/Graphics/ScrollContainer/VBoxContainer/AdjustmentSettings2/Contrast/HSlider
@onready var saturation_slider: HSlider = $VBoxContainer/TabContainer/Graphics/ScrollContainer/VBoxContainer/AdjustmentSettings2/Saturation/HSlider

var dlss_supported : bool:
	get:
		var gpu_name = RenderingServer.get_rendering_device().get_device_name()
		var is_rtx = "RTX" in gpu_name
		var is_new_enough = int(gpu_name) > 2000
		return is_rtx and is_new_enough

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	
	#We cannot change resolution lmao
	#resolution_option.item_selected.connect(_on_resolution_selected)
	
	upscaler_option.item_selected.connect(_on_upscaler_selected)
	dlss_frame_gen_toggle.toggled.connect(_on_enable_DLSS_frame_generation)
	if dlss_supported:
		upscaler_option.add_item("DLSS 3.5", 3)
		dlss_frame_gen_group.visible = dlss_supported
	
	fsr_sharpness_slider.value_changed.connect(_on_fsr_sharpness_changed)
	
	res_scale_slider.value_changed.connect(_on_res_scale_changed)
	
	fullscreen_option.item_selected.connect(_on_fullscreen_selected)
	vsync_option.item_selected.connect(_on_vsync_selected)
	
	fps_limit_slider.value_changed.connect(_on_fps_limit_changed)
	aa_option.item_selected.connect(_on_aa_selected)
	
	brightness_slider.value_changed.connect(_on_brightness_changed)
	contrast_slider.value_changed.connect(_on_contrast_changed)
	saturation_slider.value_changed.connect(_on_saturation_changed)
	
	apply_settings_to_ui()

var prev_menu : Control
func show_settings_menu(prev_menu : Control):
	self.prev_menu = prev_menu
	prev_menu.visible = false
	self.visible = true

func _on_back_pressed() -> void:
	self.visible = false
	self.prev_menu.visible = true
	update_settings_from_ui()
	pass

#func _on_resolution_changed() -> void:	

func _on_upscaler_selected(_index: int) -> void:
	#Make sure the fsr_sharpness_group is visible for fsr stuff
	fsr_sharpness_group.visible = false
	if _index == 1 or _index == 2:
		fsr_sharpness_group.visible = true

	if _index == 0:
		get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	elif _index == 1:
		get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
	elif _index == 2:
		get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2
	elif _index == 3:
		get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_DLSS
	pass
#
func _on_enable_DLSS_frame_generation(_value : bool) -> void:
	dlss_frame_gen_toggle.text = "Enabled" if _value else "Disabled"
	RenderingServer.viewport_set_frame_generation(get_viewport().get_viewport_rid(), _value)
	
func _on_fsr_sharpness_changed(_value: float) -> void:
	fsr_sharpness_label.text = str(_value)
	get_viewport().fsr_sharpness = 2.0 - _value
	pass

func _on_res_scale_changed(_value: float) -> void:
	res_scale_label.text = "%d%%" % round(get_viewport().scaling_3d_scale * 100)
	get_viewport().scaling_3d_scale = _value
	var viewport_render_size = get_viewport().size * _value
	resolution_label.text = "%d × %d (%d%%)" \
		% [viewport_render_size.x, viewport_render_size.y, round(get_viewport().scaling_3d_scale * 100)]
	pass

func _on_fullscreen_selected(_index: int) -> void:
	if _index == 0:
		get_tree().root.set_mode(Window.MODE_WINDOWED)
	elif _index == 1:
		get_tree().root.set_mode(Window.MODE_FULLSCREEN)
	elif _index == 2:
		get_tree().root.set_mode(Window.MODE_EXCLUSIVE_FULLSCREEN)
	pass

func _on_vsync_selected(_index: int) -> void:
	# Vsync is enabled by default.
	#0 -> Disabled
	#1 -> Adaptive
	#2 -> Enabled
	DisplayServer.window_set_vsync_mode(_index)
	pass

func _on_fps_limit_changed(_value: float) -> void:
	fps_limit_label.text = str(_value)
	Engine.max_fps = _value
	if(_value == 0):
		fps_limit_label.text = "no limit"
	pass

	#0 = Disabled
	#1 = FSAA
	#1 = SMAA
	#2 = MSAA 2x
	#3 = MSAA 4x
	#4 = MSAA 8x
func _on_aa_selected(_index: int) -> void:
	#first we disable all AA
	get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	get_viewport().msaa_3d = Viewport.MSAA_DISABLED
	match _index:
		0, 1: #+1 cause we start at 0, so its 1, 2
			get_viewport().screen_space_aa = _index + 1
		2, 3, 4: #-1 so we map 2,3,4 -> 1,2,3
			get_viewport().msaa_3d = _index - 1
	pass

func _on_brightness_changed(_value: float) -> void:
	pass

func _on_contrast_changed(_value: float) -> void:
	pass

func _on_saturation_changed(_value: float) -> void:
	pass
	
func apply_settings_to_ui() -> void:
	upscaler_option.selected = GraphicSettings.instance.upscaler_mode
	res_scale_slider.value = GraphicSettings.instance.resolution_scale
	fsr_sharpness_slider.value = GraphicSettings.instance.fsr_sharpness
	dlss_frame_gen_toggle.button_pressed = GraphicSettings.instance.dlss_frame_generation
	fullscreen_option.selected = GraphicSettings.instance.window_mode
	vsync_option.selected = GraphicSettings.instance.vsync_mode
	fps_limit_slider.value = GraphicSettings.instance.fps_limit
	aa_option.selected = GraphicSettings.instance.anti_aliasing_index
	
	_on_upscaler_selected(GraphicSettings.instance.upscaler_mode)
	_on_res_scale_changed(GraphicSettings.instance.resolution_scale)
	_on_fullscreen_selected(GraphicSettings.instance.window_mode)

func update_settings_from_ui() -> void:
	# 1. Update the Resource properties from UI current values
	GraphicSettings.instance.upscaler_mode = upscaler_option.selected
	GraphicSettings.instance.resolution_scale = res_scale_slider.value
	GraphicSettings.instance.fsr_sharpness = fsr_sharpness_slider.value
	
	# DLSS / NVIDIA Specifics
	GraphicSettings.instance.dlss_frame_generation = dlss_frame_gen_toggle.button_pressed
	
	# Display & FPS
	GraphicSettings.instance.window_mode = fullscreen_option.selected
	GraphicSettings.instance.vsync_mode = vsync_option.selected
	GraphicSettings.instance.fps_limit = int(fps_limit_slider.value)
	GraphicSettings.instance.anti_aliasing_index = aa_option.selected
	
	# Post-Process Sliders
	GraphicSettings.instance.brightness = brightness_slider.value
	GraphicSettings.instance.contrast = contrast_slider.value
	GraphicSettings.instance.saturation = saturation_slider.value
	
	GraphicSettings.instance.save_settings()
