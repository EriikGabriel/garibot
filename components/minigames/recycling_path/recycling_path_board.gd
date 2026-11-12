class_name RecyclingPathBoard
extends Control

## "Caminho" em etapas: um objeto (ex.: celular quebrado) percorre estações até virar
## o resultado final (peças novas). Os cartões das etapas ficam embaralhados embaixo e
## a pergunta é sempre a mesma: "qual é o próximo passo?". Tocar no cartão (ou arrastá-lo
## até o caminho) coloca a etapa na próxima vaga; escolher fora de hora mostra uma dica
## específica daquele cartão.
##
## Teclado/controle: os cartões são botões (Tab/setas + Enter). O leitor de tela anuncia
## cada cartão e o resultado. `reduced_motion` desliga balanço, tremida e deslizes.

signal completed
signal answer_checked(correct: bool)

const STATION_SIZE := Vector2(170, 132)
const ARROW_GAP := 56.0
const ICON_SIZE := 64.0
const TOKEN_SIZE := 48.0
const CARD_SIZE := Vector2(340, 104)
const CARD_GAP := 28.0
const CARD_ICON_SIZE := 64.0
const INSTRUCTION_HEIGHT := 32.0
const PATH_Y := 96.0
const CARDS_LABEL_GAP := 20.0
const CARDS_GAP := 34.0
const FEEDBACK_GAP := 14.0
const FEEDBACK_HEIGHT := 48.0
const MOVE_TIME := 0.45
const SHAKE_TIME := 0.3
## Distância (px) que o ponteiro precisa andar para virar "arrastar".
const DRAG_THRESHOLD := 10.0

@export var start_label := "Celular quebrado"
@export var start_icon: Texture2D
@export var end_label := "Peças novas!"
@export var end_icon: Texture2D
## Etapas na ordem certa. As listas abaixo seguem a mesma ordem.
@export var step_names: PackedStringArray
@export var step_descriptions: PackedStringArray
@export var step_icons: Array[Texture2D] = []
## Frase dita ao acertar cada etapa.
@export var step_success: PackedStringArray
## Dica quando o cartão é escolhido antes da hora.
@export var step_too_early: PackedStringArray
## Ordem dos cartões na tela (índices das etapas), para não ficarem já em ordem.
@export var card_order: PackedInt32Array
@export_multiline var instruction_text := "Qual é o próximo passo? Toque no cartão certo ou arraste até o caminho."
@export var cards_caption := "Escolha o próximo passo:"
@export var done_text := "Caminho completo!"
@export var generic_too_early := "Ainda não é a vez desse passo. O que acontece antes?"

@export_group("Cores")
@export var ink := Color("#18252a")
@export var edge := Color("#8d9b77")
@export var paper := Color("#e9e4ca")
@export var active := Color("#e0b75f")
@export var empty := Color("#475453")
@export var wrong := Color("#d0453c")
@export var success := Color("#7fcf6a")

## Próxima etapa esperada (0 = primeira); igual ao total quando terminou.
var next_step := 0
var cards: Array[Button] = []
var feedback: Label

## Posição do celular no caminho, em "estações" (0 = partida). Animada por tween.
var token_station := 0.0:
	set(value):
		token_station = value
		queue_redraw()

var _time := 0.0
var _press_card := -1
var _press_position := Vector2.ZERO
var _dragging := false
var _drag_icon: TextureRect
var _flying_icon: TextureRect
## Ordem dos cartões na tela (índices das etapas).
var _card_slots: Array[int] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if not _has_valid_data():
		push_error("RecyclingPathBoard: configure nomes, descrições e ícones com o mesmo tamanho.")
		return
	_build()


func _process(delta: float) -> void:
	_time += delta
	if not _reduced_motion():
		queue_redraw()


## Coloca o foco no primeiro cartão disponível (navegação por teclado).
func focus_first() -> void:
	for card in cards:
		if card.visible and not card.disabled:
			card.grab_focus()
			return


func is_done() -> bool:
	return next_step >= step_names.size()


# --- Montagem ------------------------------------------------------------------------


func _has_valid_data() -> bool:
	var count := step_names.size()
	return (
		count > 0
		and step_descriptions.size() == count
		and step_icons.size() == count
		and step_success.size() == count
	)


func _station_count() -> int:
	return step_names.size() + 2


func _path_width() -> float:
	var count := _station_count()
	return count * STATION_SIZE.x + (count - 1) * ARROW_GAP


