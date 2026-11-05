@tool
extends EditorPlugin

## Alças no editor 2D para nós que expõem limites ajustáveis (ex.: inimigos).
##
## Contrato (duck typing, sem depender de class_name):
##   editor_handles() -> PackedVector2Array          pontos em coordenadas locais
##   editor_handle_properties() -> PackedStringArray propriedades alteradas pelas alças
##   editor_handle_moved(index, local_pos) -> Dictionary {propriedade: novo valor}
## Opcionais (rotas com vários pontos):
##   editor_insert_point(after_index, local_pos) -> Dictionary
##   editor_remove_point(index) -> Dictionary   ({} = não pode remover)
##
## Uso: arraste uma alça; clique no "+" entre dois pontos para inserir; botão
## direito sobre um ponto para removê-lo. Tudo entra no histórico (Ctrl+Z).

const HANDLE_RADIUS := 7.0
const INSERT_RADIUS := 5.0
const HANDLE_FILL := Color("#f2c14e")
const HANDLE_ACTIVE := Color("#ffffff")
const HANDLE_BORDER := Color("#1b2126")

var _target: Node2D
var _drag_index := -1
var _drag_start := {}


func _handles(object: Object) -> bool:
	return object is Node2D and object.has_method("editor_handles")


func _edit(object: Object) -> void:
	_target = object as Node2D if object != null and _handles(object) else null
	_drag_index = -1
	update_overlays()


func _make_visible(visible: bool) -> void:
	if not visible:
		_target = null
		_drag_index = -1
	update_overlays()


func _forward_canvas_draw_over_viewport(overlay: Control) -> void:
	if not _is_valid():
		return
	var points := _screen_handles()
	if _can_insert():
		for i in points.size() - 1:
			var mid := (points[i] + points[i + 1]) / 2.0
			overlay.draw_circle(mid, INSERT_RADIUS + 1.0, HANDLE_BORDER)
			overlay.draw_circle(mid, INSERT_RADIUS, Color(HANDLE_FILL, 0.6))
			overlay.draw_line(mid - Vector2(3, 0), mid + Vector2(3, 0), HANDLE_BORDER, 2.0)
			overlay.draw_line(mid - Vector2(0, 3), mid + Vector2(0, 3), HANDLE_BORDER, 2.0)
	for i in points.size():
		overlay.draw_circle(points[i], HANDLE_RADIUS + 1.5, HANDLE_BORDER)
		overlay.draw_circle(points[i], HANDLE_RADIUS, HANDLE_ACTIVE if i == _drag_index else HANDLE_FILL)


func _forward_canvas_gui_input(event: InputEvent) -> bool:
	if not _is_valid():
		return false
	if event is InputEventMouseButton:
		return _on_mouse_button(event)
	if event is InputEventMouseMotion and _drag_index >= 0:
		_apply(_target.editor_handle_moved(_drag_index, _to_local(event.position)))
		update_overlays()
		return true
	return false


func _on_mouse_button(event: InputEventMouseButton) -> bool:
	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var hit := _hit_handle(event.position)
		if hit >= 0:
			_drag_index = hit
			_drag_start = _snapshot()
			update_overlays()
			return true
		var segment := _hit_insert(event.position)
		if segment >= 0:
			_commit("Inserir ponto da rota", _target.editor_insert_point(segment, _to_local(event.position)))
			return true
	elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and _drag_index >= 0:
		_finish_drag()
		return true
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var hit := _hit_handle(event.position)
		if hit >= 0 and _target.has_method("editor_remove_point"):
			_commit("Remover ponto da rota", _target.editor_remove_point(hit))
			return true
	return false


func _finish_drag() -> void:
	var undo := get_undo_redo()
	undo.create_action("Mover limite do inimigo", UndoRedo.MERGE_DISABLE, _target)
	for property: String in _drag_start:
		undo.add_do_property(_target, property, _target.get(property))
		undo.add_undo_property(_target, property, _drag_start[property])
	# Os valores já foram aplicados durante o arraste.
	undo.commit_action(false)
	_drag_index = -1
	_drag_start = {}
	update_overlays()


## Registra a mudança no histórico e aplica.
func _commit(action: String, changes: Dictionary) -> void:
	if changes.is_empty():
		return
	var undo := get_undo_redo()
	undo.create_action(action, UndoRedo.MERGE_DISABLE, _target)
	for property: String in changes:
		undo.add_do_property(_target, property, changes[property])
		undo.add_undo_property(_target, property, _target.get(property))
	undo.commit_action()
	update_overlays()


func _apply(changes: Dictionary) -> void:
	for property: String in changes:
		_target.set(property, changes[property])


func _snapshot() -> Dictionary:
	var values := {}
	for property: String in _target.editor_handle_properties():
		values[property] = _target.get(property)
	return values


func _is_valid() -> bool:
	return is_instance_valid(_target) and _target.is_inside_tree()


func _can_insert() -> bool:
	return _target.has_method("editor_insert_point")


## Local do nó -> tela do viewport do editor (inclui zoom e rolagem).
func _screen_transform() -> Transform2D:
	return _target.get_viewport_transform() * _target.get_global_transform_with_canvas()


func _screen_handles() -> PackedVector2Array:
	var xform := _screen_transform()
	var result := PackedVector2Array()
	for point in _target.editor_handles():
		result.append(xform * point)
	return result


func _to_local(screen_position: Vector2) -> Vector2:
	return _screen_transform().affine_inverse() * screen_position


func _hit_handle(screen_position: Vector2) -> int:
	var points := _screen_handles()
	# De trás para frente: a alça desenhada por cima tem prioridade.
	for i in range(points.size() - 1, -1, -1):
		if points[i].distance_to(screen_position) <= HANDLE_RADIUS + 3.0:
			return i
	return -1


func _hit_insert(screen_position: Vector2) -> int:
	if not _can_insert():
		return -1
	var points := _screen_handles()
	for i in points.size() - 1:
		if ((points[i] + points[i + 1]) / 2.0).distance_to(screen_position) <= INSERT_RADIUS + 3.0:
			return i
	return -1
