class_name NewspaperCrossword
extends PanelContainer

## Jornal de fim de fase: cabeçalho, uma matéria com foto e a cruzadinha como
## passatempo. Cada fase instancia esta cena e configura textos, foto e o JSON
## da cruzadinha. Expõe a mesma API da CrosswordBoard (`check_answers`,
## `select_word`, `completed`, `answer_checked`) para quem controla a página.

signal completed
signal answer_checked(correct: bool)

const BOARD_PATH := ^"Page/Body/Puzzle/Board"

@export var newspaper_name := "A Gazeta da Vila"
@export var edition := "Edição nº 1"
@export var tagline := "Notícias que reciclam"
@export var headline := ""
@export_multiline var article := ""
@export var photo: Texture2D
@export var photo_caption := ""
@export var puzzle_title := "Cruzadinha"
## Instrução exibida na linha de status da cruzadinha até a primeira verificação.
@export var puzzle_hint := "Escolha uma pista e preencha uma letra por casa."
@export_file("*.json") var puzzle_file := ""

@onready var board: CrosswordBoard = get_node(BOARD_PATH)


func _enter_tree() -> void:
	# A cruzadinha lê `puzzle_file` no próprio _ready, que roda antes deste.
	var crossword := get_node_or_null(BOARD_PATH) as CrosswordBoard
	if crossword and not puzzle_file.is_empty():
		crossword.puzzle_file = puzzle_file


func _ready() -> void:
	%Name.text = newspaper_name
	%Edition.text = edition
	%Tagline.text = tagline
	%Headline.text = headline
	%Article.text = article
	%Caption.text = photo_caption
	%PuzzleTitle.text = puzzle_title
	%Photo.texture = photo
	%Photo.visible = photo != null
	%Caption.visible = photo != null and not photo_caption.is_empty()
	if not puzzle_hint.is_empty() and board.status:
		board.status.text = puzzle_hint
	board.completed.connect(completed.emit)
	board.answer_checked.connect(answer_checked.emit)


func check_answers() -> void:
	board.check_answers()


func select_word(index: int) -> void:
	board.select_word(index)


## Texto da matéria para leitura em voz alta (leitor de tela).
func spoken_summary() -> String:
	return "%s. %s. %s %s" % [newspaper_name, headline, article, puzzle_title]
