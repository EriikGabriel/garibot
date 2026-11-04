@tool
class_name BlockSurface
extends NinePatchRect

## Arte 9-slice de um bloco. Copia o retângulo da colisão do nó irmão `Shape`,
## então para mudar um bloco basta alterar o RectangleShape2D.

@export var clean_texture: Texture2D
## 0 = acompanha o progresso; 0.2…1.0 = restaura de uma vez no 1º…5º REEE.
@export_range(0.0, 1.0, 0.05) var restore_step := 0.0
@export var shape_path := NodePath("../Shape")
## Omite a borda lateral quando outro bloco com a mesma textura encosta daquele lado.
@export var auto_seams := true
@export var edge_width := 4


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fit_to_shape()
	if Engine.is_editor_hint():
		return
	material = RestorationProgress.create_material(clean_texture)
	RestorationProgress.connect_to(self, _on_progress)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_fit_to_shape()


func shape_rect() -> Rect2:
	var shape_node := get_node_or_null(shape_path) as CollisionShape2D
	if shape_node == null or not shape_node.shape is RectangleShape2D:
		return Rect2()
	var extent: Vector2 = shape_node.shape.size
	return Rect2((shape_node.position - extent / 2.0).round(), extent.round())


## Retângulo no espaço do nó que agrupa os blocos.
func block_rect() -> Rect2:
	var rect := shape_rect()
	var body := get_parent() as Node2D
	if body:
		rect.position += body.position
	return rect


func _on_progress(shown: float) -> void:
	material.set_shader_parameter(
		"progress", RestorationProgress.restore_factor(shown, restore_step)
	)


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
			var other := body.get_node_or_null(NodePath(name)) as BlockSurface
			if other == null or other == self or other.texture != texture:
				continue
			var theirs := other.block_rect()
			if absf(theirs.position.y - mine.position.y) >= 0.5:
				continue
			seam_left = seam_left or absf(theirs.end.x - mine.position.x) < 0.5
			seam_right = seam_right or absf(theirs.position.x - mine.end.x) < 0.5
	var cut_left := edge_width if seam_left else 0
	var cut_right := edge_width if seam_right else 0
	var region := Rect2(
		cut_left, 0, texture.get_width() - cut_left - cut_right, texture.get_height()
	)
	if region_rect != region:
		region_rect = region
	patch_margin_left = edge_width - cut_left
	patch_margin_right = edge_width - cut_right
