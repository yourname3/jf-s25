shader_type canvas_item;

uniform float t;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec2 uv = UV;
	uv.y = UV.y * SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
	uv *= 8.0;
	vec2 sub_uv = mod(uv, vec2(1.0));
	
	float sub_t = t - floor(uv.x) / 3.0 - floor(uv.y) / 3.0;
	
	if(sub_uv.x > sub_t) { discard; }
	COLOR.xy = uv;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
