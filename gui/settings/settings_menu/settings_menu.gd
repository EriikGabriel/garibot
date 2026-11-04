extends Control

## Configurações em dois modos: assistente em etapas antes da fase, ou páginas
## com categorias laterais quando aberto pela pausa (`opened_from_pause`).

@export var next_phase: PackedScene

var opened_from_pause := false
var current_step := 0

@onready var pages: Array[Control] = [
	%VisualPage,
	%ControlsPage,
	%AudioDialoguePage,
	%DisplayMotionPage,
]
@onready var sidebar: VBoxContainer = %Sidebar
@onready var categories: Array[Button] = [
	sidebar.get_node("Visual"),
	sidebar.get_node("Controls"),
	sidebar.get_node("AudioDialogue"),
	sidebar.get_node("DisplayMotion"),
]
@onready var content: ScrollContainer = %Content
@onready var title: Label = %Title
@onready var step_label: Label = %Step
@onready var navigation: Control = %Navigation
@onready var previous: Button = %Previous
@onready var next: Button = %Next
@onready var finish: Button = %Finish


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if opened_from_pause:
		add_to_group("pause_settings")
		title.text = "Configurações"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		sidebar.show()
		step_label.hide()
		navigation.hide()
		for index in categories.size():
			categories[index].pressed.connect(_show_step.bind(index))
	_show_step(0)


func _unhandled_input(event: InputEvent) -> void:
	if opened_from_pause and event.is_action_pressed("ui_cancel"):
		GameAudio.play_sound(&"ui_back")
		get_viewport().set_input_as_handled()
		_on_finish_pressed()


func _show_step(step: int) -> void:
	current_step = clampi(step, 0, pages.size() - 1)
	for index in pages.size():
		pages[index].visible = index == current_step
	content.scroll_vertical = 0
	content.scroll_horizontal = 0
	if opened_from_pause:
		for index in categories.size():
			categories[index].set_pressed_no_signal(index == current_step)
		categories[current_step].grab_focus()
		return
	step_label.text = "Etapa %d de %d" % [current_step + 1, pages.size()]
	previous.disabled = current_step == 0
	next.visible = current_step < pages.size() - 1
	finish.visible = not next.visible
	(next if next.visible else finish).grab_focus()


func _on_next_pressed() -> void:
	_show_step(current_step + 1)


func _on_previous_pressed() -> void:
	_show_step(current_step - 1)


func _on_restore_pressed() -> void:
	Settings.reset_settings()


func _on_finish_pressed() -> void:
	Settings.save_settings()
	if opened_from_pause:
		GameController.instance.delete_current_gui_scene()
		get_tree().get_first_node_in_group("pause_menu").resume()
		return
	GameController.instance.change_2d_scene(next_phase)
	GameController.instance.delete_current_gui_scene()
