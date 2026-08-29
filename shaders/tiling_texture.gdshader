shader_type canvas_item;

varying vec4 modulate;
varying vec2 world_pos;
uniform float uv_scale = 1000.0;
uniform float rotation_degrees = 0.0;
varying vec2 node_origin;
void vertex() {
	modulate = COLOR;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	node_origin = MODEL_MATRIX[3].xy;   // translation column
}
vec2 rotate(vec2 uv, vec2 pivot, float angle)
{
	mat2 rotation = mat2(vec2(sin(angle), -cos(angle)),
						vec2(cos(angle), sin(angle)));
	
	uv -= pivot;
	uv = uv * rotation;
	uv += pivot;
	return uv;
}
void fragment() {
	COLOR = texture(TEXTURE, rotate(world_pos, node_origin, radians(rotation_degrees)) / uv_scale);
	COLOR *=modulate;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
