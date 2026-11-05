class_name Phase1Minigames
extends CanvasLayer

## Modal de atividades da fase 1. As páginas exibidas (e a ordem) vêm de `pages`,
## definido antes de adicionar a cena à árvore.

## Emitido ao fechar. `perfect` é verdadeiro se nenhuma atividade foi pulada.
signal finished(perfect: bool)

const PAGE_CROSSWORD := &"cruzadinha"
const PAGE_MATCHING := &"associacao"
const PAGE_SORTING := &"triagem"

@export var pages: Array[StringName] = [PAGE_CROSSWORD, PAGE_MATCHING]
@export var final_title := "Missão concluída!"
@export_multiline var final_message := (
	"Você aprendeu que resíduos eletrônicos possuem materiais valiosos e precisam de coleta e reciclagem adequadas."
)
@export var final_button_text := "Concluir fase"

var _active_pages: Array[Control] = []
## Nome de cada página na telemetria.
var _page_ids := {}
var _index := -1
var _perfect := true

@onready var crossword: NewspaperCrossword = $Backdrop/Panel/Margin/Body/WordPage/Newspaper
@onready var word_page: Control = $Backdrop/Panel/Margin/Body/WordPage
@onready var match_page: Control = $Backdrop/Panel/Margin/Body/MatchPage
@onready var sort_page: Control = $Backdrop/Panel/Margin/Body/SortPage
@onready var final_page: Control = $Backdrop/Panel/Margin/Body/FinalPage
@onready var word_feedback: Label = $Backdrop/Panel/Margin/Body/WordPage/Feedback
@onready var check_button: Button = $Backdrop/Panel/Margin/Body/WordPage/Actions/Check
@onready var next_button: Button = $Backdrop/Panel/Margin/Body/WordPage/Actions/Next
@onready var matching_board: MatchingBoard = $Backdrop/Panel/Margin/Body/MatchPage/MatchingBoard
@onready var sort_board: MatchingBoard = $Backdrop/Panel/Margin/Body/SortPage/SortBoard
@onready var finish_button: Button = $Backdrop/Panel/Margin/Body/FinalPage/Finish


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	add_to_group("minigame_modal")
	matching_board.completed.connect(_on_board_completed.bind(match_page))
	matching_board.answer_checked.connect(_on_answer_checked)
	sort_board.completed.connect(_on_board_completed.bind(sort_page))
	sort_board.answer_checked.connect(_on_answer_checked)
	crossword.answer_checked.connect(_on_answer_checked)
	crossword.completed.connect(_on_crossword_completed)
	check_button.set_meta("audio_cue", &"")
	for page: Control in [word_page, match_page, sort_page, final_page]:
		page.hide()
	var by_name := {
		PAGE_CROSSWORD: word_page,
		PAGE_MATCHING: match_page,
		PAGE_SORTING: sort_page,
	}
	for page_name in pages:
		if by_name.has(page_name):
			_active_pages.append(by_name[page_name])
			_page_ids[by_name[page_name]] = str(page_name)
	$Backdrop/Panel/Margin/Body/FinalPage/Title.text = final_title
	$Backdrop/Panel/Margin/Body/FinalPage/Message.text = final_message
	finish_button.text = final_button_text
	_advance()


func _advance() -> void:
	if _index >= 0 and _index < _active_pages.size():
		_active_pages[_index].hide()
	_index += 1
	if _index >= _active_pages.size():
		final_page.show()
		finish_button.grab_focus()
		_announce_final_page()
		return
	var page := _active_pages[_index]
	page.show()
	if page == word_page:
		crossword.select_word.call_deferred(0)
	elif page == match_page:
		matching_board.left_buttons[0].grab_focus()
	elif page == sort_page:
		sort_board.left_buttons[0].grab_focus()


func _on_check_pressed() -> void:
	crossword.check_answers()


func _on_answer_checked(correct: bool) -> void:
	GameAudio.play_sound(&"correct" if correct else &"incorrect")
	Analytics.track("minigame_resposta", {"atividade": _current_page_id(), "correta": correct})


func _on_crossword_completed() -> void:
	GameAudio.play_sound(&"completed")
	word_feedback.show()
	word_feedback.text = "Muito bem!"
	check_button.hide()
	next_button.show()
	next_button.grab_focus()


func _on_next_pressed() -> void:
	_advance()


func _on_board_completed(page: Control) -> void:
	await get_tree().create_timer(0.8, true).timeout
	if not page.visible:
		return
	GameAudio.play_sound(&"victory")
	_advance()


func _on_skip_pressed() -> void:
	Analytics.track("minigame_pulou", {"atividade": _current_page_id()})
	_perfect = false
	_advance()


func _announce_final_page() -> void:
	Speech.speak(
		(
			final_title
			+ " "
			+ final_message
			+ " Selecione %s para continuar." % final_button_text
		),
		"minigame"
	)


func _on_finish_pressed() -> void:
	Speech.stop()
	get_tree().paused = false
	finished.emit(_perfect)
	queue_free()


func _current_page_id() -> String:
	if _index >= 0 and _index < _active_pages.size():
		return _page_ids.get(_active_pages[_index], "")
	return ""
