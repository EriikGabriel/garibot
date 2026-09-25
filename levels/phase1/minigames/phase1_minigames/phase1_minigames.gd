extends CanvasLayer

signal finished

@onready var crossword = $Backdrop/Panel/Margin/Body/WordPage/Crossword

@onready var word_page: Control = $Backdrop/Panel/Margin/Body/WordPage
@onready var match_page: Control = $Backdrop/Panel/Margin/Body/MatchPage
@onready var final_page: Control = $Backdrop/Panel/Margin/Body/FinalPage
@onready var word_feedback: Label = $Backdrop/Panel/Margin/Body/WordPage/Feedback
@onready var check_button: Button = $Backdrop/Panel/Margin/Body/WordPage/Actions/Check
@onready var next_button: Button = $Backdrop/Panel/Margin/Body/WordPage/Actions/Next
@onready var matching_board: MatchingBoard = $Backdrop/Panel/Margin/Body/MatchPage/MatchingBoard
@onready var finish_button: Button = $Backdrop/Panel/Margin/Body/FinalPage/Finish

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	matching_board.completed.connect(_on_matching_completed)
	matching_board.answer_checked.connect(_on_answer_checked)
	crossword.answer_checked.connect(_on_answer_checked)
	check_button.set_meta("audio_cue", &"")
	add_to_group("minigame_modal")
	crossword.completed.connect(_on_crossword_completed)
	crossword.select_word.call_deferred(0)

func _on_check_pressed() -> void:
	crossword.check_answers()

func _on_answer_checked(correct: bool) -> void:
	GameAudio.play_sound(&"correct" if correct else &"incorrect")

func _on_crossword_completed() -> void:
	GameAudio.play_sound(&"completed")
	word_feedback.show()
	word_feedback.text = "Muito bem! Agora vamos conhecer o caminho da reciclagem."
	check_button.hide()
	next_button.show()
	next_button.grab_focus()

func _on_next_pressed() -> void:
	word_page.hide()
	match_page.show()
	matching_board.left_buttons[0].grab_focus()

func _on_matching_completed() -> void:
	await get_tree().create_timer(0.8, true).timeout
	if not match_page.visible:
		return
	GameAudio.play_sound(&"victory")
	match_page.hide()
	final_page.show()
	finish_button.grab_focus()

func _on_skip_pressed() -> void:
	if word_page.visible:
		_on_next_pressed()
		return
	match_page.hide()
	final_page.show()
	finish_button.grab_focus()

func _on_finish_pressed() -> void:
	get_tree().paused = false
	finished.emit()
	queue_free()
