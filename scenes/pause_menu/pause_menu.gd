extends CanvasLayer

@onready var panel: Control = $Panel

func _ready() -> void:
	add_to_group("pause_menu")
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.hide()
	$Dim.hide()

func _unhandled_input(event: InputEvent) -> void:
	if get_tree().get_first_node_in_group("minigame_modal") != null:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if panel.visible:
			resume()
		else:
			open()

func open() -> void:
	get_tree().paused = true
	$Dim.show()
	panel.show()
	$Panel/Margin/Buttons/Resume.grab_focus()

func resume() -> void:
	panel.hide()
	$Dim.hide()
	get_tree().paused = false

func open_settings() -> void:
	panel.hide()
	$Dim.hide()
	# Carregado sob demanda para evitar dependência circular com a fase,
	# que também instancia este menu de pausa.
	var settings_scene := load("res://gui/settings/settings_menu/settings_menu.tscn") as PackedScene
	if settings_scene == null:
		push_error("PauseMenu: não foi possível carregar as configurações.")
		panel.show()
		$Dim.show()
		return
	var settings := settings_scene.instantiate()
	settings.opened_from_pause = true
	SceneManager.game_controller.change_gui_scene_instance(settings)

func _on_resume_pressed() -> void:
	resume()

func _on_settings_pressed() -> void:
	open_settings()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	SceneManager.game_controller.delete_current_2d_scene()
	SceneManager.game_controller.change_gui_scene("res://gui/main_menu/main_menu.tscn")
