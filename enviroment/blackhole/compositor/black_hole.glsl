#[compute]
#version 450
#extension GL_EXT_samplerless_texture_functions : require

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform image2D color_image;
layout(set = 0, binding = 1) uniform sampler my_sampler;
layout(set = 0, binding = 2) uniform textureCube sky_panorama;

layout(set = 0, binding = 3, std140) uniform Params {
    mat4 inv_view_matrix;
    mat4 inv_proj_matrix;
    mat4 rotation_offset_matrix;
    vec4 star_color;
    vec3 star_center; float star_radius;
    vec3 black_hole_center; float Schwarzschild_radius;
    vec3 cam_vel_dir; float cam_frac_of_lightspeed;
    vec3 ship_angular_vel; float sky_panorama_brightness;
    float MAX_DIST; float ITERATIONS; float EPSILON; float near_bh_step_mult;
    float sim_speed; float shutter_speed; float motion_blur_sample_count; float padding;
} p;

layout(set = 0, binding = 4) uniform texture2DArray depth_buffer;
layout(rgba16f, set = 0, binding = 5) uniform image2D history_image;

struct Surface { float dist; float id; };

struct Ray {
    vec3 origin;
    vec3 pos;
    vec3 dir;
    float dist;
    int iterations;
    bool hit;
    float id;
    bool inside_bh;
    float transmittance;
};

Surface opUnion(Surface d1, Surface d2) {
    return (d1.dist < d2.dist) ? d1 : d2;
}

float sdCapsule(vec3 pos, vec3 a, vec3 b, float r) {
    vec3 pa = pos - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

Surface map(Ray r) {
    Surface skybox;
    skybox.dist = p.MAX_DIST;
    skybox.id = 0.0;

    Surface star;
    vec3 smear = cross(p.ship_angular_vel, p.star_center - r.origin) * pow(p.cam_frac_of_lightspeed, 0.25) * p.sim_speed;
    star.dist = sdCapsule(r.pos - p.star_center, smear * 0.3, -smear * 0.3, p.star_radius);
    star.id = 2.0;

    return opUnion(star, skybox);
}

Ray raymarch(vec3 ro, vec3 rd) {
    Ray r;
    r.origin = ro;
    r.dist = 0.0;
    r.iterations = 0;
    r.hit = false;
    r.id = 0.0;
    r.inside_bh = false;
    r.pos = ro;
    r.dir = rd;
    r.transmittance = 1.0;

    int max_iter = int(p.ITERATIONS);
    for (int i = 0; i < max_iter; i++) {
        r.iterations = i;
        Surface sdf = map(r);
        float d = sdf.dist;
        r.id = sdf.id;

        if (d < p.EPSILON) {
            r.hit = true;
            return r;
        }

        vec3 rel_p = r.pos - p.black_hole_center;
        float r2 = dot(rel_p, rel_p);
        float r_len = sqrt(r2);

        if (r_len < p.Schwarzschild_radius * 0.1) {
            r.inside_bh = true;
            return r;
        }

        vec3 L = cross(rel_p, r.dir);
        float h2 = dot(L, L);
        float denom = max(r2 * r2 * r_len, 0.0001);
        vec3 accel = -1.5 * p.Schwarzschild_radius * h2 * rel_p / denom;
        float step_size = min(d, r_len * p.near_bh_step_mult);

        r.dist += step_size;
        r.pos += r.dir * step_size;
        r.dir = normalize(r.dir + accel * step_size);

        if (r.dist > p.MAX_DIST) break;
    }
    return r;
}

vec3 solveRayColor(Ray r, vec3 ro) {
    vec3 color = vec3(0.0);
    if (r.inside_bh) {
        color = vec3(0.0);
    } else if (r.hit) {
        float sun_mask = step(abs(2.0 - r.id), 0.5);
        color += (p.star_color.rgb * sun_mask) * p.star_color.a;
    } else {
        float dist_from_bh = length(ro - p.black_hole_center);
        float safe_dist = max(dist_from_bh, p.Schwarzschild_radius + 0.001);
        float g_shift = 1.0 / sqrt(1.0 - (p.Schwarzschild_radius / safe_dist));

        float bend_factor = float(r.iterations) / 100.0;
        float blur_amount = float(r.iterations) * 0.0015;
        vec3 sky_color = textureLod(samplerCube(sky_panorama, my_sampler), r.dir, blur_amount).rgb * p.sky_panorama_brightness;
        float brightness = clamp(1.0 / g_shift, 0.0, 1.0);

        sky_color.r *= brightness;
        sky_color.g *= pow(brightness, 2.0);
        sky_color.b *= pow(brightness, 3.0);

        color = sky_color * p.sky_panorama_brightness;
    }
    return color;
}

void main() {
    ivec2 texel = ivec2(gl_GlobalInvocationID.xy);
    ivec2 size = imageSize(color_image);
    if (texel.x >= size.x || texel.y >= size.y) return;

    float depth = texelFetch(depth_buffer, ivec3(texel, 0), 0).r;
    if (depth > 0.0) return;

    vec2 uv = (vec2(texel) + 0.5) / vec2(size);
    vec4 target = p.inv_proj_matrix * vec4(uv * 2.0 - 1.0, 1.0, 1.0);
    vec3 view_dir = normalize(target.xyz / max(abs(target.w), 0.0001));

    vec3 ro = (p.inv_view_matrix * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
    vec3 rd = normalize((p.inv_view_matrix * vec4(view_dir, 0.0)).xyz);

    mat3 rot_mat = mat3(p.rotation_offset_matrix);
    rd = rot_mat * rd * vec3(-1.0);
    ro = rot_mat * ro;

    Ray r = raymarch(ro, rd);

    vec3 blur_vector = cross(p.ship_angular_vel, r.dir) * (1.0 / p.shutter_speed);
    vec3 accumulation = vec3(0.0);
    int samples = int(p.motion_blur_sample_count);

    for (int i = 0; i < samples; i++) {
        float t = float(i) / float(max(samples - 1, 1));
        Ray _r = r;
        _r.dir = normalize(r.dir + blur_vector * (t - 0.5));
        accumulation += solveRayColor(_r, ro);
    }

    vec3 current_col = accumulation / float(max(samples, 1));
    vec3 history_col = imageLoad(history_image, texel).rgb;
    vec3 final_col = mix(history_col, current_col, 0.15);

    imageStore(color_image, texel, vec4(final_col, 1.0));
    imageStore(history_image, texel, vec4(final_col, 1.0));
}
