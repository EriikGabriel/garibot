shader_type canvas_item;

// Mistura a versão suja (textura do Sprite2D) com a limpa conforme os REEE coletados.
// Máscara: pixel cinza = objeto restaurado no degrau indicado (51 = 1/5 ... 255 = 5/5);
// pixel transparente = muda gradualmente com o progresso (céu, terreno, água).
uniform sampler2D clean_texture : filter_nearest, repeat_enable;
uniform sampler2D progress_mask : filter_nearest, repeat_enable;
uniform bool use_mask = true;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float step_softness : hint_range(0.01, 1.0) = 0.2;

void fragment() {
	vec4 dirty = texture(TEXTURE, UV);
	vec4 clean = texture(clean_texture, UV);
	float f = progress;
	if (use_mask) {
		vec4 m = texture(progress_mask, UV);
		if (m.a > 0.5) {
			f = smoothstep(m.r - step_softness, m.r, progress);
		}
	}
	// Mistura pré-multiplicada: onde as duas versões são opacas, não há transparência no meio da troca.
	vec4 a = vec4(dirty.rgb * dirty.a, dirty.a);
	vec4 b = vec4(clean.rgb * clean.a, clean.a);
	vec4 r = mix(a, b, f);
	COLOR = r.a > 0.0001 ? vec4(r.rgb / r.a, r.a) : vec4(0.0);
}
