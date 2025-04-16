shader_type canvas_item;

uniform vec4 old_color : hint_color;
uniform vec4 new_color : hint_color;

void fragment() {
    vec4 curr_color = texture(TEXTURE,UV); // Get current color of pixel

    if (distance(curr_color, old_color) < 0.1) {
        COLOR = new_color;
    } else {
        COLOR = curr_color;
    }
}