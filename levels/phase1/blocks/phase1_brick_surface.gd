@tool
extends NinePatchRect
class_name Phase1BrickSurface

## Arte de tijolos de um bloco do Blockout (9-slice em modo tile).
## Acompanha sozinha o retângulo da colisão do nó irmão "Shape": para mudar
## um bloco, altere só o RectangleShape2D. Fica mais limpa conforme os REEE.
const BLEND_SHADER := preload("res://levels/phase1/background/pollution_blend.gdshader")

@export var clean_texture: Texture2D:
	set(value):
		clean_texture = value
		if _material:
			_material.set_shader_parameter("clean_texture", value)
## 0 = limpa de forma gradual a cada coleta; 0.2…1.0 = de uma vez no degrau.
@export_range(0.0, 1.0, 0.05) var restore_step := 0.0
@export var shape_path := NodePath("../Shape")
## Esconde a borda lateral quando outro bloco de mesma textura encosta deste lado
## (evita a linha preta na emenda entre trechos de chão).
@export var auto_seams := true
## Largura da borda lateral no atlas (colunas de contorno/sombra).
@export var edge_width := 4

var _material: ShaderMaterial
var _background: Phase1Background

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_material = ShaderMaterial.new()
	_material.shader = BLEND_SHADER
	_material.set_shader_parameter("clean_texture", clean_texture)
	_material.set_shader_parameter("use_mask", false)
	material = _material
	_fit_to_shape()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_fit_to_shape()
	if not is_instance_valid(_background):
		_background = get_tree().get_first_node_in_group("phase1_background") as Phase1Background
		if _background == null:
			return
	_material.set_shader_parameter("progress", Phase1Background.restore_factor(_background.shown_progress(), restore_step))

## Retângulo da colisão no espaço do corpo (StaticBody2D).
func shape_rect() -> Rect2:
	var shape_node := get_node_or_null(shape_path) as CollisionShape2D
	if shape_node == null or not shape_node.shape is RectangleShape2D:
		return Rect2()
	var extent := (shape_node.shape as RectangleShape2D).size
	return Rect2((shape_node.position - extent / 2.0).round(), extent.round())

## Mesmo retângulo, no espaço do nó que agrupa os blocos (Blockout).
func block_rect() -> Rect2:
	var body := get_parent() as Node2D
	var rect := shape_rect()
	return Rect2(rect.position + (body.position if body else Vector2.ZERO), rect.size)

func _fit_to_shape() -> void:
	var rect := shape_rect()
	if rect.size == Vector2.ZERO:
		return
	if position != rect.position:
		position = rect.position
	if size != rect.size:
		size = rect.size
	_update_seams()

func _update_seams() -> void:
	if texture == null:
		return
	var seam_left := false
	var seam_right := false
	var mine := block_rect()
	var group := get_parent().get_parent() if get_parent() else null
	if auto_seams and group:
		for body in group.get_children():
			var other := body.get_node_or_null("Tijolos") as Phase1BrickSurface
			if other == null or other == self or other.texture != texture:
				continue
			var theirs := other.block_rect()
			var same_top := absf(theirs.position.y - mine.position.y) < 0.5
			if same_top and absf(theirs.end.x - mine.position.x) < 0.5:
				seam_left = true
			if same_top and absf(theirs.position.x - mine.end.x) < 0.5:
				seam_right = true
	var cut_left := edge_width if seam_left else 0
	var cut_right := edge_width if seam_right else 0
	var tex_size := texture.get_size()
	var region := Rect2(cut_left, 0, tex_size.x - cut_left - cut_right, tex_size.y)
	if region_rect != region:
		region_rect = region
	patch_margin_left = 0 if seam_left else edge_width
	patch_margin_right = 0 if seam_right else edge_width
