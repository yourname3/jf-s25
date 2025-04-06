shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec2 thing = 2.0 * (UV - vec2(0.5));
	vec2 offset = dot(thing, thing) * thing * SCREEN_PIXEL_SIZE * 128.0;
	
	vec4 input = texture(SCREEN_TEXTURE, SCREEN_UV + offset);
	
	COLOR = input;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
