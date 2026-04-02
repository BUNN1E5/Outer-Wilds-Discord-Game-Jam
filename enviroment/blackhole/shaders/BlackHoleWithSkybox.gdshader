shader_type spatial;
render_mode cull_disabled;
render_mode unshaded;
#include "res://shaders/SDFShapes.gdshaderinc"
#include "res://shaders/SDFOperations.gdshaderinc"
#include "res://shaders/helpers.gdshaderinc"
#include "res://shaders/SDFMaterials.gdshaderinc"

uniform samplerCube sky_panorama : source_color, filter_linear_mipmap;

uniform mat3 rotation_offset_matrix;
uniform float sky_panorama_brightness = 1.;

uniform float star_radius = 1.;
uniform vec3 star_center = vec3(1.);
uniform vec4 star_color : source_color;

uniform vec3 black_hole_center = vec3(0,0,0);
uniform float Schwarzschild_radius = 1.0;  // must match the main shader's uniform

uniform float near_bh_step_mult = .05;

uniform float MAX_DIST = 1000.;
uniform int ITERATIONS = 10000;
uniform float EPSILON = .001;

uniform vec3 cam_vel_dir;
uniform float cam_frac_of_lightspeed; //in speed of light
uniform float sim_speed = 1.;
uniform float doppler_intensity = 1.; //in speed of light

uniform vec3 ship_angular_vel = vec3(1.);

Surface map(in Ray r){
	
	Surface skybox;
	skybox.dist = MAX_DIST;
	skybox.id = 0.;
	
	//Surface bh;
	//bh.dist = sdSphere(p - black_hole_center, Schwarzschild_radius);
	//bh.id = 1.;
	
	Surface star;
	//star.dist = sdSphere(p - star_center, star_radius);
	vec3 smear = cross(ship_angular_vel.xyz * 2., star_center - r.origin) * pow(cam_frac_of_lightspeed, .05) * sim_speed; 
	star.dist = sdCapsule(r.pos - star_center, smear*.5, -smear*.5, star_radius);
	
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
		
		// Convert ray direction to Equirectangular UVs
		//vec2 sky_uv = vec2(atan(r.dir.z, r.dir.x) * 0.1591549 + 0.5, acos(r.dir.y) * 0.3183098);
		float blur_amount = float(r.iterations) * .0015;
		vec3 sky_color = texture(sky_panorama, r.dir, blur_amount).rgb * sky_panorama_brightness;
		
		// Use g_shift to fade the brightness as you go deeper
		float brightness = clamp(1.0 / g_shift, 0.0, 1.0);

		//sky_color.r *= brightness; // Red stays longest
		//sky_color.g *= pow(brightness, 2.0);
		//sky_color.b *= pow(brightness, 3.0); // Blue vanishes first


		// Combine with a "Void" color
		//COLOR = mix(vec3(0.0), sky_color * sky_panorama_brightness, 1.);
		color = sky_color;
	}
	return color;
}

void fragment() {
	//vec3 ro = POSITION;
	//vec3 rd = EYEDIR;
	//mat3 rot_mat = mat3(
		//vec3(cos(a)*cos(b),cos(a)*sin(b)*sin(y) - sin(a)*cos(y), cos(a)*cos(b)*cos(y) + sin(a)*sin(y)),
		//vec3(sin(a)*cos(b), sin(a)*sin(b)*sin(y)+cos(a)*cos(y), sin(a)*sin(b)*cos(y)-cos(y)*sin(y)),
		//vec3(-sin(b), cos(b)*sin(y), cos(b)*cos(y)));
	
	
    vec2 uv = (FRAGCOORD.xy * 2. - VIEWPORT_SIZE.xy) / VIEWPORT_SIZE.y;
	//ro = Ray Origin || rd = ray direction
	vec3 ro = CAMERA_POSITION_WORLD;
	//vec3 rd = normalize((INV_VIEW_MATRIX * vec4(VERTEX, 1)).xyz - ro);
	vec3 rd = normalize((INV_VIEW_MATRIX * vec4(VERTEX, 0.)).xyz);
	rd = rotation_offset_matrix * rd * vec3(-1);
	ro = rotation_offset_matrix * ro;
	
	Ray r = raymarch(ro, rd);
	ALBEDO = solveRayColor(r, ro, SCREEN_UV);
	
		//Relatavistic Beaming	
	//Theta is the angle between the camera position and the ray position
	float cos_theta = dot(cam_vel_dir, rd);
	//D = 1/(1-Bcos(theta)*y
	float beta = cam_frac_of_lightspeed * doppler_intensity;
	//Lorentz factor (y)
	//float lorentz = 1./sqrt(1.-(beta));
	//float doppler = 1./((1.-beta*cos_theta)*lorentz);
	//float intensity = pow(doppler, 3.);
	//ALBEDO *= intensity;
}