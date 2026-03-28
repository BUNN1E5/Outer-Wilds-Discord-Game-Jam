shader_type spatial;
render_mode cull_disabled;
render_mode unshaded;
#include "res://shaders/SDFShapes.gdshaderinc"
#include "res://shaders/SDFOperations.gdshaderinc"
#include "res://shaders/helpers.gdshaderinc"
#include "res://shaders/SDFMaterials.gdshaderinc"

uniform samplerCube sky_panorama : source_color, filter_linear_mipmap;

uniform vec3 view_dir_offset = vec3(0);
uniform float sky_panorama_brightness = 1.;

uniform float star_radius = 1.;
uniform vec3 star_center = vec3(1.);
uniform vec4 star_color : source_color;

uniform vec3 black_hole_center = vec3(0,0,0);
uniform float near_bh_step_mult = .05;

uniform float MAX_DIST = 1000.;
uniform int ITERATIONS = 10000;
uniform float EPSILON = .001;

Surface map(in vec3 p){
	
	Surface skybox;
	skybox.dist = MAX_DIST;
	skybox.id = 0.;
	
	//Surface bh;
	//bh.dist = sdSphere(p - black_hole_center, Schwarzschild_radius);
	//bh.id = 1.;
	
	Surface star;
	star.dist = sdSphere(p - star_center, star_radius);
	star.id = 2.;
	return opUnion(star, skybox);
}

Surface vmap(in vec3 p){
	Surface disk;
	disk.dist = opSubtraction(
		sdCappedCylinder(p - black_hole_center, Schwarzschild_radius * outer_radius, disc_width * .5),
		sdCappedCylinder(p - black_hole_center, Schwarzschild_radius * inner_radius, disc_width * .5)
	);
	disk.id = 2.;
	return disk;
}

Ray raymarch(vec3 ro, vec3 rd){
	Ray r;
	r.dist = 0.;
	r.iterations = 0;
	r.hit = false;
	r.id = 0.;
	r.inside_bh = false;
	r.pos = ro + rd * r.dist; //position along ray
	r.dir = rd;
	r.transmittance = 1.;
	r.vol_color = vec3(0.,0.,0.);
    
	for( int i=0; i < ITERATIONS; i++ ){
		r.iterations = i;
        Surface sdf = map(r.pos);
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

void fragment() {
	//vec3 ro = POSITION;
	//vec3 rd = EYEDIR;
	
    vec2 uv = (FRAGCOORD.xy * 2. - VIEWPORT_SIZE.xy) / VIEWPORT_SIZE.y;
	//ro = Ray Origin || rd = ray direction
	vec3 ro = CAMERA_POSITION_WORLD;
	vec3 rd = normalize((INV_VIEW_MATRIX * vec4(VERTEX, 1)).xyz - ro);
	
	Ray r = raymarch(ro, rd);
	
	if(r.inside_bh){
		ALBEDO = vec3(0.0);
	} else if(r.hit){
		float sun_mask = step(abs(2. - r.id), .5);
		float bh_mask = step(abs(1. - r.id), .5);
		ALBEDO += (star_color.rgb * sun_mask) * star_color.a;
	} else {
		float dist_from_bh = length(ro - black_hole_center);
		float safe_dist = max(dist_from_bh, Schwarzschild_radius + 0.001);
		float g_shift = 1./sqrt(1.0 - (Schwarzschild_radius / (safe_dist)));
		
		float bend_factor = float(r.iterations) / 100.0; 
        float total_shift = g_shift + (bend_factor * 0.2);
		
		// Convert ray direction to Equirectangular UVs
		//vec2 sky_uv = vec2(atan(r.dir.z, r.dir.x) * 0.1591549 + 0.5, acos(r.dir.y) * 0.3183098);
		vec3 sky_color = texture(sky_panorama, r.dir).rgb * sky_panorama_brightness;
		
		// Use g_shift to fade the brightness as you go deeper
		float brightness = clamp(1.0 / g_shift, 0.0, 1.0);

		sky_color.r *= brightness; // Red stays longest
		sky_color.g *= pow(brightness, 2.0);
		sky_color.b *= pow(brightness, 3.0); // Blue vanishes first

		// Combine with a "Void" color
		//COLOR = mix(vec3(0.0), sky_color * sky_panorama_brightness, 1.);
		ALBEDO = sky_color;
	}
}