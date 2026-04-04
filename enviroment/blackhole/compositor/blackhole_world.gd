@tool
extends CompositorEffect
class_name BlackHoleCompositorEffect

var rd: RenderingDevice
var shader: RID
var pipeline: RID

# History textures for Temporal Accumulation (one per view)
var history_textures: Array[RID] = []

# --- Exposed Parameters ---
@export_group("Black Hole Physics")
@export var Schwarzschild_radius: float = 1.0
@export var black_hole_center: Vector3 = Vector3.ZERO
@export var near_bh_step_mult: float = 0.05

@export_group("Star Settings")
@export var star_center: Vector3 = Vector3(10.0, 5.0, 10.0)
@export var star_radius: float = 1.0
@export var star_color: Color = Color(1.0, 0.9, 0.7, 5.0)

@export_group("Rendering")
@export var sky_panorama: Cubemap
@export var sky_panorama_brightness: float = 1.0
@export var ITERATIONS: int = 500
@export var MAX_DIST: float = 1000.0
@export var EPSILON: float = 0.001

@export_group("Motion")
@export var ship_angular_vel: Vector3 = Vector3.ZERO
@export var cam_vel_dir: Vector3 = Vector3.ZERO
@export var cam_frac_of_lightspeed: float = 0.0
@export var sim_speed: float = 1.0
@export var shutter_speed: float = 100.0
@export var motion_blur_samples: int = 5

func _init():
	effect_callback_type = EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
	rd = RenderingServer.get_rendering_device()
	_load_shader()

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		_clear_history()
		if shader.is_valid():
			rd.free_rid(shader)

func _load_shader():
	var shader_file = load("res://shaders/black_hole.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(shader)

func _clear_history():
	for rid in history_textures:
		if rid.is_valid():
			rd.free_rid(rid)
	history_textures.clear()

func _render_callback(type: int, render_data: RenderData):
	if type != EFFECT_CALLBACK_TYPE_POST_TRANSPARENT or not shader.is_valid():
		return

	var scene_buffers: RenderSceneBuffersRD = render_data.get_render_scene_buffers()
	var scene_data: RenderSceneDataRD = render_data.get_render_scene_data()
	if not scene_buffers or not scene_data:
		return

	var size = scene_buffers.get_internal_size()
	var view_count = scene_buffers.get_view_count()
	
	if history_textures.size() != view_count:
		_clear_history()
		history_textures.resize(view_count)

	# --- Setup Uniforms & Dispatch ---
	for view in range(view_count):
		var color_image = scene_buffers.get_color_layer(view)
		var depth_image = scene_buffers.get_depth_texture() # Or get_depth_layer(view)
		
		# Ensure History Texture is valid and matches resolution
		if not history_textures[view].is_valid():
			var tf := RDTextureFormat.new()
			tf.format = RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT
			tf.width = size.x
			tf.height = size.y
			tf.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
			history_textures[view] = rd.texture_create(tf, RDTextureView.new())
			rd.texture_clear(history_textures[view], Color(0,0,0,1), 0, 1, 0, 1)

		# Prepare UBO Data (std140 alignment)
		var params = PackedFloat32Array()
		
		# 1-3: Matrices (64 bytes each)
		params.append_array(_mat4_to_array(scene_data.get_cam_transform().affine_inverse()))
		params.append_array(_mat4_to_array(scene_data.get_projection_matrix().inverse()))
		params.append_array(_mat4_to_array(Transform3D(Basis.IDENTITY, Vector3.ZERO))) # rotation_offset
		
		# 4: Star Color (vec4)
		params.append_array([star_color.r, star_color.g, star_color.b, star_color.a])
		
		# 5: Star Center (vec3) + Radius (float)
		params.append_array([star_center.x, star_center.y, star_center.z, star_radius])
		
		# 6: BH Center (vec3) + RS (float)
		params.append_array([black_hole_center.x, black_hole_center.y, black_hole_center.z, Schwarzschild_radius])
		
		# 7: Cam Vel (vec3) + Frac (float)
		params.append_array([cam_vel_dir.x, cam_vel_dir.y, cam_vel_dir.z, cam_frac_of_lightspeed])
		
		# 8: Ang Vel (vec3) + Sky Brightness (float)
		params.append_array([ship_angular_vel.x, ship_angular_vel.y, ship_angular_vel.z, sky_panorama_brightness])
		
		# 9: Rendering Params (4 floats)
		params.append_array([MAX_DIST, float(ITERATIONS), EPSILON, near_bh_step_mult])
		
		# 10: Physics/Blur Params (4 floats)
		params.append_array([sim_speed, shutter_speed, float(motion_blur_samples), 0.0])

		var param_buffer = rd.uniform_buffer_create(params.size() * 4, params.to_byte_array())

		# Binding Setup
		var uniform_set = [
			_create_image_uniform(color_image, 0),
			_create_sampler_uniform(1),
			_create_texture_uniform(sky_panorama.get_rid(), 2, RenderingDevice.UNIFORM_TYPE_TEXTURE),
			_create_buffer_uniform(param_buffer, 3),
			_create_texture_uniform(depth_image, 4, RenderingDevice.UNIFORM_TYPE_TEXTURE),
			_create_image_uniform(history_textures[view], 5)
		]
		
		var set_id = rd.uniform_set_create(uniform_set, shader, 0)
		
		var compute_list = rd.compute_list_begin()
		rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
		rd.compute_list_bind_uniform_set(compute_list, set_id, 0)
		rd.compute_list_dispatch(compute_list, ceil(size.x / 8.0), ceil(size.y / 8.0), 1)
		rd.compute_list_end()

# --- Helper Functions ---

func _mat4_to_array(m: Transform3D) -> PackedFloat32Array:
	var b = m.basis
	var o = m.origin
	return PackedFloat32Array([
		b.x.x, b.x.y, b.x.z, 0.0,
		b.y.x, b.y.y, b.y.z, 0.0,
		b.z.x, b.z.y, b.z.z, 0.0,
		o.x, o.y, o.z, 1.0
	])

func _create_image_uniform(rid: RID, binding: int) -> RDUniform:
	var u = RDUniform.new()
	u.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	u.binding = binding
	u.add_id(rid)
	return u

func _create_sampler_uniform(binding: int) -> RDUniform:
	var u = RDUniform.new()
	u.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER
	u.binding = binding
	u.add_id(rd.sampler_create(RDSamplerState.new()))
	return u
	
func _create_texture_uniform(rid: RID, binding: int, type: RenderingDevice.UniformType) -> RDUniform:
	var u = RDUniform.new()
	u.uniform_type = type
	u.binding = binding
	u.add_id(rid)
	return u

func _create_buffer_uniform(rid: RID, binding: int) -> RDUniform:
	var u = RDUniform.new()
	u.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	u.binding = binding
	u.add_id(rid)
	return u
