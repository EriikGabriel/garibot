extends CanvasLayer

## Menu de pausa (Esc). Não abre por cima das configurações nem dos minigames.

const SETTINGS_SCENE_PATH := "res://gui/settings/settings_menu/settings_menu.tscn"
const MAIN_MENU_SCENE_PATH := "res://gui/main_menu/main_menu.tscn"

@onready var panel: Control = $Panel
@onready var dim: Control = $Dim


func _ready() -> void:
	add_to_group("pause_menu")
	show()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if (
		get_tree().get_first_node_in_group("pause_settings")
		or get_tree().get_first_node_in_group("minigame_modal")
	):
		return
	GameAudio.play_sound(&"ui_back" if panel.visible else &"ui_select")
	get_viewport().set_input_as_handled()
	if panel.visible:
		resume()
	else:
		open()


func open() -> void:
	get_tree().paused = true
	dim.show()
	panel.show()
	$Panel/Margin/Buttons/Resume.grab_focus()


func resume() -> void:
	panel.hide()
	dim.hide()
	get_tree().paused = false


func _on_resume_pressed() -> void:
	resume()


func _on_settings_pressed() -> void:
	panel.hide()
	dim.hide()
	# Carregada sob demanda: a cena de configurações também referencia a fase (ciclo).
	var settings: Control = load(SETTINGS_SCENE_PATH).instantiate()
	settings.opened_from_pause = true
	GameController.instance.change_gui_scene_instance(settings)


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	GameController.instance.delete_current_2d_scene()
	GameController.instance.change_gui_scene(MAIN_MENU_SCENE_PATH)
