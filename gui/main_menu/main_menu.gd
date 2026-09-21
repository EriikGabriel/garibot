extends Control

@export var next_phase: PackedScene
@export var settings_scene: PackedScene

@onready var play_button: Button = $Card/Content/Jogar

func _ready() -> void:
	play_button.grab_focus()

func _on_jogar_button_down() -> void:
	# A aventura sempre passa pelo assistente de conforto e controles.
	if settings_scene:
		SceneManager.game_controller.change_gui_scene(settings_scene.resource_path)
	elif next_phase:
		SceneManager.game_controller.delete_current_gui_scene()
		SceneManager.game_controller.change_2d_scene(next_phase)

func _on_configuracoes_button_down() -> void:
	if settings_scene:
		SceneManager.game_controller.change_gui_scene(settings_scene.resource_path)

func _on_sair_button_down() -> void:
	get_tree().quit()
