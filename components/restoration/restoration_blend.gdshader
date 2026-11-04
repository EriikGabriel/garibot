shader_type canvas_item;

// Mistura a versão suja (TEXTURE) com a limpa. Na máscara, pixel transparente
// muda de forma gradual; pixel cinza é restaurado no degrau indicado (51 = 1/5 … 255 = 5/5).
uniform sampler2D clean_texture : filter_nearest, repeat_enable;
uniform sampler2D progress_mask : filter_nearest, repeat_enable;
uniform bool use_mask = false;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float step_softness : hint_range(0.01, 1.0) = 0.2;

void fragment() {
	vec4 dirty = texture(TEXTURE, UV);
	vec4 clean = texture(clean_texture, UV);
	float amount = progress;
	if (use_mask) {
		vec4 mask = texture(progress_mask, UV);
		if (mask.a > 0.5) {
			amount = smoothstep(mask.r - step_softness, mask.r, progress);
		}
	}
	// Mistura pré-multiplicada: sem transparência no meio da troca.
	vec4 mixed = mix(vec4(dirty.rgb * dirty.a, dirty.a), vec4(clean.rgb * clean.a, clean.a), amount);
	COLOR = mixed.a > 0.0001 ? vec4(mixed.rgb / mixed.a, mixed.a) : vec4(0.0);
}
