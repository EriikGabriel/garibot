extends Control
## Assistente inicial e configurações com categorias laterais durante a pausa.

@export var next_phase: PackedScene
@export var back_to_menu := "res://gui/main_menu/main_menu.tscn"
var opened_from_pause := false

var current_step := 0
@onready var pages: Array[Control] = [
	$Overlay/Panel/Margin/Body/Layout/Content/Pages/VisualPage,
	$Overlay/Panel/Margin/Body/Layout/Content/Pages/ControlsPage,
	$Overlay/Panel/Margin/Body/Layout/Content/Pages/AudioDialoguePage,
	$Overlay/Panel/Margin/Body/Layout/Content/Pages/DisplayMotionPage,
]
@onready var step_label: Label = $Overlay/Panel/Margin/Body/Step
@onready var title: Label = $Overlay/Panel/Margin/Body/Title
@onready var previous: Button = $Overlay/Panel/Margin/Body/Navigation/Previous
@onready var next: Button = $Overlay/Panel/Margin/Body/Navigation/Next
@onready var finish: Button = $Overlay/Panel/Margin/Body/Navigation/Finish

@onready var sidebar: VBoxContainer = $Overlay/Panel/Margin/Body/Layout/Sidebar
@onready var categories: Array[Button] = [sidebar.get_node("Visual"), sidebar.get_node("Controls"), sidebar.get_node("AudioDialogue"), sidebar.get_node("DisplayMotion")]
@onready var content: ScrollContainer = $Overlay/Panel/Margin/Body/Layout/Content

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if opened_from_pause:
		title.text = "Configurações"
		add_to_group("pause_settings")
		sidebar.show()
		step_label.hide()
		$Overlay/Panel/Margin/Body/Navigation.hide()
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		for index in categories.size():
			categories[index].pressed.connect(_show_step.bind(index))
	_show_step(0)

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
	finish.visible = current_step == pages.size() - 1
	if next.visible:
		next.grab_focus()
	else:
		finish.grab_focus()

func _on_next_pressed() -> void:
	_show_step(current_step + 1)

func _on_previous_pressed() -> void:
	_show_step(current_step - 1)

func _on_finish_pressed() -> void:
	Settings.save_settings()
	if opened_from_pause:
		SceneManager.game_controller.delete_current_gui_scene()
		var pause_menu := get_tree().get_first_node_in_group("pause_menu")
		if pause_menu:
			pause_menu.resume()
		return
	# Mantém uma referência local antes de remover esta interface. O fallback
	# cobre cenas abertas por código sem a propriedade exportada configurada.
	var phase_scene := next_phase
	if phase_scene == null:
		phase_scene = load("res://levels/phase1/phase1.tscn") as PackedScene
	if phase_scene == null:
		push_error("Configurações: a cena da fase 1 não foi encontrada.")
		return
	SceneManager.game_controller.change_2d_scene(phase_scene)
	SceneManager.game_controller.delete_current_gui_scene()

func _on_restore_pressed() -> void:
	Settings.reset_settings()

func _on_back_pressed() -> void:
	if opened_from_pause:
		_on_finish_pressed()
	elif SceneManager.game_controller:
		SceneManager.game_controller.change_gui_scene(back_to_menu)

func _unhandled_input(event: InputEvent) -> void:
	if opened_from_pause and event.is_action_pressed("ui_cancel"):
		GameAudio.play_sound(&"ui_back")
		get_viewport().set_input_as_handled()
		_on_finish_pressed()
