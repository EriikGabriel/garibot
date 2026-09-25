shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float brightness : hint_range(0.5, 1.25, 0.05) = 1.0;

void fragment() {
	vec4 screen_color = texture(screen_texture, SCREEN_UV);
	COLOR = vec4(screen_color.rgb * brightness, screen_color.a);
}
