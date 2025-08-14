shader_type spatial;
render_mode depth_prepass_alpha;

//쉐이더 컨트롤
instance uniform float controller : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float emission_offset : hint_range(0.0, 0.1);
uniform vec3 emission_col : source_color = vec3(1.0);
uniform float emission_power : hint_range(1.0, 20.0, 0.1);

//기존 재질
uniform sampler2D base_tex : source_color;
uniform vec3 color_hint : source_color = vec3(1.0);
uniform float metallic : hint_range(0.0, 1.0, 0.1);
uniform float roughness : hint_range(0.0, 1.0, 0.1);
uniform sampler2D normal_tex : hint_normal;

//노이즈
uniform sampler2D noise_tex;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	
	//기존 재질 샘플텍스쳐
	vec4 base_sample = texture(base_tex, UV);
	vec4 normal_sample = texture(normal_tex, UV);
	vec4 noise_sample = texture(noise_tex, UV);
	
	float emission_mask;
	
	//컨트롤 값보다 작은 노이즈 픽셀 버리기
	if (noise_sample.r < controller)
		discard;
	
	emission_mask = step(noise_sample.r, controller + emission_offset);
	
	ALBEDO = base_sample.rgb * color_hint;
	//ALBEDO = noise_sample.rgb;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	ALPHA;
	EMISSION = emission_col * emission_mask * emission_power;
	NORMAL_MAP = normal_sample.rgb;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
