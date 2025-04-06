shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture;
uniform float animated_strength = 0.0;
uniform sampler2D noise;

void vertex() {
	// Called for every vertex the material is visible on.
}

float remap(float f) {
	float s = sign(f);
	float m = abs(f);
	m -= 0.5;
	m = 0.5 - abs(m);
	return m;// * s;
}

void fragment() {
	vec2 coords = 2.0 * (UV - vec2(0.5));
	float rand = texture(noise, normalize(coords) + vec2(animated_strength)).r;
	float strength = clamp(length(coords) + rand * 0.2, 0.0, 1.0);
	strength = remap(strength);
	float a_strength = strength * animated_strength;
	vec2 offset = a_strength * coords * SCREEN_PIXEL_SIZE * 256.0;
	
	vec4 input = textureLod(SCREEN_TEXTURE, SCREEN_UV + offset, a_strength * 4.0);
	
	COLOR = mix(input, vec4(0.0, 0.0, 0.0, input.a), strength + a_strength);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
