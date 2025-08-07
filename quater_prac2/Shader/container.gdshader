shader_type spatial;

uniform sampler2D Base_col;
uniform sampler2D col_mask;
uniform vec3 color_hint : source_color = vec3(1.0);
uniform vec3 color_hint2 : source_color = vec3(1.0);
uniform sampler2D ARM;
uniform sampler2D Normal : hint_normal;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec3 albedo = texture(Base_col, UV).rgb;
	float mask_col = texture(col_mask, UV).r;
	vec3 arm = texture(ARM, UV).rgb;
	vec4 normal = texture(Normal, UV);
	
	vec3 albedo_painter = mix(albedo * color_hint, albedo * color_hint2, mask_col);
	
	ALBEDO = albedo_painter;
	AO = arm.r;
	ROUGHNESS = arm.g;
	METALLIC = arm.b;
	NORMAL_MAP = normal.rgb;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
