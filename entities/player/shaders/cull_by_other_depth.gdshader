shader_type spatial;
render_mode unshaded;
render_mode cull_disabled;
uniform sampler2D pixelated_tex;
uniform sampler2D depth_tex : hint_depth_texture;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;



void vertex() {	POSITION = vec4(VERTEX.xy*2.0, 1.0, 1.0); }

void fragment() {
	vec4 screen = texture(screen_texture, SCREEN_UV);
	float depth = texture(depth_tex, SCREEN_UV).r;
	
	vec4 pix_data = texture(pixelated_tex, SCREEN_UV);
	
	ALBEDO = vec3(.5-pix_data.a);
	
}
