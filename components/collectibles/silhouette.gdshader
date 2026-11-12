shader_type canvas_item;

// Pinta só a silhueta (alfa da textura) com a cor do desenho. O AreaCollectible usa
// para a borda clara em volta do sprite; retângulos e círculos saem na cor pedida.

varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	COLOR = vec4(tint.rgb, tint.a * texture(TEXTURE, UV).a);
}
