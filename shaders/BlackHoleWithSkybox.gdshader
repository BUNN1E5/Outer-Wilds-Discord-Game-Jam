shader_type sky;
//render_mode cull_disabled;
//render_mode unshaded;
#include "SDFShapes.gdshaderinc"
#include "SDFOperations.gdshaderinc"
#include "helpers.gdshaderinc"
#include "SDFMaterials.gdshaderinc"

uniform sampler2D sky_panorama_2d : source_color, filter_linear_mipmap;
uniform float sky_panorama_brightness = 1.;

uniform vec3 black_hole_center = vec3(0,0,0);
uniform float near_bh_step_mult = .05;



uniform float MAX_DIST = 1000.;
uniform int ITERATIONS = 10000;
uniform float EPSILON = .001;

Surface map(in vec3 p){
	
	Surface skybox;
	skybox.dist = MAX_DIST;
	skybox.id = 0.;
	
	Surface bh;
	bh.dist = sdSphere(p - black_hole_center, Schwarzschild_radius);
	bh.id = 1.;
	return opUnion(bh, skybox);
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
		
		Surface vol = vmap(r.pos);
		if(vol.dist < 0.0){
			step_size = .2;
			VolumeSample vol = sample_disk_volume(rel_p, r.dir, POSITION);
			float density = vol.density * step_size;
            if (density > 0.0) {
                // Transmittance after this step
                float step_trans = exp(-density);
                // Emission added, weighted by current transmittance
                r.vol_color += r.transmittance * vol.emission * (1.0 - step_trans) / density;
                r.transmittance *= step_trans;
			}
		}
		if (r.transmittance < 0.01) {
            break;
        }
		
		r.dist += step_size;
		r.pos += r.dir * step_size;
		r.dir = normalize(r.dir + accel * step_size);
		
		if(r.dist > MAX_DIST) { break; }
    }
	return r;
}

void sky() {
	vec3 ro = POSITION;
	vec3 rd = EYEDIR;
	Ray r = raymarch(ro, rd);
	
	if(r.inside_bh){
		COLOR = vec3(0.0);
	} else if(r.hit){
		COLOR = r.vol_color;
		
	} else {
		float dist_from_bh = length(POSITION - black_hole_center);
		float safe_dist = max(dist_from_bh, Schwarzschild_radius + 0.001);
		float g_shift = 1./sqrt(1.0 - (Schwarzschild_radius / (safe_dist)));
		
		float bend_factor = float(r.iterations) / 100.0; 
        float total_shift = g_shift + (bend_factor * 0.2);
		
		// Convert ray direction to Equirectangular UVs
		vec2 sky_uv = vec2(atan(r.dir.z, r.dir.x) * 0.1591549 + 0.5, acos(r.dir.y) * 0.3183098);
		vec3 sky_color = texture(sky_panorama_2d, sky_uv).rgb;
		
		// Use g_shift to fade the brightness as you go deeper
		float brightness = clamp(1.0 / g_shift, 0.0, 1.0);

		sky_color.r *= brightness; // Red stays longest
		sky_color.g *= pow(brightness, 2.0);
		sky_color.b *= pow(brightness, 3.0); // Blue vanishes first

		// Combine with a "Void" color
		//COLOR = mix(vec3(0.0), sky_color * sky_panorama_brightness, 1.);
		COLOR = r.vol_color + r.transmittance * sky_color;
	}
}