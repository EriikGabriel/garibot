extends ScrollContainer
## Cada entrada define answer, clue, start (Vector2i) e vertical.
signal completed
@export var entries: Array[Dictionary] = []
@export_file("*.json") var puzzle_file := ""
@export_range(56, 96) var cell_size := 64
const GENERATOR = preload("res://components/minigames/crossword/crossword_generator.gd")
var cells: Dictionary = {}
var solution: Dictionary = {}
var paths: Array = []
var active_word := 0
var solved := false
var status: Label

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
	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 28)
	add_child(layout)
	var grid := GridContainer.new()
	grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
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
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	layout.add_child(grid)
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
			field.offset_top = 18
			slot.custom_minimum_size = Vector2(maxf(cell_size, field.get_combined_minimum_size().x), maxf(cell_size, field.get_combined_minimum_size().y + 18))
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
	var clues := VBoxContainer.new()
	clues.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clues.add_theme_constant_override("separation", 14)
	clues.custom_minimum_size.x = 290
	layout.add_child(clues)
	for i in entries.size():
		var clue := Button.new()
		clue.text = "%d. %s • %d letras\n%s" % [i + 1, "Vertical" if entries[i]["vertical"] else "Horizontal", str(entries[i]["answer"]).length(), entries[i]["clue"]]
		clue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		clue.custom_minimum_size = Vector2(250, 76)
		clue.pressed.connect(select_word.bind(i))
		clues.add_child(clue)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.text = warning if not warning.is_empty() else "Escolha uma pista e preencha uma letra por casa. Role a grade se necessário."
	clues.add_child(status)

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
