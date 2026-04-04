shader_type spatial;
render_mode cull_disabled;
render_mode unshaded;
#include "res://shaders/SDFShapes.gdshaderinc"
#include "res://shaders/SDFOperations.gdshaderinc"

uniform samplerCube sky_panorama : source_color, filter_linear_mipmap;

uniform mat3 rotation_offset_matrix;
uniform float sky_panorama_brightness = 1.;

uniform float star_radius = 1.;
uniform vec3 star_center = vec3(1.);
uniform vec4 star_color : source_color;

uniform vec3 black_hole_center = vec3(0,0,0);
uniform float Schwarzschild_radius = 1.0;

uniform float near_bh_step_mult = .05;

uniform float MAX_DIST = 1000.;
uniform int ITERATIONS = 500;
uniform float EPSILON = .001;

uniform vec3 cam_vel_dir;
uniform float cam_frac_of_lightspeed; //in speed of light
uniform float sim_speed = 1.;

uniform float shutter_speed = 100.;
uniform vec3 ship_angular_vel = vec3(1.);
uniform int motion_blur_sample_count = 5;

Surface map(in Ray r){
	
	Surface skybox;
	skybox.dist = MAX_DIST;
	skybox.id = 0.;
	
	Surface star;
	vec3 smear = cross(ship_angular_vel.xyz, star_center - r.origin) * pow(cam_frac_of_lightspeed, .25) * sim_speed; 
	star.dist = sdCapsule(r.pos - star_center, smear*.3, -smear*.3, star_radius);
	//star.dist = sdSphere(r.pos - star_center, star_radius);
	
	star.id = 2.;
	return opUnion(star, skybox);
}

Ray raymarch(vec3 ro, vec3 rd){
	Ray r;
	r.origin = ro;
	r.dist = 0.;
	r.iterations = 0;
	r.hit = false;
	r.id = 0.;
	r.inside_bh = false;
	r.pos = ro + rd * r.dist; //position along ray
	r.dir = rd;
	r.transmittance = 1.;
	
	for( int i=0; i < ITERATIONS; i++ ){
		r.iterations = i;
        Surface sdf = map(r);
		float d = sdf.dist;
		r.id = sdf.id;
		
		if(d < EPSILON){
			r.hit = true; 
			return r; 
		}
		
		vec3 rel_p = r.pos - black_hole_center;
        float r2 = dot(rel_p, rel_p);
        float r_len = sqrt(r2);
		
        if (r_len < Schwarzschild_radius * .1) {
            r.inside_bh = true;
			return r;
        }
		
        vec3 L = cross(rel_p, r.dir);
        float h2 = dot(L, L);
        vec3 accel = -1.5 * Schwarzschild_radius * h2 * rel_p / (r2 * r2 * r_len);
		float step_size = min(d, r_len * near_bh_step_mult);
		
		r.dist += step_size;
		r.pos += r.dir * step_size;
		r.dir = normalize(r.dir + accel * step_size);
		
		if(r.dist > MAX_DIST) { break; }
    }
	return r;
}

vec3 solveRayColor(Ray r, vec3 ro, vec2 screen_uv){
	vec3 color = vec3(0);
	if(r.inside_bh){
		color = vec3(0.0);
	} else if(r.hit){
		float sun_mask = step(abs(2. - r.id), .5);
		float bh_mask = step(abs(1. - r.id), .5);
		color += (star_color.rgb * sun_mask) * star_color.a;
	} else {
		float dist_from_bh = length(ro - black_hole_center);
		float safe_dist = max(dist_from_bh, Schwarzschild_radius + 0.001);
		float g_shift = 1./sqrt(1.0 - (Schwarzschild_radius / (safe_dist)));
		
		float bend_factor = float(r.iterations) / 100.0; 
        float total_shift = g_shift + (bend_factor * 0.2);
		
		float blur_amount = float(r.iterations) * .0015;
		vec3 sky_color = texture(sky_panorama, r.dir, blur_amount).rgb * sky_panorama_brightness;
		float brightness = clamp(1.0 / g_shift, 0.0, 1.0);

		sky_color.r *= brightness; // Red stays longest
		sky_color.g *= pow(brightness, 2.0);
		sky_color.b *= pow(brightness, 3.0); // Blue vanishes first


		color = mix(vec3(0.0), sky_color * sky_panorama_brightness, 1.);
	}
	return color;
}

void fragment() {
    vec2 uv = (FRAGCOORD.xy * 2. - VIEWPORT_SIZE.xy) / VIEWPORT_SIZE.y;
	
	//ro = Ray Origin || rd = ray direction
	vec3 ro = CAMERA_POSITION_WORLD;
	
	//vec3 rd = normalize((INV_VIEW_MATRIX * vec4(VERTEX, 1)).xyz - ro);
	vec3 rd = normalize((INV_VIEW_MATRIX * vec4(VERTEX, 0.)).xyz);
	rd = rotation_offset_matrix * rd * vec3(-1);
	ro = rotation_offset_matrix * ro;
	
	Ray r = raymarch(ro, rd);
	
	vec3 blur_vector = cross(ship_angular_vel, r.dir) * (1./shutter_speed);
	vec3 accumulation = vec3(0.);
	float seed = uv.x + uv.y + TIME;
	for(int i = 0; i < motion_blur_sample_count; i++){
		float noise = fract(sin(seed + float(i)) * 43758.5453);
		float t = (float(i) + noise)/float(motion_blur_sample_count - 1);
		vec3 sample_dir = normalize(r.dir + blur_vector * (t - .5));
		Ray _r = r;
		r.dir = sample_dir;
		accumulation += solveRayColor(_r, ro, SCREEN_UV);
	}
	
	ALBEDO = accumulation / float(motion_blur_sample_count);
}