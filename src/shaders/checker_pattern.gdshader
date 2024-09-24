shader_type canvas_item;

void fragment() {
	// Tile the UVs
	vec2 tiled_uv = UV * vec2(30.0,16.875);

	// Wiggle with Waves
	vec2 waves;
	waves.x = cos(TIME + tiled_uv.y + tiled_uv.x);
	waves.y = sin(TIME + tiled_uv.x)  + (TIME*2.0);

	COLOR = texture(TEXTURE, tiled_uv + waves * 0.05);
}
