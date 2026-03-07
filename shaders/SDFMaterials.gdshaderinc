#include "SDFOperations.gdshaderinc"
// SDFMaterials.gdshaderinc – Accretion disk in the style of the Unity tutorial

uniform sampler2D disc_texture;          // _DiscTex
uniform float disc_width = 0.1;           // total thickness in world units
uniform float outer_radius = 4.0;         // in Schwarzschild radii (multiplier)
uniform float inner_radius = 1.5;         // in Schwarzschild radii (multiplier)
uniform float disc_speed = 2.0;            // rotation speed
uniform vec4  disc_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float doppler_beaming_factor = 66.0;
uniform float hue_radius = 0.75;           // radial point where hue shift starts (0–1)
uniform float hue_shift_factor = -0.03;     // amount of hue shift
uniform float Schwarzschild_radius = 1.0;  // must match the main shader's uniform

// Helper functions (ported from Unity HLSL)
float remap(float v, float minOld, float maxOld, float minNew, float maxNew) {
    return minNew + (v - minOld) * (maxNew - minNew) / (maxOld - minOld);
}

vec3 hdrIntensity(vec3 emissiveColor, float intensity) {
    // intensity is used as exponent for pow(2.0, intensity)
    return emissiveColor * pow(2.0, intensity);
}

vec3 RGBToHSV(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 HSVToRGB(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 RotateAboutAxis(vec3 In, vec3 Axis, float Rotation) {
    float s = sin(Rotation);
    float c = cos(Rotation);
    float one_minus_c = 1.0 - c;
    Axis = normalize(Axis);
    mat3 rot_mat = mat3(
		vec3(
        one_minus_c * Axis.x * Axis.x + c,
        one_minus_c * Axis.x * Axis.y - Axis.z * s,
        one_minus_c * Axis.z * Axis.x + Axis.y * s
		), vec3(
        one_minus_c * Axis.x * Axis.y + Axis.z * s,
        one_minus_c * Axis.y * Axis.y + c,
        one_minus_c * Axis.y * Axis.z - Axis.x * s
		), vec3(
        one_minus_c * Axis.z * Axis.x - Axis.y * s,
        one_minus_c * Axis.y * Axis.z + Axis.x * s,
        one_minus_c * Axis.z * Axis.z + c
		)
    );
    return rot_mat * In;
}

// Compute disc color at a given point (used inside sample_disk_volume)
vec3 discColor(vec3 baseColor, vec3 planarDiscPos, vec3 discDir, vec3 cameraPos, float u, float radius) {
    vec3 newColor = baseColor;

    // Distance intensity fall-off (as in Unity)
    float intensity = remap(u, 0.0, 1.0, 0.5, -1.2);
    intensity *= abs(intensity);

    // Doppler beaming intensity change (approximated with a small rotation)
    vec3 rotatePos = RotateAboutAxis(planarDiscPos, discDir, 0.01);
    float dopplerDistance = (length(rotatePos - cameraPos) - length(planarDiscPos - cameraPos)) / radius;
    intensity += dopplerDistance * disc_speed * doppler_beaming_factor;

    newColor = hdrIntensity(baseColor, intensity);

    // Distance hue shift
    vec3 hueColor = RGBToHSV(newColor);
    float hueShift = clamp(remap(u, hue_radius, 1.0, 0.0, 1.0), 0.0, 1.0);
    hueColor.r += hueShift * hue_shift_factor;
    newColor = HSVToRGB(hueColor);

    return newColor;
}

struct VolumeSample {
    vec3 emission;
    float density;
};

VolumeSample sample_disk_volume(vec3 rel_p, vec3 view_dir, vec3 camera_pos) {
    VolumeSample samp;
    samp.emission = vec3(0.0);
    samp.density = 0.0;

    // Convert radii to world units (they are multipliers of Schwarzschild radius)
    float world_inner = inner_radius * Schwarzschild_radius;
    float world_outer = outer_radius * Schwarzschild_radius;

    float rad = length(rel_p.xz);
    float height = abs(rel_p.y);
    float angle = atan(rel_p.z, rel_p.x);

    // Disc bounds (using disc_width as total thickness)
    if (rad < world_inner || rad > world_outer || height > disc_width * 0.5)
        return samp;
	float t = (rad - world_inner) / (world_outer - world_inner);
	vec3 simpleColor = mix(vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0), t);

	// Set emission and density
	samp.emission = disc_color.rgb * 10.0; // HDR bright
	samp.density = 5.0;
	return samp;
}