func _cards_width() -> float:
	var count := step_names.size()
	return count * CARD_SIZE.x + (count - 1) * CARD_GAP


func _board_width() -> float:
	return maxf(_path_width(), _cards_width())


func _station_rect(index: int) -> Rect2:
	var x := (_board_width() - _path_width()) / 2.0 + index * (STATION_SIZE.x + ARROW_GAP)
	return Rect2(Vector2(x, PATH_Y), STATION_SIZE)


func _path_rect() -> Rect2:
	var first := _station_rect(0)
	return Rect2(
		first.position - Vector2(0, TOKEN_SIZE + 8.0), Vector2(_path_width(), STATION_SIZE.y + TOKEN_SIZE + 8.0)
	)


func _cards_y() -> float:
	return PATH_Y + STATION_SIZE.y + CARDS_LABEL_GAP + CARDS_GAP


func _build() -> void:
	var width := _board_width()
	var feedback_y := _cards_y() + CARD_SIZE.y + FEEDBACK_GAP
	custom_minimum_size = Vector2(width, feedback_y + FEEDBACK_HEIGHT)

	var instruction := _label(instruction_text, 20)
	instruction.position = Vector2.ZERO
	instruction.size = Vector2(width, INSTRUCTION_HEIGHT)
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var caption := _label(cards_caption, 18)
	caption.position = Vector2(0, PATH_Y + STATION_SIZE.y + CARDS_LABEL_GAP)
	caption.size = Vector2(width, 26)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_color_override("font_color", active)

	var order: Array[int] = []
	for step in step_names.size():
		order.append(card_order[step] if card_order.size() == step_names.size() else step)
	cards.resize(step_names.size())
	_card_slots = order
	for step in order:
		cards[step] = _build_card(step)
	_layout_cards(false)

	feedback = _label("", 19)
	feedback.position = Vector2(0, feedback_y)
	feedback.size = Vector2(width, FEEDBACK_HEIGHT)
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# Ícones que voam por cima de tudo: o arrastado e o que vai para a vaga.
	_drag_icon = _icon_rect(CARD_ICON_SIZE)
	_flying_icon = _icon_rect(CARD_ICON_SIZE)


func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	add_child(label)
	return label


func _icon_rect(icon_size: float) -> TextureRect:
	var rect := TextureRect.new()
	rect.size = Vector2.ONE * icon_size
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.hide()
	add_child(rect)
	return rect


## Cartão = botão com o sprite da etapa, o nome em destaque e o que acontece nela.
func _build_card(step: int) -> Button:
	var card := Button.new()
	card.size = CARD_SIZE
	card.focus_mode = Control.FOCUS_ALL
	card.set_meta("speech_managed", true)
	card.set_meta("audio_cue", &"")
	card.pressed.connect(_choose.bind(step))
	card.focus_entered.connect(_announce_card.bind(step))
	add_child(card)

	var icon := TextureRect.new()
	icon.texture = step_icons[step]
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.position = Vector2(16, (CARD_SIZE.y - CARD_ICON_SIZE) / 2.0)
	icon.size = Vector2.ONE * CARD_ICON_SIZE
	card.add_child(icon)

	var text_x := 16.0 + CARD_ICON_SIZE + 14.0
	var title := Label.new()
	title.text = step_names[step]
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", active)
	title.position = Vector2(text_x, 10)
	title.size = Vector2(CARD_SIZE.x - text_x - 12.0, 28)
	card.add_child(title)

	var description := Label.new()
	description.text = step_descriptions[step]
	description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	description.add_theme_font_size_override("font_size", 15)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.position = Vector2(text_x, 40)
	description.size = Vector2(CARD_SIZE.x - text_x - 12.0, CARD_SIZE.y - 46.0)
	card.add_child(description)
	return card


## Centraliza os cartões que ainda restam (os usados saem da fileira).
func _layout_cards(animated: bool) -> void:
	var remaining: Array[Button] = []
	for step in _card_slots:
		if cards[step].visible:
			remaining.append(cards[step])
	var row := remaining.size() * CARD_SIZE.x + maxi(remaining.size() - 1, 0) * CARD_GAP
	var x := (_board_width() - row) / 2.0
	for card in remaining:
		var target := Vector2(x, _cards_y())
		if animated and not _reduced_motion():
			create_tween().set_trans(Tween.TRANS_SINE).tween_property(card, "position", target, MOVE_TIME)
		else:
			card.position = target
		x += CARD_SIZE.x + CARD_GAP


