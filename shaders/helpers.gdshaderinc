vec3 rgb2hsv(vec3 rgb) {
	float r = rgb.r;
	float g = rgb.g;
	float b = rgb.b;
	
	float max_val = max(r, max(g, b));
	float min_val = min(r, min(g, b));
	float delta = max_val - min_val;
	
	float h = 0.0;
	float s = 0.0;
	float v = max_val;
	
	if (delta > 0.0001) {
		s = delta / max_val;
		
		if (abs(r - max_val) < 0.0001)      h = (g - b) / delta;
		else if (abs(g - max_val) < 0.0001) h = 2.0 + (b - r) / delta;
		else                                h = 4.0 + (r - g) / delta;
		
		h *= 60.0;
		if (h < 0.0) h += 360.0;
	}
	
	return vec3(h, s, v);
}

// Convert HSV color to RGB color space
// Input: vec3 with h in [0, 360], s and v in [0, 1]
// Output: vec3 with components in range [0, 1]
vec3 hsv2rgb(vec3 hsv) {
	float h = hsv.x;
	float s = hsv.y;
	float v = hsv.z;
	
	float c = v * s;
	float x = c * (1.0 - abs(mod(h / 60.0, 2.0) - 1.0));
	float m = v - c;
	
	vec3 rgb;
	
	if (h < 60.0)       rgb = vec3(c, x, 0.0);
	else if (h < 120.0) rgb = vec3(x, c, 0.0);
	else if (h < 180.0) rgb = vec3(0.0, c, x);
	else if (h < 240.0) rgb = vec3(0.0, x, c);
	else if (h < 300.0) rgb = vec3(x, 0.0, c);
	else                rgb = vec3(c, 0.0, x);
	
	rgb += m;
	return rgb;
}

vec3 wavelength_to_rgb(float nm) {
    float r = 0.0, g = 0.0, b = 0.0;
    
    if (nm >= 380.0 && nm < 440.0) {
        r = -(nm - 440.0) / (440.0 - 380.0);
        b = 1.0;
    } else if (nm >= 440.0 && nm < 490.0) {
        g = (nm - 440.0) / (490.0 - 440.0);
        b = 1.0;
    } else if (nm >= 490.0 && nm < 510.0) {
        g = 1.0;
        b = -(nm - 510.0) / (510.0 - 490.0);
    } else if (nm >= 510.0 && nm < 580.0) {
        r = (nm - 510.0) / (580.0 - 510.0);
        g = 1.0;
    } else if (nm >= 580.0 && nm < 645.0) {
        r = 1.0;
        g = -(nm - 645.0) / (645.0 - 580.0);
    } else if (nm >= 645.0 && nm <= 750.0) {
        r = 1.0;
    }

    // Intensity falloff at the edges of human vision
    float factor = 0.0;
    if (nm >= 380.0 && nm < 420.0) factor = 0.3 + 0.7 * (nm - 380.0) / (420.0 - 380.0);
    else if (nm >= 420.0 && nm < 701.0) factor = 1.0;
    else if (nm >= 701.0 && nm <= 750.0) factor = 0.3 + 0.7 * (750.0 - nm) / (750.0 - 701.0);

    return vec3(r, g, b) * factor;
}

float rgb_to_wavelength(vec3 color) {
    // 1. Get Hue (Simplified)
    float max_c = max(color.r, max(color.g, color.b));
    float min_c = min(color.r, min(color.g, color.b));
    float delta = max_c - min_c;
    float h = 0.0;
    if (delta > 0.0) {
        if (max_c == color.r) h = mod((color.g - color.b) / delta, 6.0);
        else if (max_c == color.g) h = (color.b - color.r) / delta + 2.0;
        else h = (color.r - color.g) / delta + 4.0;
        h /= 6.0;
    }
    // 2. Map Hue [0,1] to Visible Spectrum [400, 700]
    // Note: Hue 0 is Red (700nm), Hue 0.7 is Violet (400nm)
    return 700.0 - (h * 300.0); 
}