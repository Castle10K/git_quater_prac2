shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D base_texture;
uniform vec3 color_hint : source_color = vec3(1.0);
uniform float color_power : hint_range(1.0, 20.0, 0.1);

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 origin_tex_col = texture(base_texture, UV);
	float base_alpha = origin_tex_col.a;
	
	vec3 base_col = origin_tex_col.rgb;
	
	ALBEDO = base_col * color_hint * color_power;
	ALPHA = base_alpha;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
