shader_type spatial;
render_mode unshaded;
render_mode cull_disabled;

// Uniform for the depth texture.
uniform sampler2D depth_tex : hint_depth_texture;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void vertex() {	POSITION = vec4(VERTEX.xy*2.0, 1.0, 1.0); }


void fragment() {
    // Compute UVs from screen-space coordinates.
    float depth = texture(depth_tex, SCREEN_UV).r;
    vec4 screen = texture(screen_texture, SCREEN_UV);
	ALBEDO = screen.rgb;
}