# --- Interação -----------------------------------------------------------------------


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or is_done():
		_cancel_drag()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_card = _card_under_mouse()
			_press_position = get_local_mouse_position()
		elif _dragging:
			# Soltou fora do cartão: vale se caiu no caminho.
			var step := _press_card
			var dropped_on_path := _path_rect().grow(16).has_point(get_local_mouse_position())
			_cancel_drag()
			get_viewport().set_input_as_handled()
			if dropped_on_path:
				_choose(step)
		else:
			_press_card = -1
	elif event is InputEventMouseMotion and _press_card >= 0:
		var pointer := get_local_mouse_position()
		if not _dragging and pointer.distance_to(_press_position) > DRAG_THRESHOLD:
			_dragging = true
			_drag_icon.texture = step_icons[_press_card]
			_drag_icon.show()
		if _dragging:
			_drag_icon.position = pointer - _drag_icon.size / 2.0
			queue_redraw()


func _card_under_mouse() -> int:
	var mouse := get_global_mouse_position()
	for step in cards.size():
		var card := cards[step]
		if card.visible and not card.disabled and card.get_global_rect().has_point(mouse):
			return step
	return -1


func _cancel_drag() -> void:
	_dragging = false
	_press_card = -1
	if _drag_icon:
		_drag_icon.hide()
	queue_redraw()


func _choose(step: int) -> void:
	if is_done() or step < 0 or not cards[step].visible:
		return
	if step != next_step:
		answer_checked.emit(false)
		var hint := step_too_early[step] if step < step_too_early.size() else ""
		_say(hint if not hint.is_empty() else generic_too_early, wrong)
		_shake(cards[step])
		return
	answer_checked.emit(true)
	var card := cards[step]
	var slot := _station_rect(step + 1)
	var target := slot.position + Vector2((slot.size.x - ICON_SIZE) / 2.0, 14.0)
	card.hide()
	_layout_cards(true)
	next_step += 1
	_say(step_success[step], success)
	_fly_icon(step_icons[step], card.position + Vector2(16, (CARD_SIZE.y - CARD_ICON_SIZE) / 2.0), target)
	_move_token(float(step + 1))
	if is_done():
		_finish()
	else:
		focus_first()


func _finish() -> void:
	# O celular chega à última estação e vira "peças novas".
	var delay := 0.0 if _reduced_motion() else MOVE_TIME
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_callback(func() -> void: _move_token(float(_station_count() - 1)))
	tween.tween_interval(delay)
	tween.tween_callback(_on_finished)


func _on_finished() -> void:
	_say(done_text, success)
	completed.emit()


func _announce_card(step: int) -> void:
	Speech.speak(
		"Cartão: %s. %s. Este é o próximo passo?" % [step_names[step], step_descriptions[step]],
		"minigame"
	)


func _say(text: String, color: Color) -> void:
	feedback.text = text
	feedback.add_theme_color_override("font_color", color)
	Speech.speak(text, "minigame")


# --- Animações -----------------------------------------------------------------------


func _reduced_motion() -> bool:
	return bool(Settings.get_setting("reduced_motion", false))


func _move_token(station: float) -> void:
	if _reduced_motion():
		token_station = station
		return
	create_tween().set_trans(Tween.TRANS_SINE).tween_property(self, "token_station", station, MOVE_TIME)


func _fly_icon(texture: Texture2D, from: Vector2, to: Vector2) -> void:
	if _reduced_motion():
		queue_redraw()
		return
	_flying_icon.texture = texture
	_flying_icon.position = from
	_flying_icon.show()
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_flying_icon, "position", to, MOVE_TIME)
	tween.tween_callback(_flying_icon.hide)


func _shake(card: Control) -> void:
	if _reduced_motion():
		return
	var base := card.position
	var tween := create_tween()
	for offset: float in [-10.0, 9.0, -6.0, 4.0, 0.0]:
		tween.tween_property(card, "position:x", base.x + offset, SHAKE_TIME / 5.0)


# --- Desenho do caminho --------------------------------------------------------------


func _draw() -> void:
	if not _has_valid_data():
		return
	var font := get_theme_default_font()
	var count := _station_count()
	for index in count:
		var rect := _station_rect(index)
		if index < count - 1:
			_draw_arrow(rect, _station_rect(index + 1), index < token_station)
		_draw_station(index, rect, font)
	_draw_token()


