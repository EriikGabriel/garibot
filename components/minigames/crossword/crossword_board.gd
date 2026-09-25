extends ScrollContainer
## Cada entrada define answer, clue, start (Vector2i) e vertical.
signal completed
@export var entries: Array[Dictionary] = []
@export_file("*.json") var puzzle_file := ""
@export_range(56, 96) var cell_size := 64
@export_range(36, 56) var minimum_cell_size := 36
@export_range(160, 300) var clue_minimum_width := 200
@export_range(1, 4) var maximum_clue_columns := 2
const GENERATOR = preload("res://components/minigames/crossword/crossword_generator.gd")
var cells: Dictionary = {}
var solution: Dictionary = {}
var paths: Array = []
var active_word := 0
var solved := false
var status: Label
@onready var layout: BoxContainer = $Layout
@onready var grid: GridContainer = $Layout/Grid
@onready var clue_panel: VBoxContainer = $Layout/CluePanel
@onready var clues: GridContainer = $Layout/CluePanel/Clues
var grid_height := 0

func _ready() -> void:
	follow_focus = true
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size.y = 240
	var warning := ""
	if not puzzle_file.is_empty():
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(puzzle_file))
		if not data is Dictionary or not data.get("words") is Array:
			push_error("Cruzadinha: JSON inválido: " + puzzle_file)
			return
		var generated: Dictionary = GENERATOR.generate(data["words"])
		entries.assign(generated["entries"])
		if not generated["unplaced"].is_empty():
			warning = "Não entraram na grade: " + ", ".join(generated["unplaced"])
			push_warning(warning)
	if entries.is_empty():
		return
	var width := 0
	var height := 0
	for entry in entries:
		var path: Array[Vector2i] = []
		var answer: String = entry["answer"]
		var direction := Vector2i.DOWN if entry["vertical"] else Vector2i.RIGHT
		for i in answer.length():
			var point: Vector2i = entry["start"] + direction * i
			assert(not solution.has(point) or solution[point] == answer[i], "Cruzamento incompatível")
			solution[point] = answer[i]
			path.append(point)
			width = maxi(width, point.x + 1)
			height = maxi(height, point.y + 1)
		paths.append(path)
	grid.columns = width
	grid_height = height
	for y in height:
		for x in width:
			var point := Vector2i(x, y)
			var slot := Control.new()
			slot.custom_minimum_size = Vector2(cell_size, cell_size)
			grid.add_child(slot)
			if not solution.has(point):
				continue
			var field := LineEdit.new()
			field.alignment = HORIZONTAL_ALIGNMENT_CENTER
			field.max_length = 1
			field.expand_to_text_length = false
			field.theme_type_variation = &"CrosswordCell"
			slot.add_child(field)
			field.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			field.add_theme_font_size_override("font_size", 22)
			field.offset_top = 10
			cells[point] = field
			field.focus_entered.connect(_focus_cell.bind(point))
			field.text_changed.connect(_edit_cell.bind(point))
			for i in entries.size():
				if entries[i]["start"] == point:
					var number := Label.new()
					number.text = str(i + 1)
					number.add_theme_font_size_override("font_size", 14)
					number.add_theme_color_override("font_color", Color("#ffdf8c"))
					number.mouse_filter = Control.MOUSE_FILTER_IGNORE
					slot.add_child(number)
	for i in entries.size():
		var clue := Button.new()
		clue.text = "%d. %s • %d letras\n%s" % [i + 1, "Vertical" if entries[i]["vertical"] else "Horizontal", str(entries[i]["answer"]).length(), entries[i]["clue"]]
		clue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		clue.custom_minimum_size = Vector2(clue_minimum_width, 76)
		clue.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		clue.add_theme_font_size_override("font_size", 18)
		clue.pressed.connect(select_word.bind(i))
		clues.add_child(clue)
	status = $Layout/CluePanel/Status
	status.text = warning if not warning.is_empty() else "Escolha uma pista e preencha uma letra por casa."
	resized.connect(_fit_layout)
	_fit_layout.call_deferred()

func _fit_layout() -> void:
	if grid_height == 0:
		return
	var gap := layout.get_theme_constant("separation")
	var cell_gap := grid.get_theme_constant("h_separation")
	var minimum_grid_width := grid.columns * minimum_cell_size + (grid.columns - 1) * cell_gap
	var side_by_side := size.x >= minimum_grid_width + clue_minimum_width * 2 + gap + 24
	layout.vertical = not side_by_side
	var grid_width := maxf(minimum_grid_width, size.x * 0.48) if side_by_side else size.x
	var clue_width := size.x - grid_width - gap if side_by_side else size.x
	clues.columns = clampi(int((clue_width + 12) / (clue_minimum_width + 12)), 1, maximum_clue_columns)
	# Reserve room for the clue cards when the screen requires a stacked layout.
	var grid_available_height := size.y if side_by_side else size.y - clue_panel.get_combined_minimum_size().y - gap
	var fitted := minf((grid_width - (grid.columns - 1) * cell_gap) / grid.columns,
		(grid_available_height - (grid_height - 1) * cell_gap) / grid_height)
	var side := clampf(floorf(fitted), minimum_cell_size, cell_size)
	for slot in grid.get_children():
		slot.custom_minimum_size = Vector2(side, side)

func select_word(index: int) -> void:
	if index < 0 or index >= paths.size():
		return
	active_word = index
	cells[paths[index][0]].grab_focus()

func _focus_cell(point: Vector2i) -> void:
	if not paths[active_word].has(point):
		for i in paths.size():
			if paths[i].has(point):
				active_word = i
				break
	for key in cells:
		cells[key].modulate = Color("#ffe29b") if paths[active_word].has(key) else Color.WHITE
	cells[point].select_all()

func _edit_cell(value: String, point: Vector2i) -> void:
	var letter := value.to_upper()
	if not letter.is_empty() and (letter.unicode_at(0) < 65 or letter.unicode_at(0) > 90):
		letter = ""
	cells[point].text = letter
	if not letter.is_empty():
		var index: int = paths[active_word].find(point)
		if index + 1 < paths[active_word].size():
			cells[paths[active_word][index + 1]].grab_focus()

func check_answers() -> void:
	if solution.is_empty():
		return
	var correct := 0
	for point in solution:
		if cells[point].text == solution[point]:
			correct += 1
	if correct == solution.size():
		status.text = "Tudo certo! Cruzadinha concluída."
		if not solved:
			solved = true
			completed.emit()
	else:
		status.text = "%d de %d letras corretas. Revise as pistas e tente novamente." % [correct, solution.size()]
