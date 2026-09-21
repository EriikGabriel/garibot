extends Control

@export var next_phase: PackedScene
@export var settings_scene: PackedScene

func _on_jogar_button_down() -> void:
	# Antes de iniciar a fase, exibe a tela de configuração.
	if settings_scene:
		SceneManager.game_controller.change_gui_scene(settings_scene.resource_path)
	elif next_phase:
		SceneManager.game_controller.delete_current_gui_scene()
		SceneManager.game_controller.change_2d_scene(next_phase)

func _on_sair_button_down() -> void:
	get_tree().quit()
