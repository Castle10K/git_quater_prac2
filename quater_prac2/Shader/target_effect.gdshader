shader_type spatial;
render_mode unshaded;

uniform vec3 base_col : source_color = vec3(1.0);
uniform vec3 attack_col : source_color = vec3(1.0);
uniform float color_power : hint_range(1.0, 20.0, 0.1) = 1.0;

//코드 조정용 스케일, 색상 팩터
uniform float factor : hint_range(0.0, 1.0) = 1.0;

//base_col attack_col -> mix_col 순으로
void vertex() {
	VERTEX = mix(VERTEX, VERTEX * 0.7, factor);
}

void fragment() {
	vec3 final_col = vec3(1.0);

	vec3 mix_col = mix(base_col, attack_col, factor);

	float fresnel = pow((1.0 - dot(VIEW, NORMAL)),3.0);
	ALBEDO = mix_col * color_power;
	ALPHA = fresnel;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
