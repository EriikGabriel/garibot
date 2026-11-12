class_name AreaCollectible
extends Area2D

## Item coletado ao ser tocado por um corpo do grupo `collector_group`.
##
## Com `highlight`, o item se destaca do cenário: brilho pulsante ao fundo, borda clara
## em volta do sprite (filho `AnimatedSprite2D` ou `Sprite2D`) e faíscas piscando.

signal collected(item_name: String)

const SILHOUETTE_SHADER := preload("res://components/collectibles/silhouette.gdshader")
const SPARKLE_COUNT := 3

@export var item_name := "resíduo eletrônico"
@export var collection_group := &"collectibles"
@export var collector_group := &"player"

@export_group("Destaque")
@export var highlight := true
## Borda de 1 px em volta do sprite.
@export var outline_color := Color("#fff6cf")
@export var glow_color := Color("#ffe58a")
## Raio do brilho (px), medido a partir do centro do sprite.
@export var glow_radius := 21.0
## Pulsos do brilho por segundo (em radianos/s).
@export var pulse_speed := 3.0
@export var sparkle_color := Color("#fffbe6")

var _collected := false
var _time := 0.0
var _sprite: Node2D


func _ready() -> void:
	if not collection_group.is_empty():
		add_to_group(collection_group)
	body_entered.connect(_on_body_entered)
	_sprite = _find_sprite()
	if highlight and _sprite:
		var shader_material := ShaderMaterial.new()
		shader_material.shader = SILHOUETTE_SHADER
		material = shader_material
	set_process(highlight and _sprite != null)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


## Primeiro quadro do sprite, para ícones de HUD.
func get_icon() -> Texture2D:
	if _sprite == null:
		_sprite = _find_sprite()
	if _sprite is AnimatedSprite2D:
		var animated := _sprite as AnimatedSprite2D
		if animated.sprite_frames and animated.sprite_frames.get_frame_count(animated.animation) > 0:
			return animated.sprite_frames.get_frame_texture(animated.animation, 0)
	elif _sprite is Sprite2D:
		return (_sprite as Sprite2D).texture
	return null


func _on_body_entered(body: Node2D) -> void:
	if _collected or not body.is_in_group(collector_group):
		return
	_collected = true
	set_deferred("monitoring", false)
	collected.emit(item_name)
	queue_free()


func _find_sprite() -> Node2D:
	for child in get_children():
		if child is AnimatedSprite2D or child is Sprite2D:
			return child
	return null


func _draw() -> void:
	if not highlight or _sprite == null:
		return
	var still := bool(Settings.get_setting("reduced_motion", false))
	var pulse := 0.5 if still else 0.5 + 0.5 * sin(_time * pulse_speed)
	var center := _sprite.position
	# Brilho em anéis de pixel (mais forte no meio), crescendo de leve com o pulso.
	var radius := glow_radius * (0.9 + 0.1 * pulse)
	for ring in 3:
		var alpha := (0.14 + 0.08 * ring) * (0.6 + 0.4 * pulse)
		_draw_pixel_disc(center, roundi(radius * (1.0 - ring * 0.27)), Color(glow_color, alpha))
	_draw_outline()
	for i in SPARKLE_COUNT:
		var angle := (0.0 if still else _time * 0.7) + TAU * i / SPARKLE_COUNT - PI / 2.0
		var twinkle := 0.6 if still else 0.5 + 0.5 * sin(_time * 4.0 + i * 2.1)
		var spot := (center + Vector2.from_angle(angle) * glow_radius * 0.95).round()
		_draw_sparkle(spot, twinkle)


## Desenha o quadro atual do sprite deslocado 1 px nas 4 direções, em silhueta clara.
func _draw_outline() -> void:
	var texture: Texture2D
	var top_left := _sprite.position
	if _sprite is AnimatedSprite2D:
		var animated := _sprite as AnimatedSprite2D
		texture = animated.sprite_frames.get_frame_texture(animated.animation, animated.frame)
		top_left += animated.offset - (texture.get_size() / 2.0 if animated.centered else Vector2.ZERO)
	else:
		var sprite := _sprite as Sprite2D
		texture = sprite.texture
		if texture:
			top_left += sprite.offset - (texture.get_size() / 2.0 if sprite.centered else Vector2.ZERO)
	if texture == null:
		return
	for direction: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		draw_texture(texture, top_left + direction, outline_color)


func _draw_pixel_disc(center: Vector2, radius: int, color: Color) -> void:
	for y in range(-radius, radius + 1):
		var half := floori(sqrt(float(radius * radius - y * y)) + 0.5)
		draw_rect(Rect2(center.x - half, center.y + y, half * 2, 1), color)


func _draw_sparkle(spot: Vector2, strength: float) -> void:
	var color := Color(sparkle_color, strength)
	draw_rect(Rect2(spot, Vector2.ONE), color)
	var arm := 2 if strength > 0.7 else 1
	for i in range(1, arm + 1):
		var faded := Color(sparkle_color, strength * (0.7 if i == 1 else 0.4))
		for direction: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			draw_rect(Rect2(spot + direction * i, Vector2.ONE), faded)