func _draw_station(index: int, rect: Rect2, font: Font) -> void:
	var last := _station_count() - 1
	var is_slot := index > 0 and index < last
	var filled := is_slot and index - 1 < next_step
	var reached := index <= token_station + 0.01
	var is_next := is_slot and index - 1 == next_step
	var icon: Texture2D = null
	var label := ""
	if index == 0:
		icon = start_icon
		label = start_label
	elif index == last:
		icon = end_icon
		label = end_label
	elif filled:
		icon = step_icons[index - 1]
		label = step_names[index - 1]

	if is_slot and not filled:
		# Vaga vazia: borda tracejada, número da ordem e "?". A próxima pulsa.
		var pulse := 1.0 if _reduced_motion() else 0.6 + 0.4 * sin(_time * 5.0)
		var color := Color(active, pulse) if is_next else empty
		draw_rect(rect, Color(ink, 0.6))
		_draw_dashed_rect(rect, color, 3.0 if is_next else 2.0)
		draw_string(
			font, rect.get_center() + Vector2(-STATION_SIZE.x / 2.0, 14), "?",
			HORIZONTAL_ALIGNMENT_CENTER, STATION_SIZE.x, 44, color
		)
	else:
		var done_end := index == last and is_done() and reached
		var border := active if (filled or index == 0 or done_end) else empty
		draw_rect(rect, border)
		draw_rect(rect.grow(-3), ink)
	if is_slot:
		draw_string(
			font, rect.position + Vector2(10, 24), "%dº" % index, HORIZONTAL_ALIGNMENT_LEFT, -1, 18,
			active if (filled or is_next) else empty
		)
	if icon:
		var dim := index == last and not (is_done() and reached)
		var tint := Color(0.35, 0.4, 0.42) if dim else Color.WHITE
		var icon_rect := Rect2(rect.position + Vector2((rect.size.x - ICON_SIZE) / 2.0, 14.0), Vector2.ONE * ICON_SIZE)
		draw_texture_rect(icon, icon_rect, false, tint)
		draw_string(
			font, rect.position + Vector2(0, rect.size.y - 18.0), label, HORIZONTAL_ALIGNMENT_CENTER,
			rect.size.x, 17, paper if not dim else empty
		)
	if index == last and is_done() and reached:
		_draw_sparkles(rect)


func _draw_arrow(from_rect: Rect2, to_rect: Rect2, travelled: bool) -> void:
	var y := from_rect.get_center().y
	var start := Vector2(from_rect.end.x + 8.0, y)
	var finish := Vector2(to_rect.position.x - 10.0, y)
	var color := active if travelled else empty
	draw_line(start, finish, color, 4.0)
	draw_colored_polygon(
		PackedVector2Array([finish + Vector2(4, 0), finish + Vector2(-8, -9), finish + Vector2(-8, 9)]), color
	)


func _draw_token() -> void:
	if start_icon == null or (is_done() and token_station >= _station_count() - 1.01):
		return
	var from_index := floori(token_station)
	var to_index := mini(from_index + 1, _station_count() - 1)
	var t := token_station - from_index
	var center := _station_rect(from_index).get_center().lerp(_station_rect(to_index).get_center(), t)
	var bob := 0.0 if _reduced_motion() else sin(_time * 4.0) * 3.0
	# Pulinho no meio do trajeto entre duas estações.
	var hop := sin(t * PI) * 18.0
	var top_left := Vector2(
		center.x - TOKEN_SIZE / 2.0, PATH_Y - TOKEN_SIZE - 6.0 + bob - hop
	)
	draw_texture_rect(start_icon, Rect2(top_left, Vector2.ONE * TOKEN_SIZE), false)


func _draw_dashed_rect(rect: Rect2, color: Color, width: float) -> void:
	var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	for i in 4:
		draw_dashed_line(corners[i], corners[(i + 1) % 4], color, width, 10.0)


func _draw_sparkles(rect: Rect2) -> void:
	for i in 4:
		var angle := TAU * i / 4.0 + (0.0 if _reduced_motion() else _time * 1.5)
		var spot := (rect.get_center() + Vector2.from_angle(angle) * (ICON_SIZE * 0.7)).round()
		var arm := 3.0
		draw_rect(Rect2(spot - Vector2(arm, 1), Vector2(arm * 2.0, 2)), paper)
		draw_rect(Rect2(spot - Vector2(1, arm), Vector2(2, arm * 2.0)), paper)